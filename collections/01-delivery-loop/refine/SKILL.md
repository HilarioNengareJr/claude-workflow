---
name: refine
description: Take whatever rough text the user has written — a feature idea, a
  request, a bug complaint, a stakeholder ask — and refine it into a clear,
  unambiguous brief before any planning starts. Use whenever the input is
  fuzzy and the user wants it sharpened: "refine this", "tighten this up",
  "turn this into a proper brief", "clean up what I just wrote", "here's a
  rough idea", "make sense of this ask", or typing /refine. Also runs as the
  first stage of /cycle, before /architect. Distinct from /architect (which
  plans the implementation — it consumes the brief this skill produces),
  /digest (which extracts structure from a pasted multi-person conversation),
  and /explain (which explains existing code). This skill refines the user's
  own words into a brief; it never designs the solution.
---

# Refine

Planning quality is capped by the quality of the ask. A vague ask goes into
/architect and comes out as a confident plan for the wrong thing. This skill
sits before all of that: it takes what the user actually wrote and turns it
into a brief that says one thing, clearly, with its edges marked — while
keeping the intent exactly theirs.

The output is the user's ask, sharpened. Not a plan, not a design, not a
solution. The moment this skill starts proposing *how* to build something, it
has crossed into /architect's territory and must stop.

## Workflow

### 1. Read what was written, as written

Take the user's text seriously before improving it. Identify the core ask —
what would satisfy the person who wrote this? If the text bundles several asks
("fix the export and also the dashboard is slow and can we get emails"), split
them and say so: one brief per ask, and the user picks what's in play now.

### 2. Ground the words in the project

Read the relevant `context/` files: `context/project-overview.md` for
vocabulary, `context/progress-tracker.md` for what already exists or is in
flight, and `context/architecture.md` when the ask touches existing system
behaviour. The project has real names for things — use
them. If the user wrote "the vouchers thing", the brief says `promo_codes` /
voucher campaigns, whichever they actually mean. If a term is ambiguous in
this project, that's a question, not a guess.

### 3. Find the fog

Walk the text for the four kinds of vagueness that sink plans later:

- **Vague words** — "better", "faster", "cleaner", "like the other one",
  "handle properly". Each needs a concrete meaning or it stays fog.
- **Missing constraints** — deadline, audience, scale, which environment,
  which repo. Only the ones that change what gets planned.
- **Unstated scope** — what the user almost certainly does NOT mean but the
  text technically includes. Out-of-scope lines prevent gold-plating later.
- **Hidden assumptions** — things the text takes for granted that the project
  may not support ("just add a column" in a repo where DDL is firewalled).

### 4. Resolve it — propose, don't interrogate

For each fog item, propose a concrete reading and let the user react —
a proposal is faster to correct than a blank question. Ask an open question
only when the text and the project genuinely can't settle it. Keep the whole
exchange short; this is a sharpening pass, not a requirements workshop.

If the text is already clear, say exactly that — "this is already a solid
brief, nothing to refine" — and pass it through unchanged. Refining for the
sake of it wastes the user's time and teaches them to skip the step.

### 5. Produce the brief

```markdown
## Brief — [short name for the ask]

**What:** [one or two sentences, concrete, in project vocabulary]
**Why:** [the problem or goal behind it, one sentence]
**In scope:** [bullet list — what "done" includes]
**Out of scope:** [bullet list — near-misses explicitly excluded]
**Constraints:** [only the ones that shape the work: env, deadline, repo, scale]
**Done means:** [how the user will know it worked — observable, not vibes]
**Unresolved:** [anything left open on purpose, or "none"]
```

Present it and get the user's confirmation — the words are theirs; the brief
replaces the rough text as the input to whatever comes next (usually
/architect). Do not proceed past an unconfirmed brief.

## Example

**Input:** "refine this: the voucher sends need to handle the big campaigns
better, it dies when marketing does their thing"

**Output:** Reads context (bulk voucher send exists, 9k+ recipient campaigns,
async dispatch shipped), proposes the concrete reading — "better" = survives
marketing-scale sends end to end; "dies" = which failure, browser timeout or
send failures? User answers: send failures on bad numbers kill the whole
batch. Brief: **What:** bulk voucher send completes the batch even when
individual recipients fail; failed recipients are reported, not fatal.
**Out of scope:** changing mint behavior, new campaign types. **Done means:**
a 9k send with 50 bad numbers finishes with 8,950 sent and 50 listed failures.
User confirms; the brief goes to /architect.

## Anti-patterns

- **Solutioning.** "Add a retry queue" is /architect's call, not the brief's.
  The brief says what must be true, not how to make it true.
- **Scope inflation.** The refined version must ask for the same thing the
  rough version did — sharper, never bigger.
- **The requirements workshop.** Twenty questions for a two-line ask. Propose
  readings; ask only what you can't propose.
- **Refining the already-clear.** Pass it through and say so.
- **Losing the user's voice.** If they call it "the {{ITEM}} store", the brief
  can too — project vocabulary where precision matters, their words elsewhere.
