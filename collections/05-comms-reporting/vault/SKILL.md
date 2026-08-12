---
name: vault
description: Write notes, documentation, and backlog items into the personal
  Obsidian vault through the obsidian MCP server, in plain-English,
  straight-to-the-point prose organised for someone with ADHD to scan in
  seconds and still understand in ten years. Use whenever the user wants
  something captured, documented, or filed permanently: "document this", "put
  this in my vault", "write this up", "save this to Obsidian", "note this
  down", "add this to my backlog", "make a doc for this endpoint", "capture
  what we just learned", "file this", "what do I have on X", "find my notes
  about X", or typing /vault. Also the destination for other skills' output —
  /eod, /digest, and /client produce reports in chat; this skill is what makes
  them permanent. Distinct from /track (writes a repo's
  context/progress-tracker.md) and /remember (writes session-handoff memory) —
  those are working state, this is the durable personal knowledge base. Also
  owns CTO-grade system documentation — trigger on "record this decision",
  "ADR", "architecture decision", "tech debt register", "log this debt",
  "roadmap", "runbook", "handover doc", "document this like a CTO", "could
  someone run this without me": decisions, debt, roadmap and runbooks live as
  running files in the relevant Area, private by default, with a tokenized
  portfolio export only on explicit request.
---

# Vault

Write into the user's Obsidian vault so that the version of them who has
forgotten everything can pick a note up in ten years and get the experience
back out of it.

The vault is at `~/Documents/Obsidian Vault`. Reach it through the `obsidian`
MCP server, not the filesystem — the MCP server is the supported path and
keeps the running app in sync.

## Core principle

**Write down the part that cannot be recovered.**

In ten years the code will still be in the repo. The endpoint path, the schema,
the config value — all re-readable. What disappears is the reasoning: what was
tried, what broke, what constraint forced the decision, what the alternative
was and why it lost.

That reasoning is the whole reason to keep a vault. A note that only restates
what the code says is worth nothing. A note that says *"we used a ticker
instead of checking on the send path because exposure moves even when nobody
sends anything"* is worth the ten years.

So for anything non-trivial, capture:

- **What it is** — one line, plainly.
- **Why it is like that** — the constraint, the failure, the tradeoff.
- **What it cost** — what broke on the way, what you would do differently.

## Writing rules

These are the point of the skill. The user has ADHD; a wall of text is a note
that never gets re-read, which makes it the same as no note at all.

1. **Answer first.** The first line after the title states what the thing is or
   what was decided. No preamble, no "this document covers".
2. **One idea per line.** Break the paragraph.
3. **Bold what you would scan for.** The decision, the number, the gotcha.
4. **Use a table** whenever there are three or more parallel facts. Fields,
   statuses, options, endpoints — all tables.
5. **A heading roughly every ten lines.** If a section runs past one screen,
   it is two sections.
6. **Delete any sentence that survives deletion.** If the meaning holds without
   it, it was filler.
7. **Plain words for the prose, exact words for the tech.** "use" not
   "utilize", "start" not "initiate". But never soften a technical fact —
   an endpoint path, a status code, a column name, an error string is
   reproduced exactly. Make the sentence *around* it readable instead.
8. **Absolute dates only.** `2026-07-22`, never "yesterday" or "last week".
   Relative dates rot the moment you walk away.
9. **Name things in full the first time.** `POST /api/v1/send-bulk-notification-campaigns`,
   not "the bulk endpoint". Future-you does not know which one you meant.
10. **No hype.** If something is broken, unfinished, or a guess, the note says
    so. A note that oversells is worse than no note, because it is trusted.

## Filing: the PARA rule

The vault uses PARA. The one weakness of PARA is hesitating between Areas and
Resources, so apply this in order and stop at the first yes:

| Ask | Yes → |
|---|---|
| Does it have a finish line? | `01 Projects/` |
| Are you responsible for keeping this up, ongoing? | `02 Areas/` |
| Is it just useful to know? | `03 Resources/` |
| Is it over? | `04 Archive/` |

The Area-vs-Resource tiebreak: **would someone be let down if you stopped
maintaining it?** If yes, Area. If nobody is counting on it, Resource.

If the answer is not obvious within about five seconds, write to `00 Inbox/`
and say so. An unfiled note is fine. A note you stalled on is not.

**Never delete to "clean up".** Finished work moves to `04 Archive/` with its
folder name and dates intact.

## Work content stays off GitHub

**The vault is a public GitHub repo. {{COMPANY}} work belongs on GitLab, which is
VPN-protected. GitHub is personal.**

