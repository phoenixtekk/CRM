# Executive Summary

## The situation

Employees are creating **Copilot Agent Builder agents** — lightweight declarative agents built inside
Microsoft 365 Copilot — and sharing them with colleagues and groups. Governance needs a **complete
inventory** of those agents and, for each, a record of **who it is shared with**. An attempt to pull
this from Microsoft Graph was **blocked or failed**, leaving an open question: is the endpoint wrong,
the permission wrong, the tenant not enabled, or the data simply unavailable?

## The answer

The endpoint attempted — `GET /copilot/admin/catalog/packages/{id}`, the **Copilot Package Management
API** — is the **correct** one, and its per-agent detail object **does** return the sharing recipients
in a property named **`allowedUsersAndGroups`** (users and groups). The request fails for one of four
concrete, distinguishable reasons: a missing Graph permission scope or admin consent, an insufficient
admin role, the **Microsoft Agent 365** entitlement the current documentation states for this API, or
the API **not yet being rolled out to the tenant**. This package tells the reasons apart and resolves
each.

## What this package delivers

- A **supported, repeatable export** of every Agent Builder agent — name, owner, status, dates, publish
  state — with the inventory **filtered to Agent Builder** agents (Copilot Studio explicitly excluded).
- The **granular sharing detail** (which users and groups each agent is shared with), resolved from
  object IDs to readable names, via the Graph per-agent detail call.
- Two paths to the same result: **Path A** — the Microsoft 365 admin center Agent Registry **Export to
  CSV** (no code, no extra entitlement); **Path B** — the Graph Package Management API (scriptable,
  schedulable, includes sharing). Use A when Graph is gated; use B for the recurring, complete register.
- A clear **beta-endpoint diagnostic**: what the endpoint returns, why it blocks/fails, and the exact
  fix for each `401` / `403` / `404`.
- A maintained **`Agent Builder Governance Register`** and a **recurring monthly export** so the record
  stays current.

## Scope and honesty

Scope is **Agent Builder (declarative) agents only**; Copilot Studio governance is out of scope. The
register records **who an agent can reach** (its allowed audience), not a runtime usage log of who
opened it. The **Agent 365 entitlement** and **tenant rollout** for the Graph path are moving targets —
the package tells you how to verify your tenant's state rather than asserting one answer, and provides
the admin-center fallback so you can produce the inventory today regardless.

## Effort and outcome

Delivered as self-guided, click-by-click documentation plus five PowerShell scripts (read-only by
default). A competent administrator follows it end to end — no consultant required — and comes away with
a trustworthy, repeatable inventory of Agent Builder agents and their sharing, ready for governance
review.
