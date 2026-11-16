# Ghostty terminal configuration
#
# Ghostty is a fast, feature-rich terminal emulator with native macOS UI.
# Package installed via Homebrew (Nix package broken on Darwin).
# This module manages configuration only.
{
  config,
  lib,
  pkgs,
  ...
}: let
  fishPath = "${pkgs.fish}/bin/fish";
  tmuxPath = "${pkgs.tmux}/bin/tmux";
  ghosttyLauncher = pkgs.writeShellScript "ghostty-launcher" ''
    set -eu

    session_name="main"

    start_fish() {
      exec ${fishPath}
    }

    start_tmux() {
      start_dir="''${PWD:-$HOME}"
      if [ ! -d "$start_dir" ]; then
        start_dir="$HOME"
      fi

      ${tmuxPath} new-session -A -s "$session_name" -c "$start_dir"
    }

    # Walk to the Ghostty app pid. Surfaces are spawned via /usr/bin/login,
    # so the script's immediate parent is not Ghostty itself.
    find_ghostty_pid() {
      pid=$$
      i=0
      while [ "$i" -lt 8 ] && [ -n "$pid" ] && [ "$pid" != "0" ] && [ "$pid" != "1" ]; do
        comm=$(ps -o comm= -p "$pid" 2>/dev/null | tr -d ' ')
        case "$comm" in
          *ghostty*|*Ghostty*)
            printf '%s\n' "$pid"
            return 0
            ;;
        esac
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
        i=$((i + 1))
      done
      return 1
    }

    # Official Ghostty 1.3+ signal for a quick-terminal surface (1.4 still
    # sets this on a freshly created quick terminal and its splits). There
    # is no separate quick-terminal command option.
    if [ "''${GHOSTTY_QUICK_TERMINAL-}" = "1" ]; then
      start_fish
    fi

    if [ -z "''${PWD-}" ]; then
      export PWD="$HOME"
    fi

    if [ -n "''${TMUX-}" ]; then
      start_fish
    fi

    # Only the first non-quick surface in this Ghostty process starts or
    # attaches the shared tmux session. Later tabs and splits stay on
    # raw fish so they do not nest tmux.
    if ghostty_pid=$(find_ghostty_pid); then
      stamp="''${TMPDIR:-/tmp}/ghostty-tmux-started.$ghostty_pid"
      if ! mkdir "$stamp" 2>/dev/null; then
        start_fish
      fi
    fi

    if start_tmux; then
      exit 0
    fi

    # Fallback path if xterm-ghostty terminfo is unavailable for tmux.
    if [ "''${TERM-}" = "xterm-ghostty" ]; then
      export TERM=xterm-256color
      if start_tmux; then
        exit 0
      fi
    fi

    # Last resort: keep terminal usable even if tmux startup fails.
    start_fish
  '';