So anything about {{COMPANY}} — the {{WORKSPACE_ROOT}} platform, its endpoints, prod findings,
customer data, campaign logic, internal hostnames, colleagues' decisions —
gets filed under a gitignored path:

| Content | Path |
|---|---|
| Anything {{COMPANY}} / {{WORKSPACE_ROOT}} | `02 Areas/{{WORKSPACE_ROOT}}/` |
| Other work, same rule | `02 Areas/{{COMPANY}}/` or any `_private/` folder |

These are ignored by git, so the notes live on this machine and stay
searchable and linkable — they just never reach GitHub.

**When in doubt, treat it as work.** A personal note filed in the work area
costs nothing. A work note filed in public costs a lot, and git history means
deleting it later does not undo it.

State in your reply when a note went to a gitignored path, so the user knows
it will not appear on GitHub.

## Filenames

| Type | Pattern | Example |
|---|---|---|
| note, doc, backlog | `Descriptive Title.md` | `Bulk Voucher Send Endpoint.md` |
| log (dated entries) | `YYYY-MM-DD what it was.md` | `2026-07-22 obsidian mcp wiring.md` |

Topic notes are found by searching, so they get real titles. Log entries are
found by *when*, so they get the date in front and sort themselves.

## Backlogs

**One running file per project or area — never one note per item.** Fifty
backlog notes is a graveyard nobody opens.

Write to `_backlog.md` inside the relevant Project or Area folder. The
underscore floats it to the top of the folder.

```markdown
## Now
- [ ] The one thing being worked on

## Next
- [ ] Ordered. Top of the list is what happens after Now.

## Someday
- [ ] Unordered. No guilt attached to this section.

## Done
- [x] 2026-07-22 — what it was, one line
```

Move items down, never delete them. The Done section is the record of what the
period actually contained.

## CTO mode — document the system, not just the code

The bar for every system doc is the **handover test**: if you left tomorrow,
could someone run this from the note alone? A note that fails the test is a
diary entry, not documentation.

CTO docs are **running files per Area or Project**, same pattern as
`_backlog.md` — never one note per decision. Four artifacts:

| File | Holds | Entry shape |
|---|---|---|
| `_decisions.md` | Architecture decision records, newest first | date, decision in bold, context, options that lost and why, cost accepted, revisit-when |
| `_debt.md` | Tech debt register | what, severity, interest being paid now, cost to fix, dated Done when paid |
| `_roadmap.md` | Direction: Now / Next / Later | outcomes with a why — not tasks (tasks live in `_backlog.md`) |
| `Runbook — <system>.md` | How to actually run it | start/deploy/verify commands, where secrets live (pointers, never values), failure playbook, the ops rhythm |

### Decision entry template

```markdown
## 2026-08-04 — **Seed products inactive at price 0, activate only after sync**
Context: checkout ignores is_active and completes 0-total orders as free.
Options: seed priced (loses the price check) · hand-set offering ids (skips verification).
Chose the ordering invariant because nothing may be both buyable and priceless.
Cost: products are invisible until two external fixes land.
Revisit when: checkout gains a price>0 guard.
```

Rules that keep these honest:

- **Record the decision the day it happens.** A reconstructed ADR is a guess
  with a date on it.
- **Debt gets an interest line.** "We pay 15 min per deploy" is a register;
  "code is messy" is a mood.
- **If a repo already tracks debt (e.g. beads), don't duplicate it** — the
  register holds cross-repo debt and the *reasoning*, and links the tracker id.
