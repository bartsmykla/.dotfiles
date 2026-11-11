#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
# shellcheck disable=SC2016  # Test literals intentionally contain Nix interpolation syntax

Describe 'npm registry auth file'
    setup() {
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export NPM_MODULE="${DOTFILES_PATH}/nix/modules/home/fish/functions/npm.nix"
        export SOPS_MODULE="${DOTFILES_PATH}/nix/modules/home/sops.nix"
        export SECRETS_FILE="${DOTFILES_PATH}/nix/secrets/secrets.yaml"
    }
    Before 'setup'

    It 'does not materialize ~/.npmrc as a Home Manager store file'
        When call grep -qF 'home.file.".npmrc"' "${NPM_MODULE}"
        The status should be failure
    End

    It 'declares a sops-nix secret for the user npmrc'
        When call grep -qF 'sops.secrets."npm/npmrc"' "${NPM_MODULE}"
        The status should be success
    End

    It 'installs the decrypted npmrc into $HOME at mode 0600'
        When call grep -qF 'install -m 600' "${NPM_MODULE}"
        The status should be success
    End

    It 'does not symlink ~/.npmrc into the purgable Darwin temp secrets dir'
        When call grep -qF 'ln -sf' "${NPM_MODULE}"
        The status should be failure
    End

    It 'leaves ~/.npmrc alone while the sops secret is still the placeholder'
        When call grep -qF 'PLACEHOLDER_REPLACE_WITH_NPMRC' "${NPM_MODULE}"
        The status should be success
    End

    It 'does not resolve the token from 1Password into the shell environment'
        When call grep -qE 'op read|__npm_token|NPM_TOKEN' "${NPM_MODULE}"
        The status should be failure
    End

    It 'keeps the encrypted npmrc secret in the sops file'
        secrets_file_has_npm_npmrc() {
            awk '
                /^sops:[[:space:]]*$/ { exit }
                /^[[:space:]]*npm:[[:space:]]*$/ { npm=1; next }
                npm && /^[[:space:]]*npmrc:[[:space:]]/ { found=1; exit }
                npm && /^[^[:space:]]/ { npm=0 }
                END { exit !found }
            ' "${SECRETS_FILE}"
        }

        When call secrets_file_has_npm_npmrc
        The status should be success
    End
End
