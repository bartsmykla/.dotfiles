# Zsh shell configuration
#
# Configures zsh to support aliases in both interactive and non-interactive shells.
# This is needed for Claude Code which uses zsh for its built-in shell.
{ config, lib, pkgs, ... }:

{
  # An unmanaged ~/.zprofile predates home-manager managing this file for
  # session vars, which blocks activation otherwise. The zsh module writes it
  # under the "./.zprofile" key because dotDir defaults to the home directory,
  # but the "./" prefix breaks the collision check's forced-path comparison,
  # so normalize the target while forcing the overwrite.
  home.file."./.zprofile" = {
    force = true;
    target = ".zprofile";
  };

  programs.zsh = {
    enable = true;

    # .zshenv is sourced for ALL zsh shells (interactive, non-interactive, login, etc.)
    # This is perfect for Claude Code's non-interactive shells
    envExtra = ''
      # Prevent "unbound variable" errors in strict mode (set -u)
      # PROMPT_COMMAND is typically set by interactive shells but not in non-interactive mode
      : "''${PROMPT_COMMAND:=}"

      # Fish sets this, but a zsh started outside fish has none
      export LANG="''${LANG:-en_US.UTF-8}"

      # Suppress pkg_resources deprecation warning from kathara_lab_checker
      export PYTHONWARNINGS="ignore::UserWarning"

      # Claude Code skills CLI wrapper
      export PATH="$HOME/Projects/github.com/smykla-skalski/research/claude-code/skills/_bin:$PATH"

      # Python shell.nix location for direnv
      # Found at startup because the checkout moves between GitHub owners
      for dotfiles_flake in "$HOME"/Projects/github.com/*/.dotfiles/nix/flake.nix(N); do
        export DOTFILES_PATH="''${dotfiles_flake%/nix/flake.nix}"
        break
      done
      unset dotfiles_flake
      export PYTHON_SHELL_NIX="$DOTFILES_PATH/nix/python-env/shell.nix"

      # Codex home (shared across users)
      export CODEX_HOME="/Users/Shared/codex-home"

      # Homebrew shellenv (for non-interactive shells that don't inherit launchd PATH)
      if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      # Cargo environment
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      # Bun
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"

      # Rancher Desktop
      [ -d "$HOME/.rd/bin" ] && export PATH="$HOME/.rd/bin:$PATH"

      # For non-interactive shells, use mise hook-env
      mise_bin=""
      if [ -x "$HOME/.local/bin/mise" ]; then
          mise_bin="$HOME/.local/bin/mise"
      elif [ -x /opt/homebrew/bin/mise ]; then
          mise_bin="/opt/homebrew/bin/mise"
      elif [ -x /usr/local/bin/mise ]; then
          mise_bin="/usr/local/bin/mise"
      fi

      if [ -n "$mise_bin" ]; then
          eval "$("$mise_bin" hook-env -s zsh)"
      fi

      # Source shared shell functions (from Fish functions)
      [ -f "$HOME/.config/shell/functions.sh" ] && source "$HOME/.config/shell/functions.sh"

      # Source shared shell aliases (from Fish abbreviations)
      [ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"

      # Fish abbreviation-tips exports are shell-local UI config. Keep them out
      # of non-Fish processes so toolchains do not inherit malformed prompt bytes.
      unset ABBR_TIPS_PROMPT ABBR_TIPS_REGEXES ABBR_TIPS_AUTO_UPDATE

      # Keep user-installed binaries ahead of Homebrew, Nix, and mise-managed paths.
      typeset -U path PATH
      path=("$HOME/.local/bin" $path)
      export PATH

      # Drop missing PATH directories after path_helper and mise. libuv and
      # posix_spawnp try each PATH entry; a miss from a provenance-tracked
      # app logs a syspolicyd qtn_proc error.
      if [ -f "$HOME/.config/shell/filter-existing-path.sh" ]; then
        . "$HOME/.config/shell/filter-existing-path.sh"
      fi
    '';

    # .zprofile content (login shells). Runs after /etc/zprofile, which is
    # where path_helper would re-add /etc/paths.d entries on a stock macOS
    # zsh. nix-darwin's /etc/zprofile currently does not call path_helper,
    # but inherited PATH from a parent that did still needs filtering, and
    # this keeps login zsh correct if path_helper is added later.
    profileExtra = ''
      # Drop missing PATH directories after path_helper and mise. libuv and
      # posix_spawnp try each PATH entry; a miss from a provenance-tracked
      # app logs a syspolicyd qtn_proc error.
      if [ -f "$HOME/.config/shell/filter-existing-path.sh" ]; then
        . "$HOME/.config/shell/filter-existing-path.sh"
      fi
    '';

    # .zshrc content (interactive shells only)
    initContent = lib.mkMerge [
      # Homebrew formulae install completions here, outside the Nix fpath.
      # Order 550 runs before compinit. Appended, so Nix completions win.
      (lib.mkOrder 550 ''
        if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
          fpath+=(/opt/homebrew/share/zsh/site-functions)
        fi
      '')
      ''
      # fzf integration
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

      # Activate mise for interactive shells (prompt hook re-evaluates on cd)
      mise_bin=""
      if [ -x "$HOME/.local/bin/mise" ]; then
        mise_bin="$HOME/.local/bin/mise"
      elif [ -x /opt/homebrew/bin/mise ]; then
        mise_bin="/opt/homebrew/bin/mise"
      elif [ -x /usr/local/bin/mise ]; then
        mise_bin="/usr/local/bin/mise"
      fi

      if [ -n "$mise_bin" ]; then
        eval "$("$mise_bin" activate zsh)"
      fi

      typeset -U path PATH
      path=("$HOME/.local/bin" $path)
      export PATH

      if command -v opencode >/dev/null 2>&1; then
        eval "$(opencode --completions zsh)"
      fi

      # Drop missing PATH directories after path_helper and mise. libuv and
      # posix_spawnp try each PATH entry; a miss from a provenance-tracked
      # app logs a syspolicyd qtn_proc error.
      if [ -f "$HOME/.config/shell/filter-existing-path.sh" ]; then
        . "$HOME/.config/shell/filter-existing-path.sh"
      fi
    ''
    ];
  };
}