in {
  programs.ghostty = {
    enable = true;

    # Don't install via Nix - package broken on Darwin, use Homebrew cask instead
    package = null;

    # Fish shell integration for proper terminfo
    enableFishIntegration = true;

    settings = {
      # Font configuration
      font-family = "FiraCode Nerd Font Mono";
      font-size = 15;
      font-thicken = true;

      # Window configuration
      window-decoration = "auto";
      macos-option-as-alt = true;
      # Keep the default titlebar style: "hidden" disallows native tabs.
      # No window at process start so a login agent can launch Ghostty
      # for the global quick-terminal hotkey without a fullscreen window.
      initial-window = false;
      fullscreen = true;

      # Scrollback
      scrollback-limit = 10000;

      # Keep Ghostty terminal identity for app feature detection.
      term = "xterm-ghostty";

      # The first surface is often the quick terminal: Ghostty creates it
      # at launch when a global keybind is set, especially with
      # initial-window = false. initial-command therefore stays on raw
      # fish. Regular windows use the launcher, which starts the shared
      # tmux session once per process and skips it when
      # GHOSTTY_QUICK_TERMINAL=1 (set on a freshly created quick terminal
      # and its splits in 1.4). Later tabs and splits stay on fish so
      # they do not nest tmux.
      # macOS window restore can drop GHOSTTY_QUICK_TERMINAL (#13042 in
      # 1.4.0) and can also revive a hidden fullscreen window at launch.
      # Session state lives in tmux, so window restore is disabled.
      window-save-state = "never";
      initial-command = "direct:${fishPath}";
      command = "direct:${ghosttyLauncher}";

      # Shell integration (title needed for fish_title to work)
      shell-integration-features = "cursor,sudo,title";

      # Quick terminal (drop-down from the top of the screen under the
      # cursor). The global hotkey requires Ghostty to be running and
      # macOS Accessibility permission. grave_accent is accepted and
      # canonicalizes to backquote (the ` key) in Ghostty 1.4.
      quick-terminal-position = "top";
      quick-terminal-screen = "mouse";
      quick-terminal-animation-duration = "0.1";
      quick-terminal-autohide = true;
      quick-terminal-space-behavior = "move";
      # Primary-axis height for a top-positioned quick terminal.
      quick-terminal-size = "50%";

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;

      # Bell: surface terminal BEL as dock attention + title mark + border
      # flash. Silent (omit `audible` / `system` from bell-features). tmux
      # (bell-action any) forwards BEL from inside any pane so Claude Code's
      # claude-notify hook can grab attention.
      bell-features = "attention,title,border";

      # Copy/paste behavior
      copy-on-select = "clipboard";
      clipboard-paste-protection = false;
      clipboard-trim-trailing-spaces = true;

      # Keep Shift reserved for Ghostty so Cmd+Shift+Click still opens URLs
      # when tmux or another TUI has mouse reporting enabled.
      link-url = true;
      mouse-shift-capture = "never";

      # Always confirm before closing (protects against accidental Cmd+Q)
      confirm-close-surface = "always";

      # Aesthetics
      background-opacity = 0.95;

      # Unfocused split configuration
      # Moderate dimming with subtle color tint for better distinction
      unfocused-split-opacity = 0.65;
      unfocused-split-fill = "#1a1a1a";

      # Bright, visible divider (coral/salmon pink from terminal)
      split-divider-color = "#E06C75";

      # Theme
      theme = "Monokai Classic";

      # Optional local config overlay (writable, for runtime modifications like font-size)
      # Hammerspoon can modify this file to override settings without touching Nix config
      config-file = "?~/.config/ghostty/config.local";

      # Keybindings - Using standard terminal shortcuts (iTerm2/Terminal.app style)
      keybind = [
        # Shift+Enter sends newline (for Claude Code)
        "shift+enter=text:\\n"

        # Quick Terminal global hotkey (requires Accessibility permission)
        "global:cmd+alt+grave_accent=toggle_quick_terminal"

        # Inspector for debugging keybindings
        "super+i=inspector:toggle"

        # Ghostty always un-tabs new_window (ignores AppleWindowTabbingMode),
        # so Cmd+N opens a native tab instead. With no window open, new_tab
        # falls back to creating a window.
        "cmd+n=new_tab"

        # === Tmux-first pane workflow ===
        # Create panes
        "cmd+d=text:\\x01|"
        "cmd+shift+d=text:\\x01-"
        "cmd+alt+z=text:\\x01z"

        # Navigate panes
        "cmd+alt+left=text:\\x01h"
        "cmd+alt+right=text:\\x01l"
        "cmd+alt+up=text:\\x01k"
        "cmd+alt+down=text:\\x01j"

        # Keep these for Ghostty split cycling used by Hammerspoon
        "cmd+bracket_left=goto_split:previous" # Cmd+[
        "cmd+bracket_right=goto_split:next" # Cmd+]

        # Resize panes
        "cmd+ctrl+left=text:\\x01H"
        "cmd+ctrl+right=text:\\x01L"
        "cmd+ctrl+up=text:\\x01K"
        "cmd+ctrl+down=text:\\x01J"
        "cmd+shift+equal=text:\\x01="

        # === Tmux windows ===
        "cmd+t=text:\\x01c"
        "cmd+w=text:\\x01X"

        # Window navigation
        "cmd+one=text:\\x011"
        "cmd+two=text:\\x012"
        "cmd+three=text:\\x013"
        "cmd+four=text:\\x014"
        "cmd+five=text:\\x015"
        "cmd+six=text:\\x016"
        "cmd+seven=text:\\x017"
        "cmd+eight=text:\\x018"
        "cmd+nine=text:\\x019"
        "cmd+shift+bracket_left=text:\\x01p"
        "cmd+shift+bracket_right=text:\\x01n"
        "cmd+grave_accent=text:\\x01n"
        "cmd+shift+grave_accent=text:\\x01p"

        # === Utility shortcuts ===
        "cmd+k=clear_screen" # Clear screen (Terminal.app standard)
        "cmd+shift+k=clear_screen" # Alternative clear
        "cmd+r=reload_config" # Reload config

        # Shell integration - jump between prompts
        "ctrl+shift+up=jump_to_prompt:-1"
        "ctrl+shift+down=jump_to_prompt:1"
      ];
    };
  };

  # Global keybinds only work while Ghostty is running. Start it at login
  # in the background so the quick terminal is available after a reboot
  # without opening a window (see initial-window).
  launchd.agents.ghostty-login = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = ["/usr/bin/open" "-ga" "Ghostty"];
      RunAtLoad = true;
      LimitLoadToSessionType = "Aqua";
    };
  };
}
