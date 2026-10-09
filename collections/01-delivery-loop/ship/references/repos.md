# The repos /ship covers

This table is a cache. Each repo's own `AGENTS.md`, `CLAUDE.md` and shipping
docs win over it; when they disagree, follow the repo and fix the row here.
Add a row the first time /ship runs on a repo that is not listed.

## GitLab: {{COMPANY}} {{PRODUCT}}

All eight live under `~/SKINS/` and push to `git@{{GITLAB_HOST}}:{{GITLAB_GROUP}}/<repo>.git`.
Default branch is `main` everywhere; the user is the maintainer everywhere.
Every repo except operator-assistant has a local `pre-commit` hook.

| Repo | Stack | QA gate to run before pushing | Hook | CI | Deploys |
|---|---|---|---|---|---|
| {{SERVICE_REPO}} | Go, Makefile | `make check-quick` (gofmt, vet, unit tests). Fuller: `make test`, `make lint`, `make test-contract`, `make coverage` (90% per file, 95% overall) | dev docs check | yes | sit auto, prod manual |
| {{WEB_REPO}} | React, Vite, npm | `npm run build` then `npm run lint` (zero warnings) then `npm run test`. Add `npm run test:e2e` for checkout or funnel changes | dev docs check | yes (`test_enabled: false`) | sit auto, prod manual |
| {{ADMIN_REPO}} | React, Vite, npm | `npm run build` then `npm run lint`. No test framework: drive the UI by hand for anything behavioural | dev docs check | yes | sit auto, prod manual |
| {{CAMPAIGNS_REPO}} | Next.js, npm | `npm run build` then `npm run lint` then `npm run test` | dev docs check | yes | sit auto, prod manual |
| {{COVERS_REPO}} | Python (codes/), later packs/ | `cd codes && .venv/bin/python -m pytest -q` | gitleaks on staged files (`.gitleaks.toml`) | not yet (spec 0008 brings it) | none; push is the shipment |
| {{FINANCE_REPO}} | React, Vite, npm | `npm run build` then `npm run lint` | dev docs check | no | none |
| {{KB_REPO}} | markdown + files for the n8n KB | none; eyeball the diff | dev docs check | no | none; the n8n KB sync picks it up |
| {{OPERATOR_REPO}} | n8n export + prompt | none; eyeball the diff | none | no | none |

## Beads

`{{SERVICE_REPO}}` and `{{ADMIN_REPO}}` have `.beads/`. Ids look like
`{{ADMIN_REPO}}-8qp6`. Reference the id in the commit summary, close it before
the push, log known gaps as new beads, `bd sync` before pushing. Do not `bd
init` another repo unless asked.

## Dev docs exemptions (`.devdocs-keep`)

- service keeps `docs/specs/` (build specs are a durable contract, decided 2026-09-08).
- admin keeps `.claude/` (shared agents and the react rules anyone cloning needs).

Everything else follows `~/.claude/bin/check-dev-docs.sh`. Its directory rules
are anchored to the repo root on purpose; `src/context/*.tsx` in web is
application code, not a dev doc. Never widen them.

## The shared pipeline

web, service, admin and {{CAMPAIGNS_REPO}} include
`{{PIPELINE_TEMPLATE_PROJECT}}` and only set variables. Do
not edit `.gitlab-ci.yml` or add jobs; the template owns the stages:

```
version → pre-flight → lint (hadolint, helm) → audits (gitleaks, Polaris) → build (image + chart to Harbor) → deploy (sit auto, prod manual)
```

`gitleaks` and `helm-templates-check` run with `allow_failure`. A pipeline
stops at the first blocking red, so an early failure hides everything after it.

Pipelines: `https://{{GITLAB_HOST}}/{{GITLAB_GROUP}}/<repo>/-/pipelines`
Backstage: `https://{{BACKSTAGE_HOST}}/catalog/default/component/<repo>/ci-cd`

## GitHub

CI is GitHub Actions, watched with `gh run` (see SKILL.md, Stage 4).

| Repo | Path | Stack | QA gate | Commit format | CI | Deploy |
|---|---|---|---|---|---|---|
| node-companion | `~/projects/node-companion`, `github.com/{{GITHUB_ORG}}/node-companion` | Expo RN app + Kotlin engine + Cloudflare Worker | `npm run typecheck`, `npm test`, `npm run check:runtime` (0 ok, 1 refused, 2 could not decide). Touching `worker/`: its own `npm run typecheck`, `npm test`, `npm run smoke`. Touching the engine: the Gradle unit test command in `modules/node-engine/AGENTS.md`. Touching a workflow: `actionlint .github/workflows/ci.yml` | `Area: subject`, one line, sentence case (`Bridge s38: ...`, `Runtime 1.3.5: ...`, `CI: ...`); body gives the cause and ends with a `Tests:` line | Actions on every push: app, engine, worker jobs. Runtime check is a warning only. No run means minutes may be out, never green | None on push. `npm run ota` (JS only) or a new APK (native) is a separate step, only on request and only after the green mark |

node-companion traps, all from its `AGENTS.md` and `docs/shipping.md`:

- Contract first: a change under `src/bridge/` or the engine's bridge needs the matching `docs/bridge.md` section in the same shipment.
- Native change (`android/`, engine Kotlin, native npm package, Expo SDK, app.json plugins or permissions): `runtimeVersion` bumps in both `app.json` and `android/app/src/main/res/values/strings.xml`, and they must match. Let `check:runtime` decide.
- After `npm run apk:preview`, commit `ota/runtime-baseline.json`.
- No `.devdocs-keep` yet, so the dev docs check holds back its `CLAUDE.md` pointer files and `.claude/`, even though its `AGENTS.md` expects them. `AGENTS.md` itself is not a dev doc. Ask before adding a `.devdocs-keep`.
- Tests and mocks use "Alex", "Home", "Office", "OfficeNet". No keys or personal data.

Other GitHub repos (the claude-workflow backup, `~/SKINS/rancher-logs-mcp` if it points there) have no row yet. Profile them from their own files on first ship.

## Out of scope

- The the client app checkout (`~/the client app`): vendor source, `origin` is `DISABLED_never_push` by design.
