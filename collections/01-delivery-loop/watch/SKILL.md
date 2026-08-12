---
name: watch
description: >-
  Watch a GitLab pipeline on {{GITLAB_HOST}} (the {{REPO_PREFIX}} repos) to
  completion, then read the failed jobs' logs and surface real failures plus
  suspicious structured-log ("slog") lines — panics, error/warn levels, stack
  traces, exit codes, leaks, timeouts. Use whenever the user wants to keep an
  eye on CI after a push or asks: "watch the pipeline", "watch CI", "is the
  deploy still running", "keep an eye on the pipeline", "tail the pipeline",
  "did the pipeline pass", "why did the pipeline fail", "check the pipeline
  logs", "check the logs for errors", "what's wrong with the build", "any weird
  logs in the deploy". This is the default for any pipeline-outcome question —
  it polls until the pipeline finishes AND fetches the job traces the gitlab MCP
  cannot, and returns immediately if the pipeline is already done. Use /ship
  instead only for git actions (commit, push) or a deploy/environment/todo
  lookup that is not about a pipeline's outcome.
---

# Watch a GitLab pipeline and scan its logs

This skill watches one pipeline in the `{{GITLAB_GROUP}}/{{REPO_PREFIX}}-*` GitLab group on
`{{GITLAB_HOST}}` until it finishes, then reads the log of every failed job and
pulls out the lines that matter: failures and weird structured-log output. It
answers two questions in one go — *did it pass?* and *if not, what actually went
wrong?*

It exists because the gitlab MCP can report which job failed but **cannot fetch a
job's log/trace**. This skill closes that gap with the `glab` CLI, which is
installed and authed as the project bot for all three repos.

## When this vs `ship`

`ship` is for the git workflow and a **one-shot** status snapshot
(`list_commit_statuses` on a commit). Reach for `watch` when the pipeline is
still running and you want to follow it to the end, or when a job failed and you
need the real error text from its log. `watch` calls the same MCP for status and
adds the log-reading `ship` explicitly can't do. Don't duplicate `ship`'s
push/commit steps here.

## What you need

- Run from **inside the target repo** (`{{SERVICE_REPO}}`, `{{WEB_REPO}}`, or
  `{{ADMIN_REPO}}`). The helper auto-detects the project from the `origin`
  remote, so you don't pass a project id.
- The **personal access token** the gitlab MCP is configured with — read
  automatically from `~/.claude.json`
  (`mcpServers.gitlab.env.GITLAB_PERSONAL_ACCESS_TOKEN`). This is the user's own
  PAT and it can read **all three** repos, so `watch` works everywhere. Override
  with `GITLAB_TOKEN` if needed.

### Which token — don't get these confused

There are two different tokens on {{GITLAB_HOST}}:

- **The MCP's personal access token** (in `~/.claude.json`) — user account,
  reads all three repos. **This is what `watch` uses**, via the REST API. Fetches
  job traces, which the gitlab MCP tools cannot.
- **`glab`'s login token** — a *project* access token scoped to `{{ADMIN_REPO}}`
  only (Guest role, short-lived). A project token can never see the other two
  repos by design, so `watch` does **not** rely on `glab` at all. Don't switch
  the helper to `glab` — it would break service and web.

## Workflow

1. **Pick the pipeline.** Default to the latest pipeline for the current branch.
   If the user names a commit, MR, or pipeline id, use that. A freshly pushed
   commit's pipeline can take ~30–60s to register — if none exists yet, wait and
   re-check rather than reporting "no pipeline".

2. **Run the helper in the background.** It sleeps between polls, so run it
   detached and let the harness re-invoke you when it exits:

   ```bash
   ~/.claude/skills/watch/scripts/watch-pipeline.sh            # current branch
   ~/.claude/skills/watch/scripts/watch-pipeline.sh <sha>      # a commit
   ~/.claude/skills/watch/scripts/watch-pipeline.sh <pipe_id>  # a pipeline
   ```

   Run it with `run_in_background: true`. Knobs (env vars): `POLL_SECONDS`
   (default 45 — keep polls under ~270s so the prompt cache stays warm),
   `MAX_POLLS` (default 120), `SCAN_ALL=1` (also scan jobs that passed, for a
   deeper look).

   The helper: resolves the pipeline → polls `GET /pipelines/:id` until a
   terminal state (`success|failed|canceled|skipped|manual`) → lists every job
   by stage with its `allow_failure` flag → fetches the trace of each **failed**
   job, strips ANSI/section noise, and greps for the failure/slog patterns
   below.

