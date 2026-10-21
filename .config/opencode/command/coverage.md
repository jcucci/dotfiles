---
description: Run tests with code coverage report
model: anthropic/claude-haiku-4-5-20251001
---

Run unit tests with code coverage.

## Coverage Output

!`dotnet test --filter:Category!=Integration --collect:"XPlat Code Coverage" 2>&1`

## Your Task

Analyze the coverage output and provide:

1. **Test Results**: Passed, failed, skipped

2. **Coverage Summary**: If coverage data available:
   - Overall line coverage percentage
   - Notable gaps in coverage

3. **Coverage File Location**: Where the coverage report was generated

4. **Recommendations**: Areas that might need more test coverage

Note: Full coverage analysis requires the generated coverage files. This provides a quick summary from the test output.
