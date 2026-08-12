# Architecture

Two things live in this file:

1. **The stable description of the system** — stack, folders, data flow, invariants. Sections
   below the divider. Edit in place when reality changes.
2. **A running log of implementation plans** — one block per feature, newest at the top, written
   *before* the code. Append-only. Never delete an old plan; mark it superseded.

The plan log is why this file gets large. That's fine — it's the record of why the system looks
the way it does, and it's the only place that survives after the branch is merged and the chat is
gone.

---

# Implementation Plans

> Newest first. Each block is written before building, then updated with its outcome.
> Copy the template below for each new plan.

## Implementation Plan — <FEATURE NAME> (<YYYY-MM-DD>)

### What we are building

<Two or three sentences. What changes for the user. Not how.>

### Language we agreed on

<The vocabulary this feature uses, and the words it does NOT use. This section is worth more than
it looks: it stops the same concept from acquiring three names across the codebase, the UI, and
the API. Example:>

| Term | Means | Not |
|---|---|---|
| `<term>` | <definition> | <the word we're deliberately avoiding, and why> |

### Decisions made

<Numbered list. Each entry: the decision, and the alternative it beat. A decision without its
rejected alternative can't be re-evaluated later.>

1. **<Decision>** — <why. What we gave up.>
2. **<Decision>** — <why.>

### Assumptions

<Everything taken on faith. Each one is a place this plan can break. Flag which ones are cheap to
verify and verify those before building.>

- <Assumption> — <how to check it>

### How to build it

<Ordered steps in build order, each one independently verifiable. Name real files. If a step can't
be checked when it's done, it's too big — split it.>

1. <Step> — `<path/to/file>`
2. <Step> — `<path/to/file>`

### Status

<Left blank until the work happens, then: SHIPPED <commit> / ABANDONED — <why> / SUPERSEDED by the
plan dated <date>.>

---

# The System

## Stack

| Layer | Choice | Version | Why |
|---|---|---|---|
| Language | <> | <> | <> |
| Framework | <> | <> | <> |
| Build | <> | <> | <> |
| Styling | <> | <> | <> |
| Data fetching | <> | <> | <> |
| Routing | <> | <> | <> |
| Testing | <> | <> | <> |

Note anything deliberately *not* used and why — that's the part people re-add by accident.

---

## Folder Structure

```
<repo>/
├── <src>/
│   ├── <pages or routes>/     # <what belongs here>
│   ├── <components>/          # <organizing principle — by domain? by type?>
│   ├── <hooks or services>/   # <>
│   ├── <lib>/                 # <>
│   └── <types>/               # <>
├── <tests>/
└── <config files>
```

State the rule for where a new file goes, not just where existing ones are. That's the part an
agent has to guess otherwise.

---

## System Boundaries

What this codebase owns and what it merely calls.

| Boundary | Owner | Contract |
|---|---|---|
| <e.g. the database schema> | <this repo / another team> | <migration files / OpenAPI spec / nothing formal> |

Anything the repo doesn't own can change under it. Note where that would hurt.

---

## Data Flow

### Reads

```
<UI or entry point>
  → <hook / service>
  → <client>
  → <transport>
  → <backend>
```

<One paragraph on caching, staleness, and what triggers a refetch.>

### Writes

```
<user action>
  → <mutation>
  → <client>
  → <backend>
  → <cache invalidation>
  → <UI feedback>
```

<Name the invalidation rule explicitly. Manual refetching after a write is the single most common
drift in this layer.>

---

## API Client Pattern

```
<The canonical client call, copied from real code. Include how errors are shaped and how the
response envelope is unwrapped.>
```

---

## Query / Service Hook Pattern

```
<The canonical data-access unit, copied from real code. Key naming, parameters, defaults.>
```

Every new one follows this exact shape. If a feature needs a different shape, that's an
architecture decision — write a plan block for it, don't do it inline.

---

## Key Entity Types

The three or four types that appear everywhere. Copy the real definitions.

### <Entity>

```
<type definition>
```

<One line on anything non-obvious: nullable fields that are never actually null, fields the
backend sends but nothing reads, units.>

---

## Authentication

<How a request is authorized, where the credential lives, when it expires, what happens on 401.
Never put a secret in this file — name the variable, not its value.>

---

## Invariants

Rules that must hold everywhere. If code breaks one of these, the code is wrong — not the rule.

- <Invariant — e.g. "money is always minor units in transit and in storage; formatting happens at
  the render boundary only">
- <Invariant>
- <Invariant>

Each of these should be something you could write a test for. If you can't, it's a preference —
put it in `code-standards.md` instead.
