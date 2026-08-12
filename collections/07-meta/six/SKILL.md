---
name: six
description: Render a quick-reference card for the six workflow-multiplier
  skills added on 2026-07-08 — /cycle, /standup, /db, /client, /flow, /drift —
  with each one's current one-line purpose (read live from disk) and a map of
  how they fit into a working day. Use when the user wants to see or revisit
  this set: "six", "show me the six", "the new skills", "what did we add",
  "the multiplier skills", "how do the new skills fit together", or typing
  /six. NOT for the full skill list — that's /skills; this is the cheat-sheet
  for the delivery-loop set only.
---

# Six

Show the six-skill set that turns the {{PRODUCT}} workflow into a loop: the morning
brief, the delivery cycle, and the on-demand tools around them. Read the
current state from disk so the card never lies about what exists.

## Instructions

1. The set, fixed: `cycle`, `standup`, `db`, `client`, `flow`, `drift`.

2. For each, read the live frontmatter from
   `~/.claude/skills/<name>/SKILL.md`:

   ```bash
   for s in cycle standup db client flow drift; do
     f=~/.claude/skills/$s/SKILL.md
     if [ -f "$f" ]; then
       grep -m1 '^name:' "$f" >/dev/null && echo "$s: present"
     else
       echo "$s: MISSING"
     fi
   done
   ```

   Summarize each description to one plain sentence for display. If one of the
   six is missing or renamed on disk, say so in the card — don't render it
   from memory.

   **The set of six is a hand-curated snapshot (2026-07-08), not a live query.**
   Skills added since won't appear here even if they belong. This card is a
   cheat-sheet for a specific set, not a claim about what exists — if the user
   seems to want "everything," point them at `/skills`.

3. Render the card:

   ```markdown
   ## The six

   | Skill | One line |
   |---|---|
   | /standup | [live one-liner] |
   | /cycle   | [live one-liner] |
   | /db      | [live one-liner] |
   | /client  | [live one-liner] |
   | /flow    | [live one-liner] |
   | /drift   | [live one-liner] |

   ## How they fit a day

   morning   → /standup   (bearings + plan)
   build     → /cycle     (refine → architect → build → review → break → ship → watch → track)
   any time  → /db        (prod data questions)
               /flow      (n8n / support-chat automations)
               /drift     (are the frontends still on contract?)
   outbound  → /client    (tell the stakeholders, honestly)
   ```

4. Close with one line noting `/skills` shows the complete set of all personal
   skills, not just these six.

## Example

**Input:** "/six"

**Output:** The card above with live one-liners, e.g. `/db — query {{COMPANY}}'s
production Postgres safely, read-only, cents shown as rands`, followed by the
day map and the `/skills` pointer. If `/drift` had been deleted, its row reads
"missing from disk" instead of a description.

## Anti-patterns

- Rendering descriptions from memory instead of the live files — the card
  must reflect today's frontmatter, including edits made since 2026-07-08.
- Growing the set. If a seventh skill joins the loop later, that's an edit to
  this file, not an inference at render time.
- Duplicating /skills — this card is the curated six, nothing more.