# snowdrop-patientencounters-be

## Layout
- **Solution:** only `src/Snowdrop.PatientEncounters.Api.Tests.sln`; there is no main sln/slnx. Verify merges by building the `functions-preview/*.csproj`, `functions-search/*.csproj` and `api-tests/*.csproj` projects individually.
- **QA.Shared** (ProjectReference): `src/Snowdrop.PatientEncounters.QA.Shared/`:
  - `Fixtures/PatientEncounterFixture.cs`
  - `Assert/PatientEncounterAssert.cs`
  - `Builders/`
  - `Utility/GlobalConstants.cs`
- **Tests:** `src/api-tests/Tests/` (PatientEncounterTests, PatientEncounterSearchTests, PatientEncounterBalanceTests).
- **Utility:** PortfolioHelper, ActivityHelper.

## Quirks
- **`GlobalConstants` is ambiguous.** `Sharp.QA.Core.Utility.GlobalConstants` shadows the repo's own, so polls silently use 5×2 s windows.
  - Fix: `using EncounterGlobalConstants = …` together with `LongRetryAttempts`.
- **`PatientEncounterFixture.Create()`** polls `GetEncounterPreview` until `EncounterNumber.Length > 6`. Ninja needs `LongRetryAttempts` (60 s).
- **`WaitForPlanPolicyCount`** defaults to 10×1 s. Passing `RetryInterval` (20 s) helped.
- **The encounter number endpoint** (`GET …/encounters/{locationId}/{patientId}/{date}/encounternumber`) returns 404 until the encounter is projected.
- **`BeCloseTo` timestamp failures** are projection latency.
- **Not API-observable** (manual): poison/dead-letter paths (`<queue>-poison`, the `dead-letters/{queue}/{id}` blob, the 24 h retry). Dropping malformed messages is intended.
- **Runtimes:** the two main classes (56 tests) take about 49 min, so run them in small batches.
