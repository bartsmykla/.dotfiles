#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
# shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable

Describe 'go-cache-trim'
    setup() {
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export GO_CACHE_MODULE="${DOTFILES_PATH}/nix/modules/home/go-cache.nix"
        TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/go-cache-trim-spec.XXXXXX")
        export TEST_ROOT
        TRIM_SCRIPT="${TEST_ROOT}/go-cache-trim"
        python3 - "$GO_CACHE_MODULE" "$TRIM_SCRIPT" <<'PY'
from pathlib import Path
import sys

src = Path(sys.argv[1]).read_text()
start = src.index('pkgs.writeShellScript "go-cache-trim" \'\'') + len('pkgs.writeShellScript "go-cache-trim" \'\'')
end = src.index("\n  '';\nin {", start)
body = src[start:end].replace("''${", "${").replace("${home}", "/tmp/go-cache-trim-testhome")
Path(sys.argv[2]).write_text("#!/bin/bash\n" + body.lstrip("\n"))
PY
        chmod +x "$TRIM_SCRIPT"
        export TRIM_SCRIPT

        export GO_CACHE_TRIM_GOBUILD="${TEST_ROOT}/go-build"
        export GO_CACHE_TRIM_GOLANGCI="${TEST_ROOT}/golangci-lint"
        export GO_CACHE_TRIM_LOCKDIR="${TEST_ROOT}/lock"
        export GO_CACHE_TRIM_STRAY_ROOTS="${TEST_ROOT}/worktrees"
        export GO_CACHE_TRIM_FAKE_BUSY=0
        export GO_CACHE_TRIM_FAKE_LOAD=0
        export GO_CACHE_TRIM_LOAD_THRESHOLD=14
        export GO_CACHE_TRIM_MIN_AGE_SECS=3600
        export GO_CACHE_TRIM_MAX_SECS=600
        export GO_CACHE_TRIM_GOBUILD_HIGH_KB=10485760
        export GO_CACHE_TRIM_GOBUILD_TARGET_KB=10485760
        export GO_CACHE_TRIM_GOLANGCI_HIGH_KB=10485760
        export GO_CACHE_TRIM_GOLANGCI_TARGET_KB=10485760

        mkdir -p "${GO_CACHE_TRIM_GOBUILD}" "${GO_CACHE_TRIM_GOLANGCI}" \
            "${GO_CACHE_TRIM_STRAY_ROOTS}/wt/.cache/go-build"
        # Eligible for the 2-day age trim; recent enough to skip the size pass.
        STRAY_OLD="${GO_CACHE_TRIM_STRAY_ROOTS}/wt/.cache/go-build/old-entry"
        echo stray-old >"$STRAY_OLD"
        # Portable mtime: macOS touch -A -030000 is a 3-hour adjustment, not 3 days.
        python3 -c 'import os,sys,time; t=time.time()-3*86400; os.utime(sys.argv[1], (t,t))' "$STRAY_OLD"
        export STRAY_OLD
    }

    cleanup() {
        if [ -n "${TEST_ROOT:-}" ] && [ -d "${TEST_ROOT}" ]; then
            rm -rf "${TEST_ROOT}"
        fi
    }
    Before 'setup'
    After 'cleanup'

    run_trim() {
        bash "$TRIM_SCRIPT"
    }

    It 'declares a busy-skip for the stray-cache scan in the module'
        When call grep -q 'is_busy "stray-cache scan"' "${GO_CACHE_MODULE}"
        The status should be success
    End

    It 'skips the stray-cache scan when go builds are running'
        export GO_CACHE_TRIM_FAKE_BUSY=1
        When call run_trim
        The status should be success
        The output should include "skip stray-cache scan: go compile/link/test/lint running"
        The file "$STRAY_OLD" should be exist
    End

    It 'skips the stray-cache scan when load is above the CPU threshold'
        export GO_CACHE_TRIM_FAKE_BUSY=0
        export GO_CACHE_TRIM_FAKE_LOAD=99
        When call run_trim
        The status should be success
        The output should include "skip stray-cache scan: load 99 > threshold 14"
        The file "$STRAY_OLD" should be exist
    End

    It 'age-trims stray caches when the system is not busy'
        export GO_CACHE_TRIM_FAKE_BUSY=0
        export GO_CACHE_TRIM_FAKE_LOAD=0
        When call run_trim
        The status should be success
        The output should include "done "
        The output should not include "skip stray-cache scan"
        The file "$STRAY_OLD" should not be exist
    End
End