- **Roadmap entries are falsifiable outcomes** ("customers can buy VISI
  {{PRODUCT}}"), not activities ("work on VISI").

### Portfolio export — on request only

All CTO docs live in the private work area (`02 Areas/{{WORKSPACE_ROOT}}/` etc.) like all
work content — the GitHub rule above is not relaxed for them. When the user
explicitly asks for a portfolio piece, produce a **tokenized copy** into
`03 Resources/portfolio/`: replace hostnames, company and colleague names,
internal paths, and every real value with `{{placeholders}}` — sweep by
category, then grep the copy for each real value and expect zero hits. The
reasoning and structure are the portfolio; the specifics were never the
valuable part.

## Workflow

### 1. Search before writing

Always check whether a note on this already exists:

- `search_simple` — plain text across the vault
- `vault_list` — what is in a folder
- `vault_get_document_map` — structure of a big note

**One good note beats five fragments.** If a related note exists, extend it
with `vault_append` or `vault_patch` rather than creating a near-duplicate.
Say which you did and why.

### 2. Decide the type and the folder

Type is one of `note`, `doc`, `backlog`, `log`. Apply the PARA table above for
the folder. If you had to guess, say so in your reply — do not hide it.

### 3. Write it

Use the template below. Fill only the sections that have real content; delete
the rest. An empty heading is noise.

### 4. Write to the vault

`vault_write` for a new note, `vault_append` to add to the end of an existing
one, `vault_patch` to change a specific section.

**Folders are created automatically** by writing to a nested path — there is
no mkdir tool and none is needed. Writing `01 Projects/{{PRODUCT}}/notes.md` creates
both folders.

### 5. Confirm

Report the exact path written and the type. One line. If it went to
`00 Inbox/`, say what would help you file it properly next time.

## Note template

```markdown
---
created: YYYY-MM-DD
type: note | doc | backlog | log
tags: [lowercase, hyphenated]
status: active | done | archived
---

# Title

**One line saying what this is.** Then stop.

## What it does
Plain English. Two or three lines at most.

## Why it is like this
The constraint, the tradeoff, the thing that broke. This is the section that
matters in ten years — do not skip it to save time.

## Details
Tables, endpoints, code. Exact and technical.

## Gotchas
What will bite. What you got wrong the first time.

## See also
[[Other Note]]
```

## Documenting an endpoint

When the subject is an API, the Details section takes this shape. Keep it
exact — this is reference material, not prose.

```markdown
## `POST /api/v1/example`

What it does, in one line.

**Request**

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes | Max 255 chars |

**Responses**

| Code | Means |
|---|---|
| `200` | Done |
| `422` | Failed validation — body says which field |

**Failure modes**
- What happens when it is called twice.
- What happens when a dependency is down.
```

## Linking

Link with `[[Note Title]]` whenever another note is relevant. A link to a note
that does not exist yet is fine — it marks something worth writing, and
Obsidian will show it as a gap.

Linking is what turns a folder of files into something you can actually
navigate in ten years. Link generously.

## Examples

**Input:** "document the bulk voucher send endpoint"
**Output:** Searches the vault, finds nothing. Files
`02 Areas/{{WORKSPACE_ROOT}}/Bulk Voucher Send Endpoint.md` (an Area — the platform is an
ongoing responsibility). Type `doc`. Leads with what the endpoint does in one
line, then the request/response tables, then a "Why it is like this" section
covering the three-step mint-then-send order and what happens when a channel
is invalid. Reports the path.

**Input:** "add 'fix the promo race condition' to my backlog"
**Output:** Appends one line to the `## Next` section of
`02 Areas/{{WORKSPACE_ROOT}}/_backlog.md` via `vault_patch`. Does not create a new note.
Reports where it went.

**Input:** "what do I have on NFC?"
**Output:** Runs `search_simple` for NFC, reports the matching notes with a
one-line summary of each. Writes nothing.

**Input:** "record the decision we just made about the voucher budget"
**Output:** Appends a dated entry to `02 Areas/{{WORKSPACE_ROOT}}/_decisions.md` (creating
it on first use): the decision in bold, the constraint that forced it, the
options that lost, the accepted cost, and a revisit-when line. Does not create
a standalone note. Reports the path and that it is on a gitignored path.

**Input:** "save today's EOD"
**Output:** Takes the `/eod` report from the conversation, files it as
`02 Areas/{{WORKSPACE_ROOT}}/log/2026-07-22 eod.md` with type `log`. Keeps the lessons
section — that is the part with ten-year value — and cuts the ceremony.

## Anti-patterns

- **Restating the code.** If the note only says what a reader could get from
  the repo, it is not worth keeping. Add the why.
- **A new note when one exists.** Search first. Fragments are how a vault dies.
- **One note per backlog item.** Use the running `_backlog.md`.
- **Simplifying a technical fact to make it read nicely.** Simplify the
  sentence, never the fact.
- **Relative dates.** "Last Tuesday" is meaningless on re-read.
- **Long unbroken prose.** If it does not survive a scan, it will not be read.
- **Filing by writing to disk directly.** Use the MCP server so the running
  app stays in sync.
- **A decision log written after the fact.** ADRs are recorded the day the
  decision happens or they are fiction.
- **A runbook that fails the handover test.** If it needs its author in the
  room, it is not a runbook yet — name the gap in the note itself.
- **Portfolio-exporting by copy-paste.** Every export goes through the
  tokenize-and-grep sweep; one leaked hostname in git history is permanent.

## If the MCP server is down

Symptom: the obsidian tools fail or are missing.

**Obsidian must be running** — the MCP server lives inside the app and dies
with it. Then check the Local REST API plugin's non-encrypted HTTP server
toggle is still on (port 27123; the HTTPS port fails Node's certificate
check). Tell the user which of the two it was rather than falling back to
writing files directly.
