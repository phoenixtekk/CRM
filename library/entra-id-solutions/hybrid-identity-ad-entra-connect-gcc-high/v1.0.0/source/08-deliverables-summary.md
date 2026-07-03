# Deliverables Summary — Hybrid Identity (Government / GCC High)

Everything included in this **Government (GCC High) edition**, and how the pieces fit the
Assess → Configure → Pilot → Validate → Expand model.

## Documents

| Document | What it gives you |
| --- | --- |
| `01-solution-overview.md` | The solution, the deployment model, named objects, and the **Commercial vs GCC High — what's different** section. |
| `02-requirements.md` | Every prerequisite with **Verify / Implement**, each pointed at the correct `*.us` portal/endpoint. |
| `03-implementation.md` | Ordered Gov steps, including **selecting the US Gov cloud in Entra Connect** (auto-detection or `AzureInstance=4` + Custom install). |
| `05-testing.md` | Pass/fail validation cases against the Gov surfaces, with a summary gate. |
| `06-troubleshooting.md` | GCC-High-specific failure symptoms and fixes. |
| `07-best-practices.md` | Sovereign-cloud discipline, endpoint hygiene, identity-plane safety. |
| `gcc-high-parity-notes.md` | Cited Commercial-vs-GCC-High parity reference. |
| `executive-summary.md` | One-page summary for decision-makers. |
| `global-requirements-entra-id-solutions.md` | Category-wide prerequisites (shared). |

## PowerShell scripts (`scripts/`)

All scripts connect to **Microsoft Graph US Gov** with `-Environment USGov`. Read-only scripts make
no changes; change scripts default to **`-WhatIf`**.

| Script | Type | Purpose |
| --- | --- | --- |
| `HYBIDG-Discovery.ps1` | Read-only | Inventory AD health, Connect host, UPN/domain hygiene, tenant state (Assess). |
| `HYBIDG-Validation.ps1` | Read-only | Assert the deployment targets the **US Gov** instance and is configured correctly. |
| `HYBIDG-Report.ps1` | Read-only | Produce a health/state report of sync, sign-in method, and scope. |
| `HYBIDG-Remediation.ps1` | Change (**`-WhatIf` default**) | Safely correct common drift (sync disabled, wrong settings). |
| `HYBIDG-Set-ScopeTargeting.ps1` | Change (**`-WhatIf` default`**) | Build/confirm the sync target group for staged Pilot/Expand waves. |

## How the deliverables map to the model

| Stage | Documents | Scripts |
| --- | --- | --- |
| **Assess** | 01, 02 | `HYBIDG-Discovery.ps1` |
| **Configure** | 03 | `HYBIDG-Validation.ps1` |
| **Pilot** | 03, 05 | `HYBIDG-Set-ScopeTargeting.ps1` |
| **Validate** | 05, 06 | `HYBIDG-Report.ps1` |
| **Expand** | 03, 07 | `HYBIDG-Set-ScopeTargeting.ps1`, `HYBIDG-Remediation.ps1` |

## Definition of done

- Discovery clean; break-glass accounts confirmed on `.onmicrosoft.us`.
- Entra Connect installed against the **US Gov** service instance; sign-in routes through
  `login.microsoftonline.us`.
- Pilot scope synced and validated; all applicable `05-testing.md` cases pass.
- Production expanded in waves; Connect Health green; Gov endpoint allow-list current.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.
