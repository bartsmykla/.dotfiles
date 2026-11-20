#!/usr/bin/env bash
# shellcheck disable=SC2292  # POSIX [ ] tests are used consistently in these scripts
# shellcheck disable=SC2249  # case patterns are exhaustive for the values we handle
# PATH shim for `go`. Injects `go test -exec=<go-test-cas-exec>` only for runs
# that already bypass the Go test result cache (an explicit -count, on the
# command line or in GOFLAGS). go test never caches results of a run with
# -exec, so injecting into a cacheable run would rerun every package.
#
# Skips injection when the caller passed -exec (or GOFLAGS has one), asked
# for compile-only (-c) or a kept binary (-o), targets another GOOS/GOARCH,
# or set GO_TEST_CAS=0. Never writes -exec into GOFLAGS.
#
# Resolves the real go binary by walking PATH, skipping this script and
# asking mise/asdf which go their shims would run.

set -u

debug() {
  if [ "${GO_TEST_CAS_DEBUG:-0}" != "0" ]; then
    printf 'go-shim: %s\n' "$*" >&2
  fi
}

# Resolve this script, even when invoked through a symlink.
SELF=$0
if command -v realpath >/dev/null 2>&1; then
  SELF=$(realpath "$0") 2>/dev/null || SELF=$0
elif self_link=$(readlink "$0" 2>/dev/null) && [ -n "$self_link" ]; then
  case "$self_link" in
    /*) SELF=$self_link ;;
    *) SELF=$(cd "$(dirname "$0")" && pwd)/$self_link ;;
  esac
fi
# Home Manager links each file to its own store path, so the helper sits next
# to the invoked path ($0), not next to the resolved script.
EXEC_HELPER="${GO_TEST_CAS_EXEC:-$(cd "$(dirname "$0")" && pwd)/go-test-cas-exec}"

is_this_shim() {
  cand=$1
  [ -e "$cand" ] || return 1
  if command -v realpath >/dev/null 2>&1; then
    [ "$(realpath "$cand" 2>/dev/null || echo "$cand")" = "$SELF" ]
    return
  fi
  [ "$cand" = "$SELF" ] || [ "$cand" = "$0" ]
}

is_native_go() {
  cand=$1
  [ -n "$cand" ] && [ -f "$cand" ] && [ -x "$cand" ] || return 1
  is_this_shim "$cand" && return 1
  # Real go toolchains are native binaries; shims are scripts.
  if [ -r "$cand" ]; then
    # Mach-O LE/BE, fat, or ELF. od is in PATH on macOS and Linux CI.
    sig=$(od -An -tx1 -N4 "$cand" 2>/dev/null | tr -d " \n")
    case "$sig" in
      cffaedfe|feedfacf|cafebabe|7f454c46) return 0 ;;
    esac
  fi
  return 1
}

find_real_go() {
  # Honor an explicit override even if it is a script (used in tests).
  if [ -n "${GO_TEST_CAS_REAL_GO:-}" ] && [ -x "$GO_TEST_CAS_REAL_GO" ] && ! is_this_shim "$GO_TEST_CAS_REAL_GO"; then
    printf '%s\n' "$GO_TEST_CAS_REAL_GO"
    return 0
  fi

  IFS=':'
  # shellcheck disable=SC2086
  for dir in $PATH; do
    unset IFS
    [ -n "$dir" ] || continue
    cand="${dir}/go"
    # A version-manager shim picks the go for the current directory; ask it
    # for that binary instead of exec'ing the shim, which could re-enter us.
    case "$cand" in
      */mise/shims/go|*/.mise/shims/go)
        cand=$(mise which go 2>/dev/null) || cand=""
        ;;
      */asdf/shims/go|*/.asdf/shims/go)
        cand=$(asdf which go 2>/dev/null) || cand=""
        ;;
    esac
    if is_native_go "$cand"; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  unset IFS

  for cand in /opt/homebrew/bin/go /usr/local/bin/go; do
    if is_native_go "$cand"; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  return 1
}

# Flags (with any leading -- folded to -) that pick an executor or make go
# keep the test binary (-c, -o, profiles). A kept binary can share the cache
# entry's inode, so an edit to it would change the cached bytes.
blocks_inject() {
  case "$1" in
    -exec|-exec=*|-c|-c=true|-o|-o=*) return 0 ;;
    -cpuprofile|-cpuprofile=*|-memprofile|-memprofile=*) return 0 ;;
    -blockprofile|-blockprofile=*|-mutexprofile|-mutexprofile=*) return 0 ;;
  esac
  return 1
}

