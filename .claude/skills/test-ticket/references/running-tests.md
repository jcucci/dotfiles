# Running API tests against ninja

## Before running

- **Local runs exercise ninja's deployed code, not your branch.** Before you treat a result as proof, check two things:
  - Is the fix on ninja? `git merge-base --is-ancestor <fix-sha> origin/ninja`.
  - Is it actually deployed? Look at the last **succeeded** `<repo>-ninja` pipeline run:
    ```
    az pipelines runs list --branch ninja --top 5 --organization https://dev.azure.com/sharpfm --project repositories
    ```
    `--status` takes a single value. Or check the image tag: `kubectl get deploy -n <namespace> -o wide`, where the tag is `ninja-<buildId>`.
  - A Helm `--wait` timeout can show as "failed" while the rollout actually finished. Function apps may deploy separately.
  - If the fix isn't deployed, expect new tests to fail. Offer `/merge-envs`, then rerun after the user says ninja has redeployed. A fail-then-pass across the deploy is good evidence.
  - Don't queue, cancel or poll ninja builds unless asked; others test there. Wait for "ninja has the latest".
- Run tests from the **feature branch**. The api-tests solution often doesn't compile on the ninja/gateway branches.
- Confirm the VPN with the user. Run **only** against ninja.

## Command

```bash
S=<scratchpad>; mkdir -p "$S"
cd <repo-root>/src/api-tests && set -a && source "$HOME/.config/zsh/ninja-api-tests.env" && set +a && \
  dotnet build <path to *.Api.Tests.sln> 2>&1 | grep -E ' error |Build succeeded' ; \
  dotnet test --no-build --filter "FullyQualifiedName~<Namespace>.<Class>" \
    --logger "trx;LogFileName=<ticket>-<n>.trx" --results-directory "$S" > "$S/<ticket>-<n>.log" 2>&1
```

- Never print the env file; it holds credentials. `ninjatestsource` also works (it comes from the shell snapshot), but **don't spend calls probing it**. `zsh -ic` prints `zle` noise.
- **Gate on the build.** If the build fails, `--no-build` silently runs the old DLL, and the exit code through a pipe means nothing.
- Always redirect the **full** output to a log file, plus a TRX. Never `| tail`; it has lost failure names more than once and forced reruns of 10-50 minutes.
- Use `run_in_background` for anything over about 2 minutes, then wait for the completion notification. Don't poll, and don't start a second copy.
- `ITestOutputHelper` output shows only with `--logger "console;verbosity=detailed"`.

## Filters and run time

- Always class-qualify: `FullyQualifiedName~<Class>.<Method>`, joining several with `|`. An unqualified method name matches same-named tests in other classes.
- `Category=<Trait>` works. `--filter-trait`, `Name=`, and `DisplayName~<theory args>` don't. Theory cases run as a group.
- Times on ninja:

  | Run | Time |
  |---|---|
  | One test | 1-5 min (mostly fixture setup) |
  | Whole class | 20-54 min |

  **Keep each batch to about 8 minutes or less.** Late failures in long runs are suspect; they're probably caused by login-token expiry. Estimate the time up front and warn when it's over 15 minutes.
- Before debugging a failing new test, run **one baseline**: an existing passing test that uses the same helpers. Then change one variable per run, and ask between runs, since each one costs minutes.

## Reading results

- Parse the TRX (`UnitTestResult` outcome and message) with `python3 -I`, or grep the log:
  ```
  grep -nE '^\s+Failed |\[FAIL\]|Error Message' -A6
  ```
- `grep -nE 'GET |POST |Status Code|Content:'` shows each HTTP call. A run like 404 404 404 404 200, where the 200 lands just after the window closed, means the window was too short. 404s all the way means the thing never arrived.
- `Expectation has property X that the other object does not have` buried in a timeout means a QA.Shared validator has drifted from the contract.
- TRX StdOut repeats earlier tests' output. To map IDs to tests, take each ID's first appearance.
- Logs contain auth cookies (`SharpAuth`, `Cookie`), so grep them out before quoting. To hand the user IDs for Splunk, give patient/org/claim IDs with UTC timestamps (logs are -05:00 local), and use `/ticket-artifacts` for the query and the exported results (saved under `~/projects/sharp/tickets/<TICKET>/`).
- Report per class: passed, failed, inconclusive, not run. Say which passes are **vacuous** ("does not qualify" / "nothing happens" cases, or passes against undeployed code).

