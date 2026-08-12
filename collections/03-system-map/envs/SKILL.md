---
name: envs
description: Print the {{REPO_PREFIX}} staging environment URLs for Web, Service API, and Admin. Use this skill whenever the user wants the staging endpoints, asks "what's the staging URL", "show me the staging environment", "where's the staging backend/admin/web", needs to open or curl a staging service, or types /envs. Covers the {{WEB_REPO}}, {{SERVICE_REPO}}, and {{ADMIN_REPO}} staging deployments on {{STAGING_DOMAIN}}.
---

# Show staging

Print the {{REPO_PREFIX}} staging environment URLs to the screen, exactly as below. This is a static reference — no analysis, no files to read. Just output the table.

## Instructions

Print the following table verbatim and stop:

| App         | staging URL                                          |
|-------------|--------------------------------------------------|
| Web         | https://{{WEB_STAGING_HOST}}        |
| Service API | https://{{SERVICE_STAGING_HOST}}    |
| Admin       | https://{{ADMIN_STAGING_HOST}}      |

Do not add commentary unless the user asked a follow-up question (e.g. "which one is the backend?" → Service API). The Service API is the Go backend the admin portal proxies to in dev.

## Example

**Input:** "/envs" or "what are the staging urls?"

**Output:** the table above.
