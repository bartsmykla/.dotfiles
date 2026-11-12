#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
# shellcheck disable=SC2016  # Test literals intentionally contain Nix and shell interpolation syntax

Describe 'Fish mise activation'
    setup() {
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export FISH_ENVIRONMENT_MODULE="${DOTFILES_PATH}/nix/modules/home/fish/environment.nix"
    }
    Before 'setup'

    It 'disables Homebrew fish auto-activation before the vendor hook runs'
        When call grep -qF 'set -gx MISE_FISH_AUTO_ACTIVATE 0' "${FISH_ENVIRONMENT_MODULE}"
        The status should be success
    End

    It 'writes that disable flag to fish conf.d so it loads before vendor_conf.d'
        When call grep -qF 'xdg.configFile."fish/conf.d/mise-no-auto-activate.fish"' "${FISH_ENVIRONMENT_MODULE}"
        The status should be success
    End

    It 'activates mise from Home Manager exactly once'
        activate_count() {
            # Count real activate invocations, not comments.
            grep -cE '^[[:space:]]+\$mise_bin activate fish \| source$' "${FISH_ENVIRONMENT_MODULE}"
        }

        When call activate_count
        The output should eq 1
        The status should be success
    End

    It 'does not re-filter PATH to undo a vendor-hook snapshot'
        When call grep -qF 'vendor mise-activate.fish' "${FISH_ENVIRONMENT_MODULE}"
        The status should be failure
    End
End
