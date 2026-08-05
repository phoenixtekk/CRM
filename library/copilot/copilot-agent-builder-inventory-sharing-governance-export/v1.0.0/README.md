# Copilot Agent Builder — Agent Inventory & Sharing Governance Export (Microsoft Graph) — v1.0.0

| | |
|---|---|
| Category | Copilot |
| Solution code | AGBINV |
| Commercial | $2,495.00 (`PTK-AGBINV-COMM-001`) |
| Non-Profit | $1,497.00 (`PTK-AGBINV-NPO-001`) |
| Government | $2,120.75 (`PTK-AGBINV-GOV-001`) |
| Branding | off (white-label) |
| Pricing tier | T3 — Graph export pipeline + sharing enumeration + beta-endpoint diagnostic |
| Government variant | inline (no `source-gov\`) — Package API is Global-only, so Government tenants use Path A (admin center export); scripts target Global/USGov/USGovDoD via `-Environment` |

A supported, repeatable export of every **Copilot Agent Builder (declarative) agent** and **who each is
shared with** (users and groups), plus the direct diagnostic on the customer's Graph endpoint
`GET /copilot/admin/catalog/packages/{id}`: what it returns, why requests are blocked (401/403/404), and
the supported fix. Scoped to Agent Builder only — Copilot Studio is explicitly excluded and filtered out.

**Key accuracy findings (verified against Microsoft Learn 2026-07-24):**
- The endpoint namespace is correct; the API is now documented in both `v1.0` and `beta`.
- The per-agent detail (`copilotPackageDetail`) exposes sharing via **`allowedUsersAndGroups`**; the list
  call only returns `availableTo`/`deployedTo` as `all`/`some`/`none`.
- Blocks decode to: scope/consent, admin role, the Microsoft Agent 365 entitlement (docs now require it),
  or tenant rollout / Global-only availability. Customer ruled out Agent 365 → Path A fallback provided.

**Scope boundary:** Agent Builder (declarative) agents only. Not Copilot Studio (out of scope). Records
the allowed audience (who can reach an agent), not runtime usage.

## What's included

- **Documentation** (Word + PDF): overview, requirements (9), implementation (two paths), testing (10
  gates), troubleshooting (blocked/failed decision tree), best practices, executive summary, category
  global requirements.
- **5 PowerShell scripts** (Microsoft Graph SDK; all read-only, all `-Environment Global|USGov|USGovDoD`):
  `AGBINV-Connect-Preflight.ps1`, `AGBINV-Export-AgentInventory.ps1`, `AGBINV-Export-AgentSharing.ps1`,
  `AGBINV-Filter-AgentBuilderOnly.ps1`, `AGBINV-Report-GovernanceRegister.ps1`.
- **Hero image** + listing (bagisto-products.json, sales-content.md).

## Deliverable files (deliverables/)

- `AGBINV-Solution.pdf` · `AGBINV-Solution.docx` · `AGBINV-Scripts.zip`
- `AGBINV-Complete-Solution.zip` · `AGBINV-hero.png` / `.svg`
