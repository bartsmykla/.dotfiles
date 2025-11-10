#!/usr/bin/env bash
#
# Fish Functions Tests
#
# PURPOSE:
#   Test all custom Fish functions to ensure they work correctly
#
# WHAT'S TESTED:
#   - Fish function definitions exist
#   - Functions have proper syntax
#   - Functions execute without errors
#   - Functions behave as expected
#
# HOW TO RUN:
#   shellspec spec/fish_functions_spec.sh
#   OR
#   make test-functions
#
# REFERENCE:
#   https://shellspec.info/

Describe 'Fish Functions'
    # Setup: Ensure Fish is available
    setup() {
        # shellcheck disable=SC2155  # Declare and assign separately - not critical for test setup
        export DOTFILES_PATH="$(cd "$(dirname "$0")/.." && pwd)"
    }
    Before 'setup'

    # Test: link_dotfile function exists and is defined
    Describe 'link_dotfile'
        It 'exists as a Fish function'
            When call fish -c "type -q link_dotfile"
            The status should be success
        End

        It 'has valid Fish syntax'
            When call fish -n "${DOTFILES_PATH}/.config/fish/functions/link_dotfile.fish"
            The status should be success
        End

        It 'shows help when called without arguments'
            # This will fail currently but documents expected behavior
            Skip "Not implemented yet - function should show usage"
            When call fish -c "link_dotfile"
            The status should be failure
            The stderr should include "Usage:"
        End
    End

    # Test: git_clone_to_projects function
    Describe 'git_clone_to_projects'
        It 'exists as a Fish function'
            When call fish -c "type -q git_clone_to_projects"
            The status should be success
        End

        It 'has valid Fish syntax'
            When call fish -n "${DOTFILES_PATH}/.config/fish/functions/git_clone_to_projects.fish"
            The status should be success
        End

        It 'fails with invalid repository URL'
            When call fish -c "git_clone_to_projects 'invalid-url'"
            The status should be failure
            The stderr should include "Invalid"
        End
    End

    # Test: git-push-* family of functions
    Describe 'git-push functions'
        It 'git-push-origin exists'
            When call fish -c "type -q git-push-origin"
            The status should be success
        End

        It 'git-push-upstream exists'
            When call fish -c "type -q git-push-upstream"
            The status should be success
        End

        It 'git-push-origin-force-with-lease exists'
            When call fish -c "type -q git-push-origin-force-with-lease"
            The status should be success
        End
    End

    # Test: klg and kls kubernetes functions
    Describe 'Kubernetes log functions'
        It 'klg function exists'
            When call fish -c "type -q klg"
            The status should be success
        End

        It 'klg has valid syntax'
            When call fish -n "${DOTFILES_PATH}/.config/fish/functions/klg.fish"
            The status should be success
        End

        It 'kls function exists'
            When call fish -c "type -q kls"
            The status should be success
        End

        It 'kls has valid syntax'
            When call fish -n "${DOTFILES_PATH}/.config/fish/functions/kls.fish"
            The status should be success
        End
    End

    # Test: All Fish functions have valid syntax
    Describe 'All Fish functions syntax'
        It 'checks syntax of all .fish files'
            count=0
            failed=0
            for file in "${DOTFILES_PATH}/.config/fish/functions"/*.fish; do
                [ -f "$file" ] || continue
                count=$((count + 1))
                if ! fish -n "$file" 2>/dev/null; then
                    echo "Syntax error in: $file" >&2
                    failed=$((failed + 1))
                fi
            done

            [ $failed -eq 0 ]
            The status should be success
        End
    End
End
