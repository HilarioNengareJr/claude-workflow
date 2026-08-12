# UI Rules

> Frontend repos only. Delete this file in a service, CLI, or library repo.

Rules for building the <PROJECT_NAME> interface. These cover the patterns and constraints that
keep the UI consistent, without trying to specify every pixel.

`ui-tokens.md` says what the values are. This file says how they're arranged and when they move.

---

## Font

<Where fonts are loaded and which is primary. Include the fallback stack — and a note on whether
system fonts are acceptable as a primary, because that's a decision, not a default.>

```
<font token definitions>
```

---

## Layout

- <Root shell: height, scroll behaviour>
- <Navigation region: dimensions, whether it's static or an overlay, at which widths>
- <Top bar: what it contains, whether it's always visible>
- <Main content: scroll container, width cap or lack of one>
- <Page padding, at each breakpoint>
- <Gap between major sections vs between cards inside a section — state both, they differ>

---

## Responsive Breakpoints

<Only the breakpoints that actually change something. List the change, not the pixel value alone.>

- **`<breakpoint>`** — <what switches here and why>
- **Touch targets** — <minimum hit area on interactive controls>

---

## <Navigation Region>

<Structure, zones, and the exact classes for active vs inactive states. Nav is where
inconsistency shows first because it's on every screen.>

1. **<Zone>** — <styling>
2. **<Zone>** — <styling>
   - Active: `<classes>`
   - Inactive: `<classes>`

---

## Cards

Every content section lives in a card.

```
<background>
<border>
<radius>
<padding>
<shadow>
```

<Any absolute rule about cards — e.g. "never a colored card surface; color goes inside via badges,
charts, and text.">

---

## Typography Hierarchy

**Page and section headings:**
```
<classes for page title>
<classes for card section title>
```

**Body:**
```
<classes>
```

**Secondary / muted:**
```
<classes>
```

**Stat numbers:**
```
<classes>
```

---

## Numerals

<Whether the primary font ships proportional or tabular figures, and where that matters. Most UI
fonts are proportional, which means any number that changes in place — a counter, an animating
stat — visibly jitters, and numeric columns don't line up vertically.>

Apply tabular figures to:

- **Every animating number** — the fix belongs with the animation, because that's where the damage
  is
- **Right-aligned numeric table cells** — right-alignment pins the last character only; it does
  not align the digit columns above it
- **Headline stats compared against each other**

Do NOT apply them to prose, labels, IDs, or dates — tabular figures are wider and read gappy in
running text. This is a comparison tool, not a global default.

---

## Label Capitalization

<Pick one rule and write it absolutely. The common one:>

**Sentence case for actions. Title Case for names.**

Buttons, confirm dialogs, and link actions capitalize the first word only: `Save changes`,
`New item`, `Export to sheet`.

Stays capitalized inside a sentence-cased label:

- **Acronyms** — `Download CSV`
- **Proper nouns and brands** — `Export to Excel`
- **Destination page names** in back-links — `Back to <Page>`. The capitalized word is the nav
  item's own name, not part of the verb phrase.

**Headings are not actions.** Page titles and section headings keep their own casing. Don't
sentence-case a heading while doing a label pass.

---

## Badges / Pills

<Shape, size, weight, padding. Where the color mapping lives — and that it's always imported, never
hardcoded.>

---

## Buttons

**Primary:**
```
<classes, including hover>
```

**Secondary:**
```
<classes, including hover>
```

**Danger:**
```
<classes, including hover>
```

---

## Inline Text Links

<Two categories at most. More than two and nobody can predict what a link will do.>

**<Category 1 — e.g. actionable references>:**
```
<classes>
```

**<Category 2 — e.g. de-emphasized navigation>:**
```
<classes>
```

<Any color that's forbidden here, and which token invariant it would violate.>

---

## Form Inputs

```
<background, border, radius, padding, text, placeholder, focus ring>
```

<Whether selects, textareas, and comboboxes match.>

---

## Tables

- <Row striping: yes or no>
- Row separator: `<classes>`
- Column headers: `<classes>`
- Row text: `<classes>`
- Row hover: `<classes>`

---

## Empty States

Every list or table that can be empty needs a real empty state — not a blank box.

- <Icon treatment>
- <Title classes>
- <Subtitle classes>
- <Whether an action button is expected>

---

## Loading States

<Skeleton or spinner — and the rule for which. The usual line: skeletons where the shape of the
result is known and stable, spinners where it isn't. Note where each lives.>

<Also note the honest limit: a skeleton promises real data is coming. Don't use one for content
that may turn out to be empty or an error — that's a promise you can't keep.>

---

## Shadows

<Whether this project uses shadows at all. If it's a flat design, say so absolutely and say what
replaces them — usually borders. If shadows are used, table them by elevation.>

| Class | Use |
|---|---|
| <> | <> |

---

## Animations

Keyframes are defined in `<file>`.

| Class | Use |
|---|---|
| <> | <> |

### Page entrance

<How a routed page enters, what triggers the re-fire on navigation, and whether
`prefers-reduced-motion` is honored. It must be.>

### Stagger

<Whether entrance stagger is allowed. If it was tried and removed, record the measurement that
killed it — a delay that pushes the last element past ~400ms after its data arrives reads as load
time rather than polish, and someone will re-add it unless the number is written down.>

### Dialogs

<How dialogs open and close. If entrance and exit are a transition rather than an animation, say
why: an animation can't be interrupted cleanly, so closing mid-entrance leaves no before-change
style and no exit ever starts — the dialog snaps invisible while still blocking the page.
Transitions reverse from wherever they got to; animations don't.>

---

## Do Nots

The list that gets violated most. Each line should name the specific wrong thing, not the general
principle.

- <Never use <color family> for accent — the accent is <token>>
- <Never define a color outside <the token file>>
- <Never show a raw error message to a user>
- <Never hardcode a hex value in a component>
- <Never skip the class-composition helper when composing conditional classes>
