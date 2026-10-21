---
allowed-tools: Bash(git fetch:*), Bash(git rebase:*), Bash(git merge:*), Bash(git status:*), Bash(git branch:*), Bash(git stash:*), Bash(jj git fetch:*), Bash(jj rebase:*), Bash(jj status:*), Bash(jj log:*), Bash(jj root:*)
description: Sync current branch with main/develop
---

## Context

- VCS type: !`jj root >/dev/null 2>&1 && echo jj || echo git`

**If jj:**
- Current change: !`jj log -r @ --no-graph 2>/dev/null || true`
- Status: !`jj status 2>/dev/null || true`

**If git:**
- Branch: !`git branch --show-current 2>/dev/null || true`
- Status: !`git status --short 2>/dev/null || true`
- Upstream: !`git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "No upstream"`

## Task

Sync the current change/branch with the base branch (preferred: `develop`, fallback `main` or `master`).

### jj

```bash
jj git fetch
jj rebase -d develop@origin
```

No stash needed — jj handles the working copy natively. On conflict, show `jj status` and ask whether to resolve interactively or `jj undo`.

### git

If there are uncommitted changes: `git stash push -m "Auto-stash before sync"`, restore with `git stash pop` after rebase.

```bash
git fetch origin
git rebase origin/develop
```

On conflict: list conflicting files and ask whether to resolve interactively, `git rebase --abort`, or `git rebase --skip`.

Report final position relative to origin and any remaining work.
