# Content-addressed Go test binary exec cache (macOS XProtect mitigation).
#
# A PATH shim at ~/.local/bin/go injects `go test -exec=go-test-cas-exec` so
# identical test binaries are executed from a stable inode under
# ~/Library/Caches/go-test-cas and scanned once. The trim job in go-cache.nix
# prunes that directory. GOFLAGS is left unchanged.
#
# Live Claude Code and Codex settings/hooks files are user-owned. This module
# installs the hook script and guidance, then merges additively if those files
# already exist. It never replaces ~/.claude/settings.json, ~/.claude/hooks,
# ~/.codex/hooks.json, or ~/.codex/config.toml.
{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  execScript = ./go-test-cas/go-test-cas-exec.sh;
  shimScript = ./go-test-cas/go-shim.sh;
  hookScript = ./go-test-cas/hook.py;
  mergeHooks = ./go-test-cas/merge-hooks.py;
  mergeGuidance = ./go-test-cas/merge-guidance.sh;
  guidance = ./go-test-cas/guidance.md;
in {
  # ~/.local/bin is already first on PATH (path.nix). The shim must sit there
  # so agent and GUI launches that inherit the user PATH pick it up.
  home.file.".local/bin/go-test-cas-exec" = {
    source = execScript;
    executable = true;
    force = true;
  };
  home.file.".local/bin/go" = {
    source = shimScript;
    executable = true;
    force = true;
  };
  home.file.".local/bin/go-test-cas-hook" = {
    source = hookScript;
    executable = true;
    force = true;
  };

  # Templates for a manual reset or first-time seed. Live files stay editable.
  home.file.".claude/go-test-macos.md.default" = {
    source = guidance;
    force = true;
  };
  home.file.".codex/go-test-macos.md.default" = {
    source = guidance;
    force = true;
  };

  home.activation.goTestCasMerge = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    guidance="${guidance}"
    merge_hooks="${mergeHooks}"
    merge_guidance="${mergeGuidance}"

    $DRY_RUN_CMD "${pkgs.python3}/bin/python3" "$merge_hooks" \
      --file "${home}/.claude/settings.json" \
      --matcher "Bash" \
      --command '$HOME/.local/bin/go-test-cas-hook --claude' \
      --needle "go-test-cas-hook" || true

    $DRY_RUN_CMD "${pkgs.python3}/bin/python3" "$merge_hooks" \
      --file "${home}/.codex/hooks.json" \
      --matcher "shell|shell_command|local_shell|exec_command|container.exec" \
      --command '$HOME/.local/bin/go-test-cas-hook --codex' \
      --needle "go-test-cas-hook" || true

    $DRY_RUN_CMD "$merge_guidance" --file "${home}/.claude/CLAUDE.md" --block "$guidance" || true
    $DRY_RUN_CMD "$merge_guidance" --file "${home}/.codex/AGENTS.md" --block "$guidance" || true
  '';
}
