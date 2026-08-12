---
name: ship
description: >
  Full git + GitLab workflow for the {{REPO_PREFIX}} repos ({{ADMIN_REPO}},
  {{WEB_REPO}}, {{SERVICE_REPO}}) on GitLab at {{GITLAB_HOST}}. Use whenever
  the task involves git: cloning, setting up remotes/SSH, staging, committing,
  writing commit messages, amending, and pushing straight to `main` (the user is
  the sole maintainer — no feature branches, no merge requests, no pre-merge
  review gate). Also use to query GitLab directly via the gitlab MCP server:
  a one-shot pipeline status read on a commit, deploy/environment status, and
  todos across all three repos ("is it deployed", "my gitlab todos", "what's the
  status of that commit"). NOT for watching a pipeline that is still running or
  diagnosing why one failed — "did the pipeline pass", "watch CI", "why did it
  fail", and anything needing job logs belong to /watch, which polls to
  completion and fetches traces this skill cannot.
  Because there's no MR review gate, this skill uses beads (`bd`) as the
  quality-and-traceability net — track the work, close it on ship, and log any
  quality debt as beads so nothing is lost the moment code hits `main`.
---

# Git workflow ({{REPO_PREFIX}} repos)

This skill encodes how to work with git on the {{REPO_PREFIX}} repos. The remote is
GitLab at `{{GITLAB_HOST}}`, the group is `{{GITLAB_GROUP}}`, and **the user is the sole
maintainer of all three repos.** It's a one-person repo: work goes **straight
onto `main`**. No branches, no merge requests, no review gate. Keep history clean
and never rewrite or clobber what's already pushed.

## Current working mode (read before doing anything)

**Commit and push directly to `main`.** The per-feature-branch + MR flow is
retired — there's no second maintainer and nobody reviews the MRs, so the
ceremony bought nothing.

- Work **on `main`**. Keep it current before committing:
  `git checkout main && git pull --ff-only`. Confirm with
  `git branch --show-current`.
- Commit in **small, logical units** with conventional-commit messages (see
  below). One commit = one change, so `git log` stays readable.
- **Push straight to `main`:** `git push origin main`. That's the whole ship
  step. On these repos a push to `main` auto-deploys **staging**; **prod is a
  separate manual gate** the user clicks. CI runs on `main` after the push.
- Push when the work is ready to ship. There's no pre-merge gate to wait on and
  nothing to stage behind an MR.

- **Run the repo's QA gate before you push, and track the work in beads.** With
  no MR, these two are what keep shipping honest — see the next two sections.

If the user explicitly asks for a branch or MR on a specific change, the
machinery is in "Optional: branch + MR on request" below — but that's on request
only, not the default.

## Pre-push QA gate (what the repo already enforces)

CI does **not** check code correctness. The shared pipeline
(`catalyst/pipeline-templates`) only runs build + security + deploy jobs —
`docker-lint`, `gitleaks`, helm checks, docker build, then `{{STAGING_JOB}}`/`prod` (and web
even sets `test_enabled: false`). There are no git hooks either. So the real
quality gate the previous maintainers enforced was **local commands run by hand
before shipping.** Run them before every push to `main` — they are the gate now.

- **{{SERVICE_REPO}}** (Makefile):
  - Minimum: `make check-quick` (gofmt + go vet + unit tests).
  - Fuller: `make test` (`go test -race ./...`), `make lint` (golangci-lint,
    `.golangci.yml`), `make test-contract` (validates against `api/openapi.yaml`),
    `make coverage` (enforces 90% per file / 95% overall via
    `scripts/check-coverage.sh`).
- **{{WEB_REPO}}** (npm): `npm run build` (`tsc -b && vite build`) + `npm run
  lint` (`eslint . --max-warnings 0` — **zero-warning**; the trackers hold a known
  baseline, so treat *new* warnings as failures) + `npm run test` (vitest). Run
  `npm run test:e2e` (playwright) for funnel/checkout changes.
- **{{ADMIN_REPO}}** (npm): `npm run build` (`tsc -b && vite build`) + `npm run
  lint` (`eslint .`). **No test framework exists** — so verify by driving the UI
  (see the `verify` skill). This is the weakest-gated repo; lean hardest on manual
  verification and beads here.

A red gate means don't push. If you deliberately ship with a known gap (a skipped
test, a deferred lint), that gap goes in beads — see below.

