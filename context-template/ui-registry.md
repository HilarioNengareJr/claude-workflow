# UI Registry

> Frontend repos only. Delete this file in a service, CLI, or library repo.

A catalog of every component that has been built, so the next one matches the last one.

`ui-rules.md` says how things should look. This file says what already exists — which is the
question that actually gets skipped, producing the fourth slightly-different modal.

---

## How to Use

**Before building any component:**

1. Search this file for something close. Reuse or extend it rather than building a sibling.
2. If nothing fits, build it, then add it here — with its real path and its real classes.
3. If you change an existing component's appearance, update its entry in the same commit. A stale
   registry is worse than none, because it's trusted.

Entries link to the real file so the code stays the source of truth and this stays the index.

---

## Components

### <Component> (canonical)

The reference implementation for <what pattern>. New <things of this kind> copy this.

**Path:** `<path/to/Component>`

```
<The actual markup or class string. Enough to reproduce it, not the whole file.>
```

**Props:** <the ones that change appearance, not every prop>

**Used by:** <where — this is how you know what breaks if you change it>

---

### Layout

| Component | Path | Role |
|---|---|---|
| `<Shell>` | `<path>` | <> |
| `<Nav>` | `<path>` | <> |
| `<TopBar>` | `<path>` | <> |

<For each, the details that matter for consistency: dimensions, fixed vs static, what states it
has.>

---

### Shared Primitives

The components everything else is built from. Changing one of these changes the whole product —
note that in the entry.

#### `<Primitive>` — `<path>`

<What it does, its variants, and the one rule that keeps it consistent.>

```
<key classes>
```

---

### <Domain> Components

Components specific to one area.

#### `<Component>` — `<path>`

<What it renders and any pattern worth copying.>

---

## Dated Patterns

When a component's appearance changes for a reason, record it here with the date rather than
silently editing the entry above. The reason is what stops the change being reverted.

### <Pattern name> (<YYYY-MM-DD>)

<What changed, what it replaced, and the specific problem it solved.>

**Rules if you touch it:**
- <Constraint that must hold>
- <The measurement or tradeoff that justified it>

---

### <Pattern name> (<YYYY-MM-DD>) — SUPERSEDED by <what> (<YYYY-MM-DD>)

<Kept so the old approach isn't reinvented. Say what was wrong with it.>

---

## Honest Limits

Where the current components fall short, stated plainly rather than papered over. A known limit
someone can design around beats a component that quietly does the wrong thing.

- <Limit — and what NOT to do about it>
