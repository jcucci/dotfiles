---
allowed-tools: Bash(~/.config/tmux/scripts/tmux-worktree-new:*), Bash(gh issue view:*), Bash(git branch:*), Bash(git rev-parse:*)
description: Spawn a parallel Claude agent in a new git worktree and tmux window
argument-hint: <branch | JIRA-123 | #issue> [task description]
disable-model-invocation: true
---

## Context

- In tmux: !`[ -n "$TMUX" ] && echo yes || echo no`
- Current branch: !`git branch --show-current 2>/dev/null`
- Repo: !`git rev-parse --show-toplevel 2>/dev/null`

## Task

Start a new Claude agent on its own worktree, in a new tmux window, seeded with a task. Arguments: `$ARGUMENTS`

If not in tmux or not in a git repo, say so and stop. If there are no arguments, ask what to spawn and stop.

### Work out the branch and task

The first word is the target; everything after it is the task description.

- **Jira key** (`ABC-123`): branch `features/<key lowercased>` (e.g. `features/abc-123`). The new agent should load the ticket itself with the Atlassian MCP.
- **GitHub issue** (`#123` or `123`): run `gh issue view <n> --json title,labels` and use `feat/issue-<n>-<slug>` (or `fix/…` for a bug label); slug is the lowercased title, hyphens for spaces, special chars stripped, max 50 chars.
- **Anything else**: use it as the branch name unchanged.

If the user said to branch from something other than the default branch ("from develop"), pass it as the base. Otherwise leave the base empty and worktrunk uses the default branch.

### Write the seed prompt

The new agent has none of this conversation, so the prompt must stand alone:

- the ticket or issue reference and how to load it, or the task description;
- only the context from this conversation the user clearly means to carry over (file paths, decisions already made), kept short;
- end with: "Explore first and propose a plan. Don't change code until it's approved."

### Spawn

Pass the prompt on stdin so quotes and newlines are safe. The agent starts in plan mode.

```bash
~/.config/tmux/scripts/tmux-worktree-new "<branch>" "$PWD" "<base or empty>" - "--permission-mode plan" <<'PROMPT'
<seed prompt>
PROMPT
```

Do not create the branch, check anything out, or change directory yourself; the script creates the worktree and window.

### Report

One or two lines: the branch, and that the agent is waiting in plan mode in its own window. Remind the user they can reach it with `Ctrl+a A` (picker) or `Ctrl+a j` (next waiting agent). If the script reports an error, show it as-is and stop.
