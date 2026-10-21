#!/bin/bash
# Record Claude Code's state on its tmux pane so the picker, jump-to-waiting
# keybind and status bar can read it (@claude_state / @claude_since pane options).
# The window mirrors it as @claude_wstate for the window-tab marker.
# Usage (from a hook): tmux-claude-state.sh working|done|notify|clear
#
#   working  UserPromptSubmit, PreToolUse
#   done     Stop (turn finished, waiting for your next prompt)
#   notify   Notification: permission/elicitation prompts mark "blocked";
#            idle_prompt is ignored (the pane is already "done")
#   clear    SessionEnd
#
# No-op outside tmux. Note a user interrupt (Esc) fires no Stop, so a pane can
# read "working" until the next prompt.

export PATH="/opt/homebrew/bin:$PATH"
[ -n "$TMUX_PANE" ] || exit 0

# Redraw every client's status line now instead of waiting for status-interval
refresh() {
    tmux list-clients -F '#{client_name}' | while read -r c; do
        tmux refresh-client -S -t "$c"
    done
}

mode="$1"
case "$mode" in
    working|done)
        cat >/dev/null
        state="$mode"
        ;;
    notify)
        case "$(jq -r '.notification_type // empty' 2>/dev/null)" in
            idle_prompt) exit 0 ;;
            *) state="blocked" ;;
        esac
        ;;
    clear)
        cat >/dev/null
        tmux set-option -pu -t "$TMUX_PANE" @claude_state
        tmux set-option -pu -t "$TMUX_PANE" @claude_since
        tmux set-option -wu -t "$TMUX_PANE" @claude_wstate
        refresh
        exit 0
        ;;
    *) exit 0 ;;
esac

# PreToolUse fires on every tool call; only touch the timestamp on a real change
current=$(tmux show-options -pqv -t "$TMUX_PANE" @claude_state)
[ "$current" = "$state" ] && exit 0
tmux set-option -p -t "$TMUX_PANE" @claude_state "$state"
tmux set-option -p -t "$TMUX_PANE" @claude_since "$(date +%s)"
tmux set-option -w -t "$TMUX_PANE" @claude_wstate "$state"
refresh
