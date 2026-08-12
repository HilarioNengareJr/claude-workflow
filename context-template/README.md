# Context Template

A reusable `context/` directory for Claude Code. Drop it into a repo, fill it in, and every
session starts knowing what the project is, how it's built, and what the rules are — instead of
re-deriving it from the code each time.

This is the source the [`import`](../collections/06-session-memory/import/SKILL.md) skill copies
from. It's boilerplate: structure and stack-neutral rules are real, everything project-specific
is a `<PLACEHOLDER>` for you to replace.

## Install

```bash
# from the root of your repo
cp -R /path/to/claude-workflow/context-template ./context
echo "context/" >> .gitignore
```

Then run `/import` (or just tell Claude "fill in the context dir from this codebase") and it will
replace the placeholders with what your repo actually does.

Keep it gitignored. It's your working context, not a team artifact — and it will contain opinions
your teammates haven't agreed to.

## The files

| File | What it holds | Who reads it |
|---|---|---|
| `project-overview.md` | What the product is, who uses it, what's in and out of scope | Every session, first |
| `architecture.md` | Stack, folder layout, data flow, invariants — plus a running log of implementation plans | Before any non-trivial change |
| `code-standards.md` | Language rules, naming, error handling, dependency policy | Before writing code |
| `build-plan.md` | Domain areas and their shipped/planned state | When picking up new work |
| `library-docs.md` | How *this* project uses each third-party library | Before touching a library |
| `progress-tracker.md` | Append-only log of what shipped, when, and what it cost | Updated after every unit of work |
| `ui-tokens.md` | Colors, type, spacing — the design token source of truth | Any UI work |
| `ui-rules.md` | Layout, component, and motion rules | Any UI work |
| `ui-registry.md` | Catalog of built components so the next one matches | Before building a component |

**Frontend vs backend.** The three `ui-*.md` files only belong in a repo with a user interface.
For a service, CLI, or library, delete them rather than filling them with fiction.

## How to fill them in

Three rules that decide whether this helps or hurts:

1. **Write what's true, not what you wish were true.** A rule the codebase doesn't follow is
   worse than no rule — it teaches the agent a pattern that doesn't exist, and every review after
   that flags the real code as wrong.
2. **Record the why, especially for reversals.** "We removed the stagger because the last stat
   landed 450ms after its data and read as load time" survives a year. "No stagger" doesn't, and
   someone re-adds it.
3. **Keep the structure, change the content.** These headings are load-bearing — skills and
   prompts reference them by name. If a section has no analog in your repo, keep the heading and
   write one line saying so.

## Conventions used in these templates

- `<ANGLE_BRACKETS>` — replace with your value.
- Fenced code blocks are illustrative shapes, not working code. Replace them with real snippets
  from your codebase once you have them; a pattern copied out of your own repo carries more weight
  than one invented for a template.
- Dated headings (`## Something (YYYY-MM-DD)`) mark decisions that superseded an earlier one.
  Keep the date — it's how you tell a current rule from a stale one.
