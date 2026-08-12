# Library Docs

Project-specific usage patterns for every third-party library in this project.

This file is **not** a replacement for the library's own documentation. It covers only how *this*
codebase uses each library — the patterns, the constraints, and the places where the library's
recommended approach and this project's approach differ.

Read the relevant section before implementing anything that touches these libraries.

---

## Before Using Any Library

1. **Check whether a docs MCP server is configured** for it — live docs beat training data, which
   is stale by definition for any actively maintained library.
2. **Check `AGENTS.md` / `CLAUDE.md`** at the repo root for project-level guidance.
3. **Read this file** for the project rules that override general knowledge.

Order of authority:

```
MCP server (live docs) → project skills → this file (project rules) → general training knowledge
```

Where this file and the library's docs disagree, this file wins — it describes a decision that
was already made and paid for.

---

## <Library Name> <version>

### <Pattern name — e.g. "Query — basic read">

```
<Real code from this codebase. Not from the library's README — from here. Include the imports.>
```

<One or two lines on the non-obvious parameters and why they're set that way.>

### <Pattern name — e.g. "Mutation — write and invalidate">

```
<Real code.>
```

### Constraints

- <Something this project deliberately doesn't use from this library, and why>
- <A footgun hit before and the fix>

---

## <Library Name> <version>

<Repeat the shape. One section per library that has a project-specific pattern.>

A library with no project-specific pattern doesn't need a section here — leaving it out is
information too.

---

## Version Pins

Libraries where the exact version matters, and what breaks if it moves:

| Library | Pinned to | Why |
|---|---|---|
| `<pkg>` | `<version>` | <the breaking change being avoided> |
