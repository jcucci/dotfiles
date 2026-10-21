---
description: Analyzed git status summary
model: anthropic/claude-haiku-4-5-20251001
---

Provide an analyzed summary of the current git status.

## Current State

**Branch:**
!`git rev-parse --abbrev-ref HEAD`

**Status:**
!`git status`

**Recent commits:**
!`git log --oneline -5`

## Your Task

Provide a concise, actionable summary:

1. **Branch status**: Which branch, ahead/behind remote?
2. **Working directory**: Clean or dirty?
3. **Staged changes**: What's ready to commit?
4. **Unstaged changes**: What needs to be staged?
5. **Untracked files**: Any new files?
6. **Suggested next action**: What should the user do next?

Keep it brief and actionable.
