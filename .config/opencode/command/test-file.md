---
description: Run tests for a specific file or class
model: anthropic/claude-haiku-4-5-20251001
---

Run tests matching the specified filter.

## Test Output

!`dotnet test --filter "FullyQualifiedName~$ARGUMENTS" --no-build 2>&1 || dotnet test --filter "FullyQualifiedName~$ARGUMENTS" 2>&1`

## Your Task

Analyze the test output for tests matching "$ARGUMENTS":

1. **Tests found**: How many tests matched the filter?

2. **Results**: Passed, failed, skipped counts

3. **Failures**: Detail any failures with:
   - Test name
   - Error message
   - Stack trace highlights
   - Suggested fix

4. **No matches?**: If no tests ran, suggest checking the filter or listing available tests

Keep it focused on the specific tests requested.
