---
name: standup
description: Start-of-day brief for the {{PRODUCT}} work — pulls where you left off
  (memory.md), the state of the three {{REPO_PREFIX}} repos (yesterday's commits,
  pipeline and deploy status on main), your GitLab todos and open beads, and
  hands back a short prioritized plan for the day. Use whenever the user opens
  a day and wants their bearings: "standup", "morning brief", "start my day",
  "what's on today", "where did we leave off", "what should I work on",
  "catch me up", or typing /standup. Distinct from /eod (the evening report of
  what happened) and /remember (which restores full session context — offer it
  after the brief); this skill is the morning snapshot plus a plan.
---

# Standup

Give the developer their bearings in under a minute of reading: where yesterday
ended, what state the repos woke up in, what's queued on them, and the two or
three things today should be about. Everything in the brief comes from real
evidence — files, git, GitLab, beads — never from memory of past sessions.

This skill is **read-only**. It changes nothing: no tracker edits, no bead
updates, no commits. It reports and proposes; the developer disposes.

## Sources — gather in this order

Run the gathering in parallel where possible; none of it depends on the rest.

1. **Where you left off** — read `~/{{WORKSPACE_ROOT}}/memory.md` (the `/remember` session
   handoff) and `~/{{WORKSPACE_ROOT}}/context/progress-tracker.md` (the system view: phase,
   last completed, next). If the session is scoped to one repo, read that
   repo's own `context/progress-tracker.md` too.
2. **Yesterday's actual work** — for each of `{{WEB_REPO}}`,
   `{{SERVICE_REPO}}`, `{{ADMIN_REPO}}` under `~/{{WORKSPACE_ROOT}}/`:
   ```bash
   git log --oneline --since="yesterday.midnight" --author="$(git config user.email)"
   ```
   Commits are what really happened; the tracker is what someone remembered to
   write down. When they disagree, say so.
3. **Repo state on main** — via the gitlab MCP, `list_commit_statuses` with
   `ref: "main"` for each of `{{GITLAB_GROUP}}/{{WEB_REPO}}`, `{{GITLAB_GROUP}}/{{SERVICE_REPO}}`,
   `{{GITLAB_GROUP}}/{{ADMIN_REPO}}`. Report per repo: pipeline green/red, `{{STAGING_JOB}}` deploy
   status, and whether a `prod` manual job is sitting unclicked (pushed ≠ live
   — an unclicked prod job is exactly the kind of thing a morning brief must
   surface).
4. **Your queue** — gitlab MCP `list_todos` and `my_issues`; and beads in
   `{{ADMIN_REPO}}` (the only repo with `.beads/`): `bd ready` for open
   unblocked work, `bd list --status in_progress` for anything half-done.

If a source is unavailable (MCP down, no memory.md), name the gap in the brief
rather than silently thinning it — a brief that looks complete but isn't is
worse than one with a hole labelled.

## Build the plan

The plan is the point; the rest is context. Propose **at most three items**,
ordered, each traceable to a source:

1. Anything **broken or blocking** first — a red pipeline on main, a blocked
   bead, an in-progress item that stalled.
2. Then the tracker's stated **Next**.
3. Then the top of the queue (todos / ready beads) if room remains.

Don't invent work. If the sources give fewer than three items, a short plan is
the correct plan.

## Output format

```markdown
# Standup — [date]

## Where you left off
[2–3 sentences from memory.md + tracker. Note any tracker/git disagreement.]

## Repo state
- **web:** pipeline [green/red], {{STAGING_JOB}} [deployed/failed], prod [live/unclicked]
- **service:** …
- **admin:** …
[Only note commits since yesterday if there were any.]

## Your queue
- [GitLab todos / issues — one line each, or "empty"]
- [Beads: in-progress and ready — one line each]

## Today (proposed)
1. [item — why it's first, and its source]
2. [item]
3. [item]
```

Close with one offer, not an action: "Want me to `/remember restore` for full
context, or `/cd` into the repo for item 1?"

## Example

**Input:** "standup"

**Output:** Reads memory.md (voucher redemption fix was mid-flight), tracker
(Next: Stitch webhook signature), git (one commit landed in service yesterday),
GitLab (service pipeline green but prod job unclicked; two todos), beads (one
in-progress). Brief reports all of it and proposes: 1. click/verify the service
prod deploy (pushed but not live), 2. finish the in-progress voucher bead,
3. start the Stitch webhook signature work per the tracker.

## Anti-patterns

- Writing the brief from conversation memory without running the git sweep and
  MCP calls — the whole value is that it reflects this morning's reality.
- A ten-item plan. Three, ordered, or fewer.
- Editing the tracker or beads "while you're in there" — this skill is
  read-only; `/track` and `/ship` own those.
- Padding a quiet morning. "Everything green, queue empty, tracker says X is
  next" is a complete and useful brief.