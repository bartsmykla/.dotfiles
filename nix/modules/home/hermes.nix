{ config, lib, pkgs, ... }:

let
  # Only the bootstrap script is pinned. It installs the latest Hermes release
  # from prebuilt downloads, and `hermes update` keeps it current afterwards.
  # The upstream Nix flake is not used: it has no binary cache, so it compiles
  # the whole Python and Node tree on this machine.
  installer = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/NousResearch/hermes-agent/v0.23.2/scripts/install.sh";
    hash = "sha256-xz2tTc98nsrbmFeOKMx2PSPXvj+htRNUUxkDh5VJMhQ=";
  };
in
{
  # The installer picks the rc file from $SHELL. Fish is set so it finds the
  # fish_add_path call in fish/environment.nix and leaves config.fish, a
  # read-only store link, alone.
  home.activation.installHermesAgent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x "$HOME/.local/bin/hermes" ]; then
      run env \
        SHELL=${config.programs.fish.package}/bin/fish \
        PATH="${config.programs.git.package}/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
        ${pkgs.bash}/bin/bash ${installer} --skip-setup \
        || warnEcho "Hermes Agent install failed, run home-manager switch again"
    fi
  '';
}
