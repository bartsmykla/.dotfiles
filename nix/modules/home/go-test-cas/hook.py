#!/usr/bin/env python3
"""Additive Claude Code PreToolUse hook for the go-test-cas shim.

If a Bash command looks like it runs bare `go test` and the shim is not the
`go` on this process's PATH, prepend `export PATH=<bindir>:$PATH;` so every
part of the command (loops, subshells, `cd x && go test`) resolves the shim.
Explicit go paths are left alone. Respects GO_TEST_CAS=0. Never fails the
tool call: on error, exit 0 with no rewrite. Normal permission flow applies.
"""
from __future__ import annotations

import json
import os
import re
import shutil
import sys


def main() -> int:
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
    found = shutil.which("go")
    if found and os.path.realpath(found) == os.path.realpath(shim):
        return 0

    tool_input = data.get("tool_input")
    if not isinstance(tool_input, dict) or not isinstance(tool_input.get("command"), str):
        return 0
    command = tool_input["command"]
    if not re.search(r"(?:^|[;&|\n`(]|\s)go\s+test\b", command):
        return 0
    if re.search(r"(?:^|[;&|\n]|\s)GO_TEST_CAS=0\b", command):
        return 0

    prefix = 'export PATH="%s:$PATH"; ' % bindir
    if command.startswith(prefix):
        return 0

    updated = dict(tool_input)
    updated["command"] = prefix + command
    out = {
        "hookSpecificOutput": {
            "hookEventName": data.get("hook_event_name") or "PreToolUse",
            "updatedInput": updated,
        }
    }
    sys.stdout.write(json.dumps(out, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:
        raise SystemExit(0)
