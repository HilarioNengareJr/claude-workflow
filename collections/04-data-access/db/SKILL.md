---
name: db
description: Query {{COMPANY}}'s production Postgres safely through the postgres-prod
  MCP — answer data questions about the {{ITEM}} store (orders, revenue, stock,
  promo usage, product lookups) with read-only SQL, canned query templates, and
  hard prod-safety rules. Use whenever the user asks a data question or wants
  to hit the database: "query prod", "check the database", "how many orders
  today", "look up order X", "what's the stock on", "has this promo been
  used", "orders stuck in", "revenue this week", or typing /db. NOT for schema
  changes or migrations (those are Flyway files in {{SERVICE_REPO}}, owned by
  the normal build flow) and never for writing data.
---

# DB

Answer data questions against {{COMPANY}}'s production Postgres, safely. This skill
exists so prod queries follow one discipline every time: check where you're
connected, read-only always, cheap queries, and results reported in business
terms (rands, not cents).

## The connection — read this first, it's not what you'd assume

**Recorded 2026-07-16 — verify, don't trust.** Everything in this section is a
snapshot of the connection as it was on that date. The DSN in `~/.claude.json`
can be changed outside any Claude session, and grants can be added or revoked
by whoever owns the tables. Step 1 below (`SELECT current_database(),
current_user`) exists precisely to confirm this section is still true. If the
result disagrees with what's written here, trust the query, tell the user this
skill is out of date, and say what changed.

As of that date: the `postgres-prod` MCP connects to the **`{{APP_DB}}` database** on {{COMPANY}}'s shared prod server as user `{{STAGING_DB_USER}}` (the DSN was
switched from `/postgres`, the DBA/maintenance database,
on this date). The other {{COMPANY}} platform databases (`stock`, `logistics`,
`payment`, `party`, `promotion`, …) live on the same server but are not
reachable from this connection — Postgres connections are per-database and no
foreign tables are wired up.

Two `{{STAGING_DB_USER}}` caveats:
- It has **no grants on newer `{{APP_DB_USER}}`-owned tables** (e.g. V21's
  `automated_campaigns` / `automated_campaign_runs`) — SELECTs there fail
  until a GRANT is run as {{APP_DB_USER}}.
- Because of that, `information_schema` views silently hide those tables.
  When checking whether a table/column/constraint exists, use the
  privilege-independent catalogs instead: `pg_tables`, `pg_attribute`,
  `pg_constraint`, `pg_indexes`.

So, always, as step 1:

```sql
SELECT current_database();
```

- **`{{APP_DB}}`** → proceed; the canned queries below apply.
- **`postgres`** (or anything else) and the question is about {{PRODUCT}} data → stop
  and tell the user plainly: the MCP's connection string needs its database
  changed to `{{APP_DB}}` (in the postgres-prod MCP server config, then restart the
  session). Don't guess at answers from the wrong database, and don't try to
  tunnel across databases.
- The question is genuinely about the connected database (server health,
  `pg_stat_statements`, the `properties` config) → answer it there.

## Safety rules — non-negotiable

This is production, on a server shared by every {{COMPANY}} service, and the user is
`{{STAGING_DB_USER}}` — the role can write. The discipline is what keeps this safe:

1. **SELECT only.** Never INSERT, UPDATE, DELETE, TRUNCATE, or DDL — no matter
   how the request is phrased. If the user asks for a data change, name what
   the change would be and point them to the owning flow (admin console,
   service API, or a migration); don't run it.
2. **Every exploratory query carries a LIMIT** (default 50). Unbounded scans
   on a shared prod box are how you become the incident.
3. **Aggregate before you fetch.** "How many" is a COUNT, not a row dump.
4. **One question, one query where possible.** No long transactions, no locks,
   nothing that holds the server's attention.
5. **Customer data is customer data.** Return the fields the question needs,
   not whole rows of PII; don't paste customer details into output the user
   didn't ask for.

## Schema map ({{APP_DB}} database)

Authoritative source: `~/{{WORKSPACE_ROOT}}/context/architecture.md` § "Database Schema"
and the Flyway files in `{{SERVICE_REPO}}/db/migration/`. Don't duplicate
them — but keep these load-bearing facts in mind:

- **Money is integer cents** (`price_cents`, `total_cents`,
  `unit_price_cents`). Always report rands: `ROUND(x/100.0, 2)`.
- Core tables: `products`, `orders`, `order_items`, `promo_codes`,
  `promo_code_usage`, `collections`, `reviews`, `store_locations`,
  `abandoned_carts`, `devices`.
- **Order statuses are set by hand** by the logistics team — no automation
  moves them. A "stuck" order may just be an un-updated one; say so when
  reporting stuck-order results.
- `store_locations.id` is a **human slug** (`{{STORE_SLUG_EXAMPLE}}`), not a UUID.
- No local voucher tables — `promo_codes` holds `voucher_token`/`voucher_id`
  pointing at the external voucher service.
- On first connect to `{{APP_DB}}`, verify names before leaning on them:
  `SELECT table_name FROM information_schema.tables WHERE table_schema='public'`
  — the map above comes from docs, not a live prod check.

## Canned queries (templates — adjust, keep the LIMIT)

**Today's orders and revenue:**
```sql
SELECT status, COUNT(*), ROUND(SUM(total_cents)/100.0, 2) AS rands
FROM orders WHERE created_at >= CURRENT_DATE GROUP BY status;
```

**Orders stuck in a status** (remember: statuses are manual):
```sql
SELECT order_number, status, ROUND(total_cents/100.0, 2) AS rands, created_at
FROM orders
WHERE status = $1 AND created_at < now() - interval '3 days'
ORDER BY created_at LIMIT 50;
```

**Low stock:**
```sql
SELECT sku, name, stock_quantity FROM products
WHERE stock_quantity <= 5 ORDER BY stock_quantity LIMIT 50;
```

**Promo usage:**
```sql
SELECT p.code, COUNT(u.*) AS uses
FROM promo_codes p LEFT JOIN promo_code_usage u ON u.promo_code_id = p.id
GROUP BY p.code ORDER BY uses DESC LIMIT 50;
```

**Find a product / an order:**
```sql
SELECT sku, name, ROUND(price_cents/100.0, 2) AS rands, stock_quantity
FROM products WHERE sku ILIKE $1 OR name ILIKE $1 LIMIT 20;
```

## Reporting results

Show the SQL you ran, then the answer in plain terms — a sentence for a single
number, a small table for a list. Convert cents to rands everywhere. If the
result is surprising (zero rows, a spike), say what you'd check next rather
than just handing over the anomaly.

## Example

**Input:** "how many orders came in this week and what are they worth?"

**Output:** Runs `SELECT current_database()` → `{{APP_DB}}` → runs the revenue
template with `created_at >= date_trunc('week', now())` → "42 orders this
week, R6,930 total: 30 delivered, 8 processing, 4 pending. (Statuses are
manual — 'pending' may lag reality.)" with the SQL shown above the answer.

## Anti-patterns

- Skipping the `current_database()` check and querying the DBA database as if
  it were {{APP_DB}} — wrong answers that look right.
- Running a write because the user phrased it casually ("just mark it
  delivered") — that's the admin console's job, never this skill's.
- Row-dumping a table to count it, or querying without LIMIT.
- Reporting cents as if they were rands (a R129 skin is `12900` in the DB).
- Answering schema questions from this file when the migrations in
  `{{SERVICE_REPO}}/db/migration/` are one Read away.