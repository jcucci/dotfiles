---
name: test-ticket
description: Plan and implement API test coverage (or a manual test plan) for a Jira ticket in Testing status, working from the ticket's feature branch in the current Sharp repo. Explicit invocation only.
disable-model-invocation: true
argument-hint: <jira-ticket e.g. UF-12345>
allowed-tools: Read, Glob, Grep, Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git rev-parse:*), Bash(git rev-list:*), Bash(git merge-base:*), Bash(git grep:*), Bash(git cherry:*), Bash(git worktree list:*), Bash(git status:*), Bash(git fetch:*), Bash(ls:*), Bash(find:*), Bash(dotnet build:*)
---

# Test a Jira ticket (developer-owned testing)

Developers own initial API test development for tickets in Testing. Given a ticket, produce a reviewed test plan, implement it, then record it.

Ticket: `$ARGUMENTS`. If empty, use the session's Jira ticket: read `<repo-root>/.claude/settings.local.json` (repo root via `git rev-parse --show-toplevel`) and take `jira.ticket=` from `env.OTEL_RESOURCE_ATTRIBUTES`. If none, derive it from the current branch name (`features/uf-12345` → `UF-12345`). State which ticket you are using and why. If nothing is shaped like `ABC-12345`, ask and stop.

**Supporting files** (read when relevant, not up front):
- `references/running-tests.md`: running against ninja, reading results, failure signatures, known environment bugs. Read before the first test run or when setup fails.
- `references/backends/<repo>.md` (e.g. `snowdrop-invoices-be.md`): layout, data-setup recipes, quirks for that backend. Read in Phase 1 if it exists for the current repo.

## Hard rules

- **Phases 1-3 change nothing.** No file edits, test runs, checkouts or Jira writes until the plan is approved. Read branch content with `git show`/`git diff` against refs. A `dotnet build` of the api-tests solution is allowed (it only writes `bin/obj`).
- Never post to Jira without showing the exact text and getting a go-ahead.
- Ambiguity (several candidate branches, unclear acceptance criteria, multi-repo ticket): ask, don't guess.
- Use absolute paths and `git -C <path>`; a `cd` into another repo leaves the worktree. Check `git branch --show-current` right before building or running; parallel sessions sometimes switch it.
- Edit files with Edit/Write, never `sed -i`/perl/python rewrites (BSD sed breaks them). Never write a file with a heredoc and build in the same Bash call.

## Phase 1: Gather context

1. **Ticket**: Atlassian MCP (load via ToolSearch). Get the cloudId from `getAccessibleAtlassianResources` (or use `sharpfm.atlassian.net`); don't guess URLs. Capture summary, description, acceptance criteria, comments, linked issues. Linked "(QA-Auto)" clone tickets: mention them, but don't plan work for them. QA work lives on this feature branch.
2. **Repo**: confirm the cwd is under `~/projects/sharp`, note `git worktree list`, and read the repo docs that exist: `CLAUDE.md`, `src/api-tests/CLAUDE.md`, `AGENTS.md`/`llms.txt`, any api-test guide `.md` beside it, and `references/backends/<repo>.md`.
3. **Branch**: `git fetch`, then `git branch -a | grep -i '<ticket-number>'`. Names vary (`features/uf-123`, `feature/uf-123` typo, `features/UF-123-desc`, legacy `SHRP-…`). If one candidate has 0 commits ahead of develop, say so and prefer the other.
4. **Where the fix actually is**: this has gone wrong repeatedly, so check it explicitly:
   - local vs remote: `git rev-list --left-right --count <branch>...origin/<branch>` (stale or diverged local branches are common)
   - is the fix on develop / ninja / gateway: `git branch -r --contains <fix-sha>` and `git grep '<distinctive line>' origin/develop -- src`. "Merged" sometimes means merged to gateway/ninja only, or later lost.
   - behind develop: `git rev-list --count <branch>..origin/develop`. If far behind, offer `/merge-develop` before testing.
   - Diff against **`origin/<default>`** (`git diff origin/develop...<branch>`), never stale local develop.
