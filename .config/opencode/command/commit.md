---
description: Generate commit message from staged changes and commit
agent: git-helper
model: anthropic/claude-sonnet-4-5-20250929
---

Analyze staged changes and create a commit with an appropriate message.

## Current State

**Branch:**
!`git rev-parse --abbrev-ref HEAD`

**Staged changes:**
!`git diff --cached --stat`

**Staged diff:**
!`git diff --cached`

## Your Task

1. **Extract ticket from branch name** (if present):
   - `feature/shrp-123456` → Use "SHRP-123456: " prefix
   - `feature/ns-1` → Use "NS-1: " prefix
   - Other branches → Use conventional commit format

2. **Analyze the staged changes** to understand:
   - What files were modified
   - The nature of the changes (feature, fix, refactor, etc.)
   - The purpose/intent of the changes

3. **Generate a commit message** following conventions:
   - With ticket: `SHRP-123456: Add patient validation logic`
   - Without ticket: `feat: Add patient validation logic`
   - Keep under 72 characters
   - Use imperative mood

4. **Show the proposed commit** and ask for confirmation

5. **Execute the commit** after user confirms

If there are no staged changes, inform the user and suggest using `git add` first.
