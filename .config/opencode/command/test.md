---
description: Run unit tests and summarize results
model: anthropic/claude-haiku-4-5-20251001
---

Run unit tests (excluding integration tests) and summarize results.

## Test Output

!`dotnet test --filter:Category!=Integration --no-build 2>&1 || dotnet test --filter:Category!=Integration 2>&1`

## Your Task

Analyze the test output and provide:

1. **Summary**: Total passed, failed, skipped

2. **If all passed**: Brief success message

3. **If failures**: For each failing test:
   - Test name
   - Failure reason
   - Suggested fix if obvious

4. **Performance**: Note any unusually slow tests (>5s)

Keep it concise. Focus on failures and actionable items.
