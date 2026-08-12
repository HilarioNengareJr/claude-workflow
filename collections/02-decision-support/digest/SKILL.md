---
name: digest
description: Extract structure from a pasted conversation — Slack threads, WhatsApp chats, email chains, meeting transcripts, or any back-and-forth with stakeholders, devs, managers, or clients. Use this skill whenever the user pastes a conversation and wants to know what came out of it, even if they phrase it loosely (e.g. "what do I need to do from this", "summarize this thread", "what did we agree on", "pull the action items out of this"). Output is a structured digest of action items, deliverables, ideas, open questions, and commitments.
---

# Chat Says

Turn a raw pasted conversation into a clear, owned list of what matters: who has to do what, by when, what was promised, what was decided, and what's still open. The goal is that the user never re-reads the original thread — the digest is sufficient to act on.

## Core principle

Conversations bury commitments. A casual "yeah I can get that to you Thursday" three messages deep is a deadline; "we should probably loop in X at some point" is an open question that will resurface. Extract what was *actually said*, attribute it to the person who said it, and never invent commitments that weren't made. Where something is implied but not explicit, flag it as inferred rather than stating it as fact.

## Workflow

### Step 1: Identify the participants and context

From the pasted text, determine:
- Who is speaking (names, roles if stated or inferable)
- Which participant is the user — assume the user is "me"/"I" or ask if ambiguous
- The channel and tone (formal email vs. quick Slack thread changes how literally to read promises)

If speaker labels are missing or garbled, ask the user one clarifying question rather than guessing attribution — wrong attribution of a commitment is the worst failure mode of this skill.

### Step 2: Extract into categories

Read the full conversation once before extracting, so later messages that retract or modify earlier ones are handled correctly (the last statement on a topic wins).

Extract into these buckets:

1. **My action items** — things the user committed to or was asked to do. Include deadline if stated, and quote-adjacent wording so the user can verify ("you said you'd send the contract review by EOD Friday").
2. **Others' action items** — things other people committed to or were asked to do, with owner and deadline. These are the user's follow-up triggers.
3. **Deliverables** — concrete artifacts expected to exist (a doc, an endpoint, a deck), distinct from tasks. Note who produces and who receives each one.
4. **Decisions made** — anything agreed or settled. Mark a decision only when the conversation confirms it; "let's probably do X" is not a decision.
5. **Ideas raised** — suggestions, possibilities, things worth exploring later. No owner required.
6. **Open questions / blockers** — unresolved points, things waiting on someone, and anything ambiguous that needs clarification.

Omit any bucket that is genuinely empty rather than padding it.

### Step 3: Surface what needs a response

End the digest with a short "Needs your reply" section if the conversation contains direct questions to the user or pending requests the user hasn't answered. This is the highest-urgency output — call it out even if it overlaps with the action items list.

### Step 4: Offer the follow-through

After presenting the digest, offer (don't auto-execute) one next step that fits, such as:
- Drafting a confirmation message back to the thread ("Here's what I'm taking away — correct me if I missed anything")
- Turning "My action items" into a todo list or calendar entries
- Drafting a follow-up nudge for an overdue item owned by someone else

## Output format

ALWAYS use this template (omit empty sections):

```markdown
## Digest: [thread topic, one line]
Participants: [names/roles]

### My action items
- [ ] [task] — due [date or "no deadline stated"] — based on: "[short paraphrase of the line]"

### Waiting on others
- [Name]: [task] — due [date or "no deadline stated"]

### Deliverables
- [artifact] — [producer] → [recipient]

### Decisions
- [decision, stated plainly]

### Ideas raised
- [idea] ([who raised it])

### Open questions
- [question or blocker]

### Needs your reply
- [direct question or pending request, with who's waiting]
```

## Rules of interpretation

- **Last statement wins.** If a deadline moves mid-thread ("actually, make that Monday"), report only the final state.
- **Distinguish asked vs. agreed.** Being asked to do something is not the same as agreeing to it. If the user never responded, put it under "Needs your reply", not "My action items".
- **Mark inference.** If an owner or deadline is implied but not stated, write "(inferred)" next to it.
- **No editorializing.** Don't grade the conversation, assess anyone's tone, or speculate about motivations. Report content only.
- **Preserve sensitive context privately.** If the thread contains confidential or interpersonal content, extract only the actionable parts; don't restate the sensitive material in the digest.

## Example

**Input:** [User pastes a Slack thread where Vivek says the endpoint will be merged Thursday, Jeanine asks the user when QA can start, and the user says he'll confirm after testing in staging]

**Output:**

```markdown
## Digest: Bulk campaign endpoint — merge timing and QA start
Participants: Me, Vivek (backend), Jeanine (stakeholder)

### My action items
- [ ] Test the merged endpoint in staging and confirm QA start date to Jeanine — due after Thursday merge — based on: "I'll confirm once I've tested in staging"

### Waiting on others
- Vivek: merge the endpoint — due Thursday

### Needs your reply
- Jeanine asked when QA can start — answered conditionally; she's waiting on your confirmation post-staging
```

## Anti-patterns

- Summarizing the conversation chronologically instead of extracting by category — the user wants outcomes, not a recap
- Inventing deadlines or owners to make the digest look complete
- Listing every message as an "idea" — only extract things with future relevance
- Burying a direct unanswered question in the middle of a long list
