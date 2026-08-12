---
name: flow
description: Build, inspect, debug, and maintain the {{PRODUCT}} n8n workflows (the
  support chat, knowledge-base sync, order-tracking agent) on {{COMPANY}}'s
  shared production n8n instance, via the n8n MCP — with validate-before-deploy
  discipline and strict guest rules, because the same instance runs {{COMPANY}}'s live
  {{SUPPORT_AI}} WhatsApp/voice support AI. Use whenever the task touches n8n:
  "update the {{KB_WORKFLOW}} workflow", "build an n8n workflow", "why did the chat
  bot fail", "re-run the knowledge base sync", "check the n8n executions",
  "add a node to the flow", "the {{ITEM}} agent is broken", or typing /flow.
  NOT for the KB content itself (that's files in {{KB_REPO}}) and NOT
  for the Workflow orchestration tool — this is the n8n automation platform.
---

# Flow

Work on the {{PRODUCT}} automations that live in n8n — safely. The core fact that
shapes everything here: **the n8n instance is not ours.** It is {{COMPANY}}'s shared
production automation platform.

## The instance — verified 2026-07-08

The n8n MCP connects to an instance with **100+ workflows** (the list
paginates — `hasMore` is true at 100). Almost all of them are the **{{SUPPORT_AI}}
platform**: {{COMPANY}}'s live customer-support AI over WhatsApp and ElevenLabs
voice, with several workflows **active in production** (WhatsApp interfaces,
template runners, health checks, the ElevenLabs unified interface). Billing
agents, payment tools, OTP senders — real customer-facing machinery.

The {{PRODUCT}} footprint is a handful of workflows, found by name filter:

- `the KB-sync workflow` — embeds `{{KB_REPO}}` content into Qdrant
- `{{PRODUCT}} Agent - Track Customers Order` — the order-tracking chat agent
- Possibly more — always find them by **paginated list + name filter**
  (`{{ITEM}}`/`{{PRODUCT}}`, case-insensitive), never by assuming page one has them all.

The instance-wide naming convention is `<Family> - <Type> - <Name>` with
Type ∈ Interface | Agent | Router | Tool | Utility (e.g. `{{SUPPORT_AI}} - Tool -
Send Email`). New {{PRODUCT}} workflows follow it as `{{PRODUCT}} - <Type> - <Name>`.
Don't rename the existing inconsistently-named {{PRODUCT}} workflows unprompted —
renames can break whatever references them.

## Guest rules — non-negotiable

1. **Touch only {{PRODUCT}} workflows.** Anything named `{{SUPPORT_AI}}*`, `ElevenLabs*`,
   or otherwise not clearly {{PRODUCT}} is read-only, always — no edits, no
   activations, no deactivations, no deletions, no matter how helpful the fix
   looks. If an {{SUPPORT_AI}} workflow seems broken, report it to the user; it has
   its own owners.
2. **Reading is allowed everywhere.** The {{SUPPORT_AI}} workflows are the best
   pattern library on the instance — study their structure (router → agent →
   tools, logging utilities) when building {{PRODUCT}} equivalents.
3. **Never activate on the user's behalf.** Create and update workflows
   **inactive**; the user flips the switch after reviewing. An activated
   workflow on this instance is live production behavior.
4. **No credential changes.** Workflows reference shared credentials; creating
   or editing credentials affects every workflow that uses them.

## Workflow

### 1. Locate and understand

`n8n_health_check` if connectivity is in doubt. Find the target with
`n8n_list_workflows` (paginate until `hasMore` is false or the target is
found; filter names for `{{ITEM}}`/`{{PRODUCT}}`). Read it with `n8n_get_workflow`
before proposing any change — node layout, trigger type, credentials it
references, whether it's active.

### 2. Debug from evidence

For "why did it fail": `n8n_executions` for the workflow — read the failing
execution's node-level error before theorizing. The answer is almost always in
the failed node's input/output, not in the workflow diagram.

### 3. Build and edit with the validate-first loop

- Prefer `n8n_update_partial_workflow` for edits — surgical diffs beat
  full-workflow replacement, which can clobber concurrent UI edits.
- Before any create or update lands: `validate_workflow` (and `validate_node`
  for tricky nodes). Fix what it flags — `n8n_autofix_workflow` for the
  mechanical issues — then validate again. Nothing deploys red.
- Look up node shapes with `search_nodes` / `get_node` instead of guessing
  parameter schemas from memory; n8n node schemas change between versions.
- New workflows: create **inactive**, named `{{PRODUCT}} - <Type> - <Name>`, then
  `n8n_test_workflow` to prove it runs before handing it to the user to
  activate.

### 4. The knowledge-base tie-in

The support chat answers from **Qdrant**, and Qdrant is only as fresh as the
last sync. After content changes in `{{KB_REPO}}` (files or
`system_prompt.md`), the `the KB-sync workflow` workflow must re-run —
that's the documented rule in `context/architecture.md`. Trigger it via
`n8n_test_workflow` or tell the user to run it; either way, confirm an
execution actually succeeded (`n8n_executions`) rather than assuming.

### 5. Report

Say what changed (workflow, nodes touched), validation result, test-run
result, and the activation state — explicitly "left inactive, activate when
ready" for new builds.

## Examples

**Input:** "the order tracking agent in the chat is giving wrong statuses"

**Output:** Finds `{{PRODUCT}} Agent - Track Customers Order` via filtered list,
pulls its recent executions, reads the failing/odd execution's node data —
discovers the service API call returns a status the agent's mapping doesn't
know. Reports the evidence and the one-node fix; applies it via partial
update after the user agrees; validates; test-runs; reports green.

**Input:** "I updated the KB files, get the chat bot current"

**Output:** Confirms the `{{KB_REPO}}` changes exist, runs
`the KB-sync workflow`, watches the execution to success, reports "Qdrant
re-embedded — the chat answers from the new content now."

## Anti-patterns

- Editing, activating, or "fixing" an {{SUPPORT_AI}}/ElevenLabs workflow — the
  cardinal sin on a shared production instance.
- Deploying without validating, or validating and ignoring the result.
- Full-workflow updates for one-node changes.
- Assuming the {{PRODUCT}} workflows all sit on page one of the list.
- Hand-writing node JSON from memory instead of `get_node` — version drift
  makes guessed schemas silently wrong.
- Changing KB content and calling it done without the sync run — the bot
  answers from Qdrant, not from git.