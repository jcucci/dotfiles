---
allowed-tools: Bash(gh issue:*), Bash(gh api:*), Bash(git checkout:*), Bash(git branch:*), Bash(git status:*), Bash(jj status:*), Bash(jj log:*), Bash(jj bookmark create:*), Bash(jj new:*), Bash(jj root:*)
description: Review a GitHub issue and either close it or plan implementation
---

## Context

- Issue: !`gh issue view $ARGUMENTS --json number,title,body,state,labels`
- VCS type: !`jj root >/dev/null 2>&1 && echo jj || echo git`

**If jj:**
- Current change: !`jj log -r @ --no-graph 2>/dev/null || true`
- Status: !`jj status 2>/dev/null || true`

**If git:**
- Branch: !`git branch --show-current 2>/dev/null || true`
- Status: !`git status --short 2>/dev/null || true`

## Task

Determine whether the codebase already satisfies the issue's requirements, and either close it or plan implementation.

### Extract requirements

From the issue body pull out: acceptance criteria (sections titled "Acceptance Criteria", "Requirements", "Definition of Done", or bulleted lists); technical requirements; test expectations. If none are explicit, infer from title + description.

### Evaluate against the codebase

Use `Agent` with `subagent_type=Explore` to search for implementations, tests, and any docs referencing the issue. Check multiple likely locations.

Build a requirements checklist with evidence:

| # | Requirement | Status | Evidence |
|---|-------------|--------|----------|
| 1 | … | ✓ / ✗ | `file.cs:42` or "Not found" |

Verdict: **COMPLETE** or **INCOMPLETE**.

### Choose next step (AskUserQuestion)

**If COMPLETE**: close with comment (referencing specific file paths) / review details first / cancel.

**If INCOMPLETE**: create branch + enter plan mode / create branch only / cancel.

### Execute

- Close: `gh issue close <number> --comment "Resolved: <summary with file:line refs>"`
- Branch (git): `git checkout -b feat/issue-<n>-<slug>` — **warn first** if the working tree has uncommitted changes.
- Branch (jj): `jj bookmark create feat/issue-<n>-<slug> -r @` — jj handles in-flight work natively.

Slug: lowercase, hyphens, strip specials, max 50 chars.
