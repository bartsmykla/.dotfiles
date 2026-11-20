#!/bin/sh
# shellcheck shell=sh
# Homebrew wrapper installed as ~/.local/bin/brew.
#
# Private taps download releases with
# HOMEBREW_GITHUB_API_TOKEN. Take it from the gh CLI per brew call instead of
# exporting the gh token, which has broad org scopes, to every process. Also
# hide Homebrew env hints. A shim on PATH covers fish, bash, zsh, Task and
# scripts alike.
#
# brew doctor warns if another brew is earlier on PATH (check_brew_path uses
# the process's starting PATH). When the command is doctor or its official
# alias dr, drop ~/.local/bin from PATH before exec so that check sees only
# the Homebrew prefix. Homebrew moves a leading -v to the end before it
# resolves the command, so treat `brew -v doctor` and `brew -v dr` the same
# and still forward the original arguments. Also unset BASH_ENV: configured
# shells export BASH_ENV=~/.bash_env, which prepends ~/.local/bin, and
# Homebrew's Bash entry point would otherwise restore the shim before the
# check runs.

export HOMEBREW_NO_ENV_HINTS=1

# Callers with a bare PATH (GUI apps, launchd, env -i) have no gh on it, so
# fall back to the Homebrew gh. When no token comes back, say why on stderr:
# Homebrew's own error only names the variable, not the gh failure behind it.
# DOTFILES_TEST_GH is a test hook for that fallback path.
if [ -z "${HOMEBREW_GITHUB_API_TOKEN:-}" ]; then
  _brew_gh=$(command -v gh) || _brew_gh="${DOTFILES_TEST_GH:-/opt/homebrew/bin/gh}"
  if _brew_token=$("$_brew_gh" auth token 2>&1) && [ -n "$_brew_token" ]; then
    HOMEBREW_GITHUB_API_TOKEN=$_brew_token
    export HOMEBREW_GITHUB_API_TOKEN
  else
    printf 'brew shim: no GitHub token from %s, private taps will fail: %s\n' "$_brew_gh" "$_brew_token" >&2
  fi
  unset _brew_gh _brew_token
fi

# Homebrew's brew.sh shifts a leading -v to the end before command lookup.
_brew_cmd="${1-}"
if [ "$_brew_cmd" = "-v" ]; then
  _brew_cmd="${2-}"
fi

case "$_brew_cmd" in
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
unset _brew_cmd

# DOTFILES_TEST_BREW is a test hook; production always uses the Homebrew prefix.
exec "${DOTFILES_TEST_BREW:-/opt/homebrew/bin/brew}" "$@"
