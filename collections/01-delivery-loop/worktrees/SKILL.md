---
name: worktrees
allowed-tools: Bash, Read, Grep, Glob, Agent, AskUserQuestion, Skill
argument-hint: "[all | <worktree name or path>]"
description: >-
  Run /ultron-worktrees to see every git worktree of a repo at once: which are
  finished and safe to remove, which hold unfinished edits or commits main
  does not have, which are live in another session right now, what each one
  was for and what is left to continue, and which ones overlap and should be
  consolidated into one. Matches commits by patch, so work pushed by cherry
  pick counts as landed. Reports first, read only; then offers cleanups and
  consolidations one at a time, each on your yes, never with --force. Use for
  "worktree status", "check my worktrees", "which worktrees can I delete",
  "clean up worktrees", "what's unfinished", "what's in progress", "what was I
  doing in", "what needs continuing", "consolidate the worktrees", "too many
  worktrees", "loose ends", or typing /ultron-worktrees. Pass `all` for every
  repo under ~/projects, or a worktree name for one in depth. Not for pushing
  (/ship) or the day's plan (/ultron-brief-me).
---

<!-- ULTRON-DISPATCH:START -->
## Agent dispatch (local skill, spec 0001)

The reading and sorting run in their own agent, on the model and effort set in `~/.claude/ultron/models.md`. Before spawning, read `~/.claude/ultron/dispatch.md` and follow its protocol and the `worktrees.read` brief. No Agent tool in this client? Run everything inline as written below, and say so once.

| Step | Runs as |
|---|---|
| Step 0 (the argument, which repos, the twin check) | main thread, because only you can see this session and the other live ones |
| Steps 1 to 3 (survey, read each worktree, sort, find overlaps) | phase `worktrees.read` |
| Step 4 (the report, the offers, every git action on a yes) and Step 5 (handoffs) | main thread, from the agent's report |
<!-- ULTRON-DISPATCH:END -->

## Output style (plain words, no dashes, no hyphens)

<!-- OUTPUT-STYLE:START -->
Write everything this skill produces, files and messages alike, in plain simple language. Talk to the reader as `you`, warm and direct like a colleague, and present every step as a recommendation they may run or skip, never an order. Keep technical terms that carry real meaning; explain each in plain words. Never use a dash or a hyphen as punctuation: no em dash, no en dash, and no hyphenated compounds. Write `read only`, not `read-only`. Say it in simple words, or reword the sentence. Code, file paths, command flags, and values other skills match on keep their hyphens. Use short sentences, commas, or parentheses. Clear beats clever.
<!-- OUTPUT-STYLE:END -->

# Worktrees

Worktrees pile up. Each one started for a reason (a tracer, a debug run, a
review, a scratch push), and after a few days nobody remembers which ones
still hold work. This skill tells you, for each one, whether it is finished,
live, unfinished, or ready to land, what it was for, and what is left. Then it
helps you tidy up, one safe step at a time.

## Asks vs acts

Acts first, asks after. The report comes with no questions before it. Every
change (remove a worktree, delete a branch, prune, move edits) is its own
offer, asked with `AskUserQuestion`, and runs only on a yes. The one write in
the survey is `git fetch --prune origin`, which updates the remote tracking
refs and touches no file or local branch.

## Why these checks

Plain "is the branch merged" is not a safe sign a worktree is done. Each check
below closes a gap that a simple merged check misses.

| Check | Why |
|---|---|
| `git cherry <base> HEAD` | Matches commits by patch, not by hash. A commit pushed by cherry pick from a scratch worktree shows `-` (landed), not `+`. A plain `git branch --merged` would call it unmerged |
| Files the branch changed, compared with base | Catches squash and hand merges, which `git cherry` misses. "12 of 12 files match main" means the content landed |
| Dirty files compared with base | An uncommitted edit whose content already sits on main is stale, not lost work |
| Dirty or untracked files at all | A merged branch can still carry live uncommitted edits. `git worktree remove` refuses a dirty tree; `--force` would destroy them |
| Live session (a `claude` process with its working folder here) and fresh scratchpad files | A worktree another window is using is never cleaned, whatever its git state says |
| Operation in progress (rebase, merge, cherry pick) | Half done state; removing it loses the operation |
| `git worktree prune --dry-run` | Shows metadata for folders deleted by hand. Prune only clears that metadata, never a live worktree |

