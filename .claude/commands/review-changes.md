---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(jj status:*), Bash(jj diff:*), Bash(jj root:*)
description: Review uncommitted code changes and provide feedback
---

## Context

- VCS type: !`jj root >/dev/null 2>&1 && echo jj || echo git`

**If jj:**
- Current status: !`jj status 2>/dev/null || true`
- Current diff: !`jj diff 2>/dev/null || true`

**If git:**
- Current git status: !`git status 2>/dev/null || true`
- Current git diff: !`git diff HEAD 2>/dev/null || true`

## Task

Review the diff shown in Context. Produce a severity-ranked table of issues. Focus on bugs, security, and performance; skip style nits unless they break project conventions.

**Summary**: one-line overview of what changed.

**Issues Found**:

| Severity | File | Line | Issue | Suggestion |
|----------|------|------|-------|------------|
| HIGH | path/file.cs | 42 | ... | ... |

**Severity guide**:
- **HIGH** — bugs, security issues, breaking changes
- **MEDIUM** — performance issues, unhandled edge cases
- **LOW** — style issues (only if they violate project conventions)

For deeper pre-merge review, use `/ultrareview` instead.
