---
name: skills
description: List all the user's personal skills (every skill in ~/.claude/skills/) with each one's name and a short description of what it does. Use this skill whenever the user wants to see their skills, asks "what skills do I have", "list my skills", "show my personal skills", "what can you do here", "what commands are available", or types /skills. This reads the live skills directory, so it always reflects the current set — prefer it over answering from memory.
---

# Skills

Display the user's personal skills — the ones installed globally in `~/.claude/skills/` — as a table of name and purpose. Read the directory live so the list is always current; never answer from memory or a cached list.

## Instructions

1. List the skill directories:

   ```
   ls -1d ~/.claude/skills/*/
   ```

2. For each directory, read the `name:` and `description:` fields from its `SKILL.md` frontmatter. Do this in one pass — for example:

   ```
   for d in ~/.claude/skills/*/; do
     name=$(grep -m1 '^name:' "$d/SKILL.md" | sed 's/name: *//')
     desc=$(grep -m1 '^description:' "$d/SKILL.md" | sed 's/description: *//')
     printf '%s\t%s\n' "$name" "$desc"
   done
   ```

3. Print the result as a markdown table, one row per skill, sorted alphabetically by name. Shorten each description to its first sentence — the trigger phrases in the frontmatter are for matching, not for display. Lead the command name with a slash so it is copy-pasteable.

4. End with the total count: "N skills."

Skip any directory whose `SKILL.md` is missing or has no `name:` field, and note it briefly if so. Do not invent skills that are not on disk.

## Output template

```
| Skill | What it does |
|---|---|
| /break | Stress-test a feature against edge cases and run the tests. |
| /build | Build a confirmed plan like a senior engineer. |
| … | … |

13 skills.
```

## Example

**Input:** "/skills" or "what skills do I have?"

**Output:** the table above, populated from the live contents of `~/.claude/skills/`.
