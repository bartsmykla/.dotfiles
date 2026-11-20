#!/usr/bin/env bash
# shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable

Describe 'go-test-guidance merge'
    setup() {
        DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        SRC="${DOTFILES_PATH}/nix/modules/home/go-test-guidance"
        TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/go-test-guidance-spec.XXXXXX")
    }
    cleanup() { rm -rf "${TEST_ROOT}"; }
    Before 'setup'
    After 'cleanup'

    merge_twice() {
        live="${TEST_ROOT}/AGENTS.md"
        printf '%s\n' "# existing" >"$live"
        bash "${SRC}/merge-guidance.sh" --file "$live" --block "${SRC}/guidance.md" 2>/dev/null
        bash "${SRC}/merge-guidance.sh" --file "$live" --block "${SRC}/guidance.md" 2>/dev/null
        head -1 "$live"
        grep -c 'managed:go-test-macos' "$live"
    }

    merge_missing() {
        bash "${SRC}/merge-guidance.sh" --file "${TEST_ROOT}/missing.md" --block "${SRC}/guidance.md" 2>/dev/null
        test -e "${TEST_ROOT}/missing.md"
    }

    It 'appends the block once and keeps existing content'
        When call merge_twice
        The status should be success
        The line 1 of output should eq "# existing"
        The line 2 of output should eq "2"
    End

    It 'does not create a missing file'
        When call merge_missing
        The status should be failure
    End
End
