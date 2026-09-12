#!/usr/bin/env python3
"""Maintain the status line's running-agent list on Linux and macOS."""
import fcntl
import json
import os
from pathlib import Path
import sys

mode = sys.argv[1]
try:
    payload = json.load(sys.stdin)
except ValueError:
    payload = {}
kind = payload.get("tool_input", {}).get("subagent_type") or "agent"
kind = str(kind).replace("\n", " ").replace("\r", " ")
root = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
root.mkdir(parents=True, exist_ok=True)
target = root / "running-agents.list"
with (root / "running-agents.list.lock").open("a") as lock:
    fcntl.flock(lock, fcntl.LOCK_EX)
    lines = target.read_text().splitlines() if target.exists() else []
    if mode == "start":
        lines.append(kind)
    elif mode == "stop" and kind in lines:
        lines.remove(kind)
    elif mode == "reset":
        lines = []
    target.write_text("".join(line + "\n" for line in lines))
