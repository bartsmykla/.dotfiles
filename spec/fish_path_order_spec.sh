#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
# shellcheck disable=SC2016  # The fish script expands its own variables

Describe 'Fish PATH order'
    setup() {
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export FISH_ENVIRONMENT_MODULE="${DOTFILES_PATH}/nix/modules/home/fish/environment.nix"
        FAKE_HOME=$(mktemp -d)
        export FAKE_HOME
        mkdir -p "${FAKE_HOME}/.local/bin" "${FAKE_HOME}/homebrew/bin" "${FAKE_HOME}/.config"
    }
    cleanup() { rm -rf "${FAKE_HOME}"; }
    Before 'setup'
    After 'cleanup'

    # Regression: a running shell that changed fish_user_paths later found
    # /opt/homebrew/bin/brew before the ~/.local/bin/brew token shim.
    It 'keeps ~/.local/bin first after fish rebuilds PATH from fish_user_paths'
        # A real config is needed: fish's own config rebuilds PATH when
        # fish_user_paths changes, and --no-config skips it.
        first_path_after_rebuild() {
            grep -E '^[[:space:]]+fish_add_path ' "${FISH_ENVIRONMENT_MODULE}" |
                env -i PATH=/usr/bin:/bin HOME="${FAKE_HOME}" XDG_CONFIG_HOME="${FAKE_HOME}/.config" \
                    HOMEBREW_PREFIX="${FAKE_HOME}/homebrew" "$(command -v fish)" \
                    -c 'source; set -g fish_user_paths $fish_user_paths; echo $PATH[1]'
        }

        Skip if 'fish is not installed' [ -z "$(command -v fish)" ]
        When call first_path_after_rebuild
        The output should eq "${FAKE_HOME}/.local/bin"
    End
End
