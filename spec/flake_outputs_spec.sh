#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
# shellcheck disable=SC2016  # Test literals intentionally contain Nix interpolation syntax

Describe 'Nix flake outputs'
    setup() {
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export FLAKE="${DOTFILES_PATH}/nix/flake.nix"
    }
    Before 'setup'

    It 'exports the nix-darwin package set as legacyPackages'
        When call grep -qF 'legacyPackages.${system} = self.darwinConfigurations.${hostname}.pkgs;' "${FLAKE}"
        The status should be success
    End

    It 'does not export an unofficial darwinPackages flake output'
        When call grep -qE '^[[:space:]]*darwinPackages[[:space:]]*=' "${FLAKE}"
        The status should be failure
    End
End
