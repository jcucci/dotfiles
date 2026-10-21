#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Brave Home
# @raycast.mode silent
# @raycast.icon 🏠

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call shared launcher with Home profile settings
"$SCRIPT_DIR/brave-profile-launcher.sh" 4 "Personal" "Profile 1"
