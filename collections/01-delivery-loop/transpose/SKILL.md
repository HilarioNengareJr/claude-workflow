---
name: transpose
description: Adapt a proven design philosophy — Linear, Stripe, Vercel, Apple HIG, a
  screenshot, any admired product or design system — into the current project without
  breaking its identity. Extracts the transferable principles from the reference, then
  re-expresses them through the project's own design tokens, component registry, and
  established patterns. Use whenever the user wants to borrow design inspiration, even
  phrased casually — "make this feel like X", "take inspiration from X", "apply X's
  design philosophy", "make it more like Linear but keep our brand", "steal the good
  parts of X", "why does X feel better than ours", "give it that Stripe polish", or
  typing /transpose. NOT for capturing patterns after a build (/imprint), auditing
  existing consistency (/imprint audit), or chart styling (/dataviz).
---

# Transpose

Transpose a melody and it stays the same song — it just plays in a different key. This
skill does that for design: it takes what makes a reference system great and replays it
in the project's own key — its tokens, its components, its brand.

The failure mode this skill exists to prevent has two sides. Copy the reference too
literally and the product loses its identity — suddenly there's Inter font and
`#5E6AD2` purple in an app whose whole system is Poppins and teal. Admire the reference
too vaguely and nothing changes — "make it feel like Linear" produces a coat of paint
and no craftsmanship. The fix for both is the same: **principles transfer, pixels
don't.** Extract the principle, discard the execution, re-execute through what the
project already has.

**Hard constraint — non-negotiable:** every change this skill produces is expressed in
the project's own design system. Colors come from the project's color tokens, fonts are
the project's declared fonts, classes match the component registry's documented specs.
If the project keeps `ui-tokens.md` / `ui-rules.md` / `ui-registry.md`, those files are
law: no raw hex, no new font, no class that bypasses a token, no component that
contradicts a registry entry. A transposition that can't be written in the project's
tokens doesn't get written.

---

## How to Invoke

```
/transpose [reference]                  → adapt the reference across current work
/transpose [reference] [target]         → adapt it for one page/component/flow
/transpose [screenshot or URL]          → extract from an image or live product
```

Examples: `/transpose linear`, `/transpose stripe-dashboard the orders table`,
`/transpose [pasted screenshot] our checkout flow`.

---

## Step 1 — Understand the reference and the admiration

Pin down two things before touching any code:

1. **What is the reference?** A named product (Linear, Stripe, Notion, Vercel), a formal
   design system (Apple HIG, Material 3, Polaris), a screenshot, a URL, or a vibe
   ("that calm, dense, keyboard-first feel").
2. **What does the user actually admire about it?** "Make it like Linear" hides the real
   request. If the user named specifics ("the way their tables breathe", "how Stripe
   does empty states"), work from those. If not, name the 3–5 things the reference is
   genuinely known for and confirm which ones matter here — admiration for Linear's
   speed is a different project than admiration for its typography.

If the reference is a screenshot or URL, read it properly: identify hierarchy, spacing
rhythm, density, color discipline, and interaction affordances from what is actually
visible. Never invent qualities the reference doesn't demonstrate.

---

## Step 2 — Extract transferable principles

Separate philosophy from execution. For each admired quality, write down the
*principle* — the reason it works — stripped of every brand-specific detail.

Principles live in these categories; use them as the extraction checklist:

| Category | The transferable question |
| --- | --- |
| Hierarchy | How does the eye know what matters first? How many levels exist? |
| Density | How much information per screen? Where is it allowed to be dense? |
| Spacing rhythm | Is there a consistent scale? Where does whitespace do the separating work? |
| Color discipline | How few colors do real work? What is color *reserved* for? |
| Typography scale | How many sizes/weights? What carries emphasis — weight, size, or color? |
| Motion restraint | What moves, what never moves, how fast, and why? |
| States and feedback | Loading, empty, error, success — how honest and how quiet are they? |
| Affordances | How do interactive things announce themselves without shouting? |
| Craftsmanship details | Alignment, optical corrections, consistent radii, tabular numbers |

**Banned imports — these never cross over:**

- Hex values, palettes, gradients from the reference
- The reference's fonts
- Logos, iconography style, illustration style
- Literal layout clones (recognizably "their" screen rebuilt here)
- The reference's copy, voice, or naming

If a principle can only be expressed by importing one of these, it is not transferable
— drop it and say so.

---

## Step 3 — Load the project's ground truth

The project's design system is the key everything gets transposed into. Read it before
proposing anything:

- `context/ui-tokens.md`, `context/ui-rules.md`, `context/ui-registry.md`,
  `context/code-standards.md` — when the project keeps them
- Otherwise derive ground truth from code: the theme/token source (Tailwind `@theme` or
  config, CSS variables, theme files), the shared UI primitives, and the two or three
  most-used composite components. Say explicitly that ground truth was derived, not
  documented.

While reading, build the **identity invariants list** — what must survive unchanged:

- Brand colors, accent, fonts
- Documented "do not" rules and dated decisions (registries often carry entries like
  "stagger removed 2026-07-24 — do not reintroduce"; a transposition that reverses one
  of these is a regression, not an improvement)
- Sanctioned exceptions and their reasons
- Established user experiences — flows users already know

If the project has no design ground truth at all, stop and recommend establishing a
baseline first (`/imprint audit` where available) — transposing into a system that
doesn't exist yet just creates a second ad-hoc system.

---

## Step 4 — Build the translation table

This is the core deliverable. For each extracted principle, one row:

```markdown
| Principle (from reference) | How the reference does it | How WE do it | Touches |
| --- | --- | --- | --- |
| Color is reserved for state and action | 1 accent, grays elsewhere | Already aligned — accent `--color-accent` only on actions; flag the 3 places using raw `text-blue-*` | Badge.tsx, …  |
| Tables are dense but breathe via row rhythm | 8px baseline grid, hairline separators | `DataTable` roomy prop + `border-[var(--color-border-light)]` separators | DataTable.tsx |
| Numbers align in columns | tabular-nums everywhere | add `tabular-nums` to stat + table-number cells (token-safe utility) | KpiCards, tables |
```

Rules for the "How WE do it" column:

- Every application is expressed in the project's **existing tokens and components**.
  Name the exact token, class, or registry component.
- Some rows will be "already aligned" — say so. That's a finding, not filler: it tells
  the user which parts of the admiration they already own.
- A **new token** is allowed only when the principle genuinely has no expression in the
  current system. It gets added at the token source (never inline), follows the
  project's naming, and gets called out as a system change.
- A row that **conflicts with an identity invariant** is not silently dropped — it goes
  in a separate "Conflicts" list with the invariant it hit, so the user decides. The
  default is the invariant wins.

---

## Step 5 — Confirm scope, then apply

Present the translation table with a recommendation of which rows to apply. Rows split
three ways: **apply** (clear improvements, no conflicts), **already aligned** (nothing
to do), **conflicts** (user decides).

When the user has already said "just do it" — or the invocation named a tight target —
apply the non-conflicting rows directly. Otherwise wait for the row selection.

While applying:

- Work through the project's existing components — improving `DataTable` improves every
  table; editing one page's table creates drift.
- Match the project's code conventions exactly (its class-merge utility, its file
  structure, its naming).
