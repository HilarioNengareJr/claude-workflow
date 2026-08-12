---
name: eod
description: Produce an end-of-day report — a plain-English summary of what the
  developer worked on today, the API endpoints created or hit, the migrations
  created or run, the lessons from the day that transfer beyond this repo
  (including lessons about working with AI), and references for going deeper
  into the principles and choices behind the day's work. Use whenever the user
  wraps up a
  day and asks what happened: "eod", "end of day", "what did I work on today",
  "summarize my day", "daily summary", "wrap up the day", "tell me what we did
  today". Distinct from /save (writes memory.md for the next session) and
  /track (updates the repo progress tracker) — this skill's output is a report
  for the human, read in chat, not a state file.
---

# EOD Report

At the end of a working day, tell the developer what actually happened — in one readable report. The audience is the developer themselves (or a standup the next morning), so write it the way they'd say it out loud, not the way a changelog reads.

## Sources of truth

Pull from real evidence, not memory. In order:

1. **The current session conversation** — what was built, debugged, decided, and learned today. This is the richest source; the git log only shows what was committed.
2. **Today's git activity across the {{PRODUCT}} repos** — run for each sibling repo that exists (`{{WEB_REPO}}`, `{{SERVICE_REPO}}`, `{{ADMIN_REPO}}` under `~/{{WORKSPACE_ROOT}}/`):
   ```
   git log --all --since=midnight --oneline --author="$(git config user.email)"
   ```
   For each commit found, use `git show --stat` to see which files moved.
3. **`context/progress-tracker.md`** — if it exists, cross-check; the report and the tracker should not contradict each other.

If the session is fresh and the git log is empty, say so plainly: "No commits today and this session has no work in it — nothing to report." Do not invent a day.

## What to extract

**Endpoints created** — new routes added to a backend today. Look in the service repo's route/controller files touched by today's commits. Report method + path (`POST /checkout/unified`), one line on what each does.

**Endpoints hit** — endpoints the frontend started calling or changed calls to (look at `src/services/*` diffs), plus any endpoint exercised by hand during the session (curl, staging testing). Only endpoints touched *today* — not every call in the codebase.

**Migrations** — migration files created today, and migrations actually run (look for migration commands in the session, or new files in the service repo's migrations directory from today's commits). Name each file and say what it changes in the schema. If none, say "No migrations today" — don't drop the section silently, the user asks for it specifically.

**Transferable lessons** — the part that outlives the code. Two kinds, and both count:
- *Engineering lessons* that apply beyond this repo: a debugging approach that worked, a gotcha in a library, a pattern worth reusing.
- *AI-collaboration lessons*: what made this session with Claude effective or wasteful — a prompt shape that worked, a place where verifying the AI's output caught something, a task worth delegating vs. doing by hand next time.

A lesson is only a lesson if it changes what you do tomorrow. "Learned about the checkout flow" is not one; "server-side price calculation is authoritative and the client is only a fallback — always test the server path first" is.

**Go deeper — references** — the report is also a learning tool. For each principle or design choice that shaped the day's work, give the developer somewhere real to study it:
- Name the underlying principle behind a choice made today (e.g. "we mapped raw backend errors to friendly copy" → the principle is *error handling at the boundary / anti-corruption layer*).
- Point to 1–2 places to go deeper per principle: official docs for the library involved, a well-known article or book chapter, or the canonical name of the concept so it can be searched. Prefer stable, primary sources (MDN, official framework docs, well-known engineering books) over blog spam.
- Only cite things you're confident exist. If you know the concept but not a reliable URL, give the concept name and where to look ("search: 'parse, don't validate'") rather than inventing a link.
- Cap it at 3–4 references. This is a nudge to learn one thing properly, not a reading list that gets ignored.

## Output format

Deliver in chat. Keep the whole report readable in under a minute.

```markdown
# EOD — [date]

## What you worked on
[2–5 sentences, plain English. The story of the day, not a file list.]

## Endpoints
**Created:** [method + path — one line each, or "None"]
**Hit / integrated:** [method + path — one line each, or "None"]

## Migrations
[file name + what it changes, whether it was run, or "No migrations today"]

## Transferable lessons
- [lesson — stated so it's usable tomorrow, in any repo]
- [1–4 of these; quality over count]

## Go deeper
- **[Principle behind a choice made today]** — [doc/article/book, or "search: '<concept name>'"] — [half a line on why it's worth your time]
- [2–4 of these, tied to today's actual decisions — never generic]
```

After delivering, offer once (don't do it unprompted): "Want me to `/save save` and `/track` as well to close out the day?"

## Example

**Input:** "hey, eod — tell me what I worked on today"

**Output:** Reads the session (voucher checkout error-handling work), runs the git log sweep (finds `fix(checkout): show friendly error instead of raw backend body` in {{WEB_REPO}}, nothing in the service repo), then reports: the day's story in three sentences; Endpoints hit: `POST /checkout/unified` (new error-body parsing); Migrations: none today; Lessons: "Backend error bodies are not a UI contract — always map them to friendly copy at the boundary" and "Pasting the raw failing response into the chat got to the fix faster than describing it." Go deeper: "**Anti-corruption layer** — the DDD name for translating external contracts at the boundary; search: 'anti-corruption layer pattern'" and "**HTTP error design** — RFC 9457 (Problem Details for HTTP APIs), the standard your backend errors could follow."

## Anti-patterns

- Reporting from the conversation alone without running the git sweep — commits made in other sessions today get missed.
- Listing every endpoint the app calls instead of only the ones touched today.
- Padding the lessons section with restated facts about the codebase. If nothing transferable was learned, say "quiet day, no new lessons" — that's honest and fine.
- Filling "Go deeper" with generic reading ("Clean Code, chapter 1") unconnected to today's decisions, or inventing URLs. Every reference must trace back to a choice actually made today.
- Writing the report to a file or updating the tracker as part of this skill. Report first; `/save` and `/track` own persistence.
