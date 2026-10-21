import json
import os
import sys
import time

STATE_DIR = os.path.expanduser("~/.claude/brainstall")

try:
    input_data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

session_id = input_data.get("session_id", "")
hook_event = input_data.get("hook_event_name", "")

if session_id:
    state_file = os.path.join(STATE_DIR, f"{session_id}.json")
    suppress_file = os.path.join(STATE_DIR, f".suppress_{session_id}")

    if hook_event == "Stop":
        # Don't clear directly - write a suppress marker so Notification
        # knows not to re-create the state. Also clear the state file.
        with open(suppress_file, "w") as f:
            f.write(str(time.time()))
        try:
            os.remove(state_file)
        except FileNotFoundError:
            pass
    else:
        # UserPromptSubmit, PreToolUse, SessionEnd - clear both state and suppress
        try:
            os.remove(state_file)
        except FileNotFoundError:
            pass
        try:
            os.remove(suppress_file)
        except FileNotFoundError:
            pass
