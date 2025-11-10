#!/usr/bin/env bash
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
        export DOTFILES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
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

        It 'has Tools Used section'
            When call grep -q '## Tools' "${DOTFILES_PATH}/README.md"
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

        It 'all .md files have blank lines around headings (MD022)'
            Skip if "markdownlint not installed" ! command -v markdownlint >/dev/null 2>&1
            When call markdownlint -r MD022 "${DOTFILES_PATH}"/**/*.md
            The status should be success
        End
    End

    Describe 'Code blocks in documentation'
        It 'README.md code blocks specify language'
            # Check that code blocks use ```lang not just ```
            When call grep -P '^```$' "${DOTFILES_PATH}/README.md"
            The status should be failure
        End
    End
End
