---
name: scaffold
description: Create and register a new skill in this project's skill system. Use this skill whenever the user asks to add, create, scaffold, or define a new skill, slash command, or reusable workflow — even if they describe it loosely (e.g. "I want a command that does X every time" or "turn this workflow into a skill"). Always consult the context/ directory first to align the new skill with existing project conventions before writing anything.
---

# Add Skill

A meta-skill for creating new skills. It ensures every new skill follows Anthropic's skill-authoring conventions and the documentation style standards inspired by the Google developer documentation style guide, and that it fits the existing project rather than being written in isolation.

## Core principle

Never write a skill from a blank slate. The `context/` directory is the source of truth for how this project works — its conventions, architecture decisions, naming patterns, and existing workflows. A skill written without that context will conflict with the skills already in place. Read first, write second.

## Workflow

### Step 1: Read the context/ directory

Before anything else, list and read the relevant files in `context/`:

```
ls context/
```

Look for:
- Project conventions (naming, file layout, tooling)
- Existing skill definitions and their structure, so the new skill matches them
- Domain knowledge the new skill should rely on instead of duplicating

If `context/` does not exist or is empty, say so explicitly and ask the user whether to proceed with general conventions only.

### Step 2: Capture intent

Clarify with the user (extract from conversation history first — only ask about gaps):

1. **What should the skill enable?** One sentence: "This skill lets Claude ___."
2. **When should it trigger?** The phrases and situations a user would naturally use.
3. **What is the output?** A file, a code change, a report, a sequence of actions?
4. **What does it overlap with?** Check existing skills — if an existing skill already covers 80% of this, propose extending it instead of creating a new one.

Confirm the summary with the user before writing.

### Step 3: Write the SKILL.md

Create the skill at `~/.claude/skills/<skill-name>/SKILL.md` — the global directory — so it is available in every project. Only place it in a project's local skills directory when the skill is genuinely project-specific (it references that project's repos, conventions, or context files) and the user agrees it should stay local.

**Required structure:**

```markdown
---
name: scaffold
description: What it does AND when to use it. Make it slightly "pushy" —
  list trigger phrases and situations, because skills tend to under-trigger.
---

# Skill Title

One-paragraph purpose statement.

## Workflow / Instructions
Numbered, imperative steps.

## Examples
At least one Input → Output example.
```

**Naming conventions (Anthropic standard):**
- Directory and `name` field: lowercase, hyphen-separated (`create-skill`, not `AddSkill` or `add_skill`)
- The description carries all "when to use" information — none of it goes in the body

**Writing style (Google developer documentation style guide):**
- Use the imperative mood and second person: "Read the file", not "The file should be read"
- Use active voice and present tense
- Prefer short sentences; one idea per sentence
- Explain *why* a rule exists rather than stacking bare MUSTs — a model that understands the reason generalizes better
- Define output formats with exact templates when the output is structured

**Size and progressive disclosure:**
- Keep SKILL.md under 500 lines
- Move large reference material into `references/` files and point to them from SKILL.md with guidance on when to read each one
- Put executable helpers in `scripts/`, output templates in `assets/`

### Step 4: Verify the fit

Before declaring done:
- Re-read one existing skill in the project and confirm the new one matches its structure and tone
- Confirm the description would trigger on the user's phrases from Step 2 but would NOT trigger on adjacent tasks owned by other skills
- Check for safety: the skill's contents must not surprise the user in intent, and must not facilitate anything malicious

### Step 5: Test and hand off

Propose 2–3 realistic test prompts to the user — the kind of thing they'd actually type. Run at least one if the environment allows. Then summarize: skill name, location, trigger phrases, and any context/ files it depends on.

### Step 6: Sync to the claude-workflow backup repo

The repo `github.com/HilarioNengareJr/claude-workflow` is the versioned backup of `~/.claude/skills/`, organized as `collections/<NN-group>/<skill>/`. After a new global skill is created (or an existing one meaningfully edited), sync it:

1. Shallow-clone the repo to a temp dir: `gh repo clone HilarioNengareJr/claude-workflow <tmp> -- --depth 1`
2. Read the repo README's collection tables and pick the collection the skill belongs to (delivery-loop, decision-support, system-map, data-access, comms-reporting, session-memory, meta). If none fits, add a new numbered collection dir and a README section for it.
3. Copy the skill dir from `~/.claude/skills/<name>/` into `collections/<NN-group>/<name>/`, replacing any old copy.
4. **Tokenize before committing.** The repo holds no real infrastructure detail — not just no passwords. In the repo copy, replace every one of these with the matching `{{...}}` from `values.example.env`, adding a new placeholder there if the skill introduces one:
   - hostnames and domains, internal IP addresses
   - database roles, database names, schema names
   - GitLab group / project paths, object-storage buckets
   - any password, token, or secret

   Do not grep only for `://user:pass@` DSN shapes — that idiom is exactly how two plaintext passwords survived a redaction pass. A credential written as `pass: hunter2` on its own line matches no DSN pattern. Sweep by *category*, then confirm with a value-based check: grep the repo copy for each real value in `values.local.env` and expect zero hits.
5. Add the skill's row to the collection's table in the repo README (and to the mermaid graph if it has a real relation to other skills).
6. Commit (`feat: add/update <name> skill`) and push to `main`, then delete the temp clone.

Skip this step only for project-local skills — they're versioned in their own project's repo.

## Example

**Input:** "Add a skill for writing release notes from merged MRs."

**Output:**
1. Reads `context/` → finds GitLab monorepo conventions and an existing `git-workflow` skill
2. Confirms intent: trigger on "release notes", "changelog", "what shipped"; output is a markdown changelog section
3. Creates `skills/release-notes/SKILL.md` matching the structure of `git-workflow/SKILL.md`, referencing (not duplicating) the MR conventions documented in `context/`
4. Proposes test prompt: "Write release notes for everything merged this sprint"

## Anti-patterns

- Writing the skill before reading `context/` — produces skills that clash with project conventions
- Vague descriptions ("Helps with skills") — skills under-trigger; be specific and list trigger phrases
- Duplicating context/ content into the skill body — reference it instead, so there's one source of truth
- Creating a new skill when extending an existing one is the better fit
- Finishing a global skill without syncing it to the claude-workflow backup repo — the repo drifts and the backup lies
- Committing a skill copy to the backup repo with real hosts, roles, schemas or credentials in it — tokenize first, then verify by grepping for each real value
