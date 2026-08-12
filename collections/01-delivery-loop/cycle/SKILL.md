---
name: cycle
description: Run the full feature-delivery loop as one command — chains /refine
  → /architect → /build → /review → /break → /ship → /watch → /track in order,
  auto-advancing when a stage passes clean and pausing only at the gates each
  stage reserves for a human decision. Use whenever the user wants a feature
  taken end to end: "cycle this", "run the full cycle", "take this feature
  start to finish", "build and ship this end to end", "full delivery loop on
  X", or typing /cycle. Also use to resume a loop mid-chain ("cycle from
  review", "pick up the cycle at ship"). NOT for a single stage — "build this"
  is /build, "review this" is /review, "ship it" is /ship; reach for /cycle
  only when the user wants the whole chain or a resumed chain.
---

# Cycle

One command, the whole delivery loop. `/cycle` takes a rough feature ask and
runs it through the existing skills in order: refine the ask, plan it, build
it, review it, stress-test it, ship it, watch the pipeline, update the
tracker. Each stage is its own skill and stays the authority on how that stage
works — this skill owns only the **sequencing, the handoffs, and the decision
of when to pause**.

The contract with the developer: **auto-advance on a clean pass, stop at every
gate a stage reserves for a human.** Never invent a new gate, and never skip one
a stage defines. The loop should feel like a senior engineer driving the work
and tapping you on the shoulder only when the call is genuinely yours.

## Core principle

This skill duplicates nothing. Every stage runs by invoking its skill via the
Skill tool, and that skill's own SKILL.md governs how the stage behaves. If
`/cycle` ever needs to describe *how* to refine or *how* to ship, something is
wrong — it only decides *when* each stage runs, *what carries forward*, and
*whether to pause*.

## Pre-flight

Before starting the chain:

1. **Confirm the working repo.** The chain needs one repo in focus. If the
   session isn't scoped to one (via `/cd` or by sitting inside it), ask which
   repo, or run `/cd` first. Don't start a cycle straddling repos.
2. **Confirm there's something to cycle.** Whatever the user wrote — rough or
   polished — is the input to `/refine`. If they typed bare `/cycle` with
   nothing in context, ask what the feature is — that's a real gap, not a
   formality.
3. **Lay the chain out as todos** (TodoWrite), one per stage, so the developer
   can see where the loop is at any moment. Update each as stages complete —
   if the session dies mid-cycle, the todos plus the progress tracker say where
   to resume.

## The chain

Run the stages in this order. For each: invoke the skill, let it finish, apply
the gate rule, carry its output into the next stage.

### 1. `/refine` — sharpen the ask

Invoke with whatever the user wrote. The skill grounds the words in the
project's vocabulary, burns off the fog (vague words, bundled asks, unstated
scope), and produces a confirmed brief.

**Gate — the brief confirmation.** The refined brief replaces the rough text
as the input to everything downstream, so the user must own its words. If the
ask was already crisp, `/refine` says so and passes it through — that
confirmation can be a one-liner, not a ceremony.

### 2. `/architect` — plan

Invoke with the confirmed brief. The skill aligns language, surfaces
decisions, and writes the plan to `context/architecture.md`.

**Gate — always pause.** `/architect` ends by asking the developer to confirm
the plan. That confirmation is the developer's, never yours. Do not advance to
build on an unconfirmed plan.

### 3. `/build` — implement

Invoke once the plan is confirmed. The skill grounds the plan in the codebase,
sequences the edits, builds, and verifies.

**Gates — as the skill defines them.** Two live inside `/build`: it surfaces
plan-vs-codebase conflicts (pause only if it finds any), and it says
`Ready to build.` and waits for an explicit go. Honour both. When the build
report lands clean, advance.

### 4. `/review` — verify against the plan

Invoke on the finished build. Three layers: plan alignment, system integrity,
production readiness.

**Gate — only on issues.** All three layers PASS → advance without asking; a
clean report *is* the developer's green light in a cycle. Any issue found →
stop and put the choice to the developer: fix it (loop back — see "Loops"),
accept it as intentional, or stop the cycle. **Critical-severity issues never
auto-advance**, even if the developer is in a hurry — say why.

### 5. `/break` — stress-test

Invoke on the reviewed feature. Adversarial edge-case matrix, executed, with an
honest report.

