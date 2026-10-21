#!/bin/bash
# Brainstall - Claude Code "waiting for input" hook
# Writes a state file when Claude is waiting, fires a one-time macOS notification.

# Capture stdin before anything else consumes it
INPUT=$(cat)

echo "$INPUT" | /usr/bin/python3 /Users/joe.cucci/.claude/hooks/brainstall.py
