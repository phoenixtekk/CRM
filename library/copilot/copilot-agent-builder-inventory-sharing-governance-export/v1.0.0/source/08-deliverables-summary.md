# Deliverables Summary

## What you receive

- **Solution Overview** — what Agent Builder agents are, where they surface for admins, the
  **beta-endpoint reality** (the direct answer on `GET /copilot/admin/catalog/packages/{id}`), and the
  two-path export approach.
- **Requirements** — nine requirements (roles, the exact Graph scope `CopilotPackages.Read.All`, the
  Agent 365 entitlement reality, tenant rollout, cloud selection, storage) each with Description / Why /
  Verify / Implement-if-missing, plus the Commercial-vs-Government endpoint table.
- **Implementation** — the ordered build: choose cloud/path, preflight and decode the failure, list
  agents filtered to Agent Builder, resolve sharing to users/groups, build the register, pilot, expand.
- **Testing** — ten PASS/FAIL gates from "preflight returns a clear verdict" to "Government behaves as
  documented."
- **Troubleshooting** — the blocked/failed-request decision tree: permission vs role vs Agent 365 vs
  feature-not-enabled vs undocumented vs real limitation.
- **Best Practices** — read-only posture, `v1.0` over `beta`, the recurring monthly export, triage by
  sharing scope, least privilege, and Government-cloud guidance.
- **Executive Summary** — the one-page brief for the governance sponsor.
- **Category global requirements** — the Copilot-category common prerequisites.

## The five PowerShell scripts

All accept `-Environment Global|USGov|USGovDoD` and are **read-only** against Microsoft Graph. Each
header carries Purpose / How to run / Expected results.

| Script | What it does |
|---|---|
| **`AGBINV-Connect-Preflight.ps1`** | Signs in, reports scopes + roles, calls the packages endpoint, and **decodes** the `401`/`403`/`404` into a named cause — the "why is my request blocked" answer. |
| **`AGBINV-Export-AgentInventory.ps1`** | Lists Copilot packages **filtered to the Agent Builder platform + `declarativeAgent`** and writes the inventory CSV. |
| **`AGBINV-Export-AgentSharing.ps1`** | For each agent, calls the **per-id detail** endpoint, reads **`allowedUsersAndGroups`**, and resolves users/groups to names → sharing CSV. |
| **`AGBINV-Filter-AgentBuilderOnly.ps1`** | Reduces any packages export to **Agent Builder only**, excluding Copilot Studio / Microsoft / partner agents. |
| **`AGBINV-Report-GovernanceRegister.ps1`** | Merges inventory + sharing into the **`Agent Builder Governance Register`** with review columns. |

## The artifact you maintain

- **`Agent Builder Governance Register`** (`AgentBuilder-Governance-Register_<date>.csv`) — one row per
  Agent Builder agent: owner, status, platform, dates, **sharing scope**, **shared-with recipients**,
  and review columns (OwnerConfirmed / SharingApproved / Action / ReviewedBy / ReviewedOn). Stored in
  the controlled export location and refreshed by the monthly scheduled task.

## Format

Delivered as a Word document and PDF, plus all PowerShell scripts in a single ZIP — yours to keep and
reuse across unlimited runs.
