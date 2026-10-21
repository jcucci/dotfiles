---
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(jj log:*), Bash(jj diff:*), Bash(jj root:*)
description: Generate PR description from branch changes
---

## Context

- VCS type: !`jj root >/dev/null 2>&1 && echo jj || echo git`

**If jj:**
- Bookmarks on @: !`jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null || true`
- Changes since develop: !`jj log -r 'develop@origin..@' --no-graph 2>/dev/null || true`
- Files changed: !`jj diff --from develop@origin --stat 2>/dev/null || true`

**If git:**
- Branch: !`git branch --show-current 2>/dev/null || true`
- Commits since develop: !`git log origin/develop..HEAD --oneline 2>/dev/null || true`
- Files changed: !`git diff origin/develop --stat 2>/dev/null || true`

## Task

Generate a PR description for every commit on this branch — not just the most recent one. Read the full diff before drafting.

- **jj**: `jj diff --from develop@origin`
- **git**: `git diff origin/develop`

### Output

Present in a copyable code block:

```markdown
## Summary
<1-3 bullet points>

## Changes
- <significant changes, grouped by feature/area if multiple>

## Test Plan
- [ ] <how to test this change>
- [ ] <additional verification>

## Notes
<breaking changes, follow-up work, ticket references>
```

Focus on why. Include ticket/issue references if commits mention them. Call out breaking changes explicitly.
