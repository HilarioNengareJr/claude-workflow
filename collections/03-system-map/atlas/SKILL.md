---
name: atlas
description: Load cross-repo context for the {{PRODUCT}} system into the current session. Reads the CLAUDE.md, README, and context/ files from every sibling {{PRODUCT}} repo ({{WEB_REPO}}, {{SERVICE_REPO}}, {{ADMIN_REPO}}, {{KB_REPO}}, {{CAMPAIGNS_REPO}}) so the session understands the whole system, not just the repo you're sitting in. Use this whenever you need the backend contract, admin conventions, or KB while working in another repo, or when starting fresh and asking "how do these repos fit together", "load the other repos", "what's the backend expecting", "give me the full {{PRODUCT}} picture", "map the system", or typing /atlas. Optionally pass one repo name (e.g. /atlas service) to load just that repo in depth.
---

# Atlas — map the whole {{PRODUCT}} system

An atlas is a collection of maps. This skill reads the key context files from every {{PRODUCT}} repo and pulls a compact summary of each into the session, so you can work in one repo while knowing what the others expect. The most common use: you're in `{{WEB_REPO}}` and need the backend's frontend contract or the admin portal's conventions without switching repos.

## The repos

All five live as siblings under `~/{{WORKSPACE_ROOT}}/` (the workspace root). Resolve it, don't assume it: if `~/{{WORKSPACE_ROOT}}` doesn't exist, check `${{WORKSPACE_ROOT}}_ROOT`, then look for a directory containing `{{SERVICE_REPO}}` as a sibling of the current repo. If none resolves, say the workspace root can't be found and stop — don't read from a guessed path.

| Repo | Path | What it is |
|---|---|---|
| **web** | `{{WEB_REPO}}` | React storefront ({{STOREFRONT_HOST}}) |
| **service** | `{{SERVICE_REPO}}` | Go backend API — the source of truth for contracts |
| **admin** | `{{ADMIN_REPO}}` | React admin portal (consumes the Go API) |
| **kb** | `{{KB_REPO}}` | Knowledge base + system prompt for the AI support chat |
| **campaigns** | `{{CAMPAIGNS_REPO}}` | Next.js marketing-analytics dashboard — reads {{PROD_DB}} (read-only) to measure campaign reach + attributed skin sales |

## Workflow

### Step 1: Decide the scope

- **No argument** (`/atlas`) → load a summary of all five repos. This is the default.
- **One repo argument** (`/atlas service`, `/atlas admin`, `/atlas kb`, `/atlas web`, `/atlas campaigns`) → load that one repo in depth. Accept the short name or the full repo name (`{{REPO_PREFIX}}-*` / `{{CAMPAIGNS_REPO}}`).

Skip the repo you're currently sitting in only if the user asked for "the other repos" — otherwise include it for completeness.

### Step 2: Read the files

For each repo in scope, read these files (they follow the same layout in every code repo). Use one batch of parallel reads — don't read them one at a time.

**Every code repo (web, service, admin, campaigns):**
- `CLAUDE.md` — the project guide, best single source of truth
- `context/project-overview.md` — what the repo is for
- `context/architecture.md` — how it's built
- `context/progress-tracker.md` — current state, what's shipped, what's in flight

Size guard: some `context/architecture.md` and `context/progress-tracker.md` files run to thousands of lines (web especially). Check size first (`wc -l`) and read only the head/current-status sections of anything huge — the briefing needs the top of the tracker, not its full history.

**service also has (read these — they are the contracts the frontends must match):**
- `LADUMA_BOGO_FRONTEND_CONTRACT.md`
- `LADUMA_EVERY_SKIN_FRONTEND_CONTRACT.md`
- `VOUCHER_FREE_CHECKOUT_FRONTEND_CONTRACT.md`

**kb ({{KB_REPO}}):**
- `README.md`
- `system_prompt.md`
- list `files/` (the topic text files — read individual ones only if the user asks about that topic)

If a file is missing, note it and move on — don't fail the whole skill over one absent file.

### Step 3: Summarize into the session

Produce one compact section per repo. Keep it tight — this is a briefing, not a paste-dump. For each repo give:

- **One-line purpose**
- **Stack** (framework + language, from CLAUDE.md)
- **Current state** — the top few items from progress-tracker (what's shipped / in flight)
- **What this repo expects from others** — for service, the active frontend contracts; for the frontends, which backend endpoints they lean on

End with a short **How they connect** paragraph: web + admin both call service's Go API; kb feeds the AI support chat that web embeds; campaigns sits outside the API loop and reads {{PROD_DB}} directly (read-only) to measure the campaign sends and attributed {{SALES_CHANNEL}} sales the other repos generate — its campaign UUID list (`lib/campaigns.ts`) must stay in sync with the vendor campaign IDs the service's notification config uses. Call out any live contract that affects current work (e.g. the voucher free-checkout contract if the current branch touches checkout).

### Step 4: Point, don't dump

You've now loaded the context. Tell the user what you pulled in and invite the specific question — e.g. "I've got all four repos mapped. Ask me about the voucher contract, an admin endpoint, or a KB answer and I'll pull the detail." Read deeper into a specific file only when the follow-up needs it.

## Examples

**Input:** `/atlas`
**Output:** A five-section briefing (web, service, admin, kb, campaigns) with purpose, stack, current state, and a "how they connect" paragraph. Ends by inviting a specific follow-up.

**Input:** `/atlas service` (while working in web)
**Output:** Deep summary of {{SERVICE_REPO}} — its architecture, current progress, and all three frontend contract docs spelled out, so the web change can match what the backend expects.

**Input:** "what's the backend expecting for the free voucher checkout?"
**Output:** Reads `VOUCHER_FREE_CHECKOUT_FRONTEND_CONTRACT.md` from service and summarizes the exact request/response the frontend must send.

## Notes

- These are sibling repos on disk, read directly — no git fetch or network needed. If a repo path is missing, the user may not have cloned it; say so.
- This skill only reads. It never edits files in sibling repos.
- Overlaps with nothing else: `envs` prints deploy URLs, `ship`/`do-git` handle git. Atlas is purely about loading cross-repo knowledge into the session.
