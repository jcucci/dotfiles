import json
import os
import sys
import time
from datetime import datetime, timezone

STATE_DIR = os.path.expanduser("~/.claude/brainstall")
os.makedirs(STATE_DIR, exist_ok=True)

try:
    input_data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

session_id = input_data.get("session_id", "unknown")

# Check if Stop just fired for this session (suppress marker within last 3 seconds).
# If so, Claude just finished a turn normally - don't create a notification.
suppress_file = os.path.join(STATE_DIR, f".suppress_{session_id}")
try:
    with open(suppress_file) as f:
        suppress_time = float(f.read().strip())
    if time.time() - suppress_time < 3.0:
        # Stop just fired - suppress this notification
        os.remove(suppress_file)
        sys.exit(0)
    else:
        # Stale suppress marker - clean up and proceed
        os.remove(suppress_file)
except (FileNotFoundError, ValueError):
    pass
cwd = input_data.get("cwd", "")
transcript_path = input_data.get("transcript_path", "")
repo = os.path.basename(cwd) if cwd else "unknown"

# Extract context from transcript:
# 1. Last assistant text (what Claude was working on / said)
# 2. Fallback to last user-typed prompt
context = ""
if transcript_path and os.path.exists(transcript_path):
    try:
        with open(transcript_path) as f:
            lines = f.readlines()

        # First pass: find last assistant text message
        for line in reversed(lines):
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if obj.get("type") == "assistant" and obj.get("message", {}).get("role") == "assistant":
                content = obj["message"].get("content", [])
                if isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict) and item.get("type") == "text":
                            text = item["text"].strip()
                            # Skip empty or very short assistant messages
                            if len(text) > 10:
                                context = text[:100]
                                break
                if context:
                    break

        # Fallback: last user-typed prompt (string content, not tool_results)
        if not context:
            for line in reversed(lines):
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if obj.get("type") == "user" and obj.get("message", {}).get("role") == "user":
                    content = obj["message"].get("content", "")
                    if isinstance(content, str) and content.strip():
                        context = content[:100]
                        break
    except Exception:
        pass

# Clean up context for display
context = context.replace("\n", " ").strip()

state_file = os.path.join(STATE_DIR, f"{session_id}.json")
is_new = not os.path.exists(state_file)

tmux_pane = os.environ.get("TMUX_PANE", "")

state = {
    "session_id": session_id,
    "repo": repo,
    "cwd": cwd,
    "context": context,
    "waiting_since": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "tmux_pane": tmux_pane,
}

with open(state_file, "w") as f:
    json.dump(state, f)

# Fire one-time macOS notification for new waits
if is_new:
    subtitle = f"Brainstall in {repo}"
    message = context if context else "Claude is waiting for you"
    # Escape quotes for osascript
    message = message.replace('"', '\\"')
    subtitle = subtitle.replace('"', '\\"')
    os.system(
        f'osascript -e \'display notification "{message}" with title "Brainstall" subtitle "{subtitle}"\''
    )