## Track work in beads (the traceability net)

Beads (`bd`) is a git-native issue tracker living in `.beads/issues.jsonl`, synced
with the code. With no MR and no reviewer, beads is the audit trail of what
shipped and the place quality debt goes so it isn't lost the second code lands on
`main`.

**Where it's set up:** `{{ADMIN_REPO}}` only (issue IDs like `{{ADMIN_REPO}}-1fp`).
`{{WEB_REPO}}` and `{{SERVICE_REPO}}` have no `.beads/` yet — use beads there
only after `bd init`, and only if the user asks; don't init a repo unprompted.

**The loop, per change:**

1. **Starting** — make sure a bead exists for the work. `bd ready` shows open,
   unblocked work; `bd list` shows everything. New work: `bd create "<what>"`
   (or `bd q "<what>"` for just an ID). Mark it active:
   `bd update <id> --status in_progress`.
2. **Before you push** —
   - Close what's done: `bd close <id>` (or `bd update <id> --status done`).
   - **Log every known gap as its own bead** — a skipped edge case, a follow-up, a
     `TODO` left in code, a test/lint deferred: `bd create "<gap>" -p <priority>`.
     Anything that would once have surfaced in review lands in beads instead of
     vanishing.
   - Reference the bead ID in the commit message so commit ↔ issue tie together,
     e.g. `feat: collapsible top {{ITEM}} ({{ADMIN_REPO}}-1fp)`.
3. **Sync** — `bd sync` commits the `.beads/issues.jsonl` change so tracking
   travels with the code. Run it as part of shipping, not after.

**Before calling a change shipped:** `bd status` should reflect reality — the
shipped bead closed, any debt logged. A green QA gate plus a clean `bd status` is
the new "MR approved."

> **Protected-branch note.** If a push to `main` is rejected with `You are not
> allowed to push code to protected branches`, `main` is protected server-side.
> The user can loosen it in **Settings → Repository → Protected branches** (allow
> the maintainer to push). Surface it and let them decide — don't try to force it.

## Golden rules (read first)

1. **Never force-push `main`.** It's the working branch *and* the shared history
   — a force-push can destroy commits for good. Plain `git push` only.
2. **Never bare `--force`.** If you ever force-push anything at all, it's
   `--force-with-lease`, and never on `main`.
3. **One commit = one logical change.** Don't mix a CI fix and a feature in one
   commit — `git log` is the audit trail.
4. **Non-fast-forward push? Pull, don't force.** If `git push origin main` is
   rejected as non-fast-forward, another machine pushed first:
   `git pull --rebase origin main`, then push. Never resolve it with `--force`.
5. **When unsure, do the safe boring thing**: `git pull --ff-only`, small
   `git commit`, plain `git push`.

## Remotes & SSH (git protocol over HTTPS)

HTTPS clones prompt for credentials and trip 2FA. SSH uses a key pair instead.

Check what protocol a repo uses:
```bash
git remote -v
```
If the URL starts with `https://`, it's HTTPS. Switch it to SSH:
```bash
git remote set-url origin git@{{GITLAB_HOST}}:{{GITLAB_GROUP}}/<repo>.git
```
(`<repo>` is e.g. `{{ADMIN_REPO}}`. The group is `{{GITLAB_GROUP}}`.)

One-time SSH key setup:
```bash
ls -al ~/.ssh                       # look for id_ed25519(.pub)
ssh-keygen -t ed25519 -C "work-email"   # only if no key exists
cat ~/.ssh/id_ed25519.pub           # copy this into GitLab > Preferences > SSH Keys
ssh -T git@{{GITLAB_HOST}}         # test; type "yes" to confirm fingerprint
```
After SSH works, the old `~/.git-credentials` file (stored HTTPS login) can be
removed so nothing's left lying around.

## Working on main

Stay on `main` and keep it current before every commit so you never diverge:
```bash
git checkout main            # be on main
git pull --ff-only           # fast-forward to origin/main; fails loudly if diverged
git branch --show-current    # explicit confirm: should print "main"
```
If `pull --ff-only` fails, local `main` has commits origin doesn't (or vice
versa) — reconcile with `git pull --rebase origin main` before doing more work.

