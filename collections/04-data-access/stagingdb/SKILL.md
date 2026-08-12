---
name: stagingdb
description: >
  Connect to and query the {{REPO_PREFIX}} staging Postgres cluster
  ({{STAGING_DB_HOST}}:5432, PostgreSQL 16.2 Percona) — the staging-local
  `{{APP_DB}}` database plus ~150 other {{COMPANY}} platform DBs on the same host
  (logistics, stock, party, product, communication, account, voucher). Access
  is OPEN as of 2026-07-24. Holds the working connection recipe, the confirmed
  staging schema state (Flyway history stops at V7, real schema is V16, V17–V24
  missing), and the migration-replay traps. Use whenever the user wants to
  query staging, check staging's schema or migration state, compare staging against prod,
  asks "is staging reachable", "what migrations is staging missing", "connect to staging
  db", "check the staging cluster", "which flyway version is staging on", or types
  /stagingdb. Consult before re-deriving any of it — this was blocked for two
  days and the answer is written down here. NOT for staging URLs (/envs) and NOT
  for prod data questions (/db).
---

# staging cluster — {{REPO_PREFIX}} staging Postgres

The staging-local Postgres for the {{ITEM}} stack, and the shared host for most of
{{COMPANY}}'s other staging platform databases. This is the environment the admin portal
needs to stand up on so it can come off BSS prod.

## Connection

```
host: {{STAGING_DB_HOST}}   (resolves {{STAGING_DB_IP}})   port: 5432
db:   {{APP_DB}}
```

Two working credentials, both verified **2026-07-24**:

```bash
# Personal — prefer this one
psql "postgres://{{STAGING_DB_USER}}:{{STAGING_DB_PASSWORD}}@{{STAGING_DB_HOST}}:5432/{{APP_DB}}?sslmode=disable"

# Application user (DSN lives in kubernetes/{{SERVICE_REPO}}/{{STAGING_MANIFEST}})
psql "postgres://{{APP_DB_USER}}:{{APP_DB_PASSWORD}}@{{STAGING_DB_HOST}}:5432/{{APP_DB}}?sslmode=disable"
```

**`sslmode=disable` is mandatory.** The server does not support SSL. With
`sslmode=require` you get `server does not support SSL, but SSL was required`
— that is a client-side refusal, not an access problem. Don't misread it as
the whitelist being closed.

Always set `PGCONNECT_TIMEOUT=10` so a closed whitelist fails fast instead of
hanging.

### Access history — don't re-derive this

Blocked until 2026-07-23 with a source-IP whitelist: the TCP handshake
completed but the server dropped the connection before auth
(`server closed the connection unexpectedly`). It opened on **2026-07-24**.

**`nc -z` is not a valid reachability test here** — the load balancer accepts
TCP even when the whitelist is closed, so `nc` reports success while `psql`
still fails. Always test with a real `psql` connection.

If it goes dark again, the symptom is that same pre-auth drop, and the fix is
whitelisting the VPN client IP (`{{VPN_CLIENT_IP}}`) on the staging cluster — same ask
that unblocked {{WAREHOUSE_PRODUCT}}. See [[warehouse]].

## Both credentials can WRITE

`{{STAGING_DB_USER}}` and `{{APP_DB_USER}}` both hold INSERT/UPDATE/DDL on `{{APP_DB}}`. Neither
is superuser. This is a **shared cluster carrying ~150 other teams'
databases** — a careless `UPDATE` without a `WHERE`, or a connection to the
wrong database, lands on someone else's system.

Rules:

1. Default to read-only. State plainly when you are about to write.
2. Never write outside the `{{APP_DB}}` database. The other DBs on this host belong
   to other teams.
3. Wrap any mutation in `BEGIN … ROLLBACK` first and show the row count before
   running it for real.
4. Never `DROP`. Never `TRUNCATE`.

## staging schema state — confirmed 2026-07-24

This was the two-day blocker. The answer:

| | |
|---|---|
| Flyway history says | **V7** (7 rows, stamped 2026-02-18 / 02-22) |
| Real schema is at | **V16** |
| Missing | **V17 – V24** (eight migrations) |

Tables present on prod but **absent on staging**: `campaign_send_attempts` (V17),
`billing_tenure` (V20), `automated_campaigns` + `automated_campaign_runs`
(V21), `cost_rates` + `voucher_budgets` (V23), `voucher_budget_alerts` (V24).

Confirmed at column level: `orders.voucher_token`/`channel` (V13) present,
`voucher_recipients.updated_at` (V15) present, `voucher_campaigns` present
(V16) but **without** `reminder_sent_at` (V18). So the boundary is exactly V16.

staging also carries three tables prod does not — `chat_executions`, `part_config`,
`part_config_sub` (pg_partman). Not from the repo's migrations.

Re-check the state with:

```sql
SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank;

SELECT relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind IN ('r','p') ORDER BY 1;
```

Use `pg_class`, not `information_schema.tables` — `information_schema` hides
tables the connected role lacks grants on, which is what made prod's voucher
tables look missing when they were only ungranted.

## Two traps before running any migration

### 1. The V5 numbering mismatch

Both staging and prod record V5 as *"collection details and product enrichment"*,
but the repo's `V5__update_product_prices.sql` is a different migration — that
content is the repo's **V11**. The files were renumbered after launch.

