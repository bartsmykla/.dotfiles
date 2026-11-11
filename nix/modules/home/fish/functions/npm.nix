# npm registry authentication
#
# ~/.npmrc holds the registry auth token, so it must not be a Home Manager
# store symlink: those files are world-readable 0444 and owned by root.
# sops-nix decrypts the npmrc at activation. We install a 0600 copy in $HOME
# instead of symlinking into $DARWIN_USER_TEMP_DIR, which macOS can purge
# (see claude.nix).
#
# Set the secret before home-manager switch, or activation restores the
# pre-switch ~/.npmrc as a 0600 regular file and leaves the token as it was.
# Edit with:
#   SOPS_AGE_KEY_FILE=~/.config/age/key.txt sops nix/secrets/secrets.yaml
# and give npm.npmrc the file contents:
#   //registry.npmjs.org/:_authToken=<token>
{ config, lib, ... }:

let
  # Decrypted sops destination; the $HOME copy is what npm reads.
  secretPath = "%r/secrets/npmrc";
  placeholder = "PLACEHOLDER_REPLACE_WITH_NPMRC";
  preservePath = "$HOME/.npmrc.hm-switch-preserve";
in
{
  sops.secrets."npm/npmrc" = {
    path = secretPath;
    mode = "0400";
  };

  # Dropping home.file.".npmrc" makes linkGeneration delete the old store
  # symlink at writeBoundary. Snapshot the contents first so a placeholder
  # secret cannot leave the machine without an npmrc.
  home.activation.preserveNpmrc = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ -e "$HOME/.npmrc" ] || [ -L "$HOME/.npmrc" ]; then
      $DRY_RUN_CMD rm -f ${preservePath}
      $DRY_RUN_CMD cp "$HOME/.npmrc" ${preservePath}
      $DRY_RUN_CMD chmod 600 ${preservePath}
    fi
  '';

  home.activation.npmrc = lib.hm.dag.entryAfter [
    "writeBoundary"
    "sops-nix"
    "preserveNpmrc"
    "setupLaunchAgents"
  ] ''
    # On Darwin, sops-nix only bootstraps a launchd agent and does not wait
    # for decryption. Stop that in-flight agent and run the same program in
    # the foreground so the current secret generation is installed before
    # we copy ~/.npmrc. Read Program from the Home Manager config: the
    # generated plist uses ProgramArguments, not Program.
    sops_program='${config.launchd.agents.sops-nix.config.Program}'
    sops_path='${config.sops.environment.PATH}'
    if [ -n "$sops_program" ] && [ -x "$sops_program" ]; then
      if [ -x /bin/launchctl ]; then
        domain_target="gui/$(id -u)"
        $DRY_RUN_CMD /bin/launchctl bootout "$domain_target/org.nix-community.home.sops-nix" >/dev/null 2>&1 || true
      fi
      $DRY_RUN_CMD env PATH="$sops_path" "$sops_program"
    fi

    if [ -x /usr/bin/getconf ]; then
      darwin_temp_dir=$(/usr/bin/getconf DARWIN_USER_TEMP_DIR 2>/dev/null)
    else
      darwin_temp_dir=""
    fi

    src=""
    if [ -n "$darwin_temp_dir" ] && [ -f "$darwin_temp_dir/secrets/npmrc" ]; then
      src="$darwin_temp_dir/secrets/npmrc"
    fi

    if [ -n "$src" ] && ! grep -qx '${placeholder}' "$src" 2>/dev/null; then
      $DRY_RUN_CMD rm -f "$HOME/.npmrc"
      $DRY_RUN_CMD install -m 600 "$src" "$HOME/.npmrc"
    elif [ -f ${preservePath} ]; then
      $DRY_RUN_CMD rm -f "$HOME/.npmrc"
      $DRY_RUN_CMD install -m 600 ${preservePath} "$HOME/.npmrc"
    fi

    $DRY_RUN_CMD rm -f ${preservePath}
  '';
}