# Return 0 if this invocation is a `go test` run that will execute a binary,
# already bypasses the test result cache, and has no -exec yet. Global flags
# before the subcommand (especially -C) are skipped.
should_inject() {
  if [ "${GO_TEST_CAS:-1}" = "0" ]; then
    return 1
  fi
  if [ ! -x "$EXEC_HELPER" ]; then
    debug "helper missing: $EXEC_HELPER"
    return 1
  fi

  saw_test=0
  has_count=0
  skip_value=0

  for a in "$@"; do
    if [ "$skip_value" -eq 1 ]; then
      skip_value=0
      continue
    fi
    if [ "$saw_test" -eq 0 ]; then
      case "$a" in
        -C|--C)
          skip_value=1
          continue
          ;;
        -*)
          continue
          ;;
        test)
          saw_test=1
          continue
          ;;
        *)
          # Some other subcommand (build, run, list, env, help, ...).
          return 1
          ;;
      esac
    fi
    case "$a" in --*) a=${a#-} ;; esac
    if blocks_inject "$a"; then
      return 1
    fi
    case "$a" in
      -args) break ;;
      -count)
        has_count=1
        skip_value=1
        ;;
      -count=*)
        has_count=1
        ;;
      # Regex values may start with "-"; do not read them as flags.
      -run|-skip|-bench|-list)
        skip_value=1
        ;;
    esac
  done

  if [ "$saw_test" -eq 0 ]; then
    return 1
  fi

  # Effective values, including the go env file, not only the environment.
  env_out=$("$REAL_GO" env GOFLAGS GOOS GOARCH GOHOSTOS GOHOSTARCH 2>/dev/null) || return 1
  {
    IFS= read -r goflags
    read -r goos
    read -r goarch
    read -r hostos
    read -r hostarch
  } <<EOF
$env_out
EOF
  # A cross target may use go_GOOS_GOARCH_exec; leave it to go.
  if [ "$goos" != "$hostos" ] || [ "$goarch" != "$hostarch" ]; then
    return 1
  fi
  # go accepts quoted GOFLAGS entries; do not guess how to split them.
  case "$goflags" in
    *\"*|*\'*) return 1 ;;
  esac
  # shellcheck disable=SC2086
  set -- $goflags
  for a in "$@"; do
    case "$a" in --*) a=${a#-} ;; esac
    if blocks_inject "$a"; then
      return 1
    fi
    case "$a" in
      -count=*) has_count=1 ;;
    esac
  done

  [ "$has_count" -eq 1 ]
}

# bash 3.2 with `set -u` treats "${arr[@]}" as unbound when arr is empty
# (macOS /bin/bash). Only expand the prefix when it has elements.
exec_with_prefix() {
  real=$1
  shift
  if [ "${#prefix[@]}" -gt 0 ]; then
    exec "$real" "${prefix[@]}" "$@"
  fi
  exec "$real" "$@"
}

inject_and_exec() {
  real=$1
  shift
  prefix=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -C|--C)
        [ "$#" -ge 2 ] || break
        prefix+=("$1" "$2")
        shift 2
        continue
        ;;
      -*)
        prefix+=("$1")
        shift
        continue
        ;;
      test)
        shift
        prefix+=(test)
        # go requires -C to be the first flag after the subcommand too.
        case "${1:-}" in
          -C|--C)
            if [ "$#" -ge 2 ]; then
              prefix+=("$1" "$2")
              shift 2
            fi
            ;;
          -C=*|--C=*)
            prefix+=("$1")
            shift
            ;;
        esac
        debug "inject -exec=$EXEC_HELPER"
        exec_with_prefix "$real" -exec="$EXEC_HELPER" "$@"
        ;;
      *)
        # Should not be reached; should_inject already checked.
        exec_with_prefix "$real" "$@"
        ;;
    esac
  done
  exec_with_prefix "$real" "$@"
}

REAL_GO=$(find_real_go) || {
  printf 'go-shim: could not resolve a real go binary (set GO_TEST_CAS_REAL_GO)\n' >&2
  exit 127
}
debug "real go: $REAL_GO"

if should_inject "$@"; then
  inject_and_exec "$REAL_GO" "$@"
fi

exec "$REAL_GO" "$@"
