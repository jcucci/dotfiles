# snowdrop-catalogs-be

## Layout
- Tests: `src/api-tests` (`Tests/<Catalog>/`, `Assertions/`, `Fixtures/{DataFixtures,LoginFixtures}`, `Utility/`).
- Call wrappers: `src/Snowdrop.Catalogs.QA.Shared/Calls/<Area>/` (`<X>CatalogCalls`, `Admin<X>Calls`).
- Solutions: `src/Snowdrop.Catalogs.Api.Tests.sln`; the main solution is `src/Snowdrop.Catalogs.slnx`.
- Stack: xUnit v3, net10.0. Read `src/api-tests/CLAUDE.md`, which says never to build expected values from the API under test.

## Fixture template (`Tests/FactoryCodeSystems/FactoryCodeSystemsTests.cs`)
- Wiring: `IClassFixture<XFixture>`, where `XFixture : IAsyncLifetime` takes a `LoginDataFixture`.
- `InitializeAsync`:
  - `CreateOrgAndConfigurePermissions()`, then set the `"Org-Id-Req"` header to the org id.
  - Token: `ApiLogin.GetToken(UrlHelper.StarRoadBaseUrl, LoginDataFixture.SnowdropLogin)`, then `new ApiHelpers(UrlHelper.SnowdropBaseUrl, token)`.
  - Vendor calls use `VendorToken`.
- Error handling: wrap init in try/catch that calls `DisposeAsync()` and rethrows.
- Teardown: `NimbusDataHelper.DeleteOrganization(orgId)`.
- Polling: `RetryHelper.RetryUntilAsync(..., GlobalConstants.RetryAttempts).ConfirmSuccessAndEvaluateAsync()`.
- A 204 arrives as a **failure** Result: `response.Successful.Should().BeFalse(); response.Failure.StatusCode.Should().Be(NoContent)`.

## Factory code systems
- Enable:
  1. `VendorCalls.GetCodeSystems()`
  2. `SetEnableFlags(FactoryCodeSystemStatus(id, enabled: true))`
  3. Poll `AdminFactoryCodeSystemsCalls.GetAllFactoryValues(catalogId)` until it's non-empty (an async sync into the new org).
- Expected values come from `AdminFactoryCodeSystemsDBCalls.GetCodes(codeSystemId)`, never from the endpoint under test.
- Code systems on ninja: Revenue Code, Reason Code, ANSI, Group Code.
  - Many catalogs (TransferReason, ContractualAdjustmentReason, PlanType…) are **custom-code catalogs** under Reason Code/ANSI (`FactoryCodeSystems/DB/CustomCodeCatalogs`). Pick a code system that is not custom for the catalog.
  - Catalog ids live in `SystemCatalogMappings`.
- Admin endpoints (`services-administration/.../FactoryCodeSystemsController.cs`):
  - `…/Values/{catalogId}/element/find` and `FactoryValues/{catalogId}/element/find` return 200.
  - `value/{catalogId}/element/find` returns 204 when not found or when the key is null.
  - Keys are case-insensitive. Agreed contract: a null key on a search returns OK/empty, not 400.

## Quirks
- `ShowValues` deserializes only `CodeSystemId` (its ctor param names don't match its properties). Assert on count/CodeSystemId.
- Check QA.Shared routes against the controller. `GetValues` and `GetFactoryValues` were once bound to each other's routes.
- Contract request DTOs need a parameterless ctor. Don't rename public ctor params, since the package is consumed externally.
- `findbyids` is the endpoint other services call (sets UF-11492 failed there with a 400).
