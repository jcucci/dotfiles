# snowdrop-waypoints-be

## Layout
- **Solutions:** `src/Snowdrop.Waypoints.Api.Tests.sln` is separate from `src/Snowdrop.Waypoints.slnx`.
- **Tests:**
  - `Tests/`: ActivityTests, ActivityErrorTests, ChargeTests, ChargeErrorTests, ReviewTests, BehaviorCategoryTests, NetTypeTests, `Search/{Activity,Charge,Grid,Historical,SearchCount,Summary}SearchTests.cs`, ReleasedHistoryTests
  - `Utility/`: ReviewItemHelper, PortfolioHelper, QualifierHelper, SetQualifierHelper…
- **QA.Shared:** `src/Snowdrop.Waypoints.QA.Shared/`. `Contracts/` holds the client DTOs, e.g. `ReleaseResult`; extend them when responses gain fields. `Assertions/SearchAssert`. `Utility/GlobalConstants` (`RetryAttempts` 10, `LongRetryAttempts` 30, `EventAllowance` 10 s).
- **`src/api-tests/CLAUDE.md`:**
  - Waypoints is the review/routing layer only; charge and ledger tests live in activities-be.
  - Constants: `RuleCreationAllowance` (30 s) before creating data that should qualify, `FalsePositiveDelay` (10 s) only for proving negatives, `LongRetryAttempts` after rule creation/release/rebuild.
- **Traits:** `[Trait("Category","<ClassName>")]`.
- **Unit tests:** about 1,370 on develop, about 634 on env branches (expected).

## Search
- **Grid search and card-view/summary search are different code paths.**
  - Grid uses `ManualReviewSearchAsync`, per item.
  - Summary uses `EncounterQueryBuilder`.

  Pick the test file for the path that changed.
- **Exclusionary filters:** `NOT` applies only when *all* qualifiers are exclusionary, and the filter covers the whole encounter. Read the query before writing negative tests.
- **Settle first:** before asserting exclusion, call `SearchAssert.AssertPatientIncludedInSummarySearchResults`, which polls until the in-review counts are as expected.
- **Qualifiers:** `QualifierHelper.GetElementQualifier(AttributeType.X, id)`; `ElementQualifierRequest(elementId, exclusionary)`.
- **Charge in review:** reuse `ChargeSearchTestsFixture` (create the charge, update its properties, poll `GetItemProgress`).
- **`SearchReviewItemsRequest`** requires `dateOfServiceFrom/To`, and `EncounterLabel` requires `activityCodes`. These broke 67 call sites in the past.
- **Compile quirk:** `GlobalConstants` is ambiguous with the Activities namespace. Keep the Activities import.

## Release
- **Templates:** `ActivityTests.Release` / `ChargeTests.Release`.
  - Call `_waypointActivitiesCalls.Release(new ReleaseItemRequest(itemId, ruleId))`.
  - To release one of two items: `_waypointReviewCalls.Release(new ReleaseItemsRequest([id], DateTimeOffset.UtcNow))`.
- **`validatedEventNotFound` (CanRetry)** comes back while revalidation is in flight. Poll for it.
- **Repeated releases need `ReleaseType.RetryAll`**, in both `WithRuleAction` and `ManualReviewBehaviorConfiguration`.
  - `GotoNext` releases only once; later calls return `Success()` and publish nothing.
- **`SetUpActivityFixture` makes a new activity code each time.** A second fixture won't match the first rule's qualifier.
- **Rate limit (UF-8287):**
  - Response: HTTP 200 with `succeeded=false` and `rateLimitExpiration`, **not 429**.
  - Env vars: `SNOWDROP_WAYPOINTS_MAX_RELEASES_PER_MINUTE` (5 on ninja) and `…_RELEASE_RATE_LIMIT_LOCK_DURATION_MINUTES`.
  - Blob: `Organizations/{org}/ReleaseOperation/{itemId}`.
  - Use a fresh item per test.
- **Release history:** `GET .../review/released-history` returns per-workflow daily counts only. Per-item `ReleaseHistoryItems` (100 cap) is unit-test only (`src/unit-tests/Contracts/ReviewItemTests.cs`).

## Not API-observable
- Card-view filter reincarnator backfill, and the legacy-document fallback.
- Safety-net repair. Unit tests compare through the `ProjectionDocumentComparer` ignore list; develop merges often break these.
- `IStorageQueue.InitializeQueueAsync`.

## Known issues (Nov 2026)
- **nginx 401 on `POST /snowdrop/activities/charge-validation-rules`** in nearly every run, which blocks charge release and charge search tests on ninja. Also, the `ReviewTests.ReleaseCharge` fixture throws an NRE in `ChargeHelper.SetUpGeneratedChargeFixtureFromActivityFixture`.
- The policy-count flake hits `CreateMedicalInsurancePortfolio` in any class.
- **Runtimes:** a single search test takes 2-5 min; ReleasedHistoryTests (6 tests) about 18-20 min.
- **Stray files:** develop carries root support-data dumps (`activity-events.json`, `encounter-summary.json`, `patient-activity.json`). Deleting them is fine but shows up in PRs.
