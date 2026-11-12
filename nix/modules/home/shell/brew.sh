#!/bin/sh
# shellcheck shell=sh
# Homebrew wrapper installed as ~/.local/bin/brew.
#
# Private taps (kong/agent-auth-cli) download releases with
# HOMEBREW_GITHUB_API_TOKEN. Take it from the gh CLI per brew call instead of
# exporting the gh token, which has broad org scopes, to every process. Also
# hide Homebrew env hints. A shim on PATH covers fish, bash, zsh, Task and
# scripts alike.
#
# brew doctor warns if another brew is earlier on PATH (check_brew_path uses
# the process's starting PATH). When the command is doctor or its official
# alias dr, drop ~/.local/bin from PATH before exec so that check sees only
# the Homebrew prefix. Also unset BASH_ENV: configured shells export
# BASH_ENV=~/.bash_env, which prepends ~/.local/bin, and Homebrew's Bash
# entry point would otherwise restore the shim before the check runs.

export HOMEBREW_NO_ENV_HINTS=1

if [ -z "${HOMEBREW_GITHUB_API_TOKEN:-}" ] && token=$(gh auth token 2>/dev/null) && [ -n "$token" ]; then
  HOMEBREW_GITHUB_API_TOKEN=$token
  export HOMEBREW_GITHUB_API_TOKEN
fi

case "${1-}" in
doctor|dr)
  _brew_shim_dir="${HOME}/.local/bin"
  _brew_new=""
  _brew_rest="${PATH-}"

  while [ -n "$_brew_rest" ]; do
    _brew_dir="${_brew_rest%%:*}"
    if [ "$_brew_dir" = "$_brew_rest" ]; then
      _brew_rest=""
    else
      _brew_rest="${_brew_rest#*:}"
    fi

    # Skip empty components from leading, trailing, or doubled colons.
    [ -n "$_brew_dir" ] || continue
    [ "$_brew_dir" = "$_brew_shim_dir" ] && continue

    if [ -n "$_brew_new" ]; then
      _brew_new="${_brew_new}:${_brew_dir}"
    else
      _brew_new="${_brew_dir}"
    fi
  done

  PATH="${_brew_new}"
  export PATH
  unset BASH_ENV
  unset _brew_new _brew_rest _brew_dir _brew_shim_dir
  ;;
*)
  ;;
esac

# DOTFILES_TEST_BREW is a test hook; production always uses the Homebrew prefix.
exec "${DOTFILES_TEST_BREW:-/opt/homebrew/bin/brew}" "$@"
