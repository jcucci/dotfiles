#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Jump to Claude Code
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Tmux

# Documentation:
# @raycast.description Focus Ghostty and switch to the singleton "claude" tmux window in the "main" session
# @raycast.author joe_cucci

export PATH="/opt/homebrew/bin:$PATH"

SESSION="main"
WINDOW="claude"

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION"
fi

if tmux list-windows -t "$SESSION" -F '#W' | grep -q "^${WINDOW}$"; then
  tmux select-window -t "${SESSION}:${WINDOW}"
else
  tmux new-window -t "$SESSION" -n "$WINDOW" -c "$HOME" "exec $SHELL -l -i -c 'claude'"
fi

osascript -e 'tell application "Ghostty" to activate'
