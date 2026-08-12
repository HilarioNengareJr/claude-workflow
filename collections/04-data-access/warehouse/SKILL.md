---
name: warehouse
description: >
  Connect to and query {{COMPANY}}'s {{WAREHOUSE_PRODUCT}} warehouse ({{WAREHOUSE_VENDOR}}, host {{WAREHOUSE_HOST}}
  port 8000, db {{WAREHOUSE_DB}}, working role {{WAREHOUSE_USER}}) — the home of the {{HISTORY_SCHEMA}}.*
  and {{REPORTING_SCHEMA}}.* schemas: router radio history (eact/RSRP, and confirmed
  live CNR + GPS in {{HISTORY_SCHEMA}}.device_gps), device registry, and the
  {{COHORT}} cohort gates. Use whenever the user wants to query {{WAREHOUSE_PRODUCT}} or the
  warehouse, run the CNR/GPS Stage 1 verification, export the signal
  pass-list for the campaign-run job, check device_wan/device_gps history, or
  says "query the warehouse", "check the warehouse", "run the query pack", "is the warehouse
  reachable yet", "signal pass-list", or types /warehouse. Access is OPEN as of
  2026-07-24; the skill holds the working connection recipe and the
  object-storage performance traps — consult it before re-deriving anything.
---

# Warehouse — {{COMPANY}}'s {{WAREHOUSE_PRODUCT}} warehouse

The separate {{WAREHOUSE_VENDOR}} warehouse that holds what the {{ITEM}} Postgres cluster
cannot see: per-device radio history (`{{HISTORY_SCHEMA}}.device_wan`,
`{{HISTORY_SCHEMA}}.device_wan_interface`), the device registry (`{{HISTORY_SCHEMA}}.device`), and
the `{{REPORTING_SCHEMA}}.*` mirror used by the {{COHORT}} gates. Getting into it is
**Gate 0** of the CNR/GPS movement-recording map.

## Connection

```
host: {{WAREHOUSE_HOST}}   port: 8000   db: {{WAREHOUSE_DB}}
role: {{WAREHOUSE_USER}}   pass: {{WAREHOUSE_PASSWORD}}      ← WORKING (verified 2026-07-24)
```

```bash
psql "postgres://{{WAREHOUSE_USER}}:{{WAREHOUSE_PASSWORD}}@{{WAREHOUSE_HOST}}:8000/{{WAREHOUSE_DB}}?connect_timeout=10"
```

The personal `{{WAREHOUSE_USER_ALT}}` / `{{WAREHOUSE_PASSWORD_ALT}}` cred is the one that was
whitelisted late on 2026-07-23; when the block lifted (2026-07-24) it was
`{{WAREHOUSE_USER}}` that actually authenticated and returned rows, so that is the
cred to use. Try `{{WAREHOUSE_USER_ALT}}` again once its own whitelist/grant is
confirmed. Stock `psql` (libpq) connects fine — **no sha256/protocol hurdle
after all**; the fallbacks below were never needed.

Requires the {{COMPANY}} VPN (same tunnel as `{{PROD_DB_CLUSTER}}`; the host
routes via the utun interface). **Read-only by convention — never write,
never DDL.** Aggregates over row dumps; no PII leaves the warehouse beyond
what the task needs (msisdn pass-lists are the accepted exception, one per
line, per the signal seam).

## ✅ Access status: OPEN (as of 2026-07-24) — connection verified

The source-IP block lifted. Confirmed working 2026-07-24 with the `{{WAREHOUSE_USER}}`
cred over VPN:

- `SELECT version()` → `PostgreSQL 9.2.4 ({{WAREHOUSE_PRODUCT}} 9.1.0 build c232682d)`.
  Stock `psql`/libpq speaks the protocol — **no sha256 or wire-protocol hurdle**;
  the driver fallbacks that used to live below were never needed.
- Schemas readable: `{{HISTORY_SCHEMA}}` (65 tables), `{{REPORTING_SCHEMA}}` (120 tables).
- Sanity: VPN up + `nc -z -G 5 {{WAREHOUSE_HOST}} 8000` succeeds. TCP-open was true
  even while blocked, so that alone never proved access — an actual `SELECT` does.

**Performance trap — these are foreign tables over object storage, not a normal
DB.** `{{HISTORY_SCHEMA}}.device_gps` and the other `{{HISTORY_SCHEMA}}.*` history tables are Parquet
files in {{WAREHOUSE_VENDOR}} {{WAREHOUSE_STORAGE}} (`{{OBS_BUCKET}}` bucket, `prod/{{WAREHOUSE_DB}}/{{HISTORY_SCHEMA}}/...`,
partitioned `partition_year`/`partition_month`/`partition_day`). So:
- **Never run an unbounded `GROUP BY` / full scan** — always pin
  `partition_year` + `partition_month` (+ `partition_day` for point checks), or
  it reads every Parquet chunk and hangs (a plain `GROUP BY partition_month`
  over all history timed out >120s).
