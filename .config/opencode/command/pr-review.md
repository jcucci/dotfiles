---
description: Quick review of current branch changes vs main
model: anthropic/claude-sonnet-4-5-20250929
---

Review the changes in this branch compared to main.

## Branch Context

**Current branch:**
!`git rev-parse --abbrev-ref HEAD`

**Commits in this branch (not in main):**
!`git log main..HEAD --oneline`

**Files changed:**
!`git diff main...HEAD --stat`

## Detailed Changes

!`git diff main...HEAD`

## Your Task

Analyze the changes and provide a concise review covering:

1. **Summary**: What do these changes accomplish?

2. **Scope**: Is the scope appropriate? Any unrelated changes?

3. **Potential Issues**:
   - Security concerns (secrets, injection, auth)
   - Performance implications (N+1 queries, async patterns)
   - Error handling gaps
   - Missing null checks or validation

4. **Pattern Compliance**:
   - Does it follow existing codebase patterns?
   - Naming conventions followed?
   - Proper async/await usage?

5. **Testing**: Are there tests? Should there be?

6. **Documentation**: Any missing XML docs or README updates?

Provide actionable feedback, not just observations. If everything looks good, say so briefly.
