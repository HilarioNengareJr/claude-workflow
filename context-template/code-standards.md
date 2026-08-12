# Code Standards

Implementation rules and conventions for the whole project. The agent follows these in every
session without exception. These rules exist to prevent pattern drift — the slow divergence that
happens when each session invents its own approach.

---

## Engineering Mindset

The agent on this project operates as a senior engineer. That means:

- **Think before implementing** — understand what is being built and why before writing a line
- **Read context files first** — never assume; verify against `architecture.md` and
  `project-overview.md`
- **Scope is sacred** — build only what the current task requires, even when more seems helpful
- **Every change must be verifiable** — if it can't be checked right after it's written, it isn't
  finished
- **Clean over clever** — readable code a junior can follow beats a clever abstraction, always
- **One thing at a time** — finish one feature before touching the next
- **Failures are expected** — handle them explicitly; never let one failure take down everything
  around it

This section is stack-neutral on purpose. Keep it as-is unless you actively disagree with a line.

---

## <LANGUAGE>

<Rules for the primary language. Be specific and absolute — "prefer" gets ignored, "never" gets
followed. Examples of the shape:>

- Strict mode on, no exceptions
- Never use `<the escape hatch>` — use `<the safe alternative>` and narrow
- All function parameters and return types explicitly typed
- <Convention for when to use each of two similar constructs>
- Errors handled explicitly — nothing floats unhandled

---

## <FRAMEWORK> Conventions

<Rules specific to the framework, including what this project deliberately does NOT use. That
negative list matters: it stops an agent importing a pattern from the framework's docs that
doesn't apply here.>

- <What kind of app this is, and what that rules out>
- <Where data fetching is allowed to happen — and where it isn't>
- <Where mutations live>
- <What a page/route component is allowed to do>
- <What a leaf component is allowed to do>

---

## File and Folder Naming

- Folders: <case style> — `<example>`, `<example>`
- <Component/module> files: <case style> — `<example>`
- <Hook/service> files: <case style> — `<example>`
- Utility files: <case style> — `<example>`
- Type files: <case style> — `<example>`
- <One unit per file? Barrel exports allowed?>

---

## <Component / Module> Structure

Every one follows this exact order:

```
<Copy a real, small, exemplary file from the codebase. Annotate the sections with numbered
comments: imports, types, the unit itself, in the order they must appear.>
```

- <Export style — named vs default, and no exceptions>
- <Where types live relative to what uses them>
- <Styling rule>

---

## <Mutation / Write> Pattern

```
<The canonical write path, copied from real code.>
```

- <Cache invalidation rule>
- <What never happens — e.g. "never manually refetch; let invalidation do it">
- <Where error handling belongs in this path>

---

## User Feedback / Notifications

```
<The real API for showing success and failure to a user.>
```

- <When feedback is mandatory>
- <How errors are formatted before display>

---

## Error Handling

- Never use empty catch blocks — handle or re-throw
- User-facing errors always go through `<the formatter>`
- Log with a context prefix: `<the format>`
- Never surface raw backend or third-party error bodies to a user

---

## Logging / Analytics

<The library, the event naming convention, and what is never logged (PII, tokens, full request
bodies). If there's nothing configured, write "None configured — N/A" rather than deleting the
heading; the absence is itself useful to know.>

---

## Environment Variables

Defined in `<.env.local or equivalent>` for development. Never hardcode a URL or a secret.

| Variable | Used in | Notes |
|---|---|---|
| `<VAR>` | `<file>` | <build-time or runtime? injected how?> |

Note which variables are build-time-inlined versus runtime-injected — getting that wrong produces
a build that silently ships the wrong environment's config.

**Never commit a real secret to any file in this directory.** Name the variable, not the value.

---

## Import Aliases

Always use the `<@/>` alias — never relative imports that climb more than one level.

```
// Correct
<import example>

// Never
<import ../../../ example>
```

---

## Comments

- No comments explaining *what* the code does — the code says that
- Comments only for *why* — non-obvious decisions, workarounds, constraints that aren't visible
  locally
- Never leave TODO comments in committed code — file it in the tracker instead

---

## Dependencies

Never add a package without a clear reason. Check first:

1. Does the standard library or a platform API already cover this?
2. Does an existing dependency already do it?

Approved runtime dependencies:

- `<package>` — <what it's for>
- `<package>` — <what it's for>

Do not install anything not on this list without adding it here first. The list is the gate — an
undocumented dependency is an unreviewed one.
