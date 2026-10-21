---
description: Run static analysis and format checks
model: anthropic/claude-haiku-4-5-20251001
---

Run static analysis checks on the codebase.

## Format Check

!`dotnet format --verify-no-changes --verbosity diagnostic 2>&1 | head -50`

## Your Task

Analyze the output and report:

1. **Format Status**: Are there formatting issues?

2. **Issues Found**: List files with problems and the nature of issues

3. **Fixing**: If issues exist, suggest running:
   ```
   dotnet format
   ```

4. **Additional Checks**: Suggest other analysis if appropriate:
   - `dotnet build -warnaserror` for warnings
   - Security scanning tools if available

Keep it brief and actionable.
