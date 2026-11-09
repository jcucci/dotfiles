---
allowed-tools: Bash(gh pr:*), Bash(gh api:*), Bash(gh run:*), Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(jj status:*), Bash(jj diff:*), Bash(jj log:*), Bash(jj commit:*), Bash(jj git push:*), Bash(jj root:*), Bash(dotnet build:*), Bash(dotnet test:*)
description: Address PR review feedback and CI failures, then push fixes
---

## Context

- VCS type: !`jj root >/dev/null 2>&1 && echo jj || echo git`

**If jj:**
- Bookmarks on @: !`jj log -r @ --no-graph -T 'bookmarks' 2>/dev/null || true`

**If git:**
- Branch: !`git branch --show-current 2>/dev/null || true`

## Task

Address PR review feedback and CI failures, then commit and push.

### Find the PR

Use the bookmark (jj) or branch (git) name from Context:

```bash
gh pr view <name> --json number,title,state,reviewDecision,url,headRefName,reviews,comments
gh api repos/{owner}/{repo}/pulls/<pr-number>/comments
gh pr checks <name>
```

If no PR exists, tell the user and stop.

### Triage review comments

Categorize each comment as **Actionable** (code change), **Question** (reply only), **Nit** (optional), or **Praise** (no action). Present:

| # | Reviewer | Type | File:Line | Feedback | Action |
|---|----------|------|-----------|----------|--------|

### Triage CI failures

For each failed check: `gh run view <run-id> --log-failed`, identify root cause (build/test/lint), propose fix.

| Check | Status | Issue | Fix |
|-------|--------|-------|-----|

### Confirm what to do (AskUserQuestion)

- Address all
- Pick and choose (then multi-select the individual items)
- CI only
- Cancel

### Apply + verify + push

Make the changes. For build/test related fixes, verify locally before pushing.

- **git**: `git add <files>` + `git commit -m "…"` + `git push`
- **jj**: `jj commit -m "…"` + `jj git push`

Commit message should summarize what was addressed (e.g., "Fix null check and rename per review feedback").

### Reply and resolve (only after push succeeds)

Once the fixes are agreed (AskUserQuestion), implemented, verified, **and pushed**, reply to and resolve each thread whose feedback was addressed in that push. Do this automatically; no extra confirmation is needed since the user already agreed to the changes.

- Only threads the user chose to address, and whose change is in the pushed commit. Never reply to or resolve threads that were skipped, declined, or ambiguous; list those as remaining instead.
- Reply text: one or two sentences saying what changed, referencing the short commit hash (e.g. "Fixed in 28490dde: moved the count log before the `Any()` check.").
- **Question** comments the user answered: reply with the answer, then resolve only if the user said to.
- If the push failed, do not reply or resolve anything.

**Azure DevOps remote** (`dev.azure.com` in `git remote get-url origin`; `gh` will not work). Write JSON bodies to files in the scratchpad dir and use `--in-file`. Run each call explicitly (zsh does not word-split unquoted variables, so avoid `set -- $pair` style loops):

```bash
# list active threads (id + file) — project is the path segment after the org in the remote URL
az devops invoke --area git --resource pullRequestThreads --route-parameters project=<project> repositoryId=<repo> pullRequestId=<id> --org https://dev.azure.com/<org> --api-version 7.1
# reply: body {"content":"…","parentCommentId":1,"commentType":1}
az devops invoke --area git --resource pullRequestThreadComments --route-parameters project=<project> repositoryId=<repo> pullRequestId=<id> threadId=<tid> --org … --api-version 7.1 --http-method POST --in-file reply.json
# resolve: body {"status":"fixed"}
az devops invoke --area git --resource pullRequestThreads --route-parameters … threadId=<tid> --org … --api-version 7.1 --http-method PATCH --in-file status.json
```

**GitHub remote**: reply with `gh api repos/{owner}/{repo}/pulls/<pr>/comments/<comment-id>/replies -f body=…`; resolve with the GraphQL `resolveReviewThread` mutation via `gh api graphql`.

Show: files changed, commit/change id, PR URL, threads replied to and resolved, any remaining unaddressed comments.

## Notes

- Only reply to and resolve threads after the agreed change is pushed (see above). Never dismiss threads or resolve ones that were not addressed.
- If a comment is ambiguous, flag it instead of guessing.
- Call out CI failures that look unrelated to the PR changes (flaky tests, infra).
