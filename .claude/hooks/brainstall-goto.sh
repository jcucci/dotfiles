#!/bin/bash
# Brainstall - navigate to a tmux pane and activate Ghostty

PANE_ID="$1"
[ -z "$PANE_ID" ] && exit 1

# Find the session:window.pane target for this pane ID
TARGET=$(/opt/homebrew/bin/tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_id}" 2>/dev/null | grep "$PANE_ID" | head -1 | cut -d' ' -f1)
[ -z "$TARGET" ] && exit 1

# Switch tmux client to that session:window and select the pane
/opt/homebrew/bin/tmux switch-client -t "$TARGET" 2>/dev/null
/opt/homebrew/bin/tmux select-pane -t "$TARGET" 2>/dev/null

# Bring Ghostty to front
osascript -e 'tell application "Ghostty" to activate' 2>/dev/null
