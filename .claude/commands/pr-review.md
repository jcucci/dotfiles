---
allowed-tools: Bash(gh pr:*), Bash(gh api:*), Bash(gh run:*), Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(jj status:*), Bash(jj diff:*), Bash(jj log:*), Bash(jj commit:*), Bash(jj git push:*), Bash(jj root:*), Bash(dotnet build:*), Bash(dotnet test:*)
description: Address PR review feedback and CI failures, then push fixes
---

## Context

- VCS type: !`jj root >/dev/null 2>&1 && echo jj || echo git`

**If jj:**
- Bookmarks on @: !`jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null || true`

**If git:**
- Branch: !`git branch --show-current 2>/dev/null || true`

## Task

Address PR review feedback and CI failures, then commit and push.

### Find the PR

Use the bookmark (jj) or branch (git) name from Context:

```bash
gh pr view <name> --json number,title,state,reviewDecision,url,headRefName,reviews,comments
gh api repos/{owner}/{repo}/pulls/<pr-number>/comments
gh pr checks <name>
```

If no PR exists, tell the user and stop.

### Triage review comments

Categorize each comment as **Actionable** (code change), **Question** (reply only), **Nit** (optional), or **Praise** (no action). Present:

| # | Reviewer | Type | File:Line | Feedback | Action |
|---|----------|------|-----------|----------|--------|

### Triage CI failures

For each failed check: `gh run view <run-id> --log-failed`, identify root cause (build/test/lint), propose fix.

| Check | Status | Issue | Fix |
|-------|--------|-------|-----|

### Confirm what to do (AskUserQuestion)

- Address all
- Pick and choose (then multi-select the individual items)
- CI only
- Cancel

### Apply + verify + push

Make the changes. For build/test related fixes, verify locally before pushing.

- **git**: `git add <files>` + `git commit -m "…"` + `git push`
- **jj**: `jj commit -m "…"` + `jj git push`

Commit message should summarize what was addressed (e.g., "Fix null check and rename per review feedback").

Show: files changed, commit/change id, PR URL, any remaining unaddressed comments.

## Notes

- Don't resolve/dismiss review threads — let the reviewer do that.
- If a comment is ambiguous, flag it instead of guessing.
- Call out CI failures that look unrelated to the PR changes (flaky tests, infra).
