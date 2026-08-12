---
name: break
description: Take a newly built feature, hunt down every edge case that could break it, and stress-test it systematically — then actually run the tests and report what survived. Use this skill whenever the user wants a feature tested beyond the happy path, even if phrased casually (e.g. "stress test this", "test the new feature properly", "what edge cases are we missing", "have we tested X enough", "battle-test this before the MR", "try to break it"). Distinct from /verify (happy-path confirmation that a change works) and /code-review (static analysis) — this skill is adversarial and dynamic: it devises the failure modes, executes everything runnable, and hands back evidence.
---

# Stress Test

Test a feature the way an adversary-minded QA engineer would: build a model of how it should behave, enumerate the ways reality could violate that model, then execute every case you can and report honestly on the rest. The goal is not a green checkmark — it is finding the bug before a customer does.

## Core principle

The happy path has already been tested by the person who built the feature — that is what building it means. The value of this skill lives entirely in the cases nobody ran: the empty input, the double-click, the refresh mid-flow, the network that dies halfway. A stress-test that re-confirms the demo is wasted effort. Spend the effort where the uncertainty is.

## Workflow

### Step 1: Understand the feature before attacking it

You cannot find edge cases for behaviour you don't understand. Trace the feature end to end in the real code — entry points, state it reads and writes, every I/O boundary (network calls, storage, URL), and where it ends. If the project has a `context/` directory or an implementation plan (e.g. `context/architecture.md`), read the relevant entry: the plan's stated assumptions and out-of-scope notes are a map of where the soft spots are. Read `context/code-standards.md` too — the test code you write in Step 4 has to follow it like any other code.

Also read the existing tests for the feature. They tell you what is already covered — never re-test it — and what conventions new test code must follow.

### Step 2: Build the edge-case matrix

Enumerate candidate cases dimension by dimension. Walk every dimension even when it feels inapplicable — the "inapplicable" ones are where untested behaviour hides:

- **Input edges** — empty, missing, malformed, boundary values (0, 1, max, max+1), wrong type, very long, unicode/emoji, leading/trailing whitespace, case variants
- **State edges** — first ever use, repeat use, stale persisted state (old localStorage/sessionStorage shapes), state from a previous version, two things active at once that assume exclusivity
- **Timing and network edges** — slow response, timeout, offline, failure halfway through a multi-step flow, retry after failure, double-submit (rapid double-click), out-of-order responses
- **Environment edges** — page refresh mid-flow, browser back/forward, deep link straight into the middle, second tab open simultaneously, smallest supported viewport
- **Hostile-shaped input** — injection-shaped strings, URL-encoded payloads, oversized payloads. This is defensive: confirm the feature treats them as inert data. Do not develop actual exploits.
- **Scale and stress** — the loop run many times fast, the list with hundreds of items, the largest realistic data set

For each candidate, write the expected behaviour *before* running it. A test without a prediction can't fail.

### Step 3: Triage — rank and route

Not all cases deserve equal effort. Score each by likelihood × impact, then route it:

- **Automate** — unit-testable logic → write a real test in the project's framework and conventions
- **Probe** — flow-level behaviour → drive the running app (dev server, browser automation) and observe
- **Checklist** — needs something you can't reach (real payment rails, production SMS, third-party callbacks) → precise manual steps with expected outcome, for the user to run

Cut candidates that are genuinely impossible-by-construction, and say why you cut them. Silent dropping is the cardinal sin of this skill.

### Step 4: Execute

1. Run the existing test suite first — establish a green baseline before adding anything. If it's already red, stop and report; stress results on a broken baseline mean nothing.
2. Write and run the automated cases. Test the real code, not a mock of it — a mock that mirrors your assumptions will pass for the wrong reason.
3. Probe the running app for the flow cases, capturing evidence (what was done, what happened).
4. **When the feature runs in a deployed environment, get the server's side of the story via the `rancher-logs` MCP.** A client-side probe only shows half of each case — the pod logs show what the service actually did. Use `pods_list` to find the pod and `pod_logs` (prefix names like `{{SERVICE_REPO}}` resolve to the newest Running pod; `grep` filters; `previous: true` reads a crashed instance) to pull evidence around each probe: capture the log signature when a case fails, and confirm silence when a case should be a no-op. It is read-only over namespaces `{{STAGING_JOB}}` and `prod` and needs the {{COMPANY}} VPN — if it's unreachable, record the affected cases as not-run-with-reason instead of passing them on client evidence alone.
5. Run the stress cases last — they're the most likely to leave dirty state behind.

When a case fails: record the exact reproduction, the expected vs. actual behaviour, and your severity read — then **keep testing**. Do not stop to fix it, and do not fix anything unless the user asks; a mid-test fix invalidates every result after it and hides the bug from the report.

New test files you write are kept in the working tree and listed in the report — the user decides which become permanent suite members and which were throwaway probes.

### Step 5: Report

Deliver a single structured report (template below). Honesty rules:

- Every matrix case appears exactly once: passed, failed, or not-run-with-reason
- "Not run" with a reason is a respectable result; an unlisted case is a lie of omission
- Distinguish "verified safe" from "didn't break in one attempt"

## Output format

```markdown
## Stress-test report: [feature]

**Verdict:** [one sentence — ship it / fix X first / needs the manual checklist run]

### Found issues
| # | Severity | Case | Expected | Actual | Repro |
|---|---|---|---|---|---|

### Passed (N cases)
[Grouped one-liners — dimension: cases]

### Not run
- [Case] — [why, and how to run it manually if it matters]

### Test artifacts
- [New/changed test files, and whether each is worth keeping]
```

## Example

**Input:** "stress test the voucher auto-apply feature"

**Output (abridged):**

```markdown
## Stress-test report: voucher auto-apply from campaign links

**Verdict:** Ship-blocking: none. One medium issue — two tabs racing on the same sessionStorage key last-write-wins silently.

### Found issues
| # | Severity | Case | Expected | Actual | Repro |
|---|---|---|---|---|---|
| 1 | Medium | Two tabs, different campaign links | Defined winner | Last tab to validate wins, first tab's banner goes stale | Open /all?codeA in tab 1, /all?codeB in tab 2, refresh tab 1 |

### Passed (14 cases)
- Input: empty bare key, 500-char token, URL-encoded `%3Cscript%3E` token treated as inert, channel with emoji
- State: stale pre-feature sessionStorage shape ignored cleanly; expired stash purged on restore
- Timing: validation timeout → quiet fail, checkout unblocked; double navigation → single validate call

### Not run
- Real SMS deep-link on a physical handset — needs a sent campaign; manual steps below.

### Test artifacts
- src/utils/campaignLink.test.ts — 4 added cases, worth keeping
```

## Anti-patterns

- Re-testing the happy path with cosmetic variations and calling it a stress test
- Testing your mock instead of the feature — assertions that can only confirm your own assumptions
- Giving all cases equal weight — fifty trivial passes burying one real failure
- Silently skipping a case that turned out to be hard to run
- Fixing bugs mid-run without being asked — the report is the deliverable, the fix is a separate decision
- Leaving stress-test state behind (dirty storage, junk orders) without flagging it in the report
- Calling a deployed-flow case passed on client-side evidence alone when the pod's logs were one `rancher-logs` MCP call away
