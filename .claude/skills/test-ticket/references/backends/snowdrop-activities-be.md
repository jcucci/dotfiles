# snowdrop-activities-be

## Layout
- **Tests:** `src/api-tests` contains:
  - `Tests/{InitialValidation,ActivityValidation,ChargeGeneration,ChargeValidation/{LinkAuthorization,AggregateCharge},DataIntegrity,PayerValidation}`
  - plus `ChargeTests`, `LedgerChargeTests`, `DraftActivityTests`
- **Fixtures:** `Fixtures/{DataFixtures,LoginFixtures,RulesSetup}`.
- **Utility:** `Utility/{DataIntegrity/*, PortfolioHelper, PolicyHelper, CatalogHelper, WaypointsHelper, ProviderHelper}`.
- **Shared:** `src/Snowdrop.Activities.QA.Shared/{Builders,Calls,Fixtures,BehaviorConfigurations,Contracts,Utility/GlobalConstants.cs}`.
- **Solutions:** `src/Snowdrop.Activities.Api.Tests.sln` and the main `src/Snowdrop.Activities.slnx`.
- **Docs:**
  - `src/api-tests/CLAUDE.md` (long), `api-tests-framework-guide.md`, `DATA_INTEGRITY_TEST_PLAN.md`.
  - `docs/context/monitoring-logging.md`: log IDs only, never ICD codes or DOS.
- **Unit tests:** about 2,450 tests in about 4 s (`dotnet test src/unit-tests --filter:Category!=Integration`). Reverting the fix and watching them fail is a cheap way to prove a test.
- **Request DTOs for internal endpoints** go in `QA.Shared/Contracts/`, because api-tests doesn't reference `validation`.

## Wiring and the activity flow
- Class attributes: `[Collection(LoginFixtureNames.ChargeTestsCollection)]` plus `[Trait("Category","…")]`.
- Constructor takes `LoginDataFixture` and `ITestOutputHelper`; the class also uses `SequenceCollectionFixture` and `SafetyNetHarness _safetyNet`.
- Rule-driven tests use `_scenarios.<Scenario>.CreateActivityAsync(_activityFixtureBuilder)`.
- Build an activity: `ActivityFixtureBuilder.WithPatient(..).WithPortfolio(..).WithReferringProvider(..).BuildAndCreate()`.
- Then assert in **pipeline order**:
  1. `AssertActivityPassedInitialValidation`
  2. `AssertActivityFailed/PassedPayerValidation`
  3. `AssertActivityArchived`
  4. finally `_safetyNet.WaitForActivityToSettleAsync(id)` and `AssertActivityRestsAsync(id, LeftAlone|Closed)`

  **Skipping the payer-validation assertion makes the final check flaky** (`Escalated`).
- For charges, finish with `_safetyNet.AssertChargeRestsAsync(chargeId, SafetyNetCheckOutcomes.LeftAlone)`.

## Data setup
- Patient and portfolio:
  - `PatientFixture.CreatePatient(_loginDataFixture, _testOutputHelper)`
  - `PortfolioHelper.CreateMedicalInsurancePortfolio(..., patientId)`
- Catalog set: `SetFixture.CreateCatalogSet(LoginDataFixture, new NullTestOutputHelper(), CatalogType.ChargeCodes, GlobalConstants.LongRetryAttempts)`. Its namespace is `Snowdrop.Activities.Api.Tests.Fixtures`.
- Codes: `CatalogHelper.CreateActivityCode` and `CreateModifier`.
- Rules:
  - Build with `RuleFixtureBuilder.WithBehaviorCategory(..).WithBehaviorConfiguration(JObject.FromObject(new XBehaviorConfiguration(...)))`.
  - `QA.Shared/BehaviorConfigurations/<Area>/` mirrors `src/rulebehaviors`. Add a missing config class there.
- Held charge you can edit:
  - Follow the `ChargeTests.EditCharge_NotLocked` pattern, then `chargeFixture.EditCharge(EditChargeRequest)`.
  - Change `billingUnits` to force a real event to wait on.
- Ledger correction:
  - `Snowdrop.Ledger.Charges.QA.Shared` `LedgerChargesCalls.CorrectCharge`.
  - Wait until the activities charge is Posted with financials **before** taking a baseline.
- Re-trigger charge generation: `ChargeGenerationCalls` posts a `ValidationRequest {ChargeGenerationId, SkipGlobalDuplicateDetection}` to `charge-generation/validate`.
- Import path:
  - `ActivityCreator` runs only for `POST /snowdrop/activities/import/activity(ies)`. `CreateRenderedActivity` bypasses it.
  - Use `ImportCalls.ImportActivity`, then read back with `GET RenderedActivity`.
  - The rendered-activity API **normalizes activity-code casing**. Only Draft Activity release (`DraftActivityTests`, `WithActivityCode`) keeps raw input.

## Event streams
- `Utility/DataIntegrity/SafetyNetStreamReader`, created with `new SafetyNetStreamReader(_loginDataFixture)` or taken from `_safetyNet.Streams`.
- Methods:
  - `Snapshot{Charge,Activity}StreamAsync` returns a `StreamSnapshot` (`EventCount`, `CountsByType`, `DescribeChangesSince`).
  - `Read{Charge,Activity}StreamWhenAsync` and `ReadRaw*`.
- Use these for "event (not) published" tests: snapshot, no-op action, real change, wait for its event, then assert the count grew by exactly 1.

## Not API-observable (use unit tests)
- The null-activity path in `InitialValidator`, reached through the `ActivityInitialValidation` queue function. Unit test: `src/unit-tests/Validation/InitialValidatorTests.cs` with `InMemoryEventPublisher`.
- Log-only changes. Queue behaviour: `Data/InMemoryStorageQueue`, `Fixtures/RenderedActivityFixture`.

## Quirks and known issues
- Aggregate-charge rule: if a matched charge is already Posted, the others go to manual review. That makes concurrent-activity tests race: detect `InManualReview` and retry on a new patient.
- `LinkAuthorization*Tests` share one collection, and their fixtures pass a null `ITestOutputHelper`, so you get no plan output on failure. The policy-count flake hits these hardest.
- Runtimes: one test takes about 2-5 min; the 20-test LinkAuthorization filter takes about 38 min; `Category=ArchiveTests` (24 tests) takes about 38 min.
- xUnit v3:
  - Wrap helpers for unmigrated shared packages with `.AsV2()` (`Fixtures/V2TestOutputHelper.cs`).
  - `Task.Delay(GlobalConstants.*)` raises xUnit1051 everywhere. Match the existing file; don't sweep.
- Event-helper env vars: older helpers (`ActivityEventHelper`) read `CDB_KING_SHARP_BE_URI/_KEY`. `SafetyNetStreamReader` reads `LoginDataFixture.EventDbUri/EventDbKey`.
