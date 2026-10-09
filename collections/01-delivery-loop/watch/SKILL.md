---
name: watch
description: >-
  Watches a CI run, pipeline or background task to its end, reports the
  verdict in plain words, and on a failure hands the evidence to the skill
  that owns the fix: /ultron-debug for a failing test, build or deploy,
  /recover when fixes keep failing, /ship for a one line fix forward,
  /ultron-test when a bug slipped past the suite. Covers GitHub Actions
  (through gh) and the GitLab {{PRODUCT}} pipelines (through the /ship watcher
  script). Read only while watching; it routes and never fixes. Use whenever
  the user wants a run followed or explained: "watch", "watch CI", "watch the
  pipeline", "keep an eye on the run", "did CI pass", "did the pipeline pass",
  "why did CI fail", "why did the pipeline fail", "tell me when it's done",
  "is the build green", or typing /watch. Not for pushing (/ship), not for
  fixing (/ultron-debug), not for deploy status of prod clicks (/ship).
---

# Watch

Follow one run to its end, say plainly whether it passed, and when it did not,
pass the failure to the skill that fixes that kind of failure. You are the
lookout, not the mechanic. Keeping those apart matters: a watcher that starts
patching code hides what failed and why, and the fix skipped the discipline
the owning skill brings.

## Workflow

### Step 1: find what to watch

Work out the target from the request and the session, in this order:

1. **An id the user gave**: a GitHub run id, a GitLab pipeline id, a commit
   sha, or a background task id from this session.
2. **A background task already running in this session** (for example a
   `gh run watch` that `/ship` started). Do not start a second watcher on the
   same run; wait for that task's notification.
3. **The current repo's HEAD commit.** Read the push URL:
   - `github.com` with `.github/workflows/` → GitHub Actions.
   - `{{GITLAB_HOST}}` with `.gitlab-ci.yml` → GitLab pipeline.
   - Neither → no CI here. Say so and stop. A push with no CI is not green.

### Step 2: watch it to the end

Run the watcher in the background (`run_in_background: true`). The harness
wakes you when it exits, so never poll with sleep loops in the foreground.
Tell the user in one line what you are watching and roughly how long it takes.

**GitHub Actions**

```bash
gh run list --commit <sha> --json databaseId,workflowName,status,conclusion,url
```

A fresh push can take up to a minute to show a run. Re list before you say
"no run".

```bash
gh run watch <run-id> --exit-status --interval 30 > /dev/null 2>&1; echo "exit $?"; gh run view <run-id>
```

**GitLab ({{PRODUCT}} repos)**

```bash
~/.claude/skills/ship/scripts/watch-pipeline.sh <sha|pipeline-id>
```

It polls to a final state, lists every job and pulls the failing logs. Its
token and project rules are in `/ship`; do not switch it to `glab`. When the
user asks about odd logs in a deploy that passed, run it with `SCAN_ALL=1` so
it also scans passing jobs for panics, error or warn lines and stack traces.

**A local background task**: wait for its notification, then read its output
file.

### Step 3: read the result

Pull the evidence before you judge anything:

```bash
gh run view <run-id>                 # every job and step, plus annotations
gh run view <run-id> --log-failed    # only the failing steps' logs
gh run list --branch <branch> --limit 5 --json conclusion,headSha,displayTitle
```

Find the first real error line, not the last line of the log. Then sort the
result into one row of the routing table below.

### Step 4: route

| What you see | Verdict | Hand to |
|---|---|---|
| Every job `success`, no warnings | Green | Nobody. Name the repo's next step (see Step 5) |
| Green, but a job carries a warning annotation | Green with a warning | Nobody. Quote the warning and what the repo's docs say it means |
| A test, typecheck, build or compile step failed | Red | `/ultron-debug` |
| A deploy job (SIT, worker, release) failed after the build passed | Red at deploy | `/ultron-debug` |
| The same job failed on 2 or more of the last runs on this branch, with fix commits between them | Red, fixes not converging | `/recover` |
| A one line cause the log names outright: a format or lint rule, an unpinned or missing package version, a typo in config | Red, trivial | `/ship` to fix forward |
| Red on something a test should have caught, now fixed by hand | Gap in the suite | `/ultron-test` |
| A secret scanner (gitleaks) found a real secret | Stop | Nobody. Tell the user at once; a leak is theirs to rotate |
| `cancelled` because a newer push superseded it | Not a failure | Watch the newer run instead |
| A job failed on infrastructure (runner lost, network timeout, rate limit) and passes on the code's merits elsewhere | Probably flaky | Ask before `gh run rerun <id> --failed`; a rerun spends CI minutes |
| No run, or a run that never started a job | Unknown, not green | Nobody. Say minutes may be used up or Actions may be off, and give the run page |

When the route names a skill, invoke it with the Skill tool and pass a short
brief as `args`:

```
<repo> <branch> @ <sha>, run <id> (<url>)
Failed: <job> → <step>
Error: <the first real error line, quoted>
Recent runs on this branch: <green/red pattern, newest first>
```

Ask first instead of invoking when the next step changes something outside the
repo: a rerun, a deploy, a publish, a rotation. Routing to a skill that edits
code is fine; that skill has its own checks.

### Step 5: report

Lead with the verdict. Keep it to what the user must know or do.

```
<repo> <sha>: <GREEN | GREEN with a warning | RED at <job> → <step> | NO RUN>
Run <id>: <url>
<one line: the error quoted, or the warning, or the job count and time>
Next: <handed to /skill | nothing | the repo's publish step and its condition | your call on a rerun>
```

On green, the next step comes from the repo's own docs, never from you
running it. For example node-companion's `docs/shipping.md` says to wait for
the green mark before `npm run ota`; name that, do not run it.

## Examples

**Input:** "/watch" right after `/ship` pushed `53625dc` to node-companion.
**Output:** finds run 37904895462 already watched by a background task, waits
for its notification, reads `gh run view`: three jobs success, no warning.
Reports "node-companion 53625dc: GREEN. Run 37904895462 … 3 jobs, 4 min 40 s.
Next: nothing; docs only, no OTA needed."

**Input:** "why did CI fail" in node-companion.
**Output:** `--log-failed` shows `Engine unit tests` with
`expected:<3> but was:<2>` in `PlaceDetectorTest`. The last 5 runs show this
is the first red. Routes to `/ultron-debug` with the brief, and reports
"RED at engine → Engine unit tests. Handed to /ultron-debug."

**Input:** "watch the pipeline" in {{ADMIN_REPO}}, third red in a row on
`build`, each after a fix commit.
**Output:** reports "RED at build, third time in a row after fixes", and
routes to `/recover` instead of `/ultron-debug`, because a fourth targeted
fix is the pattern `/recover` exists to break.

## Anti-patterns

- Editing code or config yourself. Hand it to the owning skill.
- Reporting "no run" or "no pipeline" in the first minute after a push.
- Calling a missing run green.
- Quoting the last log line instead of the first real error.
- Starting a second watcher on a run another background task already follows.
- Rerunning failed jobs, deploying or publishing without asking.
- Sending a third repeat failure to `/ultron-debug` instead of `/recover`.
