# UI Tokens

> Frontend repos only. Delete this file in a service, CLI, or library repo.

Design tokens for <PROJECT_NAME>. Every color, type size, spacing step, and radius comes from
`<the token source file>`. Never hardcode a hex value in a component.

---

## How to Use

<How tokens reach a component in this project's styling system — CSS custom properties, a theme
object, generated utility classes. Show the correct usage and the wrong usage side by side; the
wrong example is the one that gets remembered.>

```
// Correct
<example>

// Also correct
<example>

// Never — hardcoded value
<example>
```

---

## Token Definitions

The complete source, copied from `<file>`. This block is the source of truth — if it drifts from
the real file, fix this file, not the code.

```
<All token definitions: fonts, colors, spacing, radii, shadows, durations.>
```

---

## Color Usage Guide

Which token goes where. This is the part that stops a palette from being applied inconsistently —
having the right colors doesn't help if nobody knows which surface takes which.

### Page Layout

| Element | Token | Value |
|---|---|---|
| Page background | `<token>` | `<value>` |
| Card / panel surface | `<token>` | `<value>` |
| Secondary surface (hover rows) | `<token>` | `<value>` |
| Default border | `<token>` | `<value>` |

### Accent

<The primary action color, where it's allowed, and — importantly — where it isn't. An accent used
everywhere stops meaning anything.>

### Status Colors

<Defined in `<constants file>`. Always import from there; never re-derive a status color inline.>

| Status | Token / class |
|---|---|
| <> | <> |

---

## Typography

| Role | Size | Weight | Color |
|---|---|---|---|
| Page title | <> | <> | <> |
| Section title | <> | <> | <> |
| Body | <> | <> | <> |
| Muted / label | <> | <> | <> |
| Stat number | <> | <> | <> |

---

## Spacing

| Context | Value |
|---|---|
| Page padding | <> |
| Gap between major sections | <> |
| Gap between cards in a section | <> |
| Card internal padding | <> |

---

## Component Tokens

Fixed values per component type, so two of the same thing never come out different.

### Cards
```
<background, border, radius, padding, shadow>
```

### Buttons
```
<primary / secondary / danger — each with its hover state>
```

### Inputs
```
<background, border, radius, padding, focus ring>
```

### Badges
```
<shape, size, weight, padding>
```

### Modals
```
<backdrop, surface, radius, max width>
```

---

## Invariants

- Tokens are defined in `<file>` and nowhere else
- Never hardcode a hex value in a component file
- <The accent color, stated absolutely — e.g. "the accent is <color>, never blue">
- <Any rule about surfaces, e.g. "cards are never colored; color goes inside them">
