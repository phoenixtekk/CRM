# Deliverables Summary — Microsoft 365 Security Baseline & Audit Readiness (Government / GCC High)

Everything included in the **Government (GCC High)** edition, and where to use it.

## Documents

| Deliverable | Purpose |
| --- | --- |
| **Solution Overview** (`01-solution-overview.md`) | What the solution does; the **Commercial vs GCC High — what's different** map; the deployment model. |
| **Requirements Guide** (`02-requirements.md`) | Every prerequisite with *verify* + *implement-if-missing*, pinned to sovereign portals and Gov licensing. |
| **Implementation Guide** (`03-implementation.md`) | Ordered steps in the `*.us` portals, phase gates, and GCC-High caveats inline where they matter. |
| **Testing & Validation** (`05-testing.md`) | Pass/fail gates per phase, plus environment sanity checks (e.g. `USGov` confirmation). |
| **Troubleshooting** (`06-troubleshooting.md`) | GCC-High-specific failures (wrong-cloud auth, missing recommendations) and fixes. |
| **Best Practices** (`07-best-practices.md`) | Keeping posture and evidence credible over time on the sovereign cloud. |
| **GCC High Parity Notes** (`gcc-high-parity-notes.md`) | Cited reference for every "different in GCC High" claim. |
| **Executive Summary** (`executive-summary.md`) | One-page business case for decision-makers. |
| **Deliverables Summary** (this document) | Index of everything in the box. |
| **Global Requirements — Security** (`global-requirements-security.md`) | Category-level prerequisites (substitute `*.us` portals for GCC High). |

## PowerShell scripts

All scripts connect to **Microsoft Graph US Gov** with **`-Environment USGov`** (`graph.microsoft.us`).
Read-only scripts make **no** changes; change-making scripts **default to `-WhatIf`**.

| Script | Type | Default safety | What it does |
| --- | --- | --- | --- |
| **`M365SECG-Discovery.ps1`** | Read-only | N/A (read-only) | Inventories baseline Secure Score, licensing, admin roles, Conditional Access, and MFA posture on the GCC High tenant. |
| **`M365SECG-Validation.ps1`** | Read-only | N/A (read-only) | Checks that piloted baseline changes took effect; reports **PASS/FAIL per check**. |
| **`M365SECG-Report.ps1`** | Read-only | N/A (read-only) | Produces a point-in-time posture report (Secure Score summary, control states, assessment progress) for audit/leadership. |
| **`M365SECG-Remediation.ps1`** | Change | **`-WhatIf`** | Previews (then, with `-Execute`, applies) a small set of common improvement actions via Graph; requests only needed write scopes. |
| **`M365SECG-Set-ScopeTargeting.ps1`** | Change | **`-WhatIf`** | Previews (then, with `-Execute`, applies) creation/population of the pilot or wave target groups (e.g. `SEC-Baseline-Pilot`). |

## Named objects you create and reuse

| Object | Default name | Where |
| --- | --- | --- |
| Pilot security group | `SEC-Baseline-Pilot` | `entra.microsoft.us` → Groups |
| Baseline CA policies | `CA-Baseline-Admins-MFA`, `CA-Baseline-BlockLegacyAuth` | `entra.microsoft.us` → Conditional Access |
| Compliance assessment | `GCCHigh-DPB-Baseline` (and/or `GCCHigh-CMMC-L2`) | `compliance.microsoft.us` → Compliance Manager |

## Evidence you produce (archive for audit)

- Baseline + later **Secure Score** screenshots (`security.microsoft.us`).
- **Compliance Manager** assessment progress (`compliance.microsoft.us`).
- **Discovery / Validation / Report** script outputs (dated), each confirming `(Get-MgContext).Environment = USGov`.
- Change tickets with approver, window, pilot scope, and rollback.

## Quick-start order

1. Read `01-solution-overview.md` (especially the parity map) and `gcc-high-parity-notes.md`.
2. Clear `02-requirements.md` (sovereign portals + Gov licensing + `-Environment USGov`).
3. Follow `03-implementation.md` phase by phase, clearing each gate in `05-testing.md`.
4. Use the scripts for evidence; keep `06-troubleshooting.md` and `07-best-practices.md` at hand.