5. **Feature work**: identify changed endpoints, contracts, handlers, rules, validation, config/feature flags, background work. For each changed field, **trace where it is set**: the obvious endpoint may never reach the changed code.
6. **Existing tests**: read `src/api-tests` (`Tests/`, `Fixtures/`, `Utility/`) and `*.QA.Shared`, including the sibling test file for **every entity type** involved before judging anything "heavy". Grep the whole tree for duplicate suites when an expected value changes.
7. **Api-tests build health**: build the api-tests solution (`ls src/*.sln*`; it is usually `src/<Name>.Api.Tests.sln`, separate from the main `.slnx`, so develop drifts and it often doesn't compile). If broken: find the cause (`git log -S<symbol> -- src`), then check whether develop or a sibling branch already fixed it (`git log origin/develop..origin/features/* -- src/api-tests`). The same fix has been re-invented across several sessions. Fix contract compile errors from the in-repo `src/contracts`, not by bumping QA packages.

## Phase 2: Classify and plan

Pick per change area: **API testable**, **Manual**, **Regression only** (no new tests; run existing neighbouring classes), or **No testing needed** (say why). When borderline, choose more coverage.

**Before classifying anything Manual, check these observability options.** Missing every one of them is the most common user correction.
- Read endpoints that render the artifact (`HttpGet` routes for edi/ub04/cms1500/summary/preview). Don't filter them out with broad `grep -v`.
- Event streams: grep api-tests and QA.Shared for `EventHelper|StreamReader|Cosmos|CDB_KING`. Assert on the event that *schedules* a delayed effect.
- Read models/blobs, and DB seams (`DbCalls/`) for global or factory data.
- Sibling repos' QA.Shared (`~/projects/sharp/*/src/*.QA.Shared/Calls`) for cross-service seeding (e.g. RTE settings, claim charge assemblies).
- "No helper exists yet" is not a reason for Manual. Plan the helper.

Genuinely not API-observable: timer/cron/queue-delay internals, poison/dead-letter paths, external submissions, ops resets/syncs, concurrency interleavings. For those:
- Offer **unit tests**, area-wide when the API coverage is weak. Prove them by temporarily reverting the fix and watching them fail.
- Offer to run the **existing neighbouring API classes as a regression check**.
- For deploy/infra tickets, regression only is the default.

### API test plan
- Prefer modifying an existing test when the new behavior fits without changing what it proved. Otherwise add a test following the neighbouring file's collection/trait/fixture wiring.
- **Copy the full setup of the closest passing test** (financial setup, dates, portfolios). Minimal setups have cost repeated ninja runs.
- Names describe behavior; **no ticket numbers** in test or class names.
- Use retry-until-observable (`RetryHelper.RetryUntilAsync`), never fixed `Task.Delay`. Setup races: retry the *rejected call* on its specific error message only.
- Negative ("nothing happens") tests: take the baseline before the trigger, use a sentinel event or settle signal, and say in the plan that they prove less. Pick invalid inputs from the branch's unit tests or parser source.
- Racy scenarios: retry on fresh data inside the test and fail clearly if every attempt races; never skip.
- Don't plan around "ninja probably has that data". Each run creates a new org; seed deterministically. No dependency on ops resets, timers or syncs.
- Plan unit tests in the repo style: setup in static `*Fixture` classes, verification in static `*Assert` classes; extend existing ones.
- Product bug found while planning: offer the fix as an explicit option (users often take it), with unit tests.

### Manual test plan
Numbered steps for ninja:
- prerequisites (flags, config: read `k8s-config/*/values.yaml`; placeholder values need the user to tell you the ninja value)
- how to trigger the behavior
- **exactly what the user must paste back** (response body, event stream, per-row statuses)
- **one observation that proves the new code ran**
- cleanup

Claude has no ninja auth cookies; offer "paste from DevTools" or `! curl --cookie …`. Ask the user to download any UI template rather than guessing the format. List what Claude can verify itself (event streams, kubectl against ninja, read endpoints) vs what needs the user (Splunk, UI).

## Phase 3: Present the plan and stop

```
# Test Plan: <TICKET> — <summary>
Repo / branch: <repo> @ <branch> (vs origin/<default>) — fix located on: <develop|ninja|gateway|branch only>
## What changed
## Classification
## API test changes   (modify / add, with setup and expected results)
## Unit test changes  (if any)
## Manual / regression plan
## Pre-existing breakage to fix first (separate commit)
## Risks / open questions   (e.g. "negative cases pass trivially", "fix not yet deployed to ninja")
## Files I will touch
## Estimated run time   (~2-5 min per test; flag anything over 15 min)
Approve? And are you on the VPN so I can run the tests against ninja?
```

Wait for explicit approval; don't proceed on silence. If later instructions clearly supersede the plan, follow them. After approval, **save the plan** to `<scratchpad>/test-plan-<ticket>.md` and re-read it if context is compacted.

## Phase 4: Implement

1. Work on the ticket's existing feature branch; confirm a clean tree before checkout; never create a new branch (exception: the user asks to move a stale legacy branch onto `features/<ticket>`).
2. **Commits by kind, each one building**: (a) pre-existing api-test repairs, (b) product fix + unit tests if agreed, (c) the ticket's tests.
3. Match repo conventions (`csharp-conventions`; `var` where the type is obvious). Common gaps: `using FluentAssertions;`, `Sharp.QA.Core.FluentAssertions`, xUnit v3 `.AsV2()`. Reuse shared QA helpers; add wrappers to the repo's QA.Shared `Calls/` when needed.
4. Don't add helpers or waits for problems you haven't reproduced. Don't bump QA packages to fix setup failures; if a bump is unavoidable, revert afterwards to confirm it was needed.
5. Build: `dotnet build <api-tests sln> && …`. Never run `--no-build` after a failed build; it silently runs the old DLL.
6. **Run against ninja** only with the user's go-ahead (VPN), and only ninja. Follow `references/running-tests.md`. Key points:
   - local runs hit **ninja's deployed code**, not your branch
   - write the full output to a log or TRX file in the scratchpad
   - class-qualify filters and keep batches to about 8 minutes or less
   - run a baseline test that shares your helpers before debugging your own
   - time-box async cross-service repros to about 2 failed runs, then present options
7. Report honestly per class: passed / failed / not run / inconclusive, and which passes are vacuous. Don't re-run an already-passing test unless asked.
8. Don't commit or push unless asked. Stop any background task you started before handing back.

## Phase 5: Close out

- Offer the Jira test summary **once**, alongside the commit or PR step (3-8 lines: what was tested and how, test names, branch/PR, what isn't covered). The user often declines; don't keep re-asking. Post to the dev ticket, not the QA clone. Check for a service-desk link first, since those comments are customer-visible (`jsdPublic`). Skip boilerplate manual-testing notes. If an `addComment` times out, re-read the comments before retrying.
- If the outcome was "no test changes", say plainly there is nothing to commit.
- Typical next steps (offer, don't do): `/commit` → `/merge-envs` (ninja + gateway) → `/dev:ado-pull-request` → `/pr-review` → `/merge-envs` again after review fixes.
