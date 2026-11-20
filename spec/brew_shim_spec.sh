#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
# shellcheck disable=SC2016  # Test literals intentionally contain Nix and shell interpolation syntax
# shellcheck disable=SC2329  # Functions are invoked indirectly via ShellSpec

Describe 'Homebrew PATH shim'
    setup() {
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export PATH_MODULE="${DOTFILES_PATH}/nix/modules/home/path.nix"
        export BREW_SHIM="${DOTFILES_PATH}/nix/modules/home/shell/brew.sh"
        export FAKE_BIN
        FAKE_BIN=$(mktemp -d "${TMPDIR:-/tmp}/brew-shim-spec.XXXXXX")
        printf '%s\n' '#!/bin/sh' 'printf "PATH=%s\n" "$PATH"' 'printf "HINTS=%s\n" "${HOMEBREW_NO_ENV_HINTS-}"' 'printf "TOKEN_SET=%s\n" "${HOMEBREW_GITHUB_API_TOKEN:+yes}"' 'if [ "${HOMEBREW_GITHUB_API_TOKEN-}" = "pre-set-token" ]; then printf "TOKEN_PRESERVED=yes\n"; fi' 'printf "ARGS=%s\n" "$*"' > "${FAKE_BIN}/brew"
        printf '%s\n' '#!/bin/sh' 'printf "%s\n" "spec-gh-token"' > "${FAKE_BIN}/gh"
        chmod +x "${FAKE_BIN}/brew" "${FAKE_BIN}/gh"
    }

    cleanup() {
        if [ -n "${FAKE_BIN:-}" ] && [ -d "${FAKE_BIN}" ]; then
            rm -rf "${FAKE_BIN}"
        fi
    }

    Before 'setup'
    After 'cleanup'

    It 'installs the wrapper as ~/.local/bin/brew from the shared script'
        When call grep -qF 'source = ./shell/brew.sh' "${PATH_MODULE}"
        The status should be success
    End

    It 'does not inline the wrapper text in path.nix'
        When call grep -qF 'exec /opt/homebrew/bin/brew' "${PATH_MODULE}"
        The status should be failure
    End

    It 'sets HOMEBREW_NO_ENV_HINTS and takes a GitHub token from gh when unset'
        run_shim() {
            env -i \
                HOME="${HOME}" \
                PATH="${FAKE_BIN}:/usr/bin:/bin" \
                DOTFILES_TEST_BREW="${FAKE_BIN}/brew" \
                /bin/sh "${BREW_SHIM}" install wget
        }

        When call run_shim
        The status should be success
        The output should include 'HINTS=1'
        The output should include 'TOKEN_SET=yes'
        The output should include 'ARGS=install wget'
        The output should include "PATH=${FAKE_BIN}:/usr/bin:/bin"
    End

    It 'leaves an already-set GitHub token alone'
        run_shim() {
            env -i \
                HOME="${HOME}" \
                PATH="${FAKE_BIN}:/usr/bin:/bin" \
                HOMEBREW_GITHUB_API_TOKEN='pre-set-token' \
                DOTFILES_TEST_BREW="${FAKE_BIN}/brew" \
                /bin/sh "${BREW_SHIM}" info wget
        }

        When call run_shim
        The status should be success
        The output should include 'TOKEN_SET=yes'
        The output should include 'TOKEN_PRESERVED=yes'
        The output should include 'ARGS=info wget'
    End

    It 'falls back to the Homebrew gh when gh is not on PATH'
        run_shim() {
            no_gh_bin="${FAKE_BIN}/no-gh"
            mkdir "${no_gh_bin}"
            cp "${FAKE_BIN}/brew" "${no_gh_bin}/brew"
            # Keep system directories off PATH: Ubuntu runners ship /usr/bin/gh
            # (and /bin is often a usrmerge symlink to /usr/bin), which would
            # hide the DOTFILES_TEST_GH fallback this case is meant to cover.
            env -i \
                HOME="${HOME}" \
                PATH="${no_gh_bin}" \
                DOTFILES_TEST_BREW="${no_gh_bin}/brew" \
                DOTFILES_TEST_GH="${FAKE_BIN}/gh" \
                /bin/sh "${BREW_SHIM}" upgrade
        }

        When call run_shim
        The status should be success
        The output should include 'TOKEN_SET=yes'
        The output should include 'ARGS=upgrade'
    End

    It 'reports the gh failure on stderr and still runs brew'
        run_shim() {
            printf '%s\n' '#!/bin/sh' 'echo "no oauth token found" >&2' 'exit 1' > "${FAKE_BIN}/gh"
            env -i \
                HOME="${HOME}" \
                PATH="${FAKE_BIN}:/usr/bin:/bin" \
                DOTFILES_TEST_BREW="${FAKE_BIN}/brew" \
                /bin/sh "${BREW_SHIM}" upgrade
        }

        When call run_shim
        The status should be success
        The output should include 'TOKEN_SET='
        The output should not include 'TOKEN_SET=yes'
        The output should include 'ARGS=upgrade'
        The error should include 'no oauth token found'
    End

    It 'drops ~/.local/bin from PATH when the command is doctor'
        run_shim() {
            env -i \
                HOME="${HOME}" \
                PATH="${HOME}/.local/bin:${FAKE_BIN}:/usr/bin:/bin" \
                DOTFILES_TEST_BREW="${FAKE_BIN}/brew" \
                /bin/sh "${BREW_SHIM}" doctor
        }

        When call run_shim
        The status should be success
        The output should include "PATH=${FAKE_BIN}:/usr/bin:/bin"
        The output should include 'ARGS=doctor'
        The output should include 'HINTS=1'
    End

    It 'keeps ~/.local/bin on PATH for non-doctor commands'
        run_shim() {
            env -i \
                HOME="${HOME}" \
                PATH="${HOME}/.local/bin:${FAKE_BIN}:/usr/bin:/bin" \
                DOTFILES_TEST_BREW="${FAKE_BIN}/brew" \
                /bin/sh "${BREW_SHIM}" update
        }

        When call run_shim
        The status should be success
        The output should include "PATH=${HOME}/.local/bin:${FAKE_BIN}:/usr/bin:/bin"
        The output should include 'ARGS=update'
    End

    It 'also drops ~/.local/bin from PATH for the official doctor alias dr'
        run_shim() {
            env -i \
                HOME="${HOME}" \
                PATH="${HOME}/.local/bin:${FAKE_BIN}:/usr/bin:/bin" \
                DOTFILES_TEST_BREW="${FAKE_BIN}/brew" \
                /bin/sh "${BREW_SHIM}" dr
        }

        When call run_shim
        The status should be success
        The output should include "PATH=${FAKE_BIN}:/usr/bin:/bin"
        The output should include 'ARGS=dr'
        The output should include 'HINTS=1'
    End

    It 'also drops ~/.local/bin from PATH for brew -v doctor'
        run_shim() {
            env -i \
                HOME="${HOME}" \
                PATH="${HOME}/.local/bin:${FAKE_BIN}:/usr/bin:/bin" \
                DOTFILES_TEST_BREW="${FAKE_BIN}/brew" \
                /bin/sh "${BREW_SHIM}" -v doctor
        }

        When call run_shim
        The status should be success
        The output should include "PATH=${FAKE_BIN}:/usr/bin:/bin"
        The output should include 'ARGS=-v doctor'
        The output should include 'HINTS=1'
    End

    It 'also drops ~/.local/bin from PATH for brew -v dr'
        run_shim() {
            env -i \
                HOME="${HOME}" \
                PATH="${HOME}/.local/bin:${FAKE_BIN}:/usr/bin:/bin" \
                DOTFILES_TEST_BREW="${FAKE_BIN}/brew" \
                /bin/sh "${BREW_SHIM}" -v dr
        }

        When call run_shim
        The status should be success
        The output should include "PATH=${FAKE_BIN}:/usr/bin:/bin"
        The output should include 'ARGS=-v dr'
        The output should include 'HINTS=1'
    End

    It 'keeps ~/.local/bin on PATH for brew -v update'
        run_shim() {
            env -i \
                HOME="${HOME}" \
                PATH="${HOME}/.local/bin:${FAKE_BIN}:/usr/bin:/bin" \
                DOTFILES_TEST_BREW="${FAKE_BIN}/brew" \
                /bin/sh "${BREW_SHIM}" -v update
        }

        When call run_shim
        The status should be success
        The output should include "PATH=${HOME}/.local/bin:${FAKE_BIN}:/usr/bin:/bin"
        The output should include 'ARGS=-v update'
    End

    It 'unsets BASH_ENV so Homebrew bash does not restore the shim during doctor'
        run_shim() {
            bash_env="${FAKE_BIN}/bash_env"
            bash_brew="${FAKE_BIN}/brew-bash"
            printf '%s\n' 'export PATH="${HOME}/.local/bin:${PATH}"' > "${bash_env}"
            printf '%s\n' '#!/bin/bash' 'printf "PATH=%s\n" "$PATH"' 'printf "BASH_ENV=%s\n" "${BASH_ENV-}"' 'printf "ARGS=%s\n" "$*"' > "${bash_brew}"
            chmod +x "${bash_brew}"
            env -i \
                HOME="${HOME}" \
                PATH="${HOME}/.local/bin:${FAKE_BIN}:/usr/bin:/bin" \
                BASH_ENV="${bash_env}" \
                DOTFILES_TEST_BREW="${bash_brew}" \
                /bin/sh "${BREW_SHIM}" doctor
        }

        When call run_shim
        The status should be success
        The output should include "PATH=${FAKE_BIN}:/usr/bin:/bin"
        The output should include 'ARGS=doctor'
        The output should include 'BASH_ENV='
    End
End
