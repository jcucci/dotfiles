#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Brave Work
# @raycast.mode silent
# @raycast.icon 💼

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call shared launcher with Work profile settings
"$SCRIPT_DIR/brave-profile-launcher.sh" 5 "Work" "Default"
