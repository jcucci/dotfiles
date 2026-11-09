# snowdrop-invoices-be

## Layout
- **api-tests:** `src/Snowdrop.Invoices.Api.Tests.sln`, laid out as `src/api-tests/{Tests,Fixtures/DataFixtures,Fixtures/LoginFixtures,Utility}`.
- **QA.Shared:** `src/Snowdrop.Invoices.QA.Shared/{Calls,Builders,Fixtures,BehaviorConfigurations}`. New wrappers go in `Calls/ClaimCalls.cs`.
- **Hosts:** build individually (`src/services`, `src/external-ledger-projector`, `src/functions-validator`, `src/qualification-safety-bot`).
- **Unit tests:** `dotnet test src/unit-tests` runs about 1.3k tests in about 3 s.
- **Docs:** `src/api-tests/CLAUDE.md` (includes `RuleCreationDelay` 60 s), `UB04_TESTING_GUIDE.md`, `RULE_TEST_COVERAGE_ANALYSIS_GUIDE.md`, `AGENTS.md`, `llms.txt`, `docs/context/*.md`.
- **Env var:** `SNOWDROP_INVOICES_BLOB_CONNECTION_STRING` is required and must be a **SAS URL** (`https://acct.blob.core.windows.net/?sv=...`). Anything else gives `UriFormatException` and every test fails in about 1 ms.
- **New test class:** add a `[CollectionDefinition]` in `LoginDataFixture.cs`, a name in `LoginDataFixtureNames.cs`, and `[Trait("Category","<ClassName>")]`.

## Claim output endpoints (the main test surface)
- `GET claims/{id}/change-healthcare/professional/edi` (and `institutional`) returns `ClaimEdiResponse`. It uses the same `EdiBuilder` as submission, which is in-memory, so this endpoint is the only place to observe it.
- `POST claims/change-healthcare/{type}/edi/build` is **stateless**: fetch the claim's `…/institutional/request` (poll; it 404s at first), change it, build, then assert on segments.
  - Segments to check: `SV1*` element 09, `SV2*`, `REF*F8*`, `REF*T4*Y`, `REF*G1`, `REF*9F`, `REF*2U`.
  - 2330B REF comes from `OtherIdentifier`.
  - Add `Assert.NotEmpty(segments)`.
- `GET claim/{id}/ub04` and `/cms1500` return `ClaimDetails.Properties` (`ClaimCalls.GetUb04Details`, `GetCms1500Details`).
- **UB-04 trap:** once `PDFAttachmentId` is set, the properties freeze. Wait for the ledger projections first (`InvoicesBlobStorageHelper.WaitForChargeAdjustmentProjectionAsync`).
- UB-04 FL76 comes from the most common charge `BillingProviderId`.
- **Building guard:**
  - Non-crossover claims are created as `Building`.
  - `PUT …/service-lines` and `claim-information` return 400 while the claim is `Building`.
  - `POST /claims/{id}/Provision` (`ClaimFixture.Provision()`) moves it on.
- `ClaimFixture.Correct` polls CMS-1500, which 404s for UB-04. `CanCorrect` needs status Sent or later.
- `RequestedICN` is set only through `POST charge-assemblies/claims` with `PreviousClaimId` and `ICN`, not through `/claims/correct`.

## Data setup
- Default claim: `ClaimHelper.CreateDefaultClaim(..., ClaimType.X, ...)`. Optional `claimBillingProviderId`; `ChargeHelper.CreateChargeFromActivityFixture` takes `billingProviderId`.
- Ledger-posted charge: `ChargeHelper.CreateLedgerPostedChargeFromActivityFixture`.
  - Needs company/division/facility, a charge master with a fee, a payer contract, and a fee schedule.
  - Create the charge **Provisional**, then update it to **Ready**. Creating it Posted locks it; creating it Ready emits nothing.
  - Adjust with `LedgerChargesCalls.AdjustCharge`.
  - The ledger stores adjustments as negative amounts. A 500 with an empty body means the charge isn't in the ledger.
