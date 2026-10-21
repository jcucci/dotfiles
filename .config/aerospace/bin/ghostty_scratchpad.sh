#!/usr/bin/env bash

APP_ID="com.mitchellh.ghostty"
SCRATCH_WS="term"

# Get current workspace before doing anything
current_ws="$(aerospace list-workspaces --focused)"

# Check if we're already on the scratchpad workspace
if [ "$current_ws" = "$SCRATCH_WS" ]; then
  # We're on scratchpad, go back to previous workspace
  aerospace workspace-back-and-forth
  exit 0
fi

# Check for existing Ghostty window on scratchpad workspace
window_id="$(aerospace list-windows --workspace "$SCRATCH_WS" --format '%{window-id}' | head -1)"

if [ -z "$window_id" ]; then
  # No window on scratchpad -> create one
  # Get current focused window ID so we know when the new one takes focus
  old_window="$(aerospace list-windows --focused --format '%{window-id}')"

  open -na Ghostty

  # Wait for new window to take focus (up to 3 seconds)
  for i in {1..30}; do
    sleep 0.1
    new_window="$(aerospace list-windows --focused --format '%{window-id}')"
    if [ "$new_window" != "$old_window" ] && [ -n "$new_window" ]; then
      # New window has focus, now move it
      aerospace move-node-to-workspace "$SCRATCH_WS"
      aerospace workspace "$SCRATCH_WS"
      aerospace layout floating

      # Explicitly focus the new window and give macOS time to update
      aerospace focus --window-id "$new_window"
      sleep 0.3

      # Center window at 80% screen size
      osascript -e '
        tell application "Finder"
          set screenBounds to bounds of window of desktop
          set screenWidth to item 3 of screenBounds
          set screenHeight to item 4 of screenBounds
        end tell

        set winWidth to screenWidth * 0.8
        set winHeight to screenHeight * 0.8
        set winX to (screenWidth - winWidth) / 2
        set winY to (screenHeight - winHeight) / 2

        tell application "System Events"
          tell process "Ghostty"
            set position of front window to {winX, winY}
            set size of front window to {winWidth, winHeight}
          end tell
        end tell
      '
      exit 0
    fi
  done

  # Fallback if detection failed
  aerospace workspace "$SCRATCH_WS"
else
  # Scratchpad exists -> switch to it and focus the window
  aerospace workspace "$SCRATCH_WS"
  aerospace focus --window-id "$window_id" 2>/dev/null || true
fi

