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

  # Private taps (kong/agent-auth-cli) download releases with
  # HOMEBREW_GITHUB_API_TOKEN. Take it from the gh CLI per brew call instead of
  # exporting the gh token, which has broad org scopes, to every process. A
  # shim on PATH covers fish, bash, zsh, Task and scripts alike.
  home.file.".local/bin/brew" = {
    executable = true;
    force = true;
    text = ''
      #!/bin/sh
      if [ -z "''${HOMEBREW_GITHUB_API_TOKEN:-}" ] && token=$(gh auth token 2>/dev/null) && [ -n "$token" ]; then
        HOMEBREW_GITHUB_API_TOKEN=$token
        export HOMEBREW_GITHUB_API_TOKEN
      fi
      exec /opt/homebrew/bin/brew "$@"
    '';
  };
}
