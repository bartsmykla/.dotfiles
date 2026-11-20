#!/usr/bin/env bash
# shellcheck disable=SC2292  # POSIX [ ] tests are used consistently in these scripts
# shellcheck disable=SC2249  # case patterns are exhaustive for the values we handle
# PATH shim for `go`. Injects `go test -exec=<go-test-cas-exec>` unless the
# caller already passed -exec, asked for compile-only (`go test -c`), or set
# GO_TEST_CAS=0. Never writes -exec into GOFLAGS.
#
# Resolves the real go binary by walking PATH and known install locations,
# skipping this script and path-lookup shims (mise, asdf) to avoid recursion.

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
SELF_DIR=$(cd "$(dirname "$SELF")" && pwd)
EXEC_HELPER="${GO_TEST_CAS_EXEC:-${SELF_DIR}/go-test-cas-exec}"

is_this_shim() {
  cand=$1
  [ -e "$cand" ] || return 1
  if command -v realpath >/dev/null 2>&1; then
    [ "$(realpath "$cand" 2>/dev/null || echo "$cand")" = "$SELF" ]
    return
  fi
  [ "$cand" = "$SELF" ] || [ "$cand" = "$0" ]
}

is_path_lookup_shim() {
  cand=$1
  case "$cand" in
    */mise/shims/*|*/.mise/shims/*|*/asdf/shims/*|*/.asdf/shims/*)
      return 0
      ;;
  esac
  return 1
}

is_native_go() {
  cand=$1
  [ -f "$cand" ] && [ -x "$cand" ] || return 1
  is_this_shim "$cand" && return 1
  is_path_lookup_shim "$cand" && return 1
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

  # Guard against recursion if a shim on PATH re-invokes `go`.
  if [ -n "${GO_TEST_CAS_RESOLVING:-}" ]; then
    return 1
  fi
  export GO_TEST_CAS_RESOLVING=1

  IFS=':'
  # shellcheck disable=SC2086
  for dir in $PATH; do
    unset IFS
    [ -n "$dir" ] || continue
    cand="${dir}/go"
    if is_native_go "$cand"; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  unset IFS

  # mise / Homebrew / usr local, newest mise install last-wins via glob sort
  for cand in \
    /opt/homebrew/bin/go \
    /usr/local/bin/go \
    "${HOME}/.local/share/mise/installs/go/"*/bin/go
  do
    if is_native_go "$cand"; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  return 1
}

goflags_has_exec() {
  # Word-split GOFLAGS the way the go command does (spaces).
  # shellcheck disable=SC2086
  set -- ${GOFLAGS:-}
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -exec|--exec|-exec=*|--exec=*) return 0 ;;
    esac
    shift
  done
  return 1
}

# Return 0 if this invocation is `go test` that will run a binary and has no
# -exec yet. Global flags before the subcommand (especially -C) are skipped.
should_inject() {
  if [ "${GO_TEST_CAS:-1}" = "0" ]; then
    return 1
  fi
  if [ ! -x "$EXEC_HELPER" ]; then
    debug "helper missing: $EXEC_HELPER"
    return 1
  fi

  saw_test=0
  has_exec=0
  has_c=0
  skip_value=0

  for a in "$@"; do
    if [ "$skip_value" -eq 1 ]; then
      skip_value=0
      continue
    fi
    if [ "$saw_test" -eq 0 ]; then
      case "$a" in
        -C)
          skip_value=1
          continue
          ;;
        -C=*)
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
    case "$a" in
      --) break ;;
      -exec|--exec)
        has_exec=1
        skip_value=1
        ;;
      -exec=*|--exec=*)
        has_exec=1
        ;;
      -c)
        has_c=1
        ;;
    esac
  done

  if [ "$saw_test" -eq 0 ]; then
    return 1
  fi
  if [ "$has_exec" -eq 1 ] || goflags_has_exec; then
    return 1
  fi
  if [ "$has_c" -eq 1 ]; then
    return 1
  fi
  return 0
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
      -C)
        prefix+=("$1" "$2")
        shift 2
        continue
        ;;
      -C=*)
        prefix+=("$1")
        shift
        continue
        ;;
      -*)
        prefix+=("$1")
        shift
        continue
        ;;
      test)
        shift
        debug "inject -exec=$EXEC_HELPER"
        exec_with_prefix "$real" test -exec="$EXEC_HELPER" "$@"
        ;;
      *)
        # Should not be reached; should_inject already checked.
        exec_with_prefix "$real" "$@"
        ;;
    esac
  done
  exec_with_prefix "$real"
}

REAL_GO=$(find_real_go) || {
  printf 'go-shim: could not resolve a real go binary (set GO_TEST_CAS_REAL_GO)\n' >&2
  exit 127
}

if should_inject "$@"; then
  inject_and_exec "$REAL_GO" "$@"
fi

exec "$REAL_GO" "$@"
