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
  plist = "${home}/Library/LaunchAgents/com.bartsmykla.hindsight-pages.plist";
  label = "com.bartsmykla.hindsight-pages";
in {
  home.file.${wrapperRel} = {
    source = ./hindsight/run-knowledge-pages.sh;
    executable = true;
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

  # Home Manager will not overwrite existing unmanaged files. Move them
  # aside (with a backup) before checkLinkTargets so the first switch can
  # install the managed copies. Already-managed Nix store symlinks are left
  # alone on later switches.
  home.activation.backupUnmanagedHindsight = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    ts=
    dest=
    backup_if_unmanaged() {
      src="$1"
      name="$2"
      if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        return 0
      fi
      if [ -L "$src" ]; then
        target=$(readlink "$src" || true)
        case "$target" in
          /nix/store/*) return 0 ;;
        esac
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
      $DRY_RUN_CMD mv "$src" "$dest/$name"
      $DRY_RUN_CMD chmod 600 "$dest/$name" || true
      # Drop a still-loaded copy of the pre-managed agent so setupLaunchAgents
      # can bootstrap the new plist under the same label.
      if [ "$name" = "com.bartsmykla.hindsight-pages.plist" ]; then
        $DRY_RUN_CMD /bin/launchctl bootout "gui/$(/usr/bin/id -u)/${label}" || true
      fi
    }
    backup_if_unmanaged "${wrapper}" "run-knowledge-pages.sh"
    backup_if_unmanaged "${plist}" "com.bartsmykla.hindsight-pages.plist"
  '';
}
