---
name: cd
description: Switch the active working scope into one of the five {{PRODUCT}} repos and keep it there for the rest of the session. Loads that repo's own context/ (architecture, code-standards, progress-tracker, ui-rules) on top of the shared {{WORKSPACE_ROOT}} umbrella context, then treats that repo as the working root — bash runs cd'd into it, file ops default there, its standards apply, and /track targets its progress-tracker. Use whenever you want to focus on and work inside one repo: "switch to service", "cd into the admin repo", "let's work in web now", "move me into the backend", "I'm working on the KB", or typing /cd service | /cd admin | /cd web | /cd kb | /cd campaigns. This is the per-repo focus counterpart to /atlas (which maps all five for reference without moving you). Re-run to switch to another repo.
---

# cd — switch into a {{PRODUCT}} repo and work from there

The {{PRODUCT}} system is five repos under one workspace. You work cross-repo, but most of the time you're *in* one repo doing the actual work. This skill is `cd` for project context: pick a repo, load its per-repo context, and make it the active working root so everything you do lands in the right place with the right conventions — while still knowing how it connects to the others.

**`cd` vs `atlas`:** `atlas` reads all five repos and hands back a briefing so you can *reference* the others without leaving where you are — breadth, non-sticky. `cd` goes *into* one repo and stays there — depth, sticky. Map the system with atlas; work in a repo with cd.

## The repos

All five live under `~/{{WORKSPACE_ROOT}}/` (the workspace root). Resolve it, don't assume it: if `~/{{WORKSPACE_ROOT}}` doesn't exist, check `${{WORKSPACE_ROOT}}_ROOT`, then look for a directory containing `{{SERVICE_REPO}}` as a sibling of the current repo. If none resolves, say the workspace root can't be found and stop.

| Short name | Directory | What it is | Has `context/`? |
|---|---|---|---|
| **service** | `{{SERVICE_REPO}}` | Go backend API — the system's brain, owns the Postgres, holds the frontend contracts | yes |
| **web** | `{{WEB_REPO}}` | React PWA storefront (the only customer-facing surface) | yes |
| **admin** | `{{ADMIN_REPO}}` | VPN-gated React admin console | yes |
| **kb** | `{{KB_REPO}}` | System prompt + KB files for the AI support chat | no — flat repo |
| **campaigns** | `{{CAMPAIGNS_REPO}}` | Next.js marketing-analytics dashboard — reads {{PROD_DB}} (read-only) for campaign reach + attributed sales | check on switch |

Accept either the short name (`service`) or the full directory name (`{{SERVICE_REPO}}`). `backend` → service, `storefront`/`frontend` → web, `console` → admin, `knowledgebase`/`{{KB_WORKFLOW}}` → kb, `analytics`/`dashboard` → campaigns.

## Workflow

### Step 1: Resolve the target repo

Map the argument to one of the five directories above. If the argument is missing or ambiguous, ask which repo — don't guess. If the resolved directory doesn't exist on disk, say so (the user may not have cloned it) and stop.

### Step 2: Load that repo's context

Read the files in one batch of parallel reads — don't read them one at a time. The umbrella context (`{{WORKSPACE_ROOT}}/context/`) is the shared cross-repo layer; the repo's own `context/` is the scoped layer you're switching into.

**Always read the shared umbrella first (once per session is enough — skip if already loaded this session):**
- `{{WORKSPACE_ROOT}}/context/project-overview.md` — how the repos fit together
- `{{WORKSPACE_ROOT}}/context/progress-tracker.md` — the system-level state

**Then the target repo's own files.**

For a code repo (**service, web, admin**):
- `CLAUDE.md` — the repo guide (but see the source-of-truth caveat below)
- `context/project-overview.md` — what the repo is for
- `context/architecture.md` — how it's built
- `context/code-standards.md` — the conventions your edits must follow
- `context/progress-tracker.md` — this repo's current state and what's in flight

For a **frontend** (web, admin) also read the UI rules — your components must match them:
- `context/ui-rules.md`, `context/ui-tokens.md`, `context/ui-registry.md`

For **service** also read the frontend contracts (these are what the frontends must match — the source of truth for cross-repo work):
- `LADUMA_BOGO_FRONTEND_CONTRACT.md`, `LADUMA_EVERY_SKIN_FRONTEND_CONTRACT.md`
- `VOUCHER_FREE_CHECKOUT_FRONTEND_CONTRACT.md`, `VOUCHER_ANALYTICS_FRONTEND_CONTRACT.md`
- `VOUCHER_CAMPAIGN_REPORTS_FRONTEND_CONTRACT.md`, `VOUCHER_REPORTS_PERIOD_TODAY_FRONTEND_CONTRACT.md`
- Read the contract that's relevant to current work in full; note the rest by name.

For **kb** (flat repo, no `context/`):
- `README.md`, `system_prompt.md`
- List `files/` (the topic text files) — read an individual one only when the user asks about that topic.