- A missing {{WAREHOUSE_STORAGE}} object throws mid-scan (seen 2026-07-24: `partition_day=23` for
  July → `NoSuchKey` on one chunk). Probe months individually to route around a
  bad day.
- **{{WAREHOUSE_PRODUCT}} is PostgreSQL 9.2-era: no `FILTER` clause.** Use
  `sum(CASE WHEN … THEN 1 ELSE 0 END)` for conditional counts.

**If a retry ever fails again** it is almost certainly the source-IP whitelist
returning — server accepts TCP then closes before any handshake. The old
diagnosis, kept for reference:

The credentials had never been tried by the server. Verified 2026-07-23:

- TCP connects, then the server **closes the connection before any protocol
  exchange** — plain startup (protocol 3.0 and 3.51), SSLRequest, TLS-first
  ClientHello, and delayed sends all get an immediate clean close or reset.
  Not an auth failure; the handshake never starts.
- Diagnosis: **source-IP whitelist** in front of the listener (LB or host
  filter). Our VPN client address was `{{VPN_CLIENT_IP}}` (utun6) — the whitelist
  ask to the DBA is that address or the VPN concentrator's NAT range,
  for role `{{WAREHOUSE_USER_ALT}}` to db `{{WAREHOUSE_DB}}` on {{WAREHOUSE_HOST}}:8000.
- Rule out first on any retry: VPN up? (`nc -z -G 5 {{WAREHOUSE_HOST}} 8000`
  should say succeeded — it did even while blocked, so TCP-open ≠ access.)

Historical note (no longer a concern — stock psql worked): {{WAREHOUSE_PRODUCT}} *can*
default to `sha256` password auth on a modified wire protocol that plain
libpq may not speak. If a future account ever fails with an auth-method or
protocol error, the fallbacks are `{{WAREHOUSE_PY_DRIVER}}` (a pure-Python driver
that speaks {{WAREHOUSE_PRODUCT}}'s wire protocol), `{{WAREHOUSE_CLI}}` on a Linux jump host, or asking the DBA to set the account's
`password_encryption_type` to MD5 (last resort — weakens the account).

## First session once connected — in this order

1. **Prove the session:** `SELECT version();` and
   `SELECT table_schema, count(*) FROM information_schema.tables
   WHERE table_schema IN ('{{HISTORY_SCHEMA}}','{{REPORTING_SCHEMA}}') GROUP BY 1;`
2. **Run Stage 1 of the CNR/GPS map** — the query pack in
   `~/{{WORKSPACE_ROOT}}/{{SERVICE_REPO}}/the CNR/GPS verdict doc` Part 4
   (Q1 columns → Q2 historisation → Q3 cadence → Q4 retention → Q5 GPS
   coverage). Update that doc's Part 1 with the verdict — it is THE MAP
   for the `deviceMovement` feature and the reason this access was chased.
3. **Only if asked:** export the signal pass-list using the verbatim
   queries in `~/{{WORKSPACE_ROOT}}/{{SERVICE_REPO}}/.claude/skills/the campaign-run job/
   references/good-customer.md` (§"The {{COHORT}} queries", Q1 + Q5–7),
   one msisdn per line, and hand it to `the campaign-run job` via
   `GOOD_DEVICE_FILE`. That flips its cohort label off "signal SUSPENDED".

## Schema traps (verified spec, do not re-derive)

- `eact` (RAT: `NR`/`ENDC` = 5G) lives on `{{HISTORY_SCHEMA}}.device_wan`;
  `rsrp` lives on `{{HISTORY_SCHEMA}}.device_wan_interface` (join via
  `device_wan_id`) — the mirror image trips everyone once.
- Both tables are partitioned: always filter `partition_year` and
  `partition_month` or the scan is unbounded.
- Column-store trap: test non-empty strings with `length(x) > 0`,
  never `x <> ''`.
- Latest-per-device pattern: `(array_agg(col ORDER BY inserted_at DESC,
  id DESC))[1]` — deterministic, re-run-stable.

## Examples

**Input:** "is the warehouse reachable yet?"
**Output:** Runs the psql one-liner. Still closing pre-handshake → "No —
still the source-IP block (see skill), the whitelist ask to the DBA is
outstanding." Connects → runs the first-session sequence and reports.

**Input:** "run the query pack" (after access lands)
**Output:** Executes Part 4 of the verdict doc against {{WAREHOUSE_PRODUCT}}, then updates
the doc's Part 1 with per-metric verdicts (historised? cadence? retention?
GPS coverage vs the 88%-blind POC benchmark) and reports the summary.

**Input:** "build the signal pass-list for Sunday"
**Output:** Runs good-customer.md Q1 + Q5–7, keeps latest RAT in
('NR','ENDC') AND latest valid RSRP > −100, writes one msisdn per line to a
local file, and points the campaign-run job at it via GOOD_DEVICE_FILE.