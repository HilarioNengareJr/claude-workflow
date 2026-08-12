---
name: drift
description: Cross-repo contract check for the {{PRODUCT}} system — compare what
  {{WEB_REPO}} and {{ADMIN_REPO}} actually call against what
  {{SERVICE_REPO}}'s api/openapi.yaml declares, and report every mismatch
  (endpoints, methods, fields, types, casing) before staging finds it. Use
  whenever the user suspects or wants to rule out frontend/backend disagreement:
  "check for drift", "does web still match the backend", "did the API change
  break admin", "contract check", "are the frontends in sync with the
  service", "audit the API usage", after a service-side contract change, or
  typing /drift. Distinct from /review (one feature vs its plan), /break
  (dynamic stress-testing), and /atlas (context loading) — this is a static,
  system-wide consumer-vs-contract sweep that reports and fixes nothing.
---

# Drift

Find every place the frontends and the backend have quietly stopped agreeing.
The service's `api/openapi.yaml` is the system's contract; web and admin are
its consumers. Drift between them doesn't fail a build — it fails at runtime,
on staging or in front of a customer. This skill catches it statically, before
that.

**Read-only.** The output is a report. Fixes go through the normal flow
(`/build` or a direct ask) — a drift sweep that starts editing files is doing
two jobs badly.

## What's already guaranteed — don't re-check it

The service repo has **contract tests** that validate the Go handlers against
`api/openapi.yaml` (per `context/architecture.md`). So contract ↔ service
agreement is enforced by CI-adjacent tests and is not this skill's job. The
unguarded gap — and this skill's whole job — is **contract ↔ consumers**:
nothing anywhere checks that web and admin call what the contract declares.

## The three surfaces

1. **Contract:** `{{SERVICE_REPO}}/api/openapi.yaml` — paths, methods,
   request/response schemas, required fields, enums.
2. **Web consumer:** `{{WEB_REPO}}/src/services/*.ts` (api, products, cart,
   checkout, devices, chat, support) — every endpoint called, plus the TS
   types the responses are parsed into.
3. **Admin consumer:** `{{ADMIN_REPO}}/src/lib/api-client.ts` and the
   TanStack Query hooks/pages that use it, plus `src/types`.

**The casing trap:** admin runs responses through
`src/lib/camel-case-keys.ts` (snake_case → camelCase). When comparing admin
types against contract schemas, compare through that conversion — a contract
field `order_number` matching an admin type field `orderNumber` is *correct*,
and flagging it is a false positive. Web has no such layer; check what it
actually does per service file.

## Workflow

### 1. Load the contract

Read `api/openapi.yaml` and build the inventory: every path + method, its
request body schema, response schema, required fields, enums. This is the
benchmark everything else is judged against.

### 2. Extract what each consumer really calls

For web and admin independently: sweep the consumer surface for every HTTP
call — path (watch for template literals building paths), method, request
payload fields, and which response fields the code actually reads (the TS
types plus real property access). For a thorough system-wide sweep, fan the
two consumers out to parallel Explore agents — they're independent and each
one is a lot of reading.

### 3. Compare, both directions

For each consumer, walk the two lists against each other:

- **Consumer calls it, contract doesn't have it** — a path or method the
  frontend uses that the contract never declares. Breaks now or soon.
- **Field mismatches** — request fields the contract doesn't accept; response
  fields the consumer reads that the schema doesn't promise; enum values
  handled that the contract doesn't emit, and vice versa (an unhandled enum
  value is drift too — e.g. a new order status the admin UI can't render).
- **Type mismatches** — contract says integer cents, consumer type says a
  formatted string; nullable in the schema, non-optional in the TS type.
- **Casing** — through the camel-case lens for admin (above).
- **Contract declares it, nobody calls it** — not a bug, but report it as a
  candidate for cleanup; dead contract surface hides real drift.

Judge severity by user impact: a checkout-path mismatch is critical; an
unused contract endpoint is a note.

### 4. Report

```markdown
## Drift report — [date]

**Verdict:** [in sync / N mismatches, worst: one line]

### Critical — will break at runtime
| Consumer | Call site | Contract says | Consumer does |
|---|---|---|---|

### Warnings — latent drift
[same table shape]

### Notes
- [unused contract endpoints, suspected-but-unconfirmed items with why]

### Not checked
- [anything skipped — dynamic paths that couldn't be resolved statically,
  files not swept — named plainly]
```

Every mismatch cites the file:line on the consumer side and the path in the
openapi.yaml. A finding the user can't click through to is a rumor.

## Example

**Input:** "I changed the orders endpoints in the service yesterday — check
nothing broke"

**Output:** Loads openapi.yaml, sweeps both consumers (scoped to order-related
calls since the change is known), reports: "1 critical — admin's order-export
hook still sends `fulfilment_status` as a query param; the contract now calls
it `status` (`api-client.ts:114` vs `/admin/orders` in openapi.yaml). 1
warning — web's tracking page handles order status `shipped` but the contract
enum now also emits `ready_for_collection`, which would render blank. Web's
checkout calls are in sync."

## Anti-patterns

- Fixing drift mid-sweep — report first; the fix is a separate, scoped task.
- Flagging admin's camelCase fields against snake_case schemas — run the
  comparison through `camel-case-keys.ts`'s conversion or drown in false
  positives.
- Re-verifying service ↔ contract — the contract tests own that; duplicated
  checking buys nothing.
- Trusting TS types alone as "what the consumer uses" — code reads properties
  the types under-declare; check real property access on hot paths.
- A report without file:line references, or one that silently skipped the
  dynamic call sites it couldn't resolve.
