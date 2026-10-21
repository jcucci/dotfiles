---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git checkout:*), Bash(git branch:*), Bash(jj status:*), Bash(jj diff:*), Bash(jj log:*), Bash(jj commit:*), Bash(jj root:*), Bash(jj git push:*)
description: Quick commit for small, obvious changes
---

## Context

- VCS type: !`jj root >/dev/null 2>&1 && echo jj || echo git`

**If jj:**
- Status: !`jj status 2>/dev/null || true`
- Diff stat: !`jj diff --stat 2>/dev/null || true`
- Bookmarks on @: !`jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null || true`

**If git:**
- Status: !`git status 2>/dev/null || true`
- Diff stat: !`git diff HEAD --stat 2>/dev/null || true`
- Branch: !`git branch --show-current 2>/dev/null || true`

## Task

Commit quickly without extensive review. If the diff is >50 lines or >3 files, suggest `/commit` instead.

### Branch protection

**git**: if on `main`/`master`/`develop`, suggest a branch name (`feat/…`, `fix/…`, `refactor/…`, `chore/…`) and use AskUserQuestion to offer: use suggested / custom / stay on current (warn).

**jj**: if `@` has a protected bookmark, warn and suggest `jj new`.

### Commit

Write a short message based on the diff.

- **git**: `git add <specific-files>` (not `git add .` unless all changes are intended), then `git commit -m "…"` (HEREDOC for multi-line).
- **jj**: `jj commit -m "…"`.

Show result: `git log -1 --stat` or `jj log -r @- --limit 1 --stat`.

## Safety

Skip if secrets are in the diff (`.env`, `*.pem`, `credentials*`).
