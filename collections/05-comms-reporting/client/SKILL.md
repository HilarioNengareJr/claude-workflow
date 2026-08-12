---
name: client
description: Turn shipped or in-flight work into a plain-English update for a
  stakeholder — a manager, the logistics team, a business owner — as an email
  or a short chat message, honest about what's live versus still pending. Use
  whenever the user wants outbound comms about the work: "write an update
  for", "client update", "stakeholder update", "tell the team what we
  shipped", "draft an email about the new feature", "what do I tell the
  business", "status update for my manager", or typing /client. Distinct from
  /digest (inbound — extracts structure from a pasted conversation) and /eod
  (a report for the developer themself); this skill writes for a non-technical
  reader outside the codebase.
---

# Client update

Translate engineering work into an update a non-technical stakeholder can read
in thirty seconds and act on. The reader doesn't know what a repo, a pipeline,
or staging is — they want to know what changed for the business, when, and what
they need to do about it, if anything.

The hard rule is honesty about deployment state. On these repos, **pushed is
not live**: a push auto-deploys staging (the test environment), and production is
a separate manual gate. Telling a stakeholder something is live when it's
sitting on staging is the one mistake this skill exists to prevent.

## Workflow

### 1. Establish what actually happened

Pull from evidence, not memory: the current session, `git log` in the relevant
repo, `context/progress-tracker.md`, and — for the live-or-not question — the
pipeline/deploy state (gitlab MCP `list_commit_statuses` on the commit, per
the `/ship` skill). Classify each piece of work as exactly one of:

- **Live** — on production, customers/staff can use it now.
- **On the test environment** — built and deployed to staging, pending the prod
  go-ahead.
- **In progress** — being built, give an honest expectation, not a promise.

### 2. Know the reader and the channel

From the conversation, work out who this is for and where it's going. If it's
genuinely unclear, ask once — audience changes everything. Two shapes:

- **Email** — subject line + short paragraphs. For managers, formal updates,
  anything that needs a paper trail.
- **Chat message** (WhatsApp/Slack) — a few sentences, no headings, no
  sign-off. For quick "the thing you asked about is done" notes.

### 3. Translate

Write what the change **means**, not what it is:

- "Customers can now pay with a saved card" — not "integrated the Stitch
  tokenized payment endpoint".
- Name systems only by what the reader calls them ("the store", "the admin
  console", "order tracking") — never repo names, branches, or job names.
  `context/project-overview.md` carries the product's real vocabulary
  (collection names, store names, device names) — use it so the update matches
  the words stakeholders already use.
- Numbers beat adjectives: "checkout is about 2 seconds faster", "37 {{ITEM}}
  across 5 collections".
- If the reader must do something (click go-live, test a flow, update the
  team), that ask goes in its own line near the top — not buried.
- Dates absolute ("by Friday 10 July"), never "soon" or sprint-speak.

### 4. Deliver

Present the draft in chat for the user to read before anything leaves the
machine. If it's an email and the user wants it in their outbox, offer to
create a **Gmail draft** via the Gmail MCP (`create_draft`) — **never send**;
sending is the user clicking the button in their own mail client.

## Output shapes

**Email:**
```markdown
Subject: [What changed, in the reader's words]

Hi [name],

[What's live / what changed, 1–2 sentences, business terms.]

[If anything is pending: what, and what it's waiting on — stated plainly.]

[If the reader must act: the ask, one line.]

[Sign-off]
```

**Chat message:**
```markdown
[One line: the thing is done / where it stands.] [One line: what it means for
them or what you need from them.]
```

## Example

**Input:** "write an update for the logistics team about the order export"

**Output:** Checks the tracker and pipeline — the XLSX export shipped to prod
last week; the new fulfilment-status filter is on staging awaiting the prod click.
Drafts a chat-style message: "The order export in the admin console now
downloads as a spreadsheet — live as of last week, you can use it today. The
filter that lets you export only 'ready to ship' orders is built and being
tested; I'll confirm when it's live, aiming for this Friday (10 July)." Then
offers a Gmail draft if they'd rather send it as email.

## Anti-patterns

- Calling something "live" that's on staging or merely pushed — the cardinal sin.
  Verify deploy state; don't infer it from a green commit.
- Jargon leaking through: repo names, "pipeline", "MR", "endpoint", "staging"
  (say "our test environment" if you must mention it at all).
- The wall of text. A stakeholder update that needs scrolling has failed;
  cut detail until it fits the shapes above.
- Padding with process ("after extensive testing and careful review…") —
  state what changed and what's next, nothing else.
- Sending anything. Draft only; the send button belongs to the user.