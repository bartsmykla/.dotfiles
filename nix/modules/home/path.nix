{ config, ... }:

{
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.file.".local/bin/python3" = {
    source = config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/python3";
    force = true;
  };

  # Shell activation and mise's shims run mise from this path. Point it at the
  # Homebrew mise from homebrew.nix, which stays updated, so a standalone copy
  # from `curl mise.run | sh` can't shadow it and go stale.
  home.file.".local/bin/mise" = {
    source = config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/mise";
    force = true;
  };
}
