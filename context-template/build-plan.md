# Build Plan

## Core Principle

Work in **domain areas**, not phases. Each area owns its data types, its data-access layer, its
page or entry point, and its own components. An area is done when all of it works together — a
half-built area is worth nothing.

Shipped work is marked ✅. Planned or in-progress work is marked 🔲.

Phases suit a project being built once. Domain areas suit a project that keeps growing, which is
every project after the first release.

---

## Status Summary

<Two or three sentences: roughly how much is built, what drives new work (backend endpoints
landing? business requests? a migration?), and whether this is still initial build or steady
state.>

---

## Domain Areas

### 01 — Core Infrastructure <✅ | 🔲>

Everything that must exist before any feature can function.

- <Scaffold and build tooling>
- <Design tokens / theme setup>
- <Data-fetching client and its defaults>
- <Routing>
- <API client(s) — one line each, including how errors are shaped>
- <Shared utilities — name them; this is what stops the fourth reimplementation of a date
  formatter>
- <Global providers — toasts, error boundary, auth>
- <Shared UI primitives — list them by name>

---

### 02 — <Domain Name> <✅ | 🔲>

<One line on what this area does and how heavily it's used.>

**Entry point:** `<path>`
**Components:** `<directory>`

- `<Component>` — <what it does>
- `<Component>` — <what it does>

**Data:** `<hook or service>` — <what it queries and from where>

---

### 03 — <Domain Name> <✅ | 🔲>

<Repeat the shape above. One block per domain.>

---

## Adding a New Domain

The checklist for a new area, so every one comes out the same shape:

1. Types in `<types dir>` — mirror the backend contract exactly; don't invent convenience fields
2. Data-access unit in `<hooks or services dir>` — follow the canonical pattern in
   `architecture.md`
3. Entry point in `<pages or routes dir>`
4. Components in `<components dir>/<domain>/`
5. Route registered in `<router file>`
6. Nav item added in `<nav file>`
7. New area added to this file, marked 🔲 → ✅ when it works end to end

---

## Feature Count

<Rough tally by area — shipped vs planned. Useful for answering "how far along is this" without
reading the whole file.>

| Area | Shipped | Planned |
|---|---|---|
| <> | <> | <> |
