#!/usr/bin/env bash
# shellcheck disable=SC2292  # POSIX [ ] tests are used consistently in these scripts
# shellcheck disable=SC2249  # case patterns are exhaustive for the values we handle
# Content-addressed exec helper for `go test -exec`.
#
# Hashes the test binary, stores it at $GO_TEST_CAS_DIR/<sha256> (hardlink
# when the cache is on the same volume, otherwise a copy), and execs the
# cache inode. macOS XProtect/syspolicyd cache by inode, so a later go test
# that writes an identical binary to a new temp path can reuse the already
# scanned inode.
#
# On any cache failure, exec the original binary so tests still run.

set -u

debug() {
  if [ "${GO_TEST_CAS_DEBUG:-0}" != "0" ]; then
    printf 'go-test-cas-exec: %s\n' "$*" >&2
  fi
}

usage() {
  printf 'usage: go-test-cas-exec <test-binary> [args...]\n' >&2
  exit 2
}

[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && usage
[ "$#" -ge 1 ] || usage

ORIG=$1
shift

run_original() {
  debug "fallback to original binary"
  exec "$ORIG" "$@"
}

if [ "${GO_TEST_CAS:-1}" = "0" ]; then
  run_original "$@"
fi

if [ ! -f "$ORIG" ] || [ ! -x "$ORIG" ]; then
  run_original "$@"
fi

CACHE_DIR="${GO_TEST_CAS_DIR:-${HOME}/Library/Caches/go-test-cas}"
if ! /bin/mkdir -p "$CACHE_DIR" 2>/dev/null; then
  run_original "$@"
fi

sha=$(/usr/bin/shasum -a 256 "$ORIG" 2>/dev/null | /usr/bin/awk '{print $1}')
if [ -z "$sha" ] || [ "${#sha}" -ne 64 ]; then
  run_original "$@"
fi

DEST="${CACHE_DIR}/${sha}"

if [ -x "$DEST" ]; then
  debug "hit $sha"
  exec "$DEST" "$@"
fi

debug "miss $sha"
TMP=$(/usr/bin/mktemp "${CACHE_DIR}/${sha}.tmp.XXXXXX") || run_original "$@"
# mktemp creates an empty file; remove it so ln can hardlink onto that name.
# (ln otherwise fails and we would always fall back to a copy.)
/bin/rm -f "$TMP"

if ! /bin/ln "$ORIG" "$TMP" 2>/dev/null; then
  if ! /bin/cp "$ORIG" "$TMP" 2>/dev/null; then
    /bin/rm -f "$TMP"
    run_original "$@"
  fi
  /bin/chmod u+rwx "$TMP" 2>/dev/null || true
fi

# Exclusive publish: ln fails if DEST already exists (lost the race).
if /bin/ln "$TMP" "$DEST" 2>/dev/null; then
  /bin/rm -f "$TMP"
else
  /bin/rm -f "$TMP"
  if [ ! -x "$DEST" ]; then
    run_original "$@"
  fi
fi

debug "exec cache $sha"
exec "$DEST" "$@"
