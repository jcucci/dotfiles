# snowdrop-charge-interventions-be

## Layout
- **Solutions:** `src/Snowdrop.ChargeInterventions.slnx` and `src/Snowdrop.ChargeInterventions.Api.Tests.sln`. Build both after merging into an env branch.
- **Docs:** `src/api-tests/CLAUDE.md`.

## Regression set for charge assemblies and interventions
- **Filter:** `FullyQualifiedName~ChargeAssemblyTests|FullyQualifiedName~MissingChargeAssemblyTests`. The 5 tests take 10-16 min.
- **Coverage:**
  - `GeneratedChargeAssembly` covers the PatientView projector.
  - The intervention and `AutomaticInterventions/MissingChargeAssemblyTests` tests cover the Validation projector.
  - The class `InitializeAsync` archives all remittance processing rules.
- **Deploy/infra tickets:** your default is to run this set as the regression check. kubectl against ninja is available to confirm deployments.

## Package drift
- **Model version mismatch:**
  - The Runtime project's `Snowdrop.Guarantors.Events` 2.0.0 pulls `Guarantors.Model` 2.0.0 into api-tests.
  - That breaks the transitive `Snowdrop.Guarantors.QA.Shared` 22.x at runtime with a `MissingMethodException` on the `GuarantorProjection` ctor.
  - Fix: a direct `PackageReference Snowdrop.Guarantors.QA.Shared 26.7.0` in the api-tests csproj.
- **General rule:** when a Runtime package bump changes a Model major version, check `obj/project.assets.json` for both versions.
- **Unexplained flake:** a one-off ledger-balance mismatch (expected 1946.67, got 0.00) never recurred. Treat it as ninja data flake.
