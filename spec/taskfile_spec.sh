#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
#
# Taskfile Tests
#
# PURPOSE:
#   Test Taskfile.yaml tasks and functionality
#
# WHAT'S TESTED:
#   - Taskfile.yaml exists and has valid syntax
#   - All expected tasks are defined
#   - Tasks can be listed without errors
#   - Task list shows all available commands
#
# HOW TO RUN:
#   shellspec spec/taskfile_spec.sh
#   OR
#   task test:shellspec
#
# REFERENCE:
#   https://taskfile.dev

Describe 'Taskfile'
    setup() {
        # shellcheck disable=SC2155  # Declare and assign separately - not critical for test setup
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        cd "${DOTFILES_PATH}" || return 1
    }
    Before 'setup'

    It 'exists in repository root'
        The file "${DOTFILES_PATH}/Taskfile.yaml" should be exist
    End

    It 'has valid YAML syntax'
        When call task --list
        The status should be success
        The output should be present
    End

    Describe 'Required tasks exist'
        It 'has default task (list)'
            When call task --list
            The output should include "default"
        End

        It 'has install task'
            When call task --list
            The output should include "install"
        End

        It 'has test task'
            When call task --list
            The output should include "test"
        End

        It 'has lint task'
            When call task --list
            The output should include "lint"
        End

        It 'has clean task'
            When call task --list
            The output should include "clean"
        End

        It 'has update task'
            When call task --list
            The output should include "update"
        End
    End

    Describe 'Task list output'
        It 'shows available tasks with descriptions'
            When call task --list
            The status should be success
            The output should include "Run all tests"
        End

        It 'can show tasks in list format'
            When call task --list-all
            The status should be success
            The output should be present
        End
    End

    Describe 'Taskfile validation'
        It 'passes JSON schema validation'
            Skip if "check-jsonschema not installed" ! command -v check-jsonschema >/dev/null 2>&1
            When call check-jsonschema --schemafile https://taskfile.dev/schema.json "${DOTFILES_PATH}/Taskfile.yaml"
            The status should be success
            The output should include "ok"
        End
    End
End
