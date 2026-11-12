#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
# shellcheck disable=SC2016  # Child-shell -c snippets must expand FILTER_SCRIPT and PATH later

Describe 'filter_existing_path'
    setup() {
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export FILTER_SCRIPT="${DOTFILES_PATH}/nix/modules/home/shell/filter-existing-path.sh"
        TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/filter-path.XXXXXX")
        export TEST_ROOT
        mkdir -p "${TEST_ROOT}/keep-a" "${TEST_ROOT}/keep-b" "${TEST_ROOT}/keep dir"
        ln -s "${TEST_ROOT}/keep-a" "${TEST_ROOT}/link-to-dir"
        # A dangling symlink and a regular file must not stay on PATH.
        ln -s "${TEST_ROOT}/does-not-exist" "${TEST_ROOT}/dangling"
        echo x >"${TEST_ROOT}/not-a-dir"
        # Capture interpreters before tests overwrite PATH.
        TEST_SH=$(command -v sh)
        TEST_BASH=$(command -v bash)
        TEST_ZSH=$(command -v zsh || true)
        export TEST_SH TEST_BASH TEST_ZSH
    }
    cleanup() {
        if [ -n "${TEST_ROOT:-}" ] && [ -d "${TEST_ROOT}" ]; then
            rm -rf "${TEST_ROOT}"
        fi
    }
    Before 'setup'
    After 'cleanup'

    run_filter() {
        # Source in POSIX sh so the snippet stays portable for bash and zsh.
        # FILTER_SCRIPT is exported; a dummy $0 is not needed.
        PATH="$1" "$TEST_SH" -c '. "$FILTER_SCRIPT"; printf %s "$PATH"'
    }

    It 'is a POSIX shell script in the repo'
        When call test -f "${FILTER_SCRIPT}"
        The status should be success
    End

    It 'drops missing directories and keeps existing ones in order'
        input="${TEST_ROOT}/keep-a:${TEST_ROOT}/missing:${TEST_ROOT}/keep-b"
        When call run_filter "$input" "$FILTER_SCRIPT"
        The output should eq "${TEST_ROOT}/keep-a:${TEST_ROOT}/keep-b"
        The status should be success
    End

    It 'deduplicates later copies and keeps the first occurrence'
        input="${TEST_ROOT}/keep-a:${TEST_ROOT}/keep-b:${TEST_ROOT}/keep-a"
        When call run_filter "$input" "$FILTER_SCRIPT"
        The output should eq "${TEST_ROOT}/keep-a:${TEST_ROOT}/keep-b"
        The status should be success
    End

    It 'skips empty PATH components from extra colons'
        input=":${TEST_ROOT}/keep-a::${TEST_ROOT}/keep-b:"
        When call run_filter "$input" "$FILTER_SCRIPT"
        The output should eq "${TEST_ROOT}/keep-a:${TEST_ROOT}/keep-b"
        The status should be success
    End

    It 'keeps directories reached through a symlink and drops dangling links and files'
        input="${TEST_ROOT}/link-to-dir:${TEST_ROOT}/dangling:${TEST_ROOT}/not-a-dir:${TEST_ROOT}/keep-b"
        When call run_filter "$input" "$FILTER_SCRIPT"
        The output should eq "${TEST_ROOT}/link-to-dir:${TEST_ROOT}/keep-b"
        The status should be success
    End

    It 'preserves directory names that contain spaces'
        input="${TEST_ROOT}/keep dir:${TEST_ROOT}/keep-a"
        When call run_filter "$input" "$FILTER_SCRIPT"
        The output should eq "${TEST_ROOT}/keep dir:${TEST_ROOT}/keep-a"
        The status should be success
    End

    It 'yields an empty PATH when every entry is missing'
        input="${TEST_ROOT}/missing-a:${TEST_ROOT}/missing-b"
        When call run_filter "$input" "$FILTER_SCRIPT"
        The output should eq ""
        The status should be success
    End

    It 'filters the same way when sourced from bash'
        run_filter_bash() {
            PATH="$1" "$TEST_BASH" --norc --noprofile -c '. "$FILTER_SCRIPT"; printf %s "$PATH"' 
        }
        input="${TEST_ROOT}/keep-a:${TEST_ROOT}/missing:${TEST_ROOT}/keep-b:${TEST_ROOT}/keep-a"
        When call run_filter_bash "$input"
        The output should eq "${TEST_ROOT}/keep-a:${TEST_ROOT}/keep-b"
        The status should be success
    End

    zsh_is_missing() {
        ! command -v zsh >/dev/null 2>&1
    }

    It 'filters the same way when sourced from zsh'
        # Skip if cannot take a raw `! command` pipeline; use a helper.
        Skip if "zsh is not installed" zsh_is_missing
        run_filter_zsh() {
            PATH="$1" "$TEST_ZSH" -f -c '. "$FILTER_SCRIPT"; printf %s "$PATH"' 
        }
        input="${TEST_ROOT}/keep-a:${TEST_ROOT}/missing:${TEST_ROOT}/keep-b:${TEST_ROOT}/keep-a"
        When call run_filter_zsh "$input"
        The output should eq "${TEST_ROOT}/keep-a:${TEST_ROOT}/keep-b"
        The status should be success
    End
End
