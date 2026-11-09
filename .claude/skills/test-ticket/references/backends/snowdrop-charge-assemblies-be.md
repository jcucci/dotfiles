# snowdrop-charge-assemblies-be

## Layout
- **Solutions:** `src/Snowdrop.ChargeAssemblies.Api.Tests.sln` is **not** part of `src/Snowdrop.ChargeAssemblies.slnx`, so it drifts and often doesn't compile. Build it in Phase 1.
- **Unit tests:** `src/unit-tests` (about 2 s; `Category=` filters work).
- **QA.Shared:** `src/Snowdrop.ChargeAssemblies.QA.Shared/`:
  - `Calls/` (ChargeAssemblies, Rule, Search, Sequence, RemittanceProcessing)
  - `Validators/*ResponseValidator.cs`, `Assertions/ChargeAssemblyAssert.cs`, `Fixtures/ChargeAssemblyFixture.cs`
  - `Utility/GlobalConstants` (`RetryAttempts` 30, `LongRetryAttempts` 60, `ExtraLongRetryAttempts` 180, `EventAllowance` 5 s, interval 2 s)
- **api-tests folders:** `Tests/` (ChargeAssemblyTests, PayerAssemblyTests, `ChargeAssemblyGeneration/{Daily,Weekly}…`, `Search/`, `ChargeAssemblyValidation/`), `DataFixtures/` (`ChargeAssemblyPortfolioFixture`, `SetFixture`), `DataFixtureBuilders/`, `LoginFixtures/`, `Utility/*Helper.cs`.
- **Docs:** `src/api-tests/CLAUDE.md`, `ChargeAssemblyLedgerIntegrationTestingGuide.md`, `FixturePatternImplementationGuide.md`, `llms.txt`, `docs/architecture-*.md`.
- **Retry interval:** `RetryHelper.RetryUntilAsync(..., RetryAttempts)` without an interval defaults to 1000 ms (30 s). The suite norm is to pass `GlobalConstants.RetryInterval`.
- **Routes:** ingress is `/snowdrop/charge-assemblies/`. Search lives under `/search/...` (`parameters`, `parameters/{id}/summary`, `assemblies`).

## Data setup
- **A charge with a balance needs a charge master, contract and fee schedule.** Copy the block from `DailyGenerationTests.RebalanceWhileCAInOpenStatus` or `WeeklyGenerationDateQualificationTests`.
  - Without it, `LedgerHelper.VerifyChargeIsInLedger` 404s for 2 min.
  - The assembly also closes with no active payer assembly and never gets a `CurrentInvoice`.
- **Back-dated charge assembly:** set `DateOfService` on the **activity**, then build the charge from it. `CreateActivityWithPatientAndPolicyPortfolio` otherwise pins today.
- **CurrentInvoice recipe:**
  1. Give each assembly its own patient, portfolio and company, plus financial setup.
  2. Create the charge assembly.
  3. Poll the workspace until `PayerAssemblies` is populated.
  4. Call `Snowdrop.Invoices.QA.Shared` `ChargeAssemblyCalls.CreateClaimChargeAssembly(ClaimType)`.
  5. Poll the search until `currentInvoice` is not null.
- **ClaimType to InvoiceType:**

  | ClaimType | InvoiceType |
  |---|---|
  | Cms1500 | Professional Paper |
  | Ub04 | Institutional Paper |
  | ChangeHealthcareProfessional | Professional Electronic |
  | ChangeHealthcareInstitutional | Institutional Electronic |
  | Crossover | (400) |
- **CPID:** comes from RTE SQL (`PlanToRtePayerMapping` takes precedence over `PayerToRtePayerMapping`). Seed it with `Snowdrop.Payers.QA.Shared` `RteSettingsDataHelper`/`RteSettingsCalls`:
  1. GET `/payers/rte-settings` and pick one with a CPID.
  2. POST `/payers/rte-settings/plan` before creating the charge assembly.

  The expected value is the picked CPID. Guarantor and SNF assemblies have a null CPID.
- **Overlapping portfolios** fail with "date range … overlaps". End the first one with `PortfolioCalls.UpdateEffectiveness`. Move a plan to another payer with `PlanFixture.ReassignPlan`.
- **The workspace always includes a guarantor payer assembly with `Payer == null`.** Select the insurance one by payer.

## Not API-observable (use unit tests)
- Provisioning (timer/queue, 24h+ delays). Only "stays Building" can be seen. Use `unit-tests/Provisioning/ProvisioningTests.cs`.
- Charges inside an assembly are locked (`PUT /activities/Charges/{id}/payer` returns 400 "The charge is locked").
- Rebalance is async through the ledger, which refuses most scenarios, so the inactive-payer-assembly state can't be reached. Use `ChargeAssemblyEventWriterTests`, `StatusCalculatorTests`.
- Claim requests: they need a delayed `ChargeSummaryBalancesCalculated`, happen only for auto-generated assemblies, and are visible only in Invoices.
- Projector rebuild-skip: check Splunk for "Charge Assembly Projection rebuild skipped".
- `ChargeAssemblyEventWriter.PublishPrimaryClaimRequestAsync` already dedupes.
- A manual `RefreshStatuses` call makes a reliable smoke test.

## Quirks and known issues
- Ambiguous types:
  - `ChargeResponse` (Ledger vs Activities)
  - `SetQualifier` (Catalogs vs charge assemblies)
  - `ReassignPayerRequest`

  Use `using X = …` aliases.
- xUnit v2/v3 mix:
  - Errors: CS0104 `ITestOutputHelper`, CS0433 `Assert`.
  - Fix: drop `using Xunit.Abstractions;`, add `xunit.assert` 2.7.0 with `ExcludeAssets="compile"`.
- A new positional record parameter breaks every `new XResponse(...)` expectation (20 sites for `Cpid`).
- `ForAssemblyNumber` uppercases its input, so it never matches mixed-case generated numbers. Scope searches by the test's company.
- Unit tests:
  - Adding a search record field means updating `unit-tests/Fixtures/SearchFixture.cs` (positional).
  - `SearchQueryBuilderTests` expected SQL keeps trailing spaces.
  - `unit-tests/Data/InMemoryCache.cs` never returns a hit, which can hide cache bugs.
- Payer IDs:
  - Account `PayerId` comes from the per-org `PayerMappingsProjection` (the `payers/mappings` projector).
  - If that projection lags, the account has no PayerId; `RefreshAccounts` recalculates it.
- Tests known to be stale on ninja (Nov 2026):
  - `VerifyPayerAssemblyRemittanceResponse`
  - `VerifyRemittanceWithAdjustment_ReflectsInPayerAssembly`
  - `UpdateRemittanceDetails_SamePayerAssemblyId_Returns400`
  - `RemittanceReverseClaimPaymentRemoved_EobRestored…`
- Runtimes: 3 ChargeAssemblyTests take about 5 min; 9 PayerAssemblyTests about 21 min; all 16 about 54 min.