- Secondary claims:
  - `SecondaryClaimHelper.CreateSecondaryClaimAsync(Date? primaryCheckDate)`.
  - Or `PortfolioHelper.CreateInsurancePayerPortfolioFixtureWithSecondaryPolicyForPatient` plus `AccountsReceivableCalls.CreateClaim`.
  - `SecondaryClaimGenerationTests` is mostly commented out; don't copy it.
- Adjudication date is the `CheckDate` of the prior `PayerAssemblyRecord`.
- Crossover: create a charge assembly, then a primary claim, then a crossover with `PrimaryClaimId`.

## Rules (claim validation)
- **Date qualification compares the rule window with `Claim.DateRangeEnd`, not DOS.**
  - `CreateDefaultClaim` sets that end to Today+5.
  - Build tables as offsets from `_chargeFixture.DateRangeEnd`: `(+1,+2,F) (0,+2,T) (-1,+2,T) (-2,-1,F) (-5,-1,F)`.
  - Tables based on `Date.TodayUtc` are wrong.
- **A skipped rule fails silently.** You get only a timeout (`Expected <code>, Actual: UN`), logged at Debug "Rule is not applicable".
- **Recipe:** follow `ClaimValidationManualReviewTests` / `ClaimValidationSnoozeTests`.
  - Give the class its own collection.
  - The class fixture creates a sequence and a rule, waits `RuleCreationDelay`, and archives in `DisposeAsync`.
  - `SetClaimQualifiesForManualReview` / `ReleaseFromManualReview` advance to the next rule.
- **Duplicate suites:** `ClaimValidationUnitAssignmentTests.cs` and `UnitAssignment/*.cs` both exist. Update both.
- **Prequalification diagnostics:**
  - Function `PreQualification` (`src/functions-validator`), queue `invoice-prequalification` (and `-poison`).
  - Info logs to look for: "Executing {BehaviorCategory} for rule" and `Factory.cs` "Claim has charges qualified…".
  - Log level comes from Key Vault `snowdrop-invoices-be-loglevel`.

## Event streams
- `api-tests/Utility/InvoicesHelper/InvoicesEventHelper` (odd namespace `Snowdrop.ChargeInterventions.Api.Tests.Utility.InvoicesHelper`) reads `snowdrop-invoices-events` via `CDB_KING_SHARP_BE_URI/_KEY`.
- Claim stream: `EventStreamIdentifier.Create(…, Claim, claimId)`. Helpers include `GetClaimSnoozeUpdatedEvent` and `GetMarginEventsAsync`.
- `SourceMetadata.UserId` carries the user.
- Use it for delayed effects (assert that `ClaimSnoozeUpdated.SnoozeEndTime == checkDate + X`) and for "no second event" checks.

## Not API-observable
- Claim submission to Zenith/CHC. Unit-test it with real `EdiSubmitter` subclasses over a mocked `IZenithSwitchService`.
- Ledger/remittance-feed handlers (`ChargeTransactionsEventHandler`).
- Concurrency fixes: at most a probabilistic `Task.WhenAll` guard that asserts every outcome.

## Quirks and known issues
- The api-tests don't compile on ninja/gateway: `ClaimVersionSummary` was removed there by `f5e56a33`. Run from the feature branch.
- `projector-workspaces` doesn't compile and isn't in any solution. Ignore it.
- Margins routes are `margins/cms1500` and `margins/ub04`. `UsersController` no longer has margin routes; repoint stale `UserTests`.
- Stale test: `CannotCreateChargeAssemblyClaimWithVoidedCharge_117039` (the message is now "...to a non voided claim").
- Package drift:
  - Newer Catalogs.QA.Shared drops `NationalDrugCodeDataHelper` (26.1.0 also drops `StatesCatalogCalls`).
  - PayerPortfolios.v2.QA.Shared 25.x drops `PortfolioType`.
  - Policies.QA.Shared 26.x is net10-only.
- Pipelines: deploy is `snowdrop-invoices-be-ninja` (id 1550); api-tests `snowdrop-invoices-api-tests-ninja` (966) is broken.
- Runtimes: one test takes about 1-2.5 min; 7 tests about 8-12 min; the full `ClaimValidationUnitAssignmentTests` about 33 min.
