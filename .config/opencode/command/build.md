---
description: Build the .NET solution and analyze errors
model: anthropic/claude-haiku-4-5-20251001
---

Build the .NET solution and analyze any errors.

## Build Output

!`dotnet build 2>&1`

## Your Task

Analyze the build output and provide:

1. **Status**: Did the build succeed or fail?

2. **If successful**: Report success briefly with any warnings worth noting

3. **If failed**: For each error:
   - File and line number
   - Error code and message
   - Brief suggestion for fixing

4. **Warnings**: Summarize any significant warnings (ignore minor ones)

Keep the response concise and actionable.
