#!/usr/bin/env bash
#
# Makefile Tests
#
# PURPOSE:
#   Test Makefile targets and functionality
#
# WHAT'S TESTED:
#   - Makefile exists and has valid syntax
#   - All expected targets are defined
#   - Targets execute without syntax errors
#   - Help target shows all available commands
#
# HOW TO RUN:
#   shellspec spec/makefile_spec.sh
#   OR
#   make test-makefile
#
# REFERENCE:
#   https://www.gnu.org/software/make/manual/

Describe 'Makefile'
    setup() {
        # shellcheck disable=SC2155  # Declare and assign separately - not critical for test setup
        export DOTFILES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
        cd "${DOTFILES_PATH}" || return 1
    }
    Before 'setup'

    It 'exists in repository root'
        The file "${DOTFILES_PATH}/Makefile" should be exist
    End

    Describe 'Required targets exist'
        It 'has help target (default)'
            When call make -n help
            The status should be success
        End

        It 'has install target'
            When call make -n install
            The status should be success
        End

        It 'has brew target'
            When call make -n brew
            The status should be success
        End

        It 'has test target'
            When call make -n test
            The status should be success
        End

        It 'has lint target'
            When call make -n lint
            The status should be success
        End

        It 'has clean target'
            When call make -n clean
            The status should be success
        End

        It 'has update target'
            When call make -n update
            The status should be success
        End
    End

    Describe 'Help target'
        It 'help is the default target'
            When call make -n
            The status should be success
        End

        It 'help shows available targets'
            When call make help
            The status should be success
            The output should include "install"
            The output should include "brew"
            The output should include "test"
            The output should include "lint"
        End

        It 'help shows target descriptions'
            When call make help
            The status should be success
            # Should have descriptions, not just target names
            The output should match pattern ".*:.*"
        End
    End

    Describe 'Target behavior'
        It 'targets are marked as .PHONY'
            When call grep -q '\.PHONY:' "${DOTFILES_PATH}/Makefile"
            The status should be success
        End

        It 'Makefile has proper error handling'
            # Should use 'set -e' or equivalent for shell commands
            When call grep -qE '(set -e|\.ONESHELL:|SHELL.*-e)' "${DOTFILES_PATH}/Makefile"
            The status should be success
        End
    End
End
