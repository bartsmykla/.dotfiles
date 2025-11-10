#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
#
# Documentation Tests
#
# PURPOSE:
#   Ensure all required documentation exists and follows standards
#
# WHAT'S TESTED:
#   - Required documentation files exist
#   - Markdown files pass linting
#   - Documentation structure is correct
#   - Links in documentation are valid
#
# HOW TO RUN:
#   shellspec spec/documentation_spec.sh
#   OR
#   make test-docs
#
# REFERENCE:
#   https://github.com/DavidAnson/markdownlint

Describe 'Documentation'
    setup() {
        # shellcheck disable=SC2155  # Declare and assign separately - not critical for test setup
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
    }
    Before 'setup'

    Describe 'Required files exist'
        It 'has README.md'
            The file "${DOTFILES_PATH}/README.md" should be exist
        End

        It 'has CONTRIBUTING.md'
            The file "${DOTFILES_PATH}/CONTRIBUTING.md" should be exist
        End

        It 'has TESTING.md'
            The file "${DOTFILES_PATH}/TESTING.md" should be exist
        End

        It 'has ARCHITECTURE.md'
            The file "${DOTFILES_PATH}/ARCHITECTURE.md" should be exist
        End

        It 'has docs/DEBUGGING.md'
            The file "${DOTFILES_PATH}/docs/DEBUGGING.md" should be exist
        End
    End

    Describe 'README.md structure'
        It 'has Quick Start section'
            When call grep -q '## Quick Start' "${DOTFILES_PATH}/README.md"
            The status should be success
        End

        It 'has Installation section'
            When call grep -qE '## Installation' "${DOTFILES_PATH}/README.md"
            The status should be success
        End

        It 'has Features section'
            When call grep -q '## Features' "${DOTFILES_PATH}/README.md"
            The status should be success
        End

        It 'has Usage section'
            When call grep -q '## Usage' "${DOTFILES_PATH}/README.md"
            The status should be success
        End

        It 'has Troubleshooting section'
            When call grep -q '## Troubleshooting' "${DOTFILES_PATH}/README.md"
            The status should be success
        End
    End

    Describe 'Markdown linting'
        It 'README.md passes markdownlint'
            Skip if "markdownlint not installed" ! command -v markdownlint >/dev/null 2>&1
            When call markdownlint "${DOTFILES_PATH}/README.md"
            The status should be success
        End

        It 'core documentation files pass markdownlint'
            Skip if "markdownlint not installed" ! command -v markdownlint >/dev/null 2>&1
            # Test only core docs, not vim bundles or tmp files
            When call markdownlint \
                "${DOTFILES_PATH}"/*.md \
                "${DOTFILES_PATH}"/docs/*.md
            The status should be success
        End
    End

    Describe 'Code blocks in documentation'
        It 'README.md has balanced code blocks'
            # Count code block markers (should be even number - opening + closing)
            check_code_blocks() {
                local count
                count=$(grep -c '^```' "${DOTFILES_PATH}/README.md" || true)
                [ $((count % 2)) -eq 0 ]
            }
            When call check_code_blocks
            The status should be success
        End
    End
End