## Staging & inspecting before commit

Never commit blind. Always look first:
```bash
git status              # what's modified / staged / untracked
git diff                # unstaged changes
git diff --staged       # what's actually going into the commit
git log -1 --stat       # the last commit's message + files (before amending!)
```
Stage deliberately — prefer naming files over `git add .` when several unrelated
changes are present, so concerns stay in separate commits:
```bash
git add Dockerfile
git add path/to/specific/file
```

## Dev-work docs never ship — check every time

**Rule (2026-07-22): contracts and markdown written for dev work are never
committed, on any platform.** Not GitLab, not GitHub. They live on disk only.

This covers `context/`, `context-v1/`, `CLAUDE.md`, `HANDOVER.md`, `FINDS*.md`,
`memory.md`, root `docs/*.md`, `.claude/`, `*_FRONTEND_CONTRACT.md`, and
`*_SPEC.md`. It does **not** cover `README.md`, `.beads/`, or the
knowledgebase's `system_prompt.md` and `files/` — those are product, not dev work.

**Run this after staging and before every commit:**

```bash
~/.claude/skills/ship/scripts/check-dev-docs.sh
```

Exit 0 is clean. Exit 1 lists what to unstage. A `pre-commit` hook in each {{PRODUCT}}
repo runs the same script, so a hand-typed `git commit` is covered too — but
run it yourself rather than relying on the hook, because the hook is local to a
clone and vanishes if the repo is re-cloned.

To audit what is *already* tracked in a repo (useful after cloning or when the
rule changes):

```bash
~/.claude/skills/ship/scripts/check-dev-docs.sh --tracked
```

Purge anything it finds with `git rm --cached <file>` — that unstages it from
the repo while leaving it on disk.

**Why the check allows deletions:** it filters on `--diff-filter=ACMR`, so
removing a dev doc from tracking passes. Purging is the fix, not a violation.

### Per-repo exemptions — `.devdocs-keep`

A repo can keep something the rule would otherwise block by committing a
`.devdocs-keep` file at its root, listing path prefixes one per line
(`#` comments and blank lines ignored).

It is committed on purpose, so the exemption survives a re-clone — unlike a
git hook or a git config value, which are local to one clone.

**`{{ADMIN_REPO}}` exempts `.claude/`** because its agents and the
`react-best-practices` skill (40-plus rule files) are shared tooling that
anyone cloning that repo needs. The exemption is scoped to that prefix only —
`CLAUDE.md` and `docs/*.md` are still blocked there, and `.claude/` is still
blocked in every other repo.

Keep exemptions narrow. Each one is a path where a dev doc can reach a remote.

**One trap to know about:** the directory rules are anchored to the repo root
on purpose. An early version matched `*/context/*` and flagged
`{{WEB_REPO}}/src/context/*.tsx` — the React context providers, i.e. real
application source. Never widen those patterns.

## Commit messages

Conventional-commits style (the {{PRODUCT}} repos lean on this):

```
<type>: <imperative summary under ~50 chars>

<optional body explaining the why, wrapped ~72 cols>
```
Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `ci`.

Examples from real work:
- `fix: pin tzdata to 2026b-r0 to satisfy docker-lint and build`
- `feat: implement voucher UI for bulk notification campaign`

Two `-m` flags = summary + body:
```bash
git commit -m "feat: implement voucher UI for bulk notification campaign" \
           -m "Wire the four-field voucher block in the campaign builder form to the bulk notification endpoint."
```

### Dropping the Claude Code trailer
To stop Claude Code adding `Co-Authored-By: Claude` / "Generated with" lines,
set in `~/.claude/settings.json` (or repo-level `.claude/settings.json`):
```json
{ "includeCoAuthoredBy": false }
```
`git commit --amend -m "..."` also drops an existing trailer because it replaces
the whole message.

## Amending & rewriting — only before the push

Rewriting history is fine while a commit is **local only**. Once it's pushed to
`main` it's shared history — rewriting it needs a force-push, which rule 1 forbids
on `main`. So:

- **Not yet pushed:** amend or squash freely, then push.
  ```bash
  git commit --amend -m "new message"              # fix the message
  git add <file> && git commit --amend --no-edit   # fold a fix into the last commit
  git rebase -i HEAD~<n>                            # squash several local commits into one
  ```
