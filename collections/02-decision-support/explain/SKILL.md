---
name: explain
description: Analyse a feature and explain it in plain, everyday language — no technical jargon, no over-engineering the explanation. Use this skill whenever the user asks to understand, explain, or walk through a feature, flow, module, or piece of behaviour, even if phrased casually (e.g. "what does this feature actually do", "explain the voucher flow to me", "how does login work in this app", "tell me about X"). Works on code in the repo, a spec, an API contract, or a pasted snippet.
---

# Tell Me About

Analyse a feature properly, then explain it the way you'd explain it to a smart colleague who doesn't live in this codebase. The analysis is rigorous; the explanation is plain. Never confuse the two — simple language is not shallow analysis.

## Core principle

Jargon hides understanding, in both directions: it lets the explainer skip the hard part of actually understanding, and it blocks the listener from checking whether the explanation makes sense. If something can't be said in plain words, it hasn't been understood yet. The test for every sentence: would someone outside the team follow it without stopping?

## Workflow

### Step 1: Analyse before explaining

Before writing a single explanatory word, actually understand the feature:

- Orient first, when the feature lives in a repo: `context/project-overview.md` (what the product is and what it calls things) and the relevant slice of `context/architecture.md` (where the feature sits and what it talks to). The explanation should use the project's own names for things.
- If it's code: trace the feature end to end — entry point, the main path through, what it touches (data, other services), and where it ends. Read the real files; don't explain from the feature's name.
- If it's a spec or API contract: read the whole thing, note what's required vs. optional, and what happens on failure.
- If something is unclear or contradictory, say so in the explanation rather than papering over it. "This part is ambiguous" is plain language too.

Do not skip or shorten this step. The plain explanation is only trustworthy if the analysis underneath it was thorough.

### Step 2: Find the one-sentence core

Every feature has a core job. State it in one sentence using everyday words before anything else. Pattern: "[Feature] lets [who] [do what] so that [why]."

Example: "The bulk campaign builder lets the marketing team send birthday vouchers to thousands of customers at once, instead of one at a time."

If the one-sentence version can't be written, return to Step 1 — the feature isn't understood yet.

### Step 3: Explain in plain language

Build outward from the core sentence. Rules:

- **Translate every technical term or drop it.** "Endpoint" → "the address the app sends the request to". "Idempotent" → "safe to retry without sending things twice". If a term genuinely earns its place (the user will hear it from colleagues), introduce it once with a plain definition, then use it.
- **Use the actors, not the components.** "When the marketer clicks Send" beats "when the frontend invokes the handler". People and actions, not modules and functions.
- **Follow one journey through.** Pick the normal, happy case and walk it start to finish before mentioning edge cases. One clear path explained fully beats five paths explained vaguely.
- **Use an analogy only if it's load-bearing.** One good comparison to something familiar (a post office, a guest list, a till receipt) can carry a whole explanation. Decorative analogies just add words — skip them.
- **Keep it short.** Most features should be explainable in 150–300 words of prose. Length is usually a sign the core hasn't been found, not a sign of thoroughness.

### Step 4: Cover what can go wrong — briefly

After the happy path, add a short "What can go wrong" note: the one or two failure cases that actually matter in practice (the request fails halfway, a duplicate gets sent, data is missing). Plain language here too: "if the connection drops halfway, some customers may get the voucher and some may not — and there's currently nothing that undoes the half-finished batch."

### Step 5: Close with the honest edges

End with anything the user genuinely needs flagged: parts that are unfinished, assumptions the feature makes, or places where the code and the spec disagree. One to three bullets, no more. If there are none, skip this entirely.

## Output format

Plain prose, structured loosely as:

```markdown
## [Feature name], in plain terms

[One-sentence core.]

[The journey: what happens from the user's action to the end result, 1–3 short paragraphs.]

**What can go wrong:** [1–2 sentences.]

**Worth knowing:** [optional, up to 3 short bullets of honest edges.]
```

No headers beyond these, no nested bullets, no diagrams unless the user asks.

## Rules of restraint

- **Don't over-sophisticate.** No architecture commentary, no design-pattern name-dropping, no "this follows the repository pattern" — unless the user asks why it's built that way.
- **Don't oversimplify into wrongness.** If the simple version would mislead (e.g. "it just sends an email" when it actually queues, retries, and deduplicates), the plain version must carry that truth: "it lines the messages up and works through them, retrying any that fail."
- **Don't pad.** No "great question", no recap of what was asked, no closing summary that repeats the explanation.
- **Match the depth to the question.** "Tell me about login" gets the short version; "tell me about login, I need to present it to Jeanine" gets the same plain language with slightly more completeness.

## Example

**Input:** "tell me about the voucher block in the campaign request"

**Output:**

```markdown
## The voucher block, in plain terms

The voucher block is the part of the campaign request that describes the gift itself — what the customer actually receives.

When a campaign is created, the request carries four pieces of voucher information: what kind of voucher it is, how much it's worth, how long it stays valid, and the message template that goes with it. The backend takes these four fields and uses them to create one voucher per customer in the batch. The same four fields apply to every customer — there's no way to give different customers different amounts within one campaign.

**What can go wrong:** if any of the four fields is missing or doesn't pass the backend's checks, the whole campaign is rejected before anything is sent — no partial sends at this stage.

**Worth knowing:**
- The spec originally allowed per-channel content; that was removed, so the voucher block is the only content source now.
```

## Anti-patterns

- Explaining the code's structure instead of the feature's behaviour
- A "simple" explanation that's really the technical one with adjectives removed
- Ten edge cases given equal weight to the main flow
- Skipping the analysis and explaining from the feature's name and vibes