3. **Read the result and judge it.** The helper prints matched log lines with
   line numbers. Decide what's real:
   - **Blocking failure** — a job **without** `(allow_failure)` failed. This
     stops the pipeline at its stage; nothing after it ran. This is what breaks
     a deploy.
   - **Known non-blocking noise** — `gitleaks` and `helm-templates-check` run
     `allow_failure: true` on these repos. They can be red without blocking the
     deploy. Still read them (a real leak matters), but don't call the pipeline
     "failed" because of them.
   - **Stage order** (admin): `version → pre-flight → lint → audits → build →
     deploy`. A pipeline stops at the first failing stage, so an early red hides
     everything downstream.

4. **Report** (template below). If nothing runnable was found — e.g. the
   pipeline is still queued after the poll ceiling — say that plainly instead of
   implying a pass.

## What counts as a "weird slog" or failure

The helper flags these in job traces (case-insensitive). Treat them as leads,
not verdicts — read the surrounding lines:

- **Go / runtime:** `panic:`, `goroutine N [`, `runtime error`, `nil pointer`,
  `invalid memory address`, `fatal error`, `segmentation`, `killed`.
- **Structured logs:** `level=error`, `level=warn`, `"level":"error"` /
  `"warn"` — a warn/error slog line that shouldn't be there in a green run.
- **Process/exit:** `command terminated with exit code`, `Job failed`.
- **Deploy/k8s:** `OOMKilled`, `CrashLoopBackOff`, `ImagePullBackOff`,
  `context deadline exceeded`, `connection refused`, `no such host`,
  `i/o timeout`, `dial tcp`, `permission denied`.
- **Tooling:** `DL####` (hadolint), `leaks found` / `secret detected`
  (gitleaks), `npm ERR!`, `error TS####` / `tsc: error`,
  `UnhandledPromiseRejection`, `Error response from daemon`.

When a failed job has **no** pattern hit, the helper prints the tail of its log
so you still have something to read.

## Output template

Report like this — lead with the verdict:

```
Pipeline <id> on <repo> — <PASS ✅ | FAILED ❌ | non-blocking red ⚠️>
<web_url>

Blocking failures:
- <job> (<stage>): <one-line cause from the log>
    <the key log line(s)>

Non-blocking (allow_failure):
- <job>: <one-line cause>   ← safe to ignore unless it's a real leak

Deploy: {{STAGING_JOB}} <status>, prod <status/manual>
Next: <what to do — fix forward, click prod, or nothing>
```

Keep it short. Quote the actual log line that proves the cause; don't paraphrase.

## Examples

**Input:** "watch the pipeline" (just pushed to `{{ADMIN_REPO}}` main)
**Output:** Run the helper in the background for the current branch. On
completion: "Pipeline 161802 — PASS ✅. All blocking jobs green; `{{STAGING_JOB}}` deployed.
Two non-blocking reds (`gitleaks`, `helm-templates-check`) — the usual baseline,
`gitleaks` shows `WRN leaks found: 1` on a test fixture. Prod is manual, unclicked."

**Input:** "why did the build fail?"
**Output:** Resolve the latest failed pipeline, scan the failing job's trace,
and report the blocking job + the exact error line (e.g. `docker-lint`:
`DL3018 pin versions in apk add`), then the fix.

## Notes

- Read-only. This skill never triggers, retries, cancels, or clicks a job — it
  only reads pipeline state and logs. To re-run or deploy, that's the user's
  call (and `ship` covers the manual prod gate).
- For a still-empty pipeline right after a push, prefer waiting ~30–60s and
  re-resolving over reporting nothing.
- To watch a repo you're not `cd`'d into, `cd` there first (or pass a pipeline
  id) — project detection reads the current repo's `origin` remote.
