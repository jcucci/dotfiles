#!/bin/bash

# SwiftBar metadata
# <xbar.title>Slack Unread Count</xbar.title>
# <xbar.desc>Shows Slack unread count from dock badge via lsappinfo</xbar.desc>
# <xbar.version>1.0</xbar.version>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

NAG_INTERVAL_SECONDS=300  # 5 minutes
STATE_FILE="/tmp/swiftbar-slack-unread-state"
LAST_NAG_FILE="/tmp/swiftbar-slack-last-nag"

APP_NAME="Slack"
SF_SYMBOL="message.badge.fill"

# Read dock badge via lsappinfo
raw=$(lsappinfo info -only StatusLabel "$APP_NAME" 2>/dev/null)
badge=$(echo "$raw" | grep -o '"label"="[^"]*"' | sed 's/"label"="//;s/"$//')

now=$(date +%s)

if [[ -z "$badge" ]]; then
    # No badge — no unreads (or app not running)
    rm -f "$STATE_FILE" "$LAST_NAG_FILE"
    echo ":${SF_SYMBOL}: | sfcolor=34,139,34"
    echo "---"
    echo "No unread messages"
    echo "Open Slack | href=slack://"
    echo "Refresh | refresh=true"
    exit 0
fi

# Badge exists — could be a number or a dot
if [[ "$badge" =~ ^[0-9]+$ ]]; then
    display="$badge"
else
    # Dot badge (activity without specific count)
    display="!"
fi

# Nag notification logic
if [[ -f "$STATE_FILE" ]]; then
    first_seen=$(cat "$STATE_FILE")
else
    echo "$now" > "$STATE_FILE"
    first_seen=$now
fi

elapsed=$((now - first_seen))

if [[ $elapsed -ge $NAG_INTERVAL_SECONDS ]]; then
    last_nag=0
    [[ -f "$LAST_NAG_FILE" ]] && last_nag=$(cat "$LAST_NAG_FILE")
    since_last_nag=$((now - last_nag))

    if [[ $since_last_nag -ge $NAG_INTERVAL_SECONDS ]]; then
        osascript -e "display notification \"$display unread message(s) in Slack\" with title \"Slack\" sound name \"Ping\""
        echo "$now" > "$LAST_NAG_FILE"
    fi
fi

echo ":${SF_SYMBOL}: $display | sfcolor=255,59,48"
echo "---"
echo "$display unread message(s)"
echo "Open Slack | href=slack://"
echo "Refresh | refresh=true"
