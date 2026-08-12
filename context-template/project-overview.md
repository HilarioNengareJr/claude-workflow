# Project Overview

## About the Project

<PROJECT_NAME> is a <one-line description: what kind of application, for whom>. It is built with
<STACK> and <consumes / exposes> <the API or data source it depends on>. It is deployed to
<ENVIRONMENT — public web, internal network, app store, package registry>.

Authentication is <AUTH_MECHANISM>. <One sentence on what carries the credential and who verifies
it.>

Keep this to two paragraphs. Anything longer belongs in the sections below.

---

## The Problem It Solves

<Two or three sentences on the real-world problem. Not the technical description — the reason
someone funded this work. What breaks, or what costs money, when this tool doesn't exist?>

---

## Pages

<For a UI project, list every route and what it does in one line. For a service, replace this
heading's content with the endpoint surface. For a library, the public API surface.>

```
/                  → <what this route shows and its main interactions>
/<resource>        → <list view — filters, search, bulk actions>
/<resource>/new    → <create form>
/<resource>/:id    → <detail view>
*                  → 404 Not Found
```

---

## Navigation

<How a user moves through the product. Sidebar, tabs, command palette. Include the actual nav item
order — it's the fastest way for an agent to know what exists.>

```
<Nav item 1>
<Nav item 2>
<Nav item 3>
```

---

## Core Workflows

The jobs people actually come here to do. One subsection per domain — a workflow the agent can
trace end to end.

### <Domain 1>

<What the user is trying to accomplish, the steps they take, and where each step's data comes
from. Name the states an entity moves through if it has any.>

### <Domain 2>

<Same shape.>

---

## Data Architecture

### API Clients

<How the app talks to its backend. Base paths, envelope shape, case conversion, error type.>

### Query Layer

<Where data-fetching lives, the naming convention, how cache invalidation works.>

### Money

<The single most common source of silent bugs. State the unit and stick to it — e.g. "prices are
always in minor units (cents); display with formatMoney(). Never store or pass a float.">

### IDs

<UUID, integer, slug? Note every exception explicitly — the exceptions are what cause bugs.>

### Enums and Status Values

<List the closed sets and their legal transitions. Example:>

```
pending → paid → processing → shipped → completed
(cancelled from any state)
```

---

## Features In Scope

- <Feature — one line each. This list is the boundary the agent respects.>
- <Feature>

---

## Features Out of Scope

Being explicit here prevents helpful-but-unwanted work more reliably than any instruction.

- <Feature deliberately not built — and one clause on why>
- <Feature owned by a different system>

---

## Target Environment

| | |
|---|---|
| Runtime | <Node 20 / Python 3.12 / Go 1.22 / browser> |
| Browsers | <if applicable> |
| Hosting | <where it runs> |
| Network | <public / VPN-only / air-gapped> |
| Config | <the env vars that change between environments> |
