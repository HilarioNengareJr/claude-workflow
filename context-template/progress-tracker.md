# Progress Tracker

The durable record of what has actually been built, shipped, and decided. Append-only.

`architecture.md` holds the plan *before* the work. This file holds what happened *after* — which
is rarely the same thing, and the difference is the most useful thing in either file.

**Rules:**

- Newest entries at the top of their section.
- Never delete an entry. Mark it superseded and point at what replaced it.
- Absolute dates only. "Last week" is worthless in three months.
- Record what it cost, not just that it shipped — the rework, the thing that turned out harder
  than expected, the assumption that was wrong.
- One owner: this file is maintained by the tracking step at the end of a unit of work, not
  edited ad hoc mid-build.

---

## Current Status

<A live snapshot, rewritten in place rather than appended. What state is the project in right now,
what's actively being worked on, what's blocked and on whom. This is the only section that gets
overwritten — everything below it accumulates.>

**Working on:** <>
**Blocked on:** <> — <who owns unblocking it>
**Next up:** <>

---

## Shipped

### <YYYY-MM-DD> — <What shipped>

**Plan:** `architecture.md` <date of the plan block>
**Commit:** `<sha>`
**Status:** <deployed where / merged / pending release>

<What changed, in a sentence or two.>

**What it cost:**
- <The part that took longer than planned, and why>
- <Anything discovered mid-build that changed the plan>

**Known gaps:**
- <What was deliberately left undone, and whether it's tracked anywhere>

---

### <YYYY-MM-DD> — <What shipped>

<Repeat the shape.>

---

## Superseded

Work that shipped and was later replaced. Kept because the reasons still matter — someone will
eventually propose the old approach again.

### <YYYY-MM-DD> — <What it was> — superseded <YYYY-MM-DD> by <what>

<Why it was replaced. Be specific about what was wrong with it; "we changed our minds" doesn't
stop the idea coming back.>

---

## Decisions Made During Build

Decisions taken while building that weren't in any plan — the ones most likely to be silently
reversed later, because nothing records them.

| Date | Decision | Instead of | Why |
|---|---|---|---|
| <YYYY-MM-DD> | <> | <> | <> |

---

## Notes

Loose observations that don't belong anywhere else yet: things that look fragile, patterns
starting to repeat, tech debt with a name. When a note here turns into real work, it graduates to
a plan block in `architecture.md`.

- <YYYY-MM-DD> — <observation>