So the history is not merely behind, it **disagrees with the repo's
numbering**. `flyway migrate` validates descriptions and checksums by default
and will fail on V5 before applying anything.

### 2. V8–V11 are not safe to replay

Since history stops at V7, a raw `migrate` starts at V8 — and those are the
non-idempotent ones:

| Migration | Problem | Already on staging? |
|---|---|---|
| V8 | 3× bare `ADD COLUMN` on `promo_codes` | yes — would fail |
| V9 | bare `ADD COLUMN` on `products` | yes — would fail |
| V10 | bare `ADD COLUMN` on `products` | yes — would fail |
| V11 | bare `CREATE TRIGGER`, un-guarded `INSERT`s | yes — would fail / duplicate rows |

**V17–V24 are all fully idempotent** — every `CREATE`/`ALTER` uses
`IF NOT EXISTS` and both V23 `INSERT`s use `ON CONFLICT DO NOTHING`. That
range is safe to apply from a V16 baseline.

So the sequence is: reconcile history to V16 first, then apply V17–V24. Never
just flip the switch and hope.

## Applying migrations — the in-cluster route

The Flyway job in `kubernetes/{{SERVICE_REPO}}/templates/migration-job.yaml`
runs **inside the cluster** as a Helm `pre-install,pre-upgrade` hook. The pod
reaches `{{STAGING_DB_HOST}}` regardless of whether your laptop can. So enabling
migrations is a **git change, not a psql session**:

```yaml
# kubernetes/{{SERVICE_REPO}}/{{STAGING_MANIFEST}}
migrations:
  enabled: true
  baselineVersion: "16"
```

`migrations.enabled` is `false` in `values.yaml` and neither `{{STAGING_MANIFEST}}` nor
`prod.yaml` overrides it — which is why nothing has ever auto-applied.

Two things to know before pushing:

- `baselineOnMigrate` only fires when there is **no** `flyway_schema_history`
  table. staging has one (7 rows), so baselining alone will not fix the gap — the
  history rows for V8–V16 have to be reconciled directly, or validation
  disabled.
- The job is a pre-upgrade hook with `backoffLimit: 1`. **If it fails, the
  whole staging Helm upgrade fails** and staging deploys stay broken until the value is
  reverted. Recoverable, but not silent.

Prod is in the same shape — history at V7, real schema current, V8–V24 applied
by hand and never recorded. Prod's schema is fine; prod's migration history is
fiction. Don't "fix" prod without a DBA.

## The other databases on this host

Unlike the prod MCP connection in [[db]] — which is locked to one database —
this cluster exposes most of {{COMPANY}}'s staging platform DBs to `{{STAGING_DB_USER}}`. Verified
readable 2026-07-24 (non-system table counts):

| Database | Tables | Database | Tables |
|---|---|---|---|
| `logistics` | 327 | `account` | 153 |
| `product` | 291 | `communication` | 142 |
| `stock` | 104 | `party` | 58 |
| `voucher` | 5 | `{{REPORTING_SCHEMA}}` | 3 |

the campaigns database exists but is empty (0 tables).

Connect by swapping the database name — Postgres connections are per-database,
so there is no cross-database join from a single session:

```bash
psql "postgres://{{STAGING_DB_USER}}:{{STAGING_DB_PASSWORD}}@{{STAGING_DB_HOST}}:5432/logistics?sslmode=disable"
```

**This is staging data, not prod.** Do not answer prod questions from it — stock
counts, order volumes and customer records here are test fixtures or stale
copies. For real numbers use [[db]] (prod MCP) or the warehouse in
[[warehouse]]. The staging service pods themselves read comms/party/product from
**{{PROD_DB}}**, not from these staging copies, because no staging equivalent was
trusted — worth remembering before assuming staging is self-contained.

## Workflow

1. **Confirm you're connected where you think.** Every session, first query:
   `SELECT current_database(), current_user, version();`
2. **Say which environment you're on** in the answer. staging and prod numbers get
   confused easily and the two clusters share the same `{{APP_DB_USER}}` password.
3. **Read-only unless the user asked for a write**, and follow the write rules
   above.
4. **Report in business terms** — rands not cents, dates not epochs.
5. **If reality disagrees with this file, trust the query** and tell the user
   the skill is stale, naming what changed.

## Examples

**Input:** "is staging reachable?"

**Output:** runs one real `psql` connection (not `nc`), reports yes/no plus
`current_user` and server version.

**Input:** "what migrations is staging missing?"

**Output:** V17–V24, eight of them, with the table-level evidence — and the
warning that V8–V11 would fail if replayed.

**Input:** "compare staging's tables against prod"

**Output:** `pg_class` listing from staging via psql, same from prod via the `/db`
MCP, diffed both directions.

## Anti-patterns

- Using `nc -z` to decide reachability — the LB accepts TCP even when blocked.
- `sslmode=require` — the server has no SSL; this fails client-side and looks
  like an access problem.
- `information_schema.tables` for "does this table exist" — it hides ungranted
  tables. Use `pg_class`.
- Quoting staging figures as prod figures.
- Enabling `migrations.enabled` without reconciling history to V16 first — the
  hook fails and takes the staging deploy down with it.