## Setup-failure signatures

All tests failing in about 1 ms means the class fixture failed before any test code ran.

| Signature | Meaning | Action |
|---|---|---|
| `SqlException … IP address … not allowed … air-team-sharp-nimbus-sql` | VPN dropped | Ask the user to reconnect; rerun once |
| `ConnectionString property has not been initialized`, `Guid.Parse(null)`, `UriFormatException`, UrlHelper throws | Env vars not loaded | Re-source the env file. Required: `TEST_ENV`, `AZURE_USER_OBJECT_ID`, `AZURE_USER_GROUP_ID`, `VENDOR_USER_ID`, `CDB_KING_SHARP_BE_URI/_KEY`, plus repo-specific ones (see the backend file) |
| `TimeoutException … Verify plan reflects at least 1 policy(ies)` (`PolicyHelper.WaitForPlanPolicyCount`) | **Known ninja bug.** The `snowdrop-policies-search` read-after-write race against Azure AI Search leaves about 20% of plans at count 0 for good, on ninja only | Rerun once; don't root-cause or add retries. Repos that removed this wait retry `AddPortfolio` instead |
| 400 `One or more policies are unassigned` from `POST payer-portfolios/v2/patients/portfolios` | Policy-projection lag (about 1s) | Retry `AddPortfolio` on that exact message. The fix is on develop in most repos; check before re-inventing it |
| nginx HTML `401 Authorization Required` on one route while sibling routes succeed | Ingress auth layer, environmental (e.g. `charge-validation-rules`, Nov 2026) | Report as blocked; don't debug test code or env vars |
| `MissingMethodException … .ctor` in setup | A transitive `*.QA.Shared` was compiled against an older Model than the Runtime project pulls in | Check `obj/project.assets.json`; Sherlock `compare_api_surface`; reference a newer QA.Shared directly; `dotnet restore --no-cache` after a publish |
| 404 on a QA.Shared call | The pinned QA.Shared package's route is stale | Use the newest version compatible with the test project's TFM and xUnit major (`ls ~/.nuget/packages/<pkg>`) |
| `BeCloseTo` timestamp miss, `Expected <x>, Actual: <default>` timeout | Projection latency, or a rule that silently didn't apply | Check the request log and date windows before blaming the code |

Other environment flakes pass on rerun:
- `POST /snowdrop/activities/RenderedActivities` 404
- NRE in `FlurlClientFactory.LogAfterCall`
- ledger-balance timeouts

Note them and move on.

## Debugging discipline

- Treat a **consistent** setup failure as a possible real bug: inspect the fields the poll got back. In-memory test doubles can hide bugs.
- A 200 from a queued action only means the request was accepted. Probe the downstream state.
- When a counter or threshold never trips, first check that each call actually produced its event.
- Time-box cross-service async repros to about 2 failed runs, then offer one of:
  - (a) Splunk queries with IDs, a UTC window, and the **exact log template** from source (placeholders included)
  - (b) a happy-path API test plus unit tests
- Experiments: state the hypothesis and the readout. Back up files to the scratchpad before `TEMP-DIAG` edits, and restore them afterwards.
- Package lookups:
  - `dotnet package search <pkg> --source sharpfm --exact-match --prerelease --format json` works, but the `nuget` CLI gets a 401. If neither works, ask the user for the latest version.
  - `dotnet restore` before searching package contents.
  - Point Sherlock at the built `bin/` DLLs.
- zsh quirks:
  - Quote globs (`--include='*.cs'`).
  - Unquoted `$VAR` holding several flags is not word-split, so write `az` flags inline.
  - Use `"${b}:path"`, not `"$b:path"`.
  - `ls` is aliased, so use `find` for listings.
- The nightly ninja api-tests pipelines are broken, so there is no CI baseline to compare against.
