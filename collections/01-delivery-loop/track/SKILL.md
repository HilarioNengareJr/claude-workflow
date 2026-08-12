---
name: track
description: Update context/progress-tracker.md after a feature is built, shipped, or meaningfully changed — this skill is the single owner of keeping that tracker current. Use it whenever a unit of work completes or its state changes: "update the tracker", "update progress", "log this", "the tracker is stale", "mark X done", "record what we just built", "what's the status", or right after /build, /inspect, or /ship finish. Distinct from /save (which writes the session-handoff memory.md) — this skill maintains the durable, repo-level project tracker. NOT for the storefront's /track order-lookup route.
---

# Track

Keep `context/progress-tracker.md` true. Any agent or teammate opening that file should instantly know what is done, what is in progress, what is blocked, and what is next — without reading the chat or the git log. The tracker only changes when something edits it; there is no automation. This skill is that something, and it is the designated owner: after every completed feature or state change, bring the tracker current.

The tracker is gitignored (it lives under `context/`), so it never shows in `git status` or commits. "It didn't update" almost always means no one ran this skill, not that a write failed.

## When to run

Run this the moment a unit of work changes state — not in a batch at the end of the day:

- A feature is built, verified, or shipped (pairs naturally with the end of `/build`, `/inspect`, `/ship`).
- Something becomes blocked, unblocked, or hands off to another person/team.
- A decision is made that future work depends on.
- The user says the tracker is stale or asks for the project status.

## Workflow

### 1. Read the current tracker first

Open `context/progress-tracker.md` and read it whole. You are editing in place, not rewriting from scratch — preserve the structure, the existing entries, and the voice. If the file does not exist, create it from the template below.

### 2. Establish what actually changed

Pull the truth from the work, not from memory. Check the real state before writing:

- `git log --oneline -5` and `git branch --show-current` — what landed and where.
- The build/lint/test result if a feature was just built.
- Any blocker, decision, or hand-off raised in the conversation.

Write what is verifiably true. "Shipped" means pushed; "done" means verified. If a step was skipped or a check failed, say so — a tracker that overstates progress is worse than none.

### 3. Update the four moving parts

Edit these in place:

1. **Current Status block** — refresh `Phase`, `Branch`, `In progress`, `Last completed`, `Next`. These are always present-tense and reflect *right now*. Convert relative dates to absolute (e.g. "today" → `2026-06-16`).
2. **Progress sections** — tick the checkbox for what finished (`[ ]` → `[x]`), add a line for new work, and mark blocked items plainly with the blocker and its owner.
3. **Decisions Made During Build** — append any decision future work depends on, one line, with the why and who made the call. Do not restate decisions already there.
4. **Notes** — only durable, non-obvious context. Not a changelog.

Keep entries terse and scannable. Date significant changes. Link a blocker to the person who owns it so the next session knows who to chase.

### 4. Confirm

Tell the user what you changed in the tracker, in two or three lines — which status fields moved and what was ticked or added. Do not paste the whole file back.

## Template (when the file does not exist)

```markdown
# Progress Tracker

Update this file after every completed feature. Any agent reading this should immediately know what is done, what is in progress, and what is next.

---

## Current Status

**Phase:** [e.g. Live in production — campaign work in progress]
**Branch:** `branch-name` (off `main`) — one-line scope
**In progress:** [the one thing being built now]
**Last completed:** [most recent finished work + date]
**Next:** [the specific next action]

---

## Progress

### [Feature / area name] ([month year], branch `x`) — [BUILT/SHIPPED date]
- [x] done item
- [ ] open item — **blocked**: reason + owner

---

## Decisions Made During Build

- [decision, stated plainly] — why, and who made the call

---

## Notes

- [durable, non-obvious context only]
```

## Examples

**Input:** "we just pushed the copy change, the tracker is stale"

**Output:** Reads the tracker, checks `git log` (sees the copy commit on the feature branch), then updates `Last completed` to the copy change with today's date, ticks the matching Progress item, and confirms: "Tracker updated — Last completed now points at the home-copy push (`664b329`); ticked the copy line under the campaign section; In progress/Next unchanged."

**Input:** "/build just finished the Laduuuma tiles"

**Output:** Moves the tiles work from `In progress` to `Last completed`, ticks the Progress checkboxes for what was built, records the direct-purchase decision under Decisions, and notes the SKU blocker with its owner under the relevant section.

## Anti-patterns

- Appending a running log instead of editing the Current Status block in place — the top of the file must always read as *now*, not as history.
- Marking something done that was only built but not verified, or "shipped" that was only committed but not pushed.
- Dumping implementation detail visible in the code — capture state and decisions, not a diff.
- Pasting the whole tracker back to the user — confirm the delta only.