- Run the project's quality gates (typecheck, lint, build) before reporting done.

---

## Step 6 — Record the transposition

An unrecorded adaptation gets undone by the next session. After applying:

- Update the project's registry/rules with what changed and *why* — the principle, the
  reference, and the date, in the project's documented-decision style. Where the project
  uses `/imprint`, run it.
- If a new token was added, document it at the token source and in the tokens doc.
- Note the rows deliberately not applied and why, so the decision isn't relitigated.

---

## The identity check

Before declaring done, the result must pass all of these:

1. Brand colors, accent, and fonts are unchanged (unless the user explicitly ordered a
   rebrand — which is a different task than this skill).
2. Zero hex values, fonts, or assets imported from the reference.
3. Every change is expressed through the project's tokens and components.
4. No dated "do not" decision in the project's docs was reversed.
5. A returning user would recognize the product immediately — it feels *better*, not
   *different*.

If any check fails, the transposition overreached. Pull it back before shipping.

---

## Example

**Input:** `/transpose linear our voucher reports page`

**Output:**
1. Confirms the admiration: Linear is known for restrained color, dense-but-rhythmic
   tables, instant-feeling interactions, quiet empty states. User confirms "the tables
   and the calm".
2. Extracts principles: color reserved for state/action; one spacing scale doing all
   separation; tabular numbers; hover states that inform without decoration.
3. Reads `context/ui-tokens.md` + `ui-registry.md` → invariants: teal accent, Poppins,
   warm stone palette, "no stagger" decision (2026-07-24), canonical card spec.
4. Translation table: 2 rows already aligned (color discipline, spacing scale), 3 to
   apply (tabular-nums on stat/table numbers via `DataTable` + KPI components; tighten
   the table's secondary-text contrast using existing stone tokens; quieter row hover —
   already-owned `--color-surface-warm`), 1 conflict flagged (Linear's near-instant
   120ms motion vs the project's documented 250ms `--duration-normal` — invariant wins
   unless the user overrides).
5. Applies the 3 rows through `DataTable.tsx` and the KPI components, runs `tsc` +
   lint, records the change and the skipped conflict in `ui-registry.md`.

No purple. No Inter. Still unmistakably the same product — with Linear's discipline.

---

## Anti-patterns

- Copying the reference's palette or font "just to try it" — that's a rebrand, not a
  transposition
- Applying principles to one page instead of the shared component — creates the drift
  this skill exists to prevent
- Reversing a dated "do not" decision because the reference does it differently —
  conflicts go to the user, invariants win by default
- Vague output ("add more whitespace") — every row names exact tokens, classes, and
  files
- Skipping Step 6 — an unrecorded transposition is a one-session coat of paint