---
name: ship
description: >-
  Ship a change from any repo the user maintains: learn that repo's own
  rules first (where it pushes, its QA gate, its commit format, its CI and
  deploy), then check, commit, push straight to main, and follow CI to the
  end. Covers the {{COMPANY}} {{PRODUCT}} repos on GitLab (pipeline, SIT auto deploy,
  manual prod) and the user's GitHub repos (GitHub Actions through gh, e.g.
  node-companion), and adapts to an unlisted repo by reading its AGENTS.md,
  CLAUDE.md, CONTRIBUTING and CI config. Use whenever the user wants work out the door or wants to know
  where it landed: "ship it", "push it", "push this up", "commit and push",
  "get this onto main", "deploy to sit", "is it deployed", "is prod
  clicked", "what's on main", or typing /ship. Watching a run or asking why
  it failed is /watch. NOT
  for the the client app app checkout (its push remote is disabled on purpose), NOT
  for publishing a release, OTA update or app build (that is the repo's own
  publish step, run only when asked), and NOT for release notes or PR prose
  (that is /ultron-document).
---

# Ship

Take a change from "done on my machine" to "on main, CI green, deployed where
the repo deploys" in one pass. The user is the sole maintainer of the repos
this covers, so work goes straight onto `main`. There are no feature branches
and no merge or pull requests unless the user asks for one, or the repo's own
docs say otherwise.

A shipment has five stages. Do them in order and do not skip the last one:
pushed is not deployed, and pushed is not green.

```
profile  →  check  →  commit  →  push  →  follow CI
```

## Stage 0: profile the repo

The skill does not assume one platform. Every repo brings its own rules, and
the repo's written rules win over this file.

1. **Find the repo, the branch and the remote.**
   ```bash
   git rev-parse --show-toplevel
   git branch --show-current
   git remote -v
   git status --short
   ```
   Refuse to ship from the the client app checkout. Its `origin` is literally
   `DISABLED_never_push`, and that is by design (vendor source, local only).
   Say so and stop. Same for any remote that is plainly disabled.

2. **Pick the platform from the push URL.**
   - `{{GITLAB_HOST}}` → GitLab. CI is the shared pipeline, watched
     with `scripts/watch-pipeline.sh`.
   - `github.com` → GitHub. CI is GitHub Actions if `.github/workflows/`
     exists, watched with `gh run`.
   - Anything else → no known CI watcher. The push is the shipment unless the
     repo's docs name a CI you can read.

3. **Look the repo up in `references/repos.md`.** It has a row for every repo
   already profiled: QA gate, hook, commit format, CI, deploy, and traps.