**Gate — only on issues.** Verdict "ship it" with no found issues → advance.
Found issues → stop; the developer decides fix / accept / stop, exactly as the
`/break` report intends. If they accept a known issue and ship anyway, it must
be logged as a bead in the ship stage — carry that forward explicitly.

### 6. `/ship` — commit and push

**Gate — always pause, before invoking.** Pushing to `main` auto-deploys staging;
that is an outward-facing action and always the developer's call. Present a
one-paragraph ship summary (what's going out, QA-gate status, beads to close or
create — including any accepted issues from review/break) and get an explicit
go. Then invoke `/ship`, which owns the QA gate, beads, commit message, and
push.

### 7. `/watch` — follow the pipeline

Invoke right after the push, in the background. No gate on a green pipeline —
report the pass and advance. On a blocking failure, stop: report the failing
job and the real log line, and offer the fix-forward loop (below). Non-blocking
reds (`gitleaks`, `helm-templates-check`) are reported but don't pause the
chain.

### 8. `/track` — record it

Invoke unconditionally — no gate. The tracker must tell the truth about what
just happened, including a failed pipeline or a cycle stopped partway.

### 9. Close

Summarize the cycle in a few lines: what shipped, what was accepted as debt
(with bead IDs), pipeline status. Then offer once — don't run it unprompted:
"Wrapping up the day? I can run `/eod`." `/eod` is a day-level report, not a
feature-level stage, so it's an offer, not a link in the chain.

## Loops — when a stage sends work back

- **Review or break found issues and the developer says fix them:** loop back
  into the build stage scoped to *those fixes only* (no re-planning, no
  gold-plating), then re-run **only the stage that failed** — a review fix
  re-runs `/review`, a break fix re-runs `/break`. Don't restart the whole
  chain; don't skip the re-check either.
- **Pipeline failed after the push:** the commit is already on `main`, so fix
  forward — a scoped build fix, a new commit via `/ship`, then `/watch` again.
  Never rewrite pushed history (that's `/ship` law).
- **Something is badly wrong** — the build went sideways, fixes are compounding,
  the diagnosis is unclear: stop looping and suggest `/recover` before another
  attempt. Repeated blind retries are how a small failure becomes a big one.

## Entry points and trimming

- `/cycle <feature>` — the full chain from the rough ask.
- `/cycle from <stage>` — resume mid-chain (e.g. "cycle from review" when the
  build already exists). Verify the earlier stages' artifacts exist — a
  confirmed brief, a plan in `context/architecture.md`, a build report —
  before trusting them.
- **Skipping a stage is the developer's call, never yours.** If they say "cycle
  this but skip break" for a trivial change, honour it and note the skip in the
  ship summary and the tracker. Never quietly drop a stage because it seems
  small.

## Examples

**Input:** "/cycle the product page should show stock per store somehow"

**Output:** Todos laid out for all eight stages → `/refine` turns the rough
ask into a confirmed brief (per-store stock badge, storefront product page,
out of scope: admin changes) → `/architect` runs on the brief, plan confirmed
by the developer → `/build` grounds it, gets its go, builds clean → `/review`
all-PASS, auto-advances → `/break` finds one medium issue (stale badge on
offline cache); developer says fix it → scoped build fix → `/break` re-run
passes → ship summary presented, developer says go → `/ship` pushes, bead
closed → `/watch` reports pipeline green, staging deployed → `/track` updates the
tracker → close-out summary + one-time `/eod` offer.

**Input:** "cycle from ship — review and break already passed this morning"

**Output:** Confirms the build report and clean review/break results exist in
the session or tracker, presents the ship summary, gates on the go, then runs
ship → watch → track as normal.

## Anti-patterns

- **Re-implementing a stage inline** instead of invoking its skill — the moment
  `/cycle` "just quickly refines" or "just quickly reviews" something itself,
  there are two standards for that stage in the project.
- **Inventing gates.** Pausing after a clean review "just to check in" trains
  the developer to ignore gates. Clean pass → advance.
- **Skipping gates.** Auto-confirming the brief or the plan, auto-going at
  "Ready to build.", or pushing to `main` without the explicit go — never,
  regardless of how obvious the answer seems.
- **Restarting the whole chain on a single failed stage** — loop back scoped,
  re-run only what failed.
- **Letting accepted issues evaporate.** An issue the developer accepted at
  review or break must surface again as a bead at ship — that's the deal that
  made accepting it safe.
- **Running `/eod` as a stage.** It's a day report; offer it once at close.