Sources (read 21 Oct 2026): the [git-worktree manual](https://git-scm.com/docs/git-worktree)
(porcelain list, locked, prunable, `prune --dry-run`), the
[git-cherry manual](https://www.kernel.org/pub/software/scm/git/docs/git-cherry.html)
(patch matching), and three published cleanup skills that agree merged alone
is not enough:
[worktree-hygiene](https://tessl.io/registry/skills/github/EpicenterHQ/epicenter/worktree-hygiene)
(dirty check before remove, `git cherry` for unmerged commits),
[nv-worktree-cleanup](https://tessl.io/registry/skills/github/novuhq/novu/nv-worktree-cleanup)
(fetch first, squash merges, `-D` only on confirm), and
[worktree-cleanup](https://tessl.io/registry/skills/github/shousper/claude-kit/worktree-cleanup)
(cleanup only when you ask, never automatic).

## Workflow

### Step 0: scope and the twin check (main thread)

1. **Route on the argument.**
   - none: the repo you are in.
   - `all`: every repo under `~/projects` (and `~` for checkouts like
     `~/Glance`) whose `git worktree list` shows two or more entries.
   - a name or path: that one worktree, in depth (full dirty diff stat, every
     unique commit, the spec it belongs to).
2. **Read the repo's own rules.** Read its `AGENTS.md` and `CLAUDE.md`, and
   Claude's project memory (`~/.claude/projects/<repo path with every / as
   ->/memory/MEMORY.md`). Look for three things and pass them to the agent:
   commits that stay local by rule (node-companion: subjects with
   `local only, never pushed` or `docs/scope`, see its memory
   `push-without-the-scope-commit`), checkouts never pushed (node-companion:
   `~/Glance-node-page`), and how work lands (push to main, PRs, cherry pick).
3. **The twin check.** Note this session's own working folder and pid, so the
   agent can tell your session from another. Run `ListAgents` if you have it.

### Step 1: survey (phase `worktrees.read`)

```bash
~/.claude/skills/worktrees/scripts/survey.sh <repo path>
```

It prints one block per worktree (branch, head, dirty files, unique and
picked commits, content on main, behind base, on origin, live session pids,
fresh scratchpad files) and a repo block (stashes, prune dry run, worktrees
on one commit, files dirty in two worktrees, branches with unique commits
and no worktree). Add `--no-fetch` when offline. With `all`, run it once per
repo.

### Step 2: read each worktree and sort it

For every worktree, find what it was for and what is left:

- **Its purpose.** Match the branch and folder name to a spec
  (`docs/specs/NNNN-*`), a scope row (`docs/scope/`), and memory notes that
  name the folder (for example node-companion's `row-52-build-spec-0013-now`
  names `node-companion-day`). Quote the source.
- **What is left.** For a spec, read its `verify.md` and status line: which
  checks are unticked. For dirty files, read `git -C <wt> diff --stat` and
  the start of the diff, and say in one line what the edit does.
- **How old.** The newest edit and the last commit date.

Then put it in exactly one bucket, first match wins:

| Bucket | Rule | Next step |
|---|---|---|
| Live | a live session pid in it, or scratchpad files written in the last 30 minutes | Leave it alone. Name the session |
| Broken | missing folder, prunable, locked with no reason, or an operation in progress | Explain; offer `git worktree prune` or say how to finish the operation |
| Ready to land | clean tree, unique commits that are not local by rule, and their files do not already match base | `/ship` from that worktree |
| To continue | dirty edits that are not already on base, or unique commits with dirty edits | Say what is left and which skill resumes it: `/ultron-develop` for a spec build, `/ultron-debug` for a `debug/*` branch, `/ultron-check verify` when the build is done and proof is owed |
| Kept by rule | the main checkout, or a checkout the rules say never pushes, whose only unique commits are local by rule | Nothing. Say so, so nobody pushes them |
| Home of open work | git says Finished, but a memory note, scope row or spec names this folder as where open work runs (21 Oct 2026: `node-companion-day` was clean and landed, yet its memory note says milestone 3 runs from there) | No removal offer. Quote the note and what is open |
| Finished | clean tree, and no unique commits except ones local by rule, or every changed file already matches base | Offer removal |
| Stale edits | dirty, but every dirty tracked file already matches base and there are no untracked files | Offer to remove after a look at the diff |

Untracked files never count as stale: they exist nowhere else. Uncommitted
docs such as `docs/reviews/*.md` in a review worktree are real work until
someone copies them somewhere.

### Step 3: find what to consolidate

Look across worktrees for:

- **One file dirty in two worktrees.** Compare the two diffs. Same edit: one
  copy is spare. Different edits: they will conflict when both land; say which
  to finish first.
- **Two worktrees on one commit, or one feature.** Two folders for one spec or
  one tracer usually means one is spare. Keep the one with the edits or the
  newer use.
- **Spare scratch worktrees.** Detached worktrees left from a cherry pick push,
  clean and fully landed.
- **Stashes.** They are shared by every worktree. List each with its date and
  say which worktree it likely belongs to.
- **Branches with unique commits and no worktree.** Loose ends with no home;
  name them, and check whether their content already matches base
  (`git diff --stat <base>...<branch>` against `git diff --stat <base> <branch>`
  over the files the branch touched).
- **Scope or local only commits copied into several worktrees.** The main
  checkout holds the newest copy; the others are spare once their worktree
  goes. Say so, so nobody pushes an old copy.

Return the report in the *Output shape* below. Every line comes from a
command run in this pass, never from memory.

### Step 4: report, then offer (main thread)

Show the report. Then make the offers, most valuable first, one
`AskUserQuestion` per group (for example "Remove these 6 finished worktrees?"
with options all, pick one by one, none). Before each action, check the state
again (`git -C <wt> status --porcelain`, the live pids, `git -C <wt> rev-parse
HEAD`): another session can change a worktree between the survey and your yes.

The only commands you run, and only on a yes:

| Action | Command | Never |
|---|---|---|
| Remove a finished worktree | `git worktree remove <path>` | `--force`. If it refuses, the tree is dirty: report it, do not force |
| Delete its branch | `git branch -d <branch>` | `-D`, unless the branch's files all match base and you said yes to that branch by name |
| Clear metadata of deleted folders | `git worktree prune --verbose` after the dry run | prune while a folder is only unmounted; `git worktree lock` it instead |
| Carry edits from a spare worktree to the keeper | `git -C <spare> diff > <scratchpad>/<name>.patch`, then `git -C <keeper> apply --check` and `git -C <keeper> apply` | remove the spare before the keeper shows the edit in `git status` |
| Copy untracked files to the keeper | `cp -n` into the same path | overwrite an existing file |

Never push, commit, reset, rebase, check out, or drop a stash: those belong
to `/ship` or to you. A worktree in the Live bucket gets no offer.

### Step 5: hand off (main thread)

For each Ready to land worktree, offer `/ship` with its path. For each To
continue worktree, name the skill and the exact first command, in the order
worth doing, one line of why each. Invoke a skill only on a yes.

## Output shape

```
Worktrees in <repo>: <N> (base <origin/main> @ <sha>, fetched <time | skipped>)

Live (leave alone)
  <folder>  <branch>  session <pid>, <what it is doing if known>

To continue
  <folder>  <branch>  <age>  <purpose, with source>
    left: <unticked checks or what the dirty edit does>
    resume: /<skill> <args>

Ready to land
  <folder>  <branch>  <n> commits: <subjects>   → /ship from <path>

Finished (safe to remove)
  <folder>  <branch>  <why: clean, n commits landed by patch | files match main>

Kept by rule
  <folder>  <n> local only commits (<rule source>)

Broken
  <folder>  <what is wrong>

Consolidate
  <one line per overlap, with the keeper named>

Loose ends: <stashes and branches with no worktree>
```

Leave out an empty bucket. Use folder names, not full paths, except in
commands.

## Examples

**Input:** `/ultron-worktrees` in node-companion, 15 worktrees.

**Output:** the survey shows `node-companion` (main) with live session pids,
so Live, and its 4 unique commits all carry `local only, never pushed`
subjects, so the report adds "kept by rule, never push these". `node-companion-case-copy`, `-live`, `-prefs`,
`-shade`, `-touch` are clean with no unique commits: Finished.
`node-companion-0018` shows 4 picked commits and 0 unique: Finished, its work
landed by cherry pick. `-row29` has 3 unique commits, all scope commits that
stay local by rule: Finished. `-cigate` and `-micwords` hold edits to tests
and source that main does not have: To continue, with `/ultron-debug` to
resume each. `-review` has two untracked review files: To continue (copy them
or commit them first). `-review` and `-touch` sit on one commit
(`de5accf`): Consolidate, keep `-review` for its files. Loose ends: two
stashes on main and the branches `secret/guard` and
`wip-glance-18-19-on-c6a1da8`. Then one offer: "Remove the 8 finished
worktrees?"

**Input:** `/ultron-worktrees node-companion-cigate`

**Output:** that one worktree in depth: 5 dirty files (the CI gate test, its
gh stand in, and spec 0004's three files), none of them already on main, last
edit 19 Oct 14:25, 63 commits behind. Purpose: the spec 0004 CI gate wait.
Left: the unticked rows in `docs/specs/0004-ota-waits-green-ci/verify.md`.
Resume: `/ultron-debug` in that folder, after it rebases onto main.

## Anti-patterns

- Calling a branch finished because `git branch --merged` lists it. It misses
  cherry picks and ignores dirty edits.
- `git worktree remove --force` or `git branch -D` without a yes for that
  exact worktree or branch.
- Acting on the survey after time has passed without checking the state
  again.
- Cleaning a worktree with a live session, even if git says it is clean.
- Calling local only scope commits "unpushed work" and suggesting a push.
- Treating untracked files as disposable.
- Pushing, committing or resetting. That is `/ship`, or yours.
- Writing purposes from memory. Quote the spec, scope row or memory note.
