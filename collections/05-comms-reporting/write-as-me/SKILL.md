---
name: write-as-me
description: >-
  Write a document as the user, Hilario Nengare of New Analog, in the user's
  own first person voice, and save it as the file they ask for: PDF, CSV, Excel,
  Word, Markdown, plain text or anything else. Polite (please and thank you),
  plain English, bullet points, a To and From header with "Name | New Analog",
  saved to the Desktop and shown in Finder. Use whenever the user wants a file
  written for someone: "in pdf can you list", "make a pdf for", "write this up
  for Jason", "put it in a spreadsheet", "export this as csv", "excel of",
  "write it like it's me", "from me to", "a doc I can send", or typing
  /write-as-me. Distinct from /client (an update email or chat message in the
  chat window, no file) and /document (PR, changelog and release prose in the
  repo); this skill makes a file the user sends or keeps.
---

# Write as me

Write a file that reads as if Hilario wrote it, in the format they ask
for, and put it where they will see it. Every rule below comes from their own
corrections on 23 Oct 2026, while building a PDF for Jason: they wanted bullets,
not prose; first person, never "Hilario does…"; both names written as
"Name | New Analog"; please and thank you throughout; and the file on the
Desktop, because they could not find it in the home folder.

## Workflow

### 1. Work out the content, the reader and the format

- **Content**: gather it from evidence (the repo, specs, reviews, memory
  notes, the conversation), not from guesswork. Mark anything you could not
  confirm, and say so in chat when you hand the file over.
- **Reader**: the person named ("for Jason", "to the team"). If no one is
  named, write it for Hilario to keep and leave out the To and From header.
- **Format**: the one they name. With none named, use a PDF for anything sent
  to a person and a CSV for a plain list of rows. Ask only when the reader or
  the format would change the content and neither can be guessed.

### 2. Write in Hilario's voice

- **First person.** "I need", "add me", "I'll do those before I merge". Never
  name Hilario in the third person inside the document. A reader who sees
  "Hilario does X" in a note from Hilario knows a tool wrote it.
- **Header** for anything sent to a person:
  `To: <First Last> | New Analog`, `From: Hilario Nengare | New Analog`,
  `Date: <d Mon yyyy>`. If the reader works somewhere else, use that
  company's name after the bar and ask if you don't know it.
- **Open** with "Hi <first name>." and one or two sentences on why you are
  writing, ending with a thank you ("Thank you in advance for your help.").
- **Asks are polite.** Each request starts "Please" or "Please could you".
  Add "Thank you." after a costly ask (an upgrade, a payment, an account
  change).
- **Bullets, grouped under short headings.** One idea per bullet. Put what
  is blocking first, decisions only the reader can make next, and "Nothing
  needed from you here" last.
- **Plain English.** Explain each technical term in half a sentence the first
  time it appears ("a Durable Object, a small long running worker"). Put every
  number next to the thing it describes, with what it is compared to.
- **No sign-off.** End on the last section. The From line already names
  Hilario, and they removed a closing "Thank you, Hilario Nengare | New
  Analog" on 23 Oct 2026.

### 3. Build the file

Write a small Python script in the session scratchpad and run it with
`python3` (no `-I`: the libraries live in the user site packages). Keep the
script, so each revision is one edit and one rerun.

| Format | How |
|---|---|
| PDF | `reportlab` platypus: `Title`, `Heading2`, a `ListFlowable` of bullets, A4, 50 pt margins |
| Excel (.xlsx) | `openpyxl`: bold header row, frozen top row, column widths set to fit, one sheet per topic |
| CSV | the `csv` module, UTF-8, one header row, no blank rows |
| Word (.docx) | `python-docx` is not installed; ask before installing it, or use the `anthropic-skills:docx` skill |
| Markdown or text | write it directly |

For harder format work (merging PDFs, formulas, charts in a workbook), load
the matching `anthropic-skills:pdf`, `anthropic-skills:xlsx` or
`anthropic-skills:docx` skill for the mechanics. This skill still decides the
voice and where the file goes.

### 4. Check, save, show

1. Read the PDF back with the Read tool, or print the first rows of a CSV or
   sheet, and check for any third person line, any missing please, and any
   broken layout.
2. Save to `~/Desktop/<short-kebab-name>.<ext>`. On a revision, overwrite the
   same file and do not make `-v2` copies.
3. Run `open -R <path>` so Finder shows it.
4. In chat: one line naming the reader ("Written for: Jason Leigh at New
   Analog, from you."), the full path, and a short list of what is in it or
   what changed. Name any line you could not confirm.

## Examples

**Input:** "in pdf can you list what is needed from jason from the paused
worktree"

**Output:** Finds the paused worktree (`node-companion-translate-worker`),
reads its review, the spec and the memory notes, and writes a one page PDF:
"To: Jason Leigh | New Analog, From: Hilario Nengare | New Analog", then
"Hi Jason. I've written and tested the worker side… Thank you in advance for
your help." Below that come bullets under "Blocking now: Cloudflare access"
("Easiest fix: please add me as a member of the account with a Workers
role."), the plan check, keys, "Decisions only you can make" and "Nothing
needed from you here", with no sign-off at the end.
It is saved to `~/Desktop/jason-asks-translation.pdf` and shown in Finder.

**Input:** "excel of the open spec 0020 tasks for jason"

**Output:** `~/Desktop/spec-0020-open-tasks.xlsx`, one sheet with the columns
Task, What it means, Waiting on, and Your call?, written in first person ("I
build this once you've added me"). The header row is bold and frozen.

## Anti-patterns

- "Hilario will…" or "the engineer" inside the document. Hilario is the author.
- Asks without please, or a bare imperative ("Add me to the account.").
- Saving to the home folder, `/tmp` or the scratchpad and calling it done.
  They look on the Desktop.
- Paragraphs where a list would do. They asked for bullet points.
- Stating something as fact that the evidence did not show, such as whether
  keys are set. Mark it as a check and say so in chat.
- Sending or emailing the file. This skill makes the file; Hilario sends it.
- A closing sign-off under the last section. The header is enough.
- Repeating the content in chat after making the file. Give the path and a
  short summary.
