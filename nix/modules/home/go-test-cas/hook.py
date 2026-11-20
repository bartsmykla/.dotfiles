#!/usr/bin/env python3
"""Additive PreToolUse hook for Claude Code and Codex.

If the tool command looks like it will run `go test` and the go-test-cas
shim would not already be the `go` on PATH for that command, rewrite the
command so it is. Respects GO_TEST_CAS=0. Does not strip -count=1.
Never fails the tool call: on error, exit 0 with no rewrite.
"""
from __future__ import annotations

import json
import os
import re
import sys


def main() -> int:
    provider = os.environ.get("GO_TEST_CAS_HOOK_PROVIDER", "claude")
    for arg in sys.argv[1:]:
        if arg == "--codex":
            provider = "codex"
        elif arg == "--claude":
            provider = "claude"

    if os.environ.get("GO_TEST_CAS", "1") == "0":
        return 0

    try:
        raw = sys.stdin.read()
        if not raw.strip():
            return 0
        data = json.loads(raw)
    except Exception:
        return 0

    home = os.environ.get("GO_TEST_CAS_HOOK_HOME") or os.path.expanduser("~")
    shim = os.environ.get("GO_TEST_CAS_HOOK_SHIM") or os.path.join(home, ".local/bin/go")
    bindir = os.environ.get("GO_TEST_CAS_HOOK_BINDIR") or os.path.join(home, ".local/bin")
    if not os.path.isfile(shim) or not os.access(shim, os.X_OK):
        return 0

    command, tool_input, key = extract_command(data)
    if command is None:
        return 0
    if not looks_like_go_test(command):
        return 0
    if re.search(r"(?:^|[;&|\n]|&&)\s*GO_TEST_CAS=0\b", command):
        return 0

    new_command = rewrite_command(command, bindir)
    if new_command == command:
        return 0

    updated = dict(tool_input)
    updated[key] = new_command
    event = data.get("hook_event_name") or data.get("hookEventName") or "PreToolUse"
    out = {
        "hookSpecificOutput": {
            "hookEventName": event,
            "updatedInput": updated,
        }
    }
    # Codex only applies updatedInput when paired with allow. The rewrite
    # only prepends PATH / prefers the go shim; it does not change the rest
    # of the command or drop -count=1. Claude keeps normal permission flow.
    if provider == "codex":
        out["hookSpecificOutput"]["permissionDecision"] = "allow"

    sys.stdout.write(json.dumps(out, separators=(",", ":")))
    return 0


def extract_command(data):
    tool_input = data.get("tool_input") or data.get("toolInput") or data.get("input") or {}
    if not isinstance(tool_input, dict):
        return None, None, None
    for key in ("command", "cmd"):
        if isinstance(tool_input.get(key), str):
            return tool_input[key], tool_input, key
    return None, None, None


def looks_like_go_test(command: str) -> bool:
    return (
        re.search(
            r"(?:^|[;&|\n]|&&|\|\||`|\$\(|\(|\s)(?:GO_TEST_CAS=0\s+)?(?:\S*/)?go\s+test\b",
            command,
        )
        is not None
    )


def rewrite_command(command: str, bindir: str) -> str:
    prefix = 'PATH="%s:$PATH" ' % bindir
    if not (
        command.startswith(prefix)
        or command.startswith("PATH=$HOME/.local/bin:$PATH ")
        or ('PATH="%s:$PATH"' % bindir) in command[:120]
    ):
        command = prefix + command

    def repl(match: re.Match) -> str:
        return match.group(1) + "go" + match.group(2)

    return re.sub(
        r"(^|[;&|\n]|&&|\|\||`|\$\(|\(|\s)(?:(?:\.\.?|\S+)/)+go(\s+test\b)",
        repl,
        command,
    )


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:
        raise SystemExit(0)
