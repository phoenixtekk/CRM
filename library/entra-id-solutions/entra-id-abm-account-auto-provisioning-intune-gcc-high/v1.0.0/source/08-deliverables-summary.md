# Deliverables Summary — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

Everything included in this Government (GCC High) edition and what each piece is for.

## Documents (source)

| File | Purpose |
| --- | --- |
| `01-solution-overview.md` | What the solution delivers on GCC High, and the **Commercial vs GCC High — what's different** section (federation/SCIM parity gap up front). |
| `02-requirements.md` | Every GCC-High-specific prerequisite with **verify** and **implement-if-missing**, including the R0 parity decision gate. |
| `03-implementation.md` | Ordered Assess → Configure → Pilot → Validate → Expand steps using `*.us` portals, with GCC-High caveats inline. |
| `05-testing.md` | Pass/fail matrix mapped to phase gates (no SCIM-success test — that path is unsupported in US Gov). |
| `06-troubleshooting.md` | GCC-High-specific symptoms and fixes, including the "federation won't complete" expected behaviour. |
| `07-best-practices.md` | Operating practices: sovereign targeting, staging, expiries, least privilege, compliance-boundary caution. |
| `08-deliverables-summary.md` | This file. |
| `executive-summary.md` | One-page summary for decision-makers, leading with the parity gap. |
| `gcc-high-parity-notes.md` | Cited reference for every Commercial-vs-GCC-High difference; the factual backbone. |
| `global-requirements-entra-id-solutions.md` | Category-level Entra prerequisites (shared). |

## Scripts (scripts/)

All scripts connect to the **US Gov** Microsoft Graph endpoint with
`Connect-MgGraph -Environment USGov`. Read-only scripts make no changes; change scripts default to
`-WhatIf`.

| Script | Type | Purpose |
| --- | --- | --- |
| `ABMPROVG-Discovery.ps1` | Read-only | Inventory tenant, licensing signals, Apple enrollment configuration, and pilot groups; surface readiness gaps. |
| `ABMPROVG-Validation.ps1` | Read-only | Check APNs certificate, ABM ⇄ Intune token, ADE profile, and pilot assignment against pass/fail criteria. |
| `ABMPROVG-Report.ps1` | Read-only | Produce a health snapshot (token/APNs expiry, enrolled pilot devices, group membership) for records and reviews. |
| `ABMPROVG-Remediation.ps1` | Change (**-WhatIf default**) | Safely fix common drift (e.g. missing group assignment) after previewing the planned actions. |
| `ABMPROVG-Set-ScopeTargeting.ps1` | Change (**-WhatIf default**) | Build/populate the `ABM-Apple-Pilot-Devices` scope group for staged rollout. |

## How they fit the deployment model

- **Assess:** `ABMPROVG-Discovery.ps1`
- **Configure:** `ABMPROVG-Validation.ps1`
- **Pilot:** `ABMPROVG-Set-ScopeTargeting.ps1`
- **Validate:** `ABMPROVG-Validation.ps1`, `ABMPROVG-Report.ps1`, `ABMPROVG-Remediation.ps1`
- **Expand:** re-run `ABMPROVG-Set-ScopeTargeting.ps1`, then `ABMPROVG-Validation.ps1` +
  `ABMPROVG-Report.ps1`

## The one thing to remember

On GCC High, **Entra ⇄ ABM federation and SCIM auto-provisioning are not supported** (Apple excludes
national clouds). This edition delivers the **supported** outcome — ABM ⇄ Intune Government enrollment
with ABM-native Managed Apple IDs — and documents the parity gap so expectations are set correctly.
See `gcc-high-parity-notes.md` for citations.
