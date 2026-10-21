---
allowed-tools: Bash(gh issue:*), Bash(gh api:*), Bash(git fetch:*), Bash(git checkout:*), Bash(git pull:*), Bash(git branch:*), Bash(git status:*), Bash(jj git fetch:*), Bash(jj new:*), Bash(jj bookmark create:*), Bash(jj bookmark set:*), Bash(jj status:*), Bash(jj log:*), Bash(jj root:*)
description: Pick a GitHub issue to work on and plan the implementation
---

## Context

- VCS type: !`jj root >/dev/null 2>&1 && echo jj || echo git`
- Open issues: !`gh issue list --state open --limit 20 --json number,title,labels,assignees,createdAt`

## Task

Sync to latest main, pick an issue, create a branch, then plan.

### Sync to main

**jj**: `jj git fetch && jj new main@origin` (fall back to `master@origin` or `develop@origin` if `main` doesn't exist).

**git**: `git fetch origin && git checkout main && git pull origin main` (fall back similarly).

### Pick an issue

Evaluate the open issues on priority labels, age, scope clarity, and blocking relationships.

- If one clear candidate: present it and ask to confirm or pick another.
- If 2–4 good candidates: use AskUserQuestion with issue number, title, and a one-line rationale per option.
- If no open issues: tell the user and stop.

### Create the branch

Slugify the issue title: lowercase, hyphens for spaces, strip special chars, max 50 chars. Name: `feat/issue-<number>-<slug>` (or `fix/…` if the issue has a bug label).

- **jj**: `jj bookmark create <name> -r @`
- **git**: `git checkout -b <name>`

### Plan

Use EnterPlanMode for the selected issue, addressing its acceptance criteria and any technical notes from the issue body.
