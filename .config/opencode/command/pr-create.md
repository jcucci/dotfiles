---
description: Generate and create a pull request
model: anthropic/claude-sonnet-4-5-20250929
---

Generate a pull request for the current branch and create it via GitHub CLI.

## Branch Context

**Current branch:**
!`git rev-parse --abbrev-ref HEAD`

**Remote tracking:**
!`git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "No upstream set"`

**Commits to be included:**
!`git log main..HEAD --oneline`

**Files changed:**
!`git diff main...HEAD --stat`

## Your Task

1. **Check if branch is pushed**: If not tracking a remote, push first with:
   ```
   git push -u origin $(git rev-parse --abbrev-ref HEAD)
   ```

2. **Extract ticket from branch name** (if present):
   - `feature/shrp-123456` → Include "SHRP-123456" in title
   - `feature/ns-1` → Include "NS-1" in title

3. **Generate PR content**:

   **Title format:**
   - With Jira ticket: `SHRP-123456: Brief description of changes`
   - With custom prefix: `NS-1: Brief description`
   - Without ticket: `Brief description of changes`

   **Body format:**
   ```markdown
   ## Summary
   - Bullet point 1 describing key change
   - Bullet point 2 if needed
   - Bullet point 3 if needed

   ## Testing
   - How this was tested
   ```

4. **Create the PR** using GitHub CLI:
   ```bash
   gh pr create --title "TITLE" --body "BODY"
   ```

5. **Report the PR URL** after creation

If the branch has no commits ahead of main, inform the user there's nothing to create a PR for.
