---
name: recover
description: When something goes wrong during a build, diagnose what type of failure it is before deciding how to respond. Targeted fix, hard reset, or full rethink — the right response depends on the right diagnosis.
---

Not every problem is a bug. Not every bug needs debugging.

When something goes wrong with AI-assisted development, the instinct is to keep prompting — describe the problem, ask for a fix, get another broken version, describe that problem, ask for another fix. The session gets longer. The context gets polluted. The code gets worse.

The problem is not the code. The problem is not knowing what type of failure you are dealing with.

This skill diagnoses the failure first. Then it prescribes the right response. Those are two separate steps and they cannot be swapped.

---

## Step 1 — Describe What Went Wrong

The developer describes the problem. The skill listens before doing anything else.

Ask:

```
Describe what is wrong. Be specific:
- What did you expect to happen?
- What happened instead?
- How many times have you tried to fix it already?
```

Read the answer carefully. The number of fix attempts is important — it tells you whether this is a fresh problem or a session that has already gone wrong.

---

## Step 2 — Identify the Failure Mode

Before classifying, ground the diagnosis in what was *supposed* to happen: read the latest plan entry in `context/architecture.md` (what was being built and the decisions behind it) and `context/progress-tracker.md` (the last known-good state), when they exist. The gap between intended and actual is often the diagnosis.

Based on the description, determine which of three failure modes this is.

**Count before you classify.** The three modes read similarly in the abstract, so anchor the call on countable evidence from the transcript, not on how bad it feels:

- **How many distinct fixes have been attempted at this problem?** Count edits made *in response to the same failing symptom*, not total edits. 0–2 → Mode 1 territory. 3+ → Mode 2 territory.
- **Did any attempt introduce a new symptom that wasn't there before?** Even one is a strong Mode 2 signal — that's the "fixes patching fixes" pattern starting.
- **Does the code do what was asked, incorrectly, or something other than what was asked?** Wrong *output* from the right approach is Mode 1 or 2. Right output from the wrong *approach* — or a working feature that solves a different problem than the plan describes — is Mode 3 regardless of the attempt count. A Mode 3 can happen on attempt zero.

When the count says Mode 1 but the third bullet says Mode 3, **Mode 3 wins** — attempt count measures thrash, and a wrong foundation can be built cleanly on the first try. State the count you used when you announce the mode, so the developer can overrule you with evidence rather than opinion.

### Failure Mode 1 — A specific thing is broken

**Signs:**

- The problem is isolated — one component, one function, one route
- The rest of the project works correctly
- This is the first or second attempt at fixing it
- The error message or wrong behaviour is clear and specific

**What it means:**
This is a normal bug. It has a root cause that can be found and fixed precisely.

**Response:** Targeted fix — go to Step 3A.

---

### Failure Mode 2 — The session has gone wrong

**Signs:**

- Multiple fix attempts have made things worse or created new problems
- The code has become tangled — fixes are patching fixes
- Context in this session is full of failed attempts
- It is no longer clear what the original problem was

**What it means:**
The session is polluted. More prompting will not help — it will compound the damage. The feature needs to be rebuilt in a clean context, not patched further.

**Response:** Hard reset — go to Step 3B.

---

### Failure Mode 3 — The foundation is wrong

**Signs:**

- The code runs but produces fundamentally wrong behaviour
- Claude has been confidently building something that misunderstands a core requirement, library API, or architectural pattern
- The problem is not a bug in the implementation — the implementation itself is wrong
- Fixing individual pieces will not help because the approach is incorrect

**What it means:**
This is not a debugging problem. The approach needs to be reconsidered before any code is written. More implementation in the wrong direction makes things harder to untangle.

**Response:** Rethink — go to Step 3C.

---

Tell the developer which failure mode this is before proceeding:

```
This looks like Failure Mode [1/2/3] — [name].

Evidence: [N] fix attempts at this symptom, [N] new symptoms introduced,
approach is [right/wrong] for what the plan describes.

[One sentence explaining why that adds up to this mode.]

Here is how we handle this:
```

---

## Step 3A — Targeted Fix

For Failure Mode 1.

### Diagnose before touching code

Ask the developer to share:

- The exact error message or wrong behaviour
- The specific file or function where it happens
- What the code is supposed to do versus what it actually does

Read the relevant code. Do not read the entire codebase — only what is directly relevant to the problem.

### Find the root cause

Identify the root cause before suggesting any fix. A root cause is the actual reason the problem exists — not a symptom of it.

State the root cause clearly:

```
Root cause: [specific explanation of why this is happening]

This is different from the symptom because: [explanation]
```

### Suggest a precise fix

Describe the fix that addresses the root cause. Not a workaround. Not a patch on top of broken code.

```
Fix: [what needs to change and why]

This will resolve the root cause because: [explanation]
```

Wait for the developer to confirm before making any changes.

### If the fix does not work

If the suggested fix does not resolve the problem — stop. Do not suggest another fix immediately.

Re-examine the root cause diagnosis. If the fix did not work, the root cause was probably wrong. Diagnose again from the beginning before trying again.

If two root cause diagnoses have both been wrong — this may actually be Failure Mode 2 or 3. Re-evaluate.

---

## Step 3B — Hard Reset

For Failure Mode 2.

### Acknowledge the situation honestly

```
This session has gone too far in the wrong direction
to recover by patching. The right move is a clean start.

This is not a failure — it is the correct response
to a polluted context. A fresh session with clear intent
will be faster than continuing here.
```

### Save what is worth keeping

Before the session ends, extract anything valuable from the current state:

- What was the original feature supposed to do?
- What parts of the current implementation, if any, are actually correct?
- What has been learned about what does not work?
- What should the next session avoid?

Write this as a brief reset note:

```
## Reset Note — [Feature Name]

### What we were building
[Original feature description]

### What went wrong
[Honest summary of how the session went off track]

### What to avoid next time
[Specific approaches or patterns that did not work]

### Starting point for next session
[Where to begin fresh — what to keep, what to discard]
```

### Instruct the developer

```
Next steps:

1. Save this reset note somewhere accessible
2. End this session completely
3. Start a fresh session
4. Begin with /remember restore if memory exists
5. Approach [feature name] again with the reset note as context

Do not continue in this session.
```

---

## Step 3C — Rethink

For Failure Mode 3.

### Name the wrong assumption

The foundation being wrong means something was assumed that should not have been. Find it. When the assumption is about a library API, check it against `context/library-docs.md` and its stated authority order — that file exists precisely to catch confident, wrong API usage.

```
The core issue is not a bug — it is a wrong assumption:

Assumed: [what was assumed]
Reality: [what is actually true]

This means the current implementation cannot be fixed
by patching. The approach needs to change.
```

### Propose the correct approach

Based on the correct understanding, describe what the approach should have been:

```
Correct approach: [description]

Key difference from current approach: [explanation]

What needs to be discarded: [what cannot be salvaged]
What can be kept: [what is still valid]
```

### Do not start rebuilding immediately

A rethink needs the developer to understand and agree before any code changes. Present the analysis and wait for confirmation.

```
Does this diagnosis match your understanding?

If yes — we can start fresh with the correct approach.
If no — tell me what I am getting wrong.
```

Only after the developer confirms does any rebuilding begin.

---

## The Principle

The worst thing you can do when something is broken is keep doing the same thing faster.

Diagnose first. Respond correctly. Different failures need different responses — and knowing which failure you are dealing with is more than half the solution.