4. **Read the repo's own rules, every time, even for a known repo.** Rows in
   `repos.md` go stale; the repo does not. Read whichever exist:
   `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and any shipping or release
   doc they point to (for example `docs/shipping.md`). Pull out:
   - the QA gate: the commands to run before a push
   - the commit format: subject style, required body lines or trailers
   - ship rules: things that must change together, contract first rules,
     version bumps, files that must be committed after a build
   - what CI does and does not prove, and what happens after a green push
     (auto deploy, manual gate, or a separate publish step)

   Where the repo's docs and `repos.md` disagree, follow the repo and fix the
   row in `repos.md` after the shipment.

5. **Unknown repo with no written rules.** Infer the gate from what is there:
   `package.json` scripts (`typecheck`, `lint`, `test`, `build`), a
   `Makefile` (`check`, `test`), `go.mod` (`go vet ./... && go test ./...`),
   `pyproject.toml` (`pytest`). Tell the user the gate you inferred before
   running it. After the shipment, add a row to `repos.md` so the next run
   does not have to guess.

## Stage 1: check

1. **Look at what is going out.** Never commit blind.
   ```bash
   git diff --staged --stat
   git diff --staged
   ```
   If nothing is staged, look at `git status` and `git diff`, then propose
   what to stage. Stage files by name, never `git add -A`, so untracked tool
   files do not ride along. If the set mixes two unrelated changes, split it
   into two commits so `git log` stays an honest audit trail.

2. **Check the repo's ship rules against the diff.** For example: a bridge or
   API code change with no matching contract doc change, a native change with
   no version bump, two version strings that must match. A broken rule is a
   stop, the same as a red gate. Say which rule and which file.

3. **Run the repo's QA gate.** On the {{PRODUCT}} GitLab repos CI does not test
   correctness (web even sets `test_enabled: false`), so the local gate is the
   only gate. On a GitHub repo whose Actions run the tests, still run the
   local gate: a red push costs CI minutes and leaves a red mark on `main`. A
   red gate means do not push; say what failed and stop.

4. **Run the dev docs check.** Rule since 2026-07-22: markdown written for dev
   work (`context/`, `CLAUDE.md`, `HANDOVER.md`, root `docs/*.md`, `.claude/`,
   `*_SPEC.md`, `memory.md`) never gets committed, on any platform.
   ```bash
   ~/.claude/bin/check-dev-docs.sh
   ```
   Exit 0 is clean. Exit 1 lists the files to `git restore --staged`. A repo
   can keep a path by listing it in a committed `.devdocs-keep` (service keeps
   `docs/specs/`, admin keeps `.claude/`). If a repo's own docs clearly expect
   one of these files to be committed and it has no `.devdocs-keep`, do not
   decide for the user: leave the file out and say so in the report. Hooks are
   local to a clone, so run the script yourself.

5. **Repo specific scanners.** On `{{COVERS_REPO}}`, gitleaks is the hook:
   ```bash
   gitleaks git --config .gitleaks.toml --staged --no-banner .
   ```
   No real key may ever enter that repo. The only PEM allowed is the throwaway
   test key under `codes/samples/`. If any repo has a `.gitleaks.toml` or a
   `pre-commit` config, run it before committing.

## Stage 2: commit

**Use the repo's commit format when it writes one down.** For example
node-companion wants a one line, sentence case subject with an area prefix
(`Bridge s38: ...`, `Runtime 1.3.5: ...`) and a body that gives the cause and
ends with a `Tests:` line. Copy the shape of the last few `git log` subjects
when the docs are thin.

**With no written format, use conventional commits:** imperative, summary
under about 50 characters, body explains the why when the diff does not.

```
<type>: <what changed>

<why, wrapped at 72 columns>
```

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `ci`, `revert`.
Real examples from the {{PRODUCT}} repos:

- `fix: bump pinned ca-certificates to 20260909-r0`
- `feat: clear button on the assistant panel, FAB breathe, scroll-to-top ({{ADMIN_REPO}}-8qp6)`
- `docs(specs): bring the cover collection specs in from the the client app repo`

On every repo: never add `Co-Authored-By` or "Generated with" trailers.

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
- Rejected as a protected branch: surface it. On GitLab the user loosens it
  under Settings, Repository, Protected branches; on GitHub under Settings,
  Branches or Rules. Or they ask for a branch and a merge or pull request (see
  the end of this file). Do not work around it.
- If the harness refuses the push, do not retry in pieces or through another
  tool. Report the exact command for the user to run and finish the rest.

Confirm the push landed:
```bash
git status -sb
```
It must read `## main...origin/main` with no `[ahead N]`.

## Stage 4: follow CI

A shipment is not done until you have read CI for the pushed commit, on
whatever platform the repo uses. Run the watcher in the background
(`run_in_background: true`); the harness wakes you when it exits.

### GitLab ({{COMPANY}} {{PRODUCT}})

Repos with `.gitlab-ci.yml` (web, service, admin, {{CAMPAIGNS_REPO}}) run the
shared template on every push to `main`: pre flight, lint, audits
(gitleaks, Polaris), build, then `sit` deploys on its own and `prod` waits for
a manual click.

```bash
~/.claude/skills/ship/scripts/watch-pipeline.sh            # latest pipeline on this branch
~/.claude/skills/ship/scripts/watch-pipeline.sh <sha>      # a specific commit
~/.claude/skills/ship/scripts/watch-pipeline.sh <id>       # a pipeline id
```

It polls until the pipeline reaches a final state, lists every job, and pulls
the failing jobs' logs, which the gitlab MCP cannot fetch. A fresh push takes
30 to 60 seconds to register a pipeline. If the script finds none, wait and re
run rather than reporting "no pipeline". Knobs: `POLL_SECONDS` (default 45),
`MAX_POLLS` (default 120), `SCAN_ALL=1` to scan passing jobs too.

The watcher reads the user's personal access token from the gitlab MCP entry
in `~/.claude.json`, which sees every repo in the group. Do not switch it to
`glab`; `glab`'s stored token for `{{GITLAB_HOST}}` is rejected (401) and a
project token would only see one repo anyway.

Judge the result:

- A failed job **without** `allow_failure` is a blocking failure. The pipeline
  stopped at that stage and nothing after it ran. SIT did not deploy.
- `gitleaks` and `helm-templates-check` run with `allow_failure` on these
  repos. Red there does not block the deploy, but read the leak report; a
  real leak matters even when CI shrugs.
- `manual` as the final state means every required job passed and only the
  prod gate remains. That is the normal good ending.

Common errors: `DL3018` from hadolint means pin the apk package version to one
that exists; `npm ERR!` or `error TS` means the local gate was skipped.

### GitHub Actions

Find the run for the pushed commit, then watch it to the end:

```bash
gh run list --commit "$(git rev-parse HEAD)" --json databaseId,workflowName,status,conclusion,url
```
```bash
gh run watch <run-id> --exit-status --interval 30
```

A fresh push can take up to a minute to show a run; wait and re list rather
than reporting "no run". When the run finishes:

```bash
gh run view <run-id>                 # every job and step
gh run view <run-id> --log-failed    # only the failing steps' logs
```

Judge the result:

- `success` on every job is green. A green job can still carry warnings in
  its summary (node-companion's runtime check is one); read and report them.
- `failure` names the job; `--log-failed` names the step. Quote the actual
  error line before changing anything.
- **No run is never green.** On a repo with workflows, a commit with no run,
  or a run that never started a job, can mean the free Actions minutes ran out
  or Actions is off. Say so and point at the run page; do not report a pass.

### No CI

Repos without CI (qr-covers, knowledgebase, finance-dashboard,
operator-assistant, or any repo with neither `.gitlab-ci.yml` nor
`.github/workflows/`): the shipment ends at the confirmed push. Say so plainly
rather than implying a deploy happened.

### After CI

A blocking failure is already on `main`. Fix forward with a new commit, never
a rewrite. To pick who fixes it, follow the routing table in `/watch` (Step 4):
it sends a failing test or build to `/ultron-debug`, repeat failures to
`/recover`, and a one line cause back here.

Some repos have a separate publish step after a green push: an OTA update, an
app build, a worker deploy, a release tag. `/ship` never runs it unless the
user asks in this request. Name it in the report's `Next:` line, with the
condition the repo sets (for example "wait for the green mark before
`npm run ota`").

## Status questions without a push

GitLab: use the gitlab MCP. Address a repo by its URL encoded path as
`project_id`, for example `{{GITLAB_GROUP}}/{{SERVICE_REPO}}`.

- Did my push pass? `list_commit_statuses` with the sha, or `ref: "main"`.
- What is on main? `list_commits` with `ref_name: "main"`.
- Is it live? The `sit` and `prod` job states in `list_commit_statuses`; the
  prod job sitting at `manual` means pushed, not live. Only the user clicks it.
- My queue: `list_todos`, `my_issues`.
- Failing job's log: the MCP cannot fetch it; run the watcher with the
  pipeline id, it returns at once when the pipeline is already finished.

GitHub: use `gh` from inside the repo.

- Did my push pass? `gh run list --commit <sha>` or `gh run list --branch main --limit 5`.
- What is on main? `git fetch origin && git log --oneline origin/main -10`.
- Why did it fail? `gh run view <run-id> --log-failed`.

## Branch and merge or pull request, on request only

If the user asks to stage something risky behind a review, or `main` rejects
the push as protected:

```bash
git checkout -b fix/<what> main
```
```bash
git push -u origin fix/<what>
```

GitLab: `create_merge_request` through the gitlab MCP with `target_branch:
"main"`. GitHub: `gh pr create --base main` (check for a pull request
template first). Use a title in the repo's commit format, and a description of
what changed and how it was verified. No reviewers; the user merges their own.

## Report

Lead with the verdict, then only what the user must act on.

```
Shipped <sha> to <repo> main: <summary line>
CI <pipeline or run id>: PASS | FAILED at <job> | non blocking red on <job> | no CI on this repo
<pipeline or run url>
Deploy: <SIT deployed, prod waiting for your click | none, publish is a separate step | n/a>
Next: <nothing | the fix forward | the command you need to run yourself>
```

## Examples

**"ship it"** in `{{COVERS_REPO}}` with a staged docs change.
Profile: GitLab remote, no CI. Check: diff is nine spec files plus a README
line, no QA gate for docs, dev docs check passes (`docs/specs/` is a folder,
the rule covers root `docs/*.md` only), gitleaks clean. Commit `docs(specs):
...`. Push as its own command. Confirm `## main...origin/main`. Report:
"Shipped b37e72e to {{COVERS_REPO}} main. No pipeline on this repo; the
push is the whole shipment."

**"did the pipeline pass?"** in `{{ADMIN_REPO}}` after a push.
Run the watcher on the current branch. It returns immediately because the
pipeline finished: "Pipeline 161802: PASS. sit deployed, prod waiting for your
click. gitleaks red but allow_failure, one hit on a test fixture, not a leak."

**"ship it"** in `node-companion` with a bridge schema change.
Profile: GitHub remote, Actions CI, rules in `AGENTS.md` and
`docs/shipping.md`. Check: the diff changes `src/bridge/schema.ts` but not
`docs/bridge.md`, which breaks "contract first". Stop and say so. Once the
contract is in, run `npm run typecheck`, `npm test` and `npm run
check:runtime`, commit as `Bridge s<NN>: ...` with a `Tests:` line, push, and
watch the run with `gh run watch`. Report the run, and put "wait for green,
then `npm run ota` if you want it on phones" in `Next:`. Never run the OTA
yourself.

**"push this to service"** with `make check-quick` failing.
Stop at stage 1: "gofmt flagged internal/admin/orders.go; not pushing. Fix the
formatting and I'll ship." Do not commit around a red gate.
