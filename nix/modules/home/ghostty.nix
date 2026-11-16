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

      # Keybindings - standard macOS terminal shortcuts
      keybind = [
        # Shift+Enter sends newline (for Claude Code)
        "shift+enter=text:\\n"

        # Quick Terminal global hotkey (requires Accessibility permission)
        "global:cmd+alt+grave_accent=toggle_quick_terminal"

        # Inspector for debugging keybindings
        "super+i=inspector:toggle"

        # Ghostty always un-tabs new_window (ignores AppleWindowTabbingMode),
        # so Cmd+N opens a native tab instead. With no window open, new_tab
        # falls back to creating a window. In the macOS quick terminal,
        # tabs are not supported (they require a title bar); splits work.
        "cmd+n=new_tab"
        "cmd+t=new_tab"
        "cmd+w=close_surface"
        "cmd+shift+bracket_left=previous_tab"
        "cmd+shift+bracket_right=next_tab"
        "cmd+grave_accent=next_tab"
        "cmd+shift+grave_accent=previous_tab"
        "cmd+one=goto_tab:1"
        "cmd+two=goto_tab:2"
        "cmd+three=goto_tab:3"
        "cmd+four=goto_tab:4"
        "cmd+five=goto_tab:5"
        "cmd+six=goto_tab:6"
        "cmd+seven=goto_tab:7"
        "cmd+eight=goto_tab:8"
        "cmd+nine=last_tab"

        # Ghostty-native splits. These also work in the quick terminal.
        # Regular windows that run tmux can still use the tmux prefix
        # for tmux panes and windows.
        "cmd+d=new_split:right"
        "cmd+shift+d=new_split:down"
        "cmd+alt+left=goto_split:left"
        "cmd+alt+right=goto_split:right"
        "cmd+alt+up=goto_split:up"
        "cmd+alt+down=goto_split:down"
        # Keep these for Ghostty split cycling used by Hammerspoon
        "cmd+bracket_left=goto_split:previous" # Cmd+[
        "cmd+bracket_right=goto_split:next" # Cmd+]
        "cmd+ctrl+left=resize_split:left,10"
        "cmd+ctrl+right=resize_split:right,10"
        "cmd+ctrl+up=resize_split:up,10"
        "cmd+ctrl+down=resize_split:down,10"
        "cmd+shift+equal=equalize_splits"
        "cmd+alt+z=toggle_split_zoom"

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
