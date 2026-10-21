#!/bin/bash

# Check if Ghostty is running (process name is "Ghostty" with capital G)
if osascript -e 'tell application "System Events" to (name of processes) contains "Ghostty"' 2>/dev/null | grep -q "true"; then
    # Ghostty is already running, create a new window
    # Use AppleScript to click the "New Window" menu item in the File menu
    osascript <<EOF
tell application "System Events"
    tell process "Ghostty"
        click menu item "New Window" of menu "File" of menu bar 1
    end tell
end tell
EOF
else
    # If not running, launch it normally
    open -a "Ghostty"
fi
