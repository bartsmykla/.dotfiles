{ config, pkgs, ... }:

{
  home.sessionPath = [ "$HOME/.local/bin" ];

  # POSIX PATH filter sourced by bash and zsh after path_helper and mise.
  # See shell/filter-existing-path.sh.
  home.file.".config/shell/filter-existing-path.sh" = {
    source = ./shell/filter-existing-path.sh;
  };


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

  # Private taps (kong/agent-auth-cli) download releases with
  # HOMEBREW_GITHUB_API_TOKEN. Take it from the gh CLI per brew call instead of
  # exporting the gh token, which has broad org scopes, to every process. A
  # shim on PATH covers fish, bash, zsh, Task and scripts alike.
  home.file.".local/bin/brew" = {
    executable = true;
    force = true;
    text = ''
      #!/bin/sh
      export HOMEBREW_NO_ENV_HINTS=1
      if [ -z "''${HOMEBREW_GITHUB_API_TOKEN:-}" ] && token=$(gh auth token 2>/dev/null) && [ -n "$token" ]; then
        HOMEBREW_GITHUB_API_TOKEN=$token
        export HOMEBREW_GITHUB_API_TOKEN
      fi
      exec /opt/homebrew/bin/brew "$@"
    '';
  };

  # Pin hot, name-resolved binaries at the front of PATH. libuv (Node/Electron)
  # and libc posix_spawnp try posix_spawn once per PATH entry; each miss from a
  # provenance-tracked app (T3 Code, Claude Code) costs a short-lived process and
  # a syspolicyd "Unable to initialize qtn_proc: 3" error. git/lsof/ps sat 19-31
  # entries deep and T3 polls them constantly.
  #
  # Nix tools link to their store paths, the same packages this Home Manager
  # profile installs. Store paths exist from boot, unlike /run/current-system,
  # which nix-darwin recreates only when its activation daemon runs. When macOS
  # blocks that daemon, links into /run dangle and PATH falls through to the
  # next git, bash or sh.
  home.file.".local/bin/git" = { source = "${config.programs.git.package}/bin/git"; force = true; };
  home.file.".local/bin/bash" = { source = "${config.programs.bash.package}/bin/bash"; force = true; };
  home.file.".local/bin/sh" = { source = "${config.programs.bash.package}/bin/sh"; force = true; };
  home.file.".local/bin/tar" = { source = "${pkgs.gnutar}/bin/tar"; force = true; };
  home.file.".local/bin/lsof" = { source = config.lib.file.mkOutOfStoreSymlink "/usr/sbin/lsof"; force = true; };
  home.file.".local/bin/ps" = { source = config.lib.file.mkOutOfStoreSymlink "/bin/ps"; force = true; };
}
