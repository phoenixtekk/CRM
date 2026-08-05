# Sales Content — Copilot Agent Builder Inventory & Sharing Governance Export

## Hook

You tried to pull your Copilot agents from Microsoft Graph — and the request was blocked. This package
answers exactly what the `/copilot/admin/catalog/packages/{id}` endpoint returns, why your request
failed, and how to export a complete inventory of **Copilot Agent Builder agents** and **who each is
shared with** — the supported, repeatable way.

## The problem

People across your organization build **Agent Builder agents** (the lightweight declarative agents
created inside Microsoft 365 Copilot) and share them with colleagues and groups. Governance needs a
complete inventory and, for each agent, the list of users and groups it is shared with. The obvious
Graph call fails with a 401/403/404 and no explanation, leaving you unable to tell whether the endpoint
is wrong, permissions are wrong, the feature is not enabled, or the data is not exposed.

## The direct answer (what makes this product accurate)

- **The endpoint is correct.** `/copilot/admin/catalog/packages` (list) and `/{id}` (per-agent detail)
  are the documented **Copilot Package Management API** — the right namespace, now available in both
  `v1.0` and `beta`.
- **The sharing data is there.** The per-agent detail returns **`allowedUsersAndGroups`** — the exact
  users and groups an agent is shared with. The *list* call only returns an `all`/`some`/`none` summary;
  you must call the per-id detail for the recipients. (This is the detail most people miss.)
- **Why it was blocked** is one of four concrete, distinguishable causes: a missing
  `CopilotPackages.Read.All` scope or consent, an insufficient admin role, the **Microsoft Agent 365**
  entitlement the current docs require for this API, or the API not yet rolled out to your tenant. The
  package's decision tree separates them from the raw 401/403/404.
- **A no-Agent-365 fallback.** If Agent 365 is ruled out (or you are in a Government cloud where the API
  is unavailable), **Path A** — the Microsoft 365 admin center Agent Registry **Export to CSV**,
  filtered to Agent Builder — produces the inventory today.

## Run it yourself — simpler, cheaper, proven

- **Simpler** — click-by-click steps, a preflight that decodes your exact failure, named objects reused
  verbatim.
- **Cheaper** — one fixed price versus consulting at thousands per day; read-only and reusable every run.
- **Tested** — Assess → Configure → Pilot → Validate → Expand, with a reconciliation gate against the
  admin center.

## What's inside

- Solution Overview, Requirements (9), Implementation (two supported paths), Testing (10 gates),
  Troubleshooting (the blocked/failed decision tree), Best Practices, Executive Summary.
- **5 read-only PowerShell scripts** (`-Environment Global|USGov|USGovDoD`): preflight/decoder, inventory
  export (filtered to Agent Builder, Copilot Studio excluded), sharing export
  (`allowedUsersAndGroups` → names), Agent-Builder-only filter, and the governance-register generator.

## Scope and honesty

Scope is **Agent Builder agents only** — Copilot Studio is out of scope (your approval gates already
govern it), and the inventory is filtered to keep the two populations separate. The register records
**who an agent can reach** (its allowed audience), not a runtime log of who used it — usage is a separate
data source. The Agent 365 entitlement and tenant rollout are moving targets; the package tells you how
to verify your tenant's state rather than asserting one answer.

## The bottom line

A trustworthy, repeatable register of every Agent Builder agent and exactly who it is shared with — the
Graph endpoint mystery solved, scoped cleanly to Agent Builder, with a fallback that works today.

## Pricing

- **Commercial** — $2,495.00 (`PTK-AGBINV-COMM-001`)
- **Non-Profit** — $1,497.00 (`PTK-AGBINV-NPO-001`) — 40% off, eligibility verified
- **Government** — $2,120.75 (`PTK-AGBINV-GOV-001`) — 15% off, eligibility verified
