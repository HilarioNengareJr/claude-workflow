---
name: counsel
description: Convene a panel of independent agents — each with a distinct perspective, working blind to each other — to deliberate on a decision, plan, tradeoff, or design question, then synthesize their positions into a verdict with a clear recommendation. Use whenever the user wants multiple viewpoints before committing, even phrased casually — "convene the counsel", "get a second opinion on this", "panel this plan", "what would the council say", "deliberate on this", "counsel on X", "am I missing an angle here", or typing /counsel. Judges decisions and plans; it does NOT write plans (/architect), verify built features (/review), review diffs (/code-review), or stress-test code (/break).
---

# Counsel

Convene a panel of independent advisors on a question the developer is about to commit to. Each advisor is a separate agent with one assigned lens, deliberating blind — no advisor sees another's output — so the positions are genuinely independent, not an echo. The skill's job is to surface real disagreement before a decision hardens, then give one synthesized verdict the developer can act on.

## Step 1 — Frame the question

Extract from the conversation (only ask if genuinely missing):

- **The question** — one sentence, decidable. "Should CTAs move to the accent token or should amber-400 become a token?" not "thoughts on buttons?"
- **The material** — the plan, audit, options, or constraints the panel needs. Gather it from the conversation and, when the question touches a repo, from that repo's `context/` files: `project-overview.md` to orient, `architecture.md` + `code-standards.md` for technical questions, `ui-rules.md`/`ui-tokens.md` for UI questions, `progress-tracker.md` for what's already built or in flight. Every advisor gets the same brief.
- **The stakes** — reversible tweak or one-way door. This sets the panel size.

If the question is not decidable as framed, tighten it with the user first. A vague question returns a vague verdict.

## Step 2 — Compose the panel

Default panel of three:

1. **The Pragmatist** — what ships fastest with acceptable quality; where is the plan gold-plating?
2. **The Purist** — long-term consistency, correctness, and convention; where does the shortcut cost more later?
3. **The Skeptic** — what breaks, what's riskier than it looks, what assumption is unexamined?

Escalate to five for one-way doors or when the user asks for a "full counsel", adding:

4. **The User Advocate** — how the end user or customer experiences each option.
5. **The Operator** — maintenance, deploys, on-call reality, and who has to live with it.

Swap in domain lenses freely when the question calls for them (a11y, security, performance, brand). Name each seat in the output — verdicts carry more weight when it's clear who said what.

## Step 3 — Deliberate in parallel

Spawn all advisors **in one batch of parallel Agent calls** (subagent_type `general-purpose`; read-only work). Each prompt contains: the question, the full shared brief, that advisor's lens, and this required return shape:

```
POSITION: <one sentence — the advisor's answer to the question>
CONFIDENCE: high | medium | low
REASONS: <top 3, each one sentence>
RISKS: <what this position accepts or ignores>
WOULD-CHANGE: <the smallest change to the proposal that would flip or strengthen the position>
```

Rules that keep the deliberation honest:

- Advisors never see each other's output — independence is the whole point.
- Each advisor argues its lens even if the conclusion feels obvious; a panel that always agrees is a wasted panel.
- Advisors may read the codebase and context files, but must not edit anything.

## Step 4 — Synthesize the verdict

Read all positions, then produce exactly this structure:

```
## Counsel Verdict — <the question>

**Panel:** <seats convened>

**Unanimous:** <points every advisor agrees on — these are settled, act on them>

**Split:** <each disagreement: who holds what, and why — the real content of the verdict>

**Recommendation:** <one committed position with reasoning — never "it depends">

**Dissent worth keeping:** <the strongest losing argument, preserved so the risk stays visible>
```

The synthesis must take a side. Presenting both options and stopping is abdication — the developer convened a counsel to get a verdict. When the panel splits, break the tie explicitly and say what evidence would reverse the call.

## Step 5 — Hand back

The verdict is advice, not action. Do not start implementing the recommendation — the developer decides. If they accept it, the natural next step is `/architect` (to plan it) or a direct build request.

## Examples

**Input:** "/counsel should we kill rounded-lg buttons everywhere or grandfather the existing ones?"
**Output:** Panel of three convened with the button audit as the shared brief. Pragmatist says grandfather + lint rule; Purist says migrate now while the count is 6 live files; Skeptic flags that half the offenders are dead code so "everywhere" overstates the cost. Verdict recommends migrating live files now and deleting the dead ones, with the Pragmatist's lint-rule idea folded in.

**Input:** "get a second opinion — is a server-side stock check at checkout worth it, or keep the manual-disable philosophy?"
**Output:** Full counsel of five (one-way-door pricing/checkout territory). Splits surface between Operator (manual disable has failed silently before) and Pragmatist (feed is binary anyway); verdict recommends a light server-side availability check behind a flag, dissent preserved.

## Anti-patterns

- Sequential advisors, or advisors shown each other's output — kills independence, produces an echo.
- A "verdict" that lists options without picking one — the developer already had the options.
- Convening a counsel for a question with a documented answer in `context/` or code-standards — read the doc instead.
- Implementing the recommendation in the same breath — counsel advises, the developer decides.