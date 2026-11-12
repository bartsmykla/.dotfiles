#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
# shellcheck disable=SC2016  # Test literals intentionally contain Nix and shell interpolation syntax

Describe 'Home Manager executable profile paths'
    setup() {
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export DARWIN_MODULE="${DOTFILES_PATH}/nix/modules/darwin/default.nix"
        export TMUX_MODULE="${DOTFILES_PATH}/nix/modules/home/tmux.nix"
        export FISH_ENVIRONMENT_MODULE="${DOTFILES_PATH}/nix/modules/home/fish/environment.nix"
    }
    Before 'setup'

    It 'uses the active Home Manager profile for every tmux Fish executable'
        count_tmux_profile_fish_references() {
            grep -cF '${config.home.profileDirectory}/bin/fish' "${TMUX_MODULE}"
        }

        When call count_tmux_profile_fish_references
        The output should eq 3
        The status should be success
    End

    It 'uses the active Home Manager profile for the exported Bash shell'
        When call grep -qF 'set --export SHELL ${config.home.profileDirectory}/bin/bash' "${FISH_ENVIRONMENT_MODULE}"
        The status should be success
    End

    It 'does not require shell executables from the optional user profile'
        When call grep -RE '\.nix-profile/bin/(bash|fish)' "${DOTFILES_PATH}/nix/modules/home"
        The status should be failure
    End

    It 'does not add the unused per-user profile to PATH configuration'
        no_stale_per_user_profile_path() {
            ! grep -qF '"/etc/profiles/per-user/${config.system.primaryUser}/bin"' "${DARWIN_MODULE}" &&
                ! grep -qF 'fish_add_path --prepend --move /etc/profiles/per-user/$USER/bin' "${DARWIN_MODULE}"
        }

        When call no_stale_per_user_profile_path
        The status should be success
    End

    It 'does not add /usr/local/sbin to the launchd path'
        When call grep -qF '"/usr/local/sbin"' "${DARWIN_MODULE}"
        The status should be failure
    End

    It 'prefers the nix-darwin system profile in the launchd path'
        launchd_profile_order_is_stable() {
            system_line=$(grep -nF '"/run/current-system/sw/bin"' "${DARWIN_MODULE}" | cut -d: -f1)
            optional_line=$(grep -nF '"${userHome}/.nix-profile/bin"' "${DARWIN_MODULE}" | cut -d: -f1)
            [ -n "${system_line}" ] && [ -n "${optional_line}" ] && [ "${system_line}" -lt "${optional_line}" ]
        }

        When call launchd_profile_order_is_stable
        The status should be success
    End

    It 'prepends the nix-darwin system profile after the standalone Home Manager profile'
        fish_profile_order_is_stable() {
            optional_line=$(grep -nF 'fish_add_path --prepend --move $HOME/.nix-profile/bin' "${DARWIN_MODULE}" | cut -d: -f1)
            system_line=$(grep -nF 'fish_add_path --prepend --move /run/current-system/sw/bin' "${DARWIN_MODULE}" | cut -d: -f1)
            [ -n "${optional_line}" ] && [ -n "${system_line}" ] && [ "${optional_line}" -lt "${system_line}" ]
        }

        When call fish_profile_order_is_stable
        The status should be success
    End

    It 'prefers the active Home Manager profile in the tmux server path'
        When call grep -qF '${config.home.profileDirectory}/bin:${config.home.homeDirectory}/.nix-profile/bin' "${TMUX_MODULE}"
        The status should be success
    End

    It 'installs the shared PATH filter next to the PATH shims'
        When call test -f "${DOTFILES_PATH}/nix/modules/home/shell/filter-existing-path.sh"
        The status should be success
    End

    It 'sources the PATH filter from bash profile, rc, and BASH_ENV'
        bash_sources_filter_three_times() {
            bash_module="${DOTFILES_PATH}/nix/modules/home/bash.nix"
            count=$(grep -cF '. "$HOME/.config/shell/filter-existing-path.sh"' "${bash_module}")
            [ "${count}" -eq 3 ]
        }

        When call bash_sources_filter_three_times
        The status should be success
    End

    It 'sources the PATH filter from zshenv, zprofile, and zshrc'
        zsh_sources_filter_three_times() {
            zsh_module="${DOTFILES_PATH}/nix/modules/home/zsh.nix"
            grep -qF 'profileExtra' "${zsh_module}" &&
                count=$(grep -cF '. "$HOME/.config/shell/filter-existing-path.sh"' "${zsh_module}") &&
                [ "${count}" -eq 3 ]
        }

        When call zsh_sources_filter_three_times
        The status should be success
    End
End
