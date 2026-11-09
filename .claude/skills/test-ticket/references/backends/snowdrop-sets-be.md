# snowdrop-sets-be

## Layout
- **Tests:** CatalogSetTests, SetsCacheTests, SetsCompanyTests, SetsFactoryTests, SetsPayerTests, SetsTypeTests, SetsValueMembershipTests.
- **Fixtures:** LoginDataFixture, SetFixture, SetValueMembershipFixture.
- **Utility:** SetHelper, ImportSetHelper, RandomDataHelper.
- **QA.Shared** (in repo): `src/Snowdrop.Sets.QA.Shared/`.
  - `Calls/`: SetsCalls, SetsCacheCalls, SetsFactoryCalls.
  - **`DbCalls/AzSqlFactoryDbCalls`** queries the factory SQL DB directly (`SNOWDROP_CATALOGS_AZ_FACTORY_DB_CONN_STR`).
- **Solutions:** `src/Snowdrop.Sets.Api.Tests.sln` is separate from `src/Snowdrop.Sets.slnx`.
- **Verification endpoints:** `GET /snowdrop/sets/sets/{setId}` and `POST /snowdrop/catalogs/{catalogId}/findbyids`.

## Factory sets: no ops resets or syncs in tests
- **`FactorySetSync` is global, not per org.** It runs hourly from `LastSyncTimeDocument`.
  - The factory cache key (`SetKey.CreateFactoryKey`) isn't org-scoped, so a new org per run **does not** isolate factory data.
  - Consumers: `SetsCacheRefreshHandler` (Redis) and `DisplaySetHandler`.
- **Test through the deterministic DB seam instead:** `AzSqlFactoryDbCalls` against the factory functions and views. The helper copies product SQL, so it can drift; note that in the PR.
  - The SQL lives in `~/projects/sharp/super-nimbus-data-be/src/FactorySets.Application/`: `Functions/factorysets.Get{Catalog}ChangesFunction.sql` and `Views/factorysets.{Catalog}SetDetails.sql`.
  - The change functions diff two AS OF snapshots. A start of MinValue returns INSERT rows only.
- **Ninja has 13 orphan `Test*` ActivityType rows.** Prefer "contains" assertions, rename tests to match, and guard loops with `.Should().NotBeEmpty()`.
- **Replay risk for `FactorySetValuesAdded/Removed`:**
  - invoices: appends without de-dup (not idempotent)
  - ledger: replaces
  - activities: enqueues and ignores the values
  - waypoints: idempotent

## Command Center bulk actions (manual)
- **Templates:** `src/runtime/CommandCenterTemplates/`. Populate Set Values is `fe7fed9e-2cc5-4eb4-a882-143d5045593d` (vendor-only, handled by `src/populate-sets-function`).
- **The UI expects xlsx**, downloaded from the UI, with headers `SetType, SetId, ElementType, ElementId`. Leave `ElementType` blank except for Payer/Company sets.
- **Populate Set Values replaces the whole value list** (a full `SetValuesUpdated`). Use a fresh set per upload.
- **`IcdCodeIdentity.TryParse`** (in catalogs `DiagnosisCode.cs`) only splits `Code-IcdCodeType`. Take negative inputs from the unit tests (`T45.1x5D-InvalidType`, a GUID).
