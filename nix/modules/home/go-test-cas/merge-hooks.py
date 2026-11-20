#!/usr/bin/env python3
"""Idempotently add a PreToolUse hook entry to a Claude Code settings JSON.

Does not print file contents. Exits 0 on success or a skip, 1 on unexpected
I/O errors. Invalid JSON is a skip (exit 0) so Home Manager activation cannot
break on a user's in-progress edit.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path


def already_present(entries, needle: str) -> bool:
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        for hook in entry.get("hooks") or []:
            if not isinstance(hook, dict):
                continue
            command = hook.get("command") or ""
            if needle in str(command):
                return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True)
    parser.add_argument("--command", required=True)
    parser.add_argument("--matcher", default="Bash")
    parser.add_argument("--needle", default="go-test-cas-hook")
    args = parser.parse_args()

    path = Path(args.file)
    # A symlink points at a file someone else manages; replacing it would
    # turn it into a plain file.
    if path.is_symlink() or not path.is_file():
        print(f"go-test-cas: skip hook merge, {path.name} is missing or not a regular file", file=sys.stderr)
        return 0
    try:
        before = path.stat().st_mtime_ns
        data = json.loads(path.read_text())
    except json.JSONDecodeError:
        print(f"go-test-cas: skip hook merge, invalid JSON in {path.name}", file=sys.stderr)
        return 0
    except OSError as exc:
        print(f"go-test-cas: skip hook merge, cannot read {path.name}: {exc}", file=sys.stderr)
        return 0
    if not isinstance(data, dict):
        print(f"go-test-cas: skip hook merge, unexpected JSON in {path.name}", file=sys.stderr)
        return 0

    hooks = data.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        print(f"go-test-cas: skip hook merge, hooks is not an object in {path.name}", file=sys.stderr)
        return 0
    entries = hooks.setdefault("PreToolUse", [])
    if not isinstance(entries, list):
        print(f"go-test-cas: skip hook merge, PreToolUse is not a list in {path.name}", file=sys.stderr)
        return 0
    if already_present(entries, args.needle):
        print(f"go-test-cas: hook already present in {path.name}", file=sys.stderr)
        return 0

    entry = {
        "matcher": args.matcher,
        "hooks": [{"type": "command", "command": args.command}],
    }
    entries.append(entry)

    text = json.dumps(data, indent=2) + "\n"
    try:
        fd, tmp = tempfile.mkstemp(prefix="go-test-cas-hooks.", suffix=".json", dir=str(path.parent))
        try:
            with os.fdopen(fd, "w") as fh:
                fh.write(text)
            os.chmod(tmp, path.stat().st_mode)
            if path.stat().st_mtime_ns != before:
                os.unlink(tmp)
                print(f"go-test-cas: skip hook merge, {path.name} changed during merge", file=sys.stderr)
                return 0
            os.replace(tmp, path)
        except Exception:
            try:
                os.unlink(tmp)
            except OSError:
                pass
            raise
    except OSError as exc:
        print(f"go-test-cas: failed to write {path.name}: {exc}", file=sys.stderr)
        return 1

    print(f"go-test-cas: added PreToolUse hook to {path.name}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