- **Already pushed to `main`:** do **not** amend or rebase it. Make a **new
  commit** on top (`git commit` a follow-up, or `git revert <sha>` to undo). A
  clean forward commit beats rewriting shared history.

## Pushing

```bash
git pull --ff-only origin main   # make sure you're current first
git push origin main             # ship it — auto-deploys staging
```
- Plain `git push` only. **Never** `git push --force` or `--force-with-lease` on
  `main`.
- Rejected as non-fast-forward? `git pull --rebase origin main`, then push again
  (golden rule 4).

## Querying GitLab directly (gitlab MCP)

The `gitlab` MCP server is wired to `{{GITLAB_HOST}}` with a personal token, so
you can read GitLab state without leaving the session. **Prefer the MCP for
status questions** — it's faster and quotable than "go check the pipeline".

Address a repo by its URL-encoded path as `project_id`:
`{{GITLAB_GROUP}}/{{SERVICE_REPO}}`, `{{GITLAB_GROUP}}/{{WEB_REPO}}`, `{{GITLAB_GROUP}}/{{ADMIN_REPO}}`. The token
covers all three.

What to reach for (commit-centric, since there are no MRs):
- **Did my push pass CI?** — `list_commit_statuses` (`sha` = the commit you
  pushed, or `ref: "main"`). Pass/fail/running per job, including the `{{STAGING_JOB}}`
  deploy job and the manual `prod` job.
- **What's the latest on main?** — `list_commits` (`ref_name: "main"`).
- **Is it deployed?** — the `{{STAGING_JOB}}`/`prod` job status in `list_commit_statuses`,
  then confirm **Deploy > Environments** in the browser for what's actually live.
- **Your queue** — `list_todos`, `my_issues`.

**The one gap:** the MCP can tell you *which* pipeline or job failed, but it can't
fetch the job's log/trace. For the actual error text, use the CLI (`glab ci view`,
`glab ci trace`) or open the failing job in the browser. See "Reading a failed
pipeline" below.

## Pushed ≠ live

Pushing puts code on `main` and auto-deploys **staging**; **prod is a separate manual
gate.** After a push, check the commit's pipeline (`list_commit_statuses` via MCP)
for a green `{{STAGING_JOB}}` deploy, then confirm **Deploy > Environments** in the browser
for what's actually running. To go live on prod, the user clicks the `when:
manual` prod job — you don't trigger it.

## Optional: branch + MR on request

The default is direct-to-`main`. Only if the user explicitly asks for a branch or
a merge request on a specific change (e.g. to stage something risky, or to dodge a
protected-`main` push rejection):
```bash
git checkout -b fix/<what-it-fixes> main    # branch off current main
# ... commit ...
git push -u origin fix/<what-it-fixes>
```
Then create the MR via the gitlab MCP `create_merge_request` (`source_branch`,
`target_branch: "main"`, conventional-style title, description = what changed +
how it was verified). Don't assign reviewers — the user merges their own. Use
this only when asked; it is not the default flow.

## Reading a failed pipeline (quick map)

Use the MCP to find *which* stage/job failed (`list_commit_statuses` on the commit
or `ref: "main"`), then read its log via `glab ci view` / `glab ci trace` or the
browser — the MCP doesn't expose job traces.

Stage order in {{PRODUCT}}-admin: `version → pre-flight → lint → audits → build`.
A pipeline stops at the first failing stage, so a `lint` failure means `build`
never ran. Common jobs:
- `docker-lint` (hadolint) — Dockerfile best-practice rules, e.g. **DL3018**
  "pin versions in apk add". Pin to a version that *exists* to satisfy both lint
  and build (`apk add tzdata=2026b-r0`, not bare `tzdata` and not a stale pin).
- `gitleaks` — scans the diff for committed secrets; often a false positive on
  test fixtures, but always verify. (Runs `allow_failure` on some repos —
  non-blocking, but read it.)
- `helm-templates-check` — renders the Helm/K8s chart; failure can mean the
  deploy step can't produce valid manifests.

CI runs on `main` after the push, so a failed job is already on the shared branch
— fix forward with a new commit, never a rewrite. Open the failing job's log and
read the actual error/rule code before changing anything — guess less, read more.
