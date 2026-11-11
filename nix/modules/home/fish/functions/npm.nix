# npm registry authentication
#
# ~/.npmrc holds the registry auth token, so it must not be a Home Manager
# store symlink: those files are world-readable 0444 and owned by root.
# sops-nix decrypts the npmrc at activation. We install a 0600 copy in $HOME
# instead of symlinking into $DARWIN_USER_TEMP_DIR, which macOS can purge
# (see claude.nix).
#
# Set the secret before home-manager switch, or activation leaves the existing
# ~/.npmrc alone. Edit with:
#   SOPS_AGE_KEY_FILE=~/.config/age/key.txt sops nix/secrets/secrets.yaml
# and give npm.npmrc the file contents:
#   //registry.npmjs.org/:_authToken=<token>
{ config, lib, ... }:

let
  # Decrypted sops destination; the $HOME copy is what npm reads.
  secretPath = "%r/secrets/npmrc";
  placeholder = "PLACEHOLDER_REPLACE_WITH_NPMRC";
in
{
  sops.secrets."npm/npmrc" = {
    path = secretPath;
    mode = "0400";
  };

  home.activation.npmrc = lib.hm.dag.entryAfter [ "writeBoundary" "sops-nix" ] ''
    if [ -x /usr/bin/getconf ]; then
      darwin_temp_dir=$(/usr/bin/getconf DARWIN_USER_TEMP_DIR 2>/dev/null)
    else
      darwin_temp_dir=""
    fi

    src=""
    if [ -n "$darwin_temp_dir" ] && [ -f "$darwin_temp_dir/secrets/npmrc" ]; then
      src="$darwin_temp_dir/secrets/npmrc"
    fi

    if [ -n "$src" ]; then
      if grep -qx '${placeholder}' "$src" 2>/dev/null; then
        echo "sops secret npm/npmrc is still the placeholder; not replacing ~/.npmrc" >&2
      else
        # Replace a previous Home Manager store symlink or an older copy.
        $DRY_RUN_CMD rm -f "$HOME/.npmrc"
        $DRY_RUN_CMD install -m 600 "$src" "$HOME/.npmrc"
      fi
    fi
  '';
}
