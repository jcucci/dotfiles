#!/bin/bash

# Generic Brave profile launcher for AeroSpace
# Usage: brave-profile-launcher.sh <workspace> <profile_name> <profile_dir>

WORKSPACE=$1
PROFILE_NAME=$2
PROFILE_DIR=$3

if [ -z "$WORKSPACE" ] || [ -z "$PROFILE_NAME" ] || [ -z "$PROFILE_DIR" ]; then
  echo "Usage: $0 <workspace> <profile_name> <profile_dir>"
  exit 1
fi

# 1. Switch AeroSpace to Workspace (only if not already there)
CURRENT_WORKSPACE=$(/opt/homebrew/bin/aerospace list-workspaces --focused)
if [ "$CURRENT_WORKSPACE" != "$WORKSPACE" ]; then
  /opt/homebrew/bin/aerospace workspace $WORKSPACE
fi

# 2. Check if Brave window with this profile already exists on this workspace
WINDOW_ID=$(/opt/homebrew/bin/aerospace list-windows --workspace $WORKSPACE --format '%{window-id}|%{app-name}|%{window-title}' | grep "Brave Browser" | grep -i "$PROFILE_NAME" | head -1 | cut -d'|' -f1)

if [ -n "$WINDOW_ID" ]; then
  # Window exists, focus it
  /opt/homebrew/bin/aerospace focus --window-id "$WINDOW_ID"
else
  # Window doesn't exist, launch new window with this profile
  # Directly invoke Brave binary with profile argument
  /Applications/Brave\ Browser.app/Contents/MacOS/Brave\ Browser --profile-directory="$PROFILE_DIR" &
fi
