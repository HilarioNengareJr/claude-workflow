---
name: import
description: Import the personal context-template directory from {{CONTEXT_SRC_DIR}} into the current repo, gitignore it, then adapt the stack-specific content of each file to match the current codebase's purpose and direction while preserving the directory's structure exactly. Use this whenever starting Claude Code work in a new or existing repo and you want your reusable context scaffolds grounded in THIS project — triggers on "import my context", "bring in the context dir", "set up context for this repo", "ground my context templates here", or any request to adapt the context-template files to the current working directory.
---

# Import Context

You are a senior engineer setting up a repo's context layer. Your job is to take the user's
personal, reusable context-template directory and ground it in the current codebase — replacing
the stack-specific content so it describes THIS project, while leaving the structure untouched.

This is the user's private tooling. It is copied in, never committed. You preserve the file and
section structure exactly and only swap the *content* that is specific to a stack, product, or
domain. You do a replace-and-fill, not a redesign.

Work through the steps in order. Do not skip the gate.

---

## 1. Locate the source — read only, change nothing

The source lives in the user's context-template directory: `{{CONTEXT_SRC_DIR}}`.

- `ls -R {{CONTEXT_SRC_DIR}}` and find the context directory inside it (it may be `context/`,
  `skills-main/context/`, or similar — locate it, don't assume the exact subpath).
- If you can't find a context directory there, STOP and show the user what you found so they can
  point you at the right path.
- Treat everything under `{{CONTEXT_SRC_DIR}}` as READ-ONLY. Copy out of it; never move,
  rename, or edit the originals.

Show the user the full tree of context files you found before continuing.

## 2. Import into the current repo — protect any existing context

- Target is `./context/` at the root of the current working directory.
- If `./context/` already exists, do NOT overwrite it. Rename the existing one to `context-v1`
  (and if `context-v1` exists, `context-v2`, and so on), then copy the fresh templates into a
  clean `./context/`.
- Copy every context file across, preserving filenames and any subfolder structure exactly.

## 3. Gitignore it

This directory is personal tooling, not a team artifact.

- Ensure `context/` is ignored. If a `.gitignore` exists, append `context/` if it isn't already
  there. If not, create one with that entry.
- Do not stage or commit the context directory.

## 4. Determine the repo's purpose and direction

You need to know what this codebase IS before you can adapt the content to it.

- First, try to read the purpose from the repo itself: `package.json` / `go.mod` / `pyproject.toml`
  / `Cargo.toml`, the `README`, the top-level directory structure, the dominant language and
  framework, the test and build tooling, and any existing `CLAUDE.md`.
- If the user handed you a plan (an `architecture.md`, a written brief, or a description in chat),
  treat that as the authoritative statement of direction and read the repo to confirm and fill gaps.
- Write down, in one or two sentences, what this repo is and what stack it uses. You will use this
  as the target for every replacement in the next step.

If after reading the repo and any plan you still can't tell what the project is, STOP and ask the
user for a one-line description rather than guessing.

## 5. Adapt each file — replace and fill, never restructure

For every context file, keep the section structure exactly as the template has it (e.g. for a
code-standards file: engineering mindset → language conventions → file naming → error handling →
dependencies). Inside that structure, replace the stack/product/domain-specific content with the
equivalent for THIS codebase, observed from the actual code — not invented.

- Swap language and framework rules (e.g. TypeScript/Next/InsForge content) for what the repo
  actually uses (Go, React, Python, etc.).
- Replace product- and domain-specific names, examples, and conventions with this repo's.
- Where the template states a rule, write the rule that is true in THIS codebase based on what you
  observe, not the template's original rule.
- **Skip files that don't apply to this repo.** The UI set (`ui-tokens.md`, `ui-rules.md`,
  `ui-registry.md`) belongs only in a frontend repo — for a backend/service repo, leave them out of
  the imported set rather than filling them with fiction. Note to the user which files you skipped
  and why.
- Do not add, remove, reorder, or rename sections. If a section genuinely has no analog in this
  repo, keep the heading and note the absence in one line rather than deleting it.

## 6. Gate — confirm before finalizing

Before you treat the import as done, show the user:

- The final file list (imported, adapted, skipped, and any `context-vN` you renamed).
- For one representative file, a short before/after of the content you changed, so they can sanity-
  check the adaptation direction.
- The `.gitignore` line you added.

Then say: **`Context imported and adapted — review before you build on it.`** Wait for the user.

## 7. Coherence pass

After confirmation, read the adapted set as a whole and make sure it's internally consistent:

- The stack, naming conventions, and patterns described in one file don't contradict another.
- Every file describes the SAME project (no leftover references to the source project's stack,
  product names, or domain).
- Cross-references between files still resolve.
- Nothing claims a rule the codebase doesn't actually follow.

Fix any drift you find, then give the user a one-paragraph summary of what the context layer now
asserts about the repo.

---

## What this is NOT

- This is NOT a redesign of the context structure. You preserve the template's shape exactly and
  only change content. If you find yourself wanting to add or reorder sections, stop — that's out
  of scope.
- This is NOT a committed team artifact. It stays gitignored and personal.
- This is NOT content invented to fill a template. Every rule you write must be grounded in what
  the repo actually does, or explicitly flagged as a placeholder for the user to fill.
- This does NOT touch the source originals in `{{CONTEXT_SRC_DIR}}`. Copy out, never modify.
