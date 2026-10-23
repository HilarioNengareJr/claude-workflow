---
name: clarify
description: >-
  Rewrite your last answer as a short, plain version the user can take in at a
  glance: where things stand, what is in the way, what passed, what is left, and
  the questions only they can answer. Use whenever the user says your reply was
  hard to follow: "too confusing", "what are you saying", "I don't get it",
  "explain simply", "say that again simply", "too much", "tl;dr", "short
  version", "in plain words", "what do you need from me", or types /clarify. It
  only rewrites what was already said: no new facts, no tools. Not for
  explaining a feature or codebase from scratch (that is /explain).
---

# Clarify

Rewrite the previous answer so the user gets it in one read. The last reply had the right facts but buried them under file names, ids and detail. This skill keeps the facts and drops the rest, in a fixed shape the user knows.

## Output style (plain words, no dashes, no hyphens)

<!-- OUTPUT-STYLE:START -->
Write everything this skill produces, files and messages alike, in plain simple language. Talk to the reader as `you`, warm and direct like a colleague, and present every step as a recommendation they may run or skip, never an order. Keep technical terms that carry real meaning; explain each in plain words. Never use a dash or a hyphen as punctuation: no em dash, no en dash, and no hyphenated compounds. Write `read only`, not `read-only`. Say it in simple words, or reword the sentence. Code, file paths, command flags, and values other skills match on keep their hyphens. Use short sentences, commas, or parentheses. Clear beats clever.
<!-- OUTPUT-STYLE:END -->

## Instructions

1. **Find what to rewrite.** Use your last substantive answer in this conversation. If the user points at an earlier one, use that. If there is nothing to rewrite, say so in one line and stop.
2. **Pull out five things,** and only from what you already said:
   - the verdict: where things stand, in one sentence
   - the blockers: what is in the way, and why each one matters to the user
   - what already worked
   - what is still left
   - the decisions only the user can make
3. **Translate every name into an everyday one.** "The back screen", not the glance panel's code name. "The translation server", not the worker or its port. "Another tab", not a session id. Drop file names, commit hashes, session ids, ports, spec numbers and acceptance criterion numbers. Keep a name only if the user has to type it or click it, because then they need it exactly.
4. **Write it in the template below.** Keep it under about 150 words. Leave out any section that has nothing in it (no blockers means no numbered list).
5. **Add nothing and do nothing.** No new facts, no tool calls, no fresh checks. The user asked for the same answer, said plainly, and a new fact slipped in here gets read without the scrutiny the first answer had. If you notice the earlier answer was wrong, say so in one plain line at the end instead of quietly fixing it.

## Template

```markdown
Sorry, that was too much. Here's the short version.

**<The verdict, one sentence.>** <Count> things are in the way:

1. **<Blocker in a few words.>** <One plain sentence: what happened and why it matters.>
2. **<Blocker in a few words.>** <One plain sentence.>

**<What already passed or worked>:** <one line>.

**<What is still left>:** <one line>.

**I need <count> answers from you:**

- **<Yes or no question?>** <What happens if yes.>
- **<Yes or no question?>** <What happens if no, or the alternative.>
```

Why this shape: the verdict comes first so the user knows the outcome before the reasons, and the questions come last so the reply ends on what the user has to do next.

## Example

**Input:** the user replies "this is too confusing what are you saying" to a long verify report full of session ids, worktree paths, APK timestamps, ports and AC numbers.

**Output:**

```markdown
Sorry, that was too much. Here's the short version.

**I can't finish checking the Translate screen yet.** Two things are in the way:

1. **The phone has a different version of the app on it.** Another tab put the ChatGPT assistant version on at 14:45, so your Translate code isn't on the phone right now.
2. **Translation can't actually run.** It needs the translation server, and that needs keys that aren't set up yet.

**The simple parts already passed:** the Translate page shows up, and pressing it on the back screen says "open the app to translate".

**The parts still to check** are the ones that need a real translation running: the face, the lines and the stop button.

**I need two answers from you:**

- **Can I put the Translate version back on the phone?** That replaces the assistant version.
- **Do you have the translation server keys?** If not, we wait for your teammate to deploy the server.
```
