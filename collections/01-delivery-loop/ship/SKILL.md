---
name: ship
description: >-
  Ship a change to any {{COMPANY}} {{PRODUCT}} repo on {{COMPANY}}'s GitLab (the {{GITLAB_GROUP}} group on
  {{GITLAB_HOST}}): run the pre commit checks, commit with a conventional
  message, pull, push straight to main, then follow the pipeline to the end
  and report whether staging deployed and whether the manual prod job is waiting.
  Also answers GitLab status questions on those repos through the gitlab MCP.
  Use whenever the user wants work out the door or wants to know where it
  landed: "ship it", "push it", "push this up", "commit and push", "send it
  to GitLab", "get this onto main", "deploy to staging", "is it deployed", "did
  the pipeline pass", "watch the pipeline", "watch CI", "why did the pipeline
  fail", "is prod clicked", "what's on main", or typing /ship. Covers all
  eight {{REPO_PREFIX}} and {{CAMPAIGNS_REPO}} repos under {{WORKSPACE_ROOT}}. NOT for the the client app
  app checkout (its push remote is disabled on purpose), NOT for GitHub
  repos, and NOT for release notes or PR prose (that is /ultron-document).
---

# Ship

Take a change from "done on my machine" to "on main, pipeline green, staging
deployed" in one pass, on any {{COMPANY}} {{PRODUCT}} repo. The user is the sole maintainer
of every repo in the `{{GITLAB_GROUP}}` group, so work goes straight onto `main`. There
are no feature branches and no merge requests unless the user asks for one.

A shipment has four stages. Do them in order and do not skip the last one:
pushed is not deployed.

```
check  →  commit  →  push  →  follow the pipeline
```

Read `references/repos.md` for the per repo table: which repos have CI, which
QA command to run first, which hook guards the commit, and where the deploy
lands. Read it before the check stage so you run the right gate.

## Stage 1: check

1. **Find the repo and confirm you are on `main`.**
   ```bash
   git rev-parse --show-toplevel
   git branch --show-current
   git status --short
   ```
   Refuse to ship from a client app checkout. Its `origin` is literally
   `DISABLED_never_push`, and that is by design (client source, local only).
   Say so and stop.

2. **Look at what is going out.** Never commit blind.
   ```bash
   git diff --staged --stat
   git diff --staged
   ```
   If the staged set mixes two unrelated changes, split it into two commits so
   `git log` stays an honest audit trail.

3. **Run the repo's QA gate** from `references/repos.md`. CI on these repos does
   not test correctness. The shared pipeline builds, scans and deploys, and
   web even sets `test_enabled: false`. The local gate is the only gate. A red
   gate means do not push; say what failed and stop.

4. **Run the dev docs check.** Rule since 2026-07-22: markdown written for dev
   work (`context/`, `CLAUDE.md`, `HANDOVER.md`, root `docs/*.md`, `.claude/`,
   `*_SPEC.md`, `memory.md`) never gets committed, on any platform.
   ```bash
   ~/.claude/bin/check-dev-docs.sh
   ```
   Exit 0 is clean. Exit 1 lists the files to `git restore --staged`. A repo
   can keep a path by listing it in a committed `.devdocs-keep` (service keeps
   `docs/specs/`, admin keeps `.claude/`). Every repo's `pre-commit` hook runs
   the same script, but hooks are local to a clone, so run it yourself.

5. **On `{{COVERS_REPO}}`, gitleaks is the hook.** It scans the staged
   files with the repo's own `.gitleaks.toml`. Run it before committing so a
   blocked commit is never a surprise:
   ```bash
   gitleaks git --config .gitleaks.toml --staged --no-banner .
   ```
   No real key may ever enter that repo. The only PEM allowed is the throwaway
   test key under `codes/samples/`.

## Stage 2: commit

Conventional commit style, imperative, summary under about 50 characters,
body explains the why when the diff does not:

```
<type>: <what changed>

<why, wrapped at 72 columns>
```

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `ci`, `revert`.
Real examples from these repos:

- `fix: bump pinned ca-certificates to 20260909-r0`
- `feat: clear button on the assistant panel, FAB breathe, scroll-to-top ({{ADMIN_REPO}}-8qp6)`
- `docs(specs): bring the collection specs in from the app repo`

Never add `Co-Authored-By` or "Generated with" trailers.

**Beads on service and admin.** Those two repos track work with `bd`. Put the
bead id in the commit summary, close the bead before you push (`bd close
<id>`), log any gap you knowingly ship as a new bead (`bd create "<gap>"`),
and run `bd sync` so the `.beads` export travels with the code. With no
reviewer, a clean `bd status` plus a green gate is the approval.

**Amend only while local.** Before the push, `git commit --amend` and squashing
are fine. After the push, never rewrite. Fix forward with a new commit or
`git revert`.

## Stage 3: push

Run the push as **its own command**, on its own line, not chained after the
commit with `&&`. The harness's permission check reads the whole command, and a
commit bundled with a push has been refused as "data exfiltration" where a
plain `git push origin main` is allowed. One command, one job.

```bash
git pull --ff-only origin main
```
```bash
git push origin main
```

- Rejected as non fast forward: `git pull --rebase origin main`, then push
  again. Never `--force` on `main`, with or without lease.