If a file is missing, note it and move on — don't fail the whole switch over one absent file.

### Step 3: Set the repo as the active working root — and keep it there

This is the sticky part. For the rest of the session, until the user runs `cd` again:

- **Bash:** run commands cd'd into the repo, e.g. `cd ~/{{WORKSPACE_ROOT}}/{{SERVICE_REPO}} && <cmd>`. Do this in one compound command — don't rely on a persistent `cd` between tool calls.
- **File operations:** treat `{{WORKSPACE_ROOT}}/<repo>/` as the base. When the user names a file without a path, resolve it inside this repo first.
- **Conventions:** apply this repo's `code-standards.md` (and `ui-rules.md`/`ui-tokens.md` for frontends) to every edit you make.
- **Progress tracking:** `/track` and any progress update target *this repo's* `context/progress-tracker.md`. Cross-repo milestones go in `{{WORKSPACE_ROOT}}/context/progress-tracker.md`.
- **Other repo skills** (`ship`, `watch`, `envs`) now act on this repo unless told otherwise.

State plainly at the end of the switch that this repo is now the active root, so the user knows where subsequent work lands.

### Step 4: Stay aware of the cross-repo picture

Being *in* one repo doesn't mean forgetting the others. `{{WORKSPACE_ROOT}}/context/` remains the shared source for how things connect. When work in the active repo touches another repo's contract — e.g. a web checkout change that must match service's `VOUCHER_FREE_CHECKOUT_FRONTEND_CONTRACT.md` — pull that specific file from the other repo directly, or suggest `/atlas` if the user needs the whole map. Don't switch away just to read one file.

### Step 5: Confirm the switch

Give a tight confirmation, not a paste-dump:
- **Where you are now** — repo name and path, "this is the active working root."
- **Stack** — one line (framework + language).
- **Current state** — the top few in-flight items from this repo's `progress-tracker.md`.
- **What it owes / expects** — for service, the live contracts that affect current work; for a frontend, which backend endpoints or contracts it leans on.

Then invite the actual task: "You're in `service`. What are we building?"

## Source-of-truth caveat

Trust `package.json` / `go.mod` / `context/` over the `README.md` and `CLAUDE.md` files. The frontend READMEs have stale stack tables and the `CLAUDE.md` files carry known errors. `{{WORKSPACE_ROOT}}/ARCHITECTURE_VERIFICATION.md` is the reliable audit. Read `CLAUDE.md` for orientation, but verify anything load-bearing against code and `context/`.

**The known-errors list is a snapshot (recorded 2026-07), not a standing truth** — any of these may have been fixed since. Treat each as "check this specific claim," never "this claim is false." If you find one has been corrected, say so and flag that this list needs an edit:

- Wrong prod URL
- "Products are static"
- "chi router" — verify the actual router in `go.mod` / `internal/server/`

## Examples

**Input:** `/cd service`
**Output:** Reads the umbrella context + `{{SERVICE_REPO}}`'s CLAUDE.md, context files, and the voucher/laduma frontend contracts. Confirms: "You're in `{{SERVICE_REPO}}` (Go, net/http, Postgres 16 + GORM) — active working root. In flight: voucher redemption strategy, Stitch webhook signature, legacy `/checkout/initiate`. What are we building?" Subsequent bash runs cd'd into the repo; edits follow its code-standards; `/track` targets its progress-tracker.

**Input:** `/cd web` (while previously in service)
**Output:** Switches the active root to `{{WEB_REPO}}`. Loads its context + UI rules/tokens/registry so new components match. Notes which service contracts its checkout depends on. From here, file ops and edits default to the web repo.

**Input:** "let's work in the admin console now"
**Output:** Same as `/cd admin` — resolves "admin console" to `{{ADMIN_REPO}}`, loads its context, sets it as the working root.

**Input:** "move me into the KB"
**Output:** Resolves to `{{KB_REPO}}`, reads `README.md` + `system_prompt.md`, lists `files/`, sets it as the active root. Notes it has no `context/` dir — it's a flat content repo feeding the support chat.

## Notes

- These are directories on disk, read directly — no git fetch or network needed.
- `cd` sets *context and working scope*; it does not change the harness's primary working directory. That's why bash commands must `cd` into the repo explicitly each call.
- Switching is idempotent and repeatable — run `/cd <other>` any time to move. There's no "exit"; you're always in exactly one active repo (or none, at session start).
- Relationship to the other {{PRODUCT}} skills: **`atlas`** maps all five for reference (breadth, non-sticky); **`cd`** puts you inside one (depth, sticky). **`envs`** prints deploy URLs, **`ship`** handles git, **`watch`** tails pipelines — after a switch, those act on the active repo.
- This skill reads and sets scope. The actual edits, builds, and commits happen through the normal tools and the build/ship skills — scoped to wherever you've `cd`'d.
