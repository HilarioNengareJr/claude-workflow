---
name: research
description: Research a question or topic properly — search the web, read the
  real sources, verify every key claim, simplify the findings into plain
  English, and compile them into a dated markdown doc in ~/Desktop/research/
  with a ready-to-send stakeholder answer, numbered references, and
  step-by-step how-to sections. Use whenever the user wants something
  researched, looked into, or fact-found, even phrased casually — "research X",
  "look into X", "find out if/whether X", "is X possible yet", "do the homework
  on X", "what's the state of X", "can X integrate with Y", "compare X and Y",
  or typing /research. Also use to re-check an old topic ("has anything changed
  on X") — reruns diff against the previous doc. NOT for explaining code in
  this repo (/explain), digesting a pasted conversation (/digest), or querying
  internal databases (/db, /stagingdb, /warehouse).
---

# Research

Answer a real question with real, verified sources, then write it up so a busy person gets the answer in the first paragraph and can go as deep as they want after that. Every run produces a doc in `~/Desktop/research/` that stands on its own — plus a ready-to-send reply for whoever asked, because the message is usually the real deliverable and the doc is the evidence behind it.

## Core principle

Research goes wrong not by missing sources but by confidently repeating one source's claim that turns out to be stale, region-limited, or misread. So: never answer from memory alone, verify the claims that matter before they enter the doc, and label what's shipped versus merely announced. The write-up is plain English — the reader may be a CEO with five minutes, not an engineer.

## Workflow

### Step 1: Pin down the question — and the question behind it

Extract from the conversation:

- The actual question(s). A vague ask ("check out Microsoft and AI") hides several concrete questions — split them out and list them at the top of the doc.
- **The decision this informs.** "Is X integrating with Y?" is rarely trivia — it's usually "can we use this / should we build on it?" State the decision in one line; it shapes what evidence matters and feeds the "So what for us" section.
- Who the answer is for (the user, or a stakeholder they'll forward it to). Default to non-technical.
- The deadline, if stated.

If the question is genuinely ambiguous, ask one clarifying question. Otherwise state your interpretation in the doc and proceed.

**Scale the effort to the stakes.** A "quick homework, 5 minutes" ask gets a light pass: fewer sources, verification only on the headline claim. An answer that will be forwarded, bet on, or spent against gets the full treatment below. Say in the doc which depth was applied.

### Step 2: Check the ledger

Read `~/Desktop/research/index.md` if it exists. If this topic (or a close cousin) was researched before, this run is a **rerun**: read the old doc, research what's current, and make the new doc lead with what *changed* since the old date. A diff is worth more than a fresh snapshot.

### Step 3: Research

Use WebSearch to find candidate sources, then WebFetch to read the ones that matter. If the topic is Claude or the Anthropic API itself, also load the `claude-api` skill — it's the authoritative source for model and integration facts; verify recency against the web as usual. Rules:

- Prefer primary sources: official docs, vendor announcements, changelogs, pricing pages. News and blogs are leads; verify against the primary source.
- Check dates. A 2023 "X can't do Y" may be obsolete. Note each source's publication or last-updated date.
- **Stamp every key claim**: `shipped` (usable today), `announced` (promised, not yet available), or `reported` (third-party claim, no primary confirmation). The distinction is often the entire answer.
- **Capture a short supporting quote** (one sentence) from the source for each key claim, at fetch time. If the link later dies or the claim is challenged, the quote is the evidence.
- If the best source is paywalled or blocks fetching: cite it via a secondary source that quotes it and mark the claim `reported`, or mark it unverified. Never silently drop the strongest source, and never cite a page you couldn't read as if you had.
- Stop when the answer is confirmed by two independent sources or one authoritative primary source. Don't pad.
- If sources conflict, say so in the doc — don't silently pick one.

### Step 4: Verify before writing

For each claim that carries the answer (usually 2–5 per run), make one deliberate attempt to **refute** it: search for evidence that it's outdated, region-limited, deprecated, announced-but-never-shipped, or a misreading. For high-stakes runs, do this with parallel checker agents — one per claim, each prompted to refute, blind to the others. A claim that survives goes in the doc as stated; one that doesn't gets corrected or downgraded to "unconfirmed". On light-pass runs, refute only the headline claim.

### Step 5: Simplify

- Lead with the direct answer to each question in one or two sentences.
- Use everyday words. Where a technical term is unavoidable (e.g. "MCP connector"), add a half-sentence saying what it is.
- Cut anything that doesn't change what the reader would do or decide.
- Never copy marketing language — restate what the thing actually does.

### Step 6: Write the doc and update the ledger

Create `~/Desktop/research/` if needed. Save as:

```
~/Desktop/research/YYYY-MM-DD-<topic-slug>.md
```

Slug: lowercase, hyphens, ASCII, ≤6 words. Never overwrite an existing doc — old research is a snapshot. If today's filename already exists, suffix `-2`, `-3`, ….

**Doc template** (omit sections that don't apply, never pad):

```markdown
# [Topic, as a plain question or short title]

Researched: [date] · For: [who asked] · Depth: [light pass / full]
Stale after: [rough horizon, e.g. "~4 weeks — fast-moving space"]

## Send this

[The ready-to-forward reply for whoever asked: 3–6 sentences, chat- or
email-shaped, plain English, no reference markers. This is the real
deliverable.]

## The short answer

[2–5 sentences. The direct answer to the question(s), with markers.]

## What changed since [old date]  ← reruns only

[The diff against the previous doc, up front.]

## What I found

[Findings in plain English, grouped by sub-question. Every factual claim
carries a marker like [1] and a stamp: (shipped) / (announced) /
(reported). State dates: "as of July 2026".]

## How to: [task, if the topic is actionable]

1. [Numbered steps, imperative, one action per step. Exact menu paths,
   URLs, commands, settings names. Repeat the section per how-to.]

## So what for us

[2–4 sentences tying the findings to the stated decision and the user's
actual context. What would you do with this answer.]

## Caveats and open questions

[What's uncertain, conflicting, in preview, or likely to change. What
was checked but couldn't be verified. Omit only if genuinely nothing.]

## References

1. [Source name — page title](URL) — accessed [date], source dated
   [date]. Supports: [claim]. "[one-sentence supporting quote]"
```

Then append one line to `~/Desktop/research/index.md` (create it with a `# Research index` heading if missing):

```
- 2026-07-29 · [Topic](2026-07-29-topic-slug.md) — [one-line answer]
```

### Step 7: Report back

In the chat: the short answer, the file path, and the "Send this" text so the user can forward it immediately. Don't paste the whole doc — the doc is the deliverable's evidence, not the message.

## Example

**Input:** "Research whether Slack can integrate with Microsoft SharePoint — David needs it today."

**Output:**
1. Splits the question (does it exist / what can it do / how to set up); notes the decision: "can our team bridge Slack and our SharePoint content". Checks `index.md` — new topic, and it's forwardable, so full depth.
2. Reads the Slack App Directory listing and Microsoft's docs; stamps claims shipped/announced; captures a quote per reference; attempts to refute the headline claim ("integration exists") against current docs.
3. Writes `~/Desktop/research/2026-07-29-slack-sharepoint-integration.md` — "Send this" reply up top, findings, a numbered "How to: connect SharePoint to Slack", "So what for us", references with quotes — and appends the index line.
4. Replies in chat with the short answer, the path, and the paste-ready reply to David.

## Anti-patterns

- Answering from memory with no sources — the doc must cite what was actually read today
- Repeating a single source's claim without one refutation attempt on the claims that carry the answer
- Blurring shipped vs. announced — that distinction is often the whole answer
- Citing a page you couldn't actually read, or references without supporting quotes
- Burying the answer under methodology — conclusion first, always
- Overwriting a previous research doc, or skipping the index — research is cumulative
- Full-depth treatment on a five-minute ask — scale effort to stakes
