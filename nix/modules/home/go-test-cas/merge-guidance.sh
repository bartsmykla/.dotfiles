#!/usr/bin/env bash
# shellcheck disable=SC2292  # POSIX [ ] tests are used consistently in these scripts
# shellcheck disable=SC2249  # case patterns are exhaustive for the values we handle
# Append the managed Go-on-macOS guidance block to a markdown file if it is
# not already present. Never overwrites existing content. Missing files are
# created with just the block when --create is passed.
set -u

CREATE=0
FILE=""
BLOCK=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --create) CREATE=1 ;;
    --file) FILE=$2; shift ;;
    --block) BLOCK=$2; shift ;;
    *) printf 'usage: merge-guidance.sh [--create] --file PATH --block PATH\n' >&2; exit 2 ;;
  esac
  shift
done

if [ -z "$FILE" ] || [ -z "$BLOCK" ]; then
  printf 'usage: merge-guidance.sh [--create] --file PATH --block PATH\n' >&2
  exit 2
fi
if [ ! -f "$BLOCK" ]; then
  printf 'go-test-cas: guidance block missing\n' >&2
  exit 1
fi

MARKER='<!-- managed:go-test-macos -->'

if [ ! -e "$FILE" ]; then
  if [ "$CREATE" -eq 0 ]; then
    printf 'go-test-cas: skip guidance merge, missing %s\n' "$(basename "$FILE")" >&2
    exit 0
  fi
  /usr/bin/install -m 600 "$BLOCK" "$FILE"
  printf 'go-test-cas: seeded %s\n' "$(basename "$FILE")" >&2
  exit 0
fi

if /usr/bin/grep -F -q "$MARKER" "$FILE"; then
  printf 'go-test-cas: guidance already present in %s\n' "$(basename "$FILE")" >&2
  exit 0
fi

{
  printf '\n'
  /bin/cat "$BLOCK"
  printf '\n'
} >> "$FILE"
printf 'go-test-cas: appended guidance to %s\n' "$(basename "$FILE")" >&2
exit 0
