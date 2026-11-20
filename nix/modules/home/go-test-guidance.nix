# Go-on-macOS test guidance for coding agents.
#
# The live ~/.claude/CLAUDE.md and ~/.codex/AGENTS.md are user-owned, so
# activation only appends the managed block when its marker is missing.
# CLAUDE.md.default (claude.nix) already carries the same block.
{ lib, config, ... }: let
  home = config.home.homeDirectory;
  guidance = ./go-test-guidance/guidance.md;
  mergeGuidance = ./go-test-guidance/merge-guidance.sh;
in {
  home.activation.goTestGuidanceMerge = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD "${mergeGuidance}" --file "${home}/.claude/CLAUDE.md" --block "${guidance}" || true
    $DRY_RUN_CMD "${mergeGuidance}" --file "${home}/.codex/AGENTS.md" --block "${guidance}" || true
  '';
}
