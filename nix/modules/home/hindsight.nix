# Manage the Hindsight knowledge-pages LaunchAgent and its stable wrapper.
#
# Launch constraints bind to this script path, not to Homebrew's node binary,
# so a node upgrade does not invalidate the agent. The wrapper stays a
# fixed path under $HOME and execs Homebrew node.
{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  wrapperRel = ".hindsight/local-tools/run-knowledge-pages.sh";
  wrapper = "${home}/${wrapperRel}";
  plistName = "com.bartsmykla.hindsight-pages.plist";
  plist = "${home}/Library/LaunchAgents/${plistName}";
  label = "com.bartsmykla.hindsight-pages";
in {
  # force lets checkLinkTargets pass over a pre-existing unmanaged wrapper
  # so we can back it up after that check, not before. The plist is not a
  # home.file; setupLaunchAgents installs it as a regular file.
  home.file.${wrapperRel} = {
    source = ./hindsight/run-knowledge-pages.sh;
    executable = true;
    force = true;
  };

  launchd.agents.hindsight-pages = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      Label = label;
      ProgramArguments = [wrapper];
      StartInterval = 900;
      RunAtLoad = true;
      ProcessType = "Background";
      StandardOutPath = "${home}/.hindsight/coding-agents-logs/pages.log";
      StandardErrorPath = "${home}/.hindsight/coding-agents-logs/pages-error.log";
    };
  };

  # Back up unmanaged copies after collision checks have passed (so a later
  # checkLinkTargets failure cannot leave the agent without its entry point)
  # and before linkGeneration / setupLaunchAgents replace them. Copy, do not
  # move, and do not boot out here: if a later activation step fails, the
  # live files stay in place; setupLaunchAgents unloads and reinstalls the
  # plist when its contents change.
  #
  # Home Manager installs LaunchAgent plists as regular files (they cannot
  # be store symlinks), so a symlink-only "already managed" check would
  # re-backup the plist on every switch. Compare against this and the
  # previous generation before treating a file as unmanaged.
  home.activation.backupUnmanagedHindsight =
    lib.hm.dag.entryBetween [
      "linkGeneration"
      "setupLaunchAgents"
    ] [ "writeBoundary" ] ''
      ts=
      dest=
      is_managed() {
        src="$1"
        rel="$2"
        if [ -L "$src" ]; then
          target=$(readlink "$src" || true)
          case "$target" in
            /nix/store/*) return 0 ;;
          esac
        fi
        if [ -f "$src" ]; then
          for gen in ''${newGenPath:-} ''${oldGenPath:-}; do
            if [ -n "$gen" ] && [ -e "$gen/$rel" ] && cmp -s "$src" "$gen/$rel"; then
              return 0
            fi
          done
        fi
        return 1
      }
      backup_if_unmanaged() {
        src="$1"
        name="$2"
        rel="$3"
        if [ ! -e "$src" ] && [ ! -L "$src" ]; then
          return 0
        fi
        if is_managed "$src" "$rel"; then
          return 0
        fi
        if [ -z "$ts" ]; then
          ts=$(date +%Y%m%d-%H%M%S)
          dest="${home}/.local/share/qtnlab/backups/$ts/hindsight"
          $DRY_RUN_CMD mkdir -p "$dest"
          $DRY_RUN_CMD chmod 700 \
            "${home}/.local/share/qtnlab" \
            "${home}/.local/share/qtnlab/backups" \
            "${home}/.local/share/qtnlab/backups/$ts" \
            "$dest" || true
        fi
        $DRY_RUN_CMD cp -p "$src" "$dest/$name"
        $DRY_RUN_CMD chmod 600 "$dest/$name" || true
      }
      backup_if_unmanaged "${wrapper}" "run-knowledge-pages.sh" "home-files/${wrapperRel}"
      backup_if_unmanaged "${plist}" "${plistName}" "LaunchAgents/${plistName}"
    '';
}