- Rejected as a protected branch: `main` is protected server side. Surface it;
  the user loosens it under Settings, Repository, Protected branches, or asks
  for a branch and MR (see the end of this file). Do not work around it.
- If the harness refuses the push, do not retry in pieces or through another
  tool. Report the exact command for the user to run and finish the rest.

Confirm the push landed:
```bash
git status -sb
```
It must read `## main...origin/main` with no `[ahead N]`.

## Stage 4: follow the pipeline

Repos with `.gitlab-ci.yml` (web, service, admin, {{CAMPAIGNS_REPO}}) run the
shared pipeline template on every push to `main`: pre flight, lint, audits
(gitleaks, Polaris), build, then `{{STAGING_JOB}}` deploys on its own and `prod` waits for
a manual click. A shipment is not done until you have read that pipeline.

Run the watcher in the background from inside the repo. It polls until the
pipeline reaches a final state, lists every job, and pulls the failing jobs'
logs, which the gitlab MCP cannot fetch.

```bash
~/.claude/skills/ship/scripts/watch-pipeline.sh            # latest pipeline on this branch
~/.claude/skills/ship/scripts/watch-pipeline.sh <sha>      # a specific commit
~/.claude/skills/ship/scripts/watch-pipeline.sh <id>       # a pipeline id
```

Use `run_in_background: true`; the harness wakes you when it exits. A fresh
push takes 30 to 60 seconds to register a pipeline. If the script finds none,
wait and re run rather than reporting "no pipeline". Knobs: `POLL_SECONDS`
(default 45), `MAX_POLLS` (default 120), `SCAN_ALL=1` to scan passing jobs too.

The watcher reads the user's personal access token from the gitlab MCP entry
in `~/.claude.json`, which sees every repo in the group. Do not switch it to
`glab`; `glab`'s stored token for `{{GITLAB_HOST}}` is rejected (401) and a
project token would only see one repo anyway.

**Judge the result:**

- A failed job **without** `allow_failure` is a blocking failure. The pipeline
  stopped at that stage and nothing after it ran. staging did not deploy.
- `gitleaks` and `helm-templates-check` run with `allow_failure` on these
  repos. Red there does not block the deploy, but read the leak report; a
  real leak matters even when CI shrugs.
- `manual` as the final state means every required job passed and only the
  prod gate remains. That is the normal good ending.

A blocking failure is already on `main`. Fix forward with a new commit, never
a rewrite. Read the actual error line from the log before changing anything.
Common ones: `DL3018` from hadolint means pin the apk package version to one
that exists; `npm ERR!` or `error TS` means the local gate was skipped.

**Repos without CI** (qr-covers, knowledgebase, finance-dashboard,
operator-assistant): the shipment ends at the confirmed push. Say so plainly
rather than implying a deploy happened.

## Status questions without a push

Use the gitlab MCP for quick reads. Address a repo by its URL encoded path as
`project_id`, for example `{{GITLAB_GROUP}}/{{SERVICE_REPO}}`.

- Did my push pass? `list_commit_statuses` with the sha, or `ref: "main"`.
- What is on main? `list_commits` with `ref_name: "main"`.
- Is it live? The `{{STAGING_JOB}}` and `prod` job states in `list_commit_statuses`; the
  prod job sitting at `manual` means pushed, not live. Only the user clicks it.
- My queue: `list_todos`, `my_issues`.

For the failing job's log, the MCP cannot help; run the watcher with the
pipeline id, it returns at once when the pipeline is already finished.

## Branch and merge request, on request only

If the user asks to stage something risky behind an MR, or `main` rejects the
push as protected:

```bash
git checkout -b fix/<what> main
git push -u origin fix/<what>
```

Then `create_merge_request` through the gitlab MCP with `target_branch:
"main"`, a conventional title, and a description of what changed and how it
was verified. No reviewers; the user merges their own.

## Report

Lead with the verdict, then only what the user must act on.

```
Shipped <sha> to <repo> main: <summary line>
Pipeline <id>: PASS | FAILED at <job> | non blocking red on <job>
<pipeline web_url>
Staging: deployed | not reached      Prod: waiting for your click | n/a
Next: <nothing | the fix forward | the command you need to run yourself>
```

## Examples

**"ship it"** in `{{COVERS_REPO}}` with a staged docs change.
Check: on `main`, diff is nine spec files plus a README line, no QA gate for
docs, dev docs check passes (`docs/specs/` is a folder, the rule covers root
`docs/*.md` only), gitleaks clean. Commit `docs(specs): ...`. Push as its own
command. Confirm `## main...origin/main`. No CI on this repo, so report:
"Shipped b37e72e to {{COVERS_REPO}} main. No pipeline on this repo; the
push is the whole shipment."

**"did the pipeline pass?"** in `{{ADMIN_REPO}}` after a push.
Run the watcher on the current branch. It returns immediately because the
pipeline finished: "Pipeline 161802: PASS. {{STAGING_JOB}} deployed, prod waiting for your
click. gitleaks red but allow_failure, one hit on a test fixture, not a leak."

**"push this to service"** with `make check-quick` failing.
Stop at stage 1: "gofmt flagged internal/admin/orders.go; not pushing. Fix the
formatting and I'll ship." Do not commit around a red gate.
