# The repos /ship covers

All eight live under `{{WORKSPACE_ROOT}}/` and push to `git@{{GITLAB_HOST}}:{{GITLAB_GROUP}}/<repo>.git`.
Default branch is `main` everywhere; the user is the maintainer everywhere.
Every repo except operator-assistant has a local `pre-commit` hook.

| Repo | Stack | QA gate to run before pushing | Hook | CI | Deploys |
|---|---|---|---|---|---|
| {{SERVICE_REPO}} | Go, Makefile | `make check-quick` (gofmt, vet, unit tests). Fuller: `make test`, `make lint`, `make test-contract`, `make coverage` (90% per file, 95% overall) | dev docs check | yes | {{STAGING_JOB}} auto, prod manual |
| {{WEB_REPO}} | React, Vite, npm | `npm run build` then `npm run lint` (zero warnings) then `npm run test`. Add `npm run test:e2e` for checkout or funnel changes | dev docs check | yes (`test_enabled: false`) | {{STAGING_JOB}} auto, prod manual |
| {{ADMIN_REPO}} | React, Vite, npm | `npm run build` then `npm run lint`. No test framework: drive the UI by hand for anything behavioural | dev docs check | yes | {{STAGING_JOB}} auto, prod manual |
| {{CAMPAIGNS_REPO}} | Next.js, npm | `npm run build` then `npm run lint` then `npm run test` | dev docs check | yes | {{STAGING_JOB}} auto, prod manual |
| {{COVERS_REPO}} | Python (codes/), later packs/ | `cd codes && .venv/bin/python -m pytest -q` | gitleaks on staged files (`.gitleaks.toml`) | not yet (its pipeline spec brings it) | none; push is the shipment |
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
version → pre-flight → lint (hadolint, helm) → audits (gitleaks, Polaris) → build (image + chart to Harbor) → deploy ({{STAGING_JOB}} auto, prod manual)
```

`gitleaks` and `helm-templates-check` run with `allow_failure`. A pipeline
stops at the first blocking red, so an early failure hides everything after it.

Pipelines: `https://{{GITLAB_HOST}}/{{GITLAB_GROUP}}/<repo>/-/pipelines`
Backstage: `https://{{BACKSTAGE_HOST}}/catalog/default/component/<repo>/ci-cd`

## Out of scope

- The the client app checkout (the the client app checkout): client source, `origin` is `DISABLED_never_push` by design.
- GitHub repos (the claude-workflow backup, `{{WORKSPACE_ROOT}}/rancher-logs-mcp` if it points there): not GitLab, not this skill.
