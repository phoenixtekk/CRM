# Deliverables Summary — Purview DLP, Labels & Retention (Government / GCC High)

This solution deploys Microsoft Purview **sensitivity labels + auto-labeling**, **DLP**, and
**retention + records** on a **US sovereign-cloud (GCC High)** tenant, correctly — right portals,
right endpoints, and Commercial-vs-GCC-High parity gaps handled — proven on a pilot before scale.

## Documents

| File | Purpose |
| --- | --- |
| `01-solution-overview.md` | The Purview model on GCC High; how the sovereign cloud differs (portals, endpoints, parity); the Assess→Configure→Pilot→Validate→Expand model. Includes a **Commercial vs GCC High** subsection. |
| `02-requirements.md` | Each prerequisite as **Description / Why / Verify / Implement-if-missing** — GCC High tenant, Gov G3/G5 licensing, Purview roles, `compliance.microsoft.us` access, endpoint allow-list, parity confirmation. |
| `03-implementation.md` | Exact ordered steps in the GCC High portals: labels + label policy, service-side auto-labeling, DLP (audit→enforce), retention + records — with GCC-High URLs and parity caveats inline where they matter. |
| `05-testing.md` | Pass/fail gates from sovereign-cloud sanity through enforcement and script validation. |
| `06-troubleshooting.md` | GCC-High-specific gotchas (feature not present, endpoint blocked, wrong portal/cloud) plus common failures. |
| `07-best-practices.md` | The assign-once, repeat-everywhere model, tuned for GCC High. |
| `gcc-high-parity-notes.md` | Reference: per-feature Commercial-vs-GCC-High status with Microsoft citations or explicit "verify for GCC High" flags. |
| `global-requirements-security.md` | Category-level prerequisites shared by all security solutions. |
| `executive-summary.md` | One-page summary for decision-makers. |

## Scripts (PowerShell, Microsoft Graph SDK, **US Gov endpoints**)

All scripts connect with **`Connect-MgGraph -Environment USGov`** for GCC High. Read-only tools are
read-only; change tools default to **`-WhatIf`**.

| Script | Role | Default |
| --- | --- | --- |
| `PURVIEWG-Discovery.ps1` | Inventory labels, label policies, DLP policies, retention/records config in the GCC High tenant. | Read-only |
| `PURVIEWG-Validation.ps1` | Check that the named objects exist and are scoped as designed; flag gaps. | Read-only |
| `PURVIEWG-Report.ps1` | Coverage / classification / DLP-event report for review. | Read-only |
| `PURVIEWG-Remediation.ps1` | Safely remediate detected gaps. | **`-WhatIf`** |
| `PURVIEWG-Set-ScopeTargeting.ps1` | Build/adjust the protection-scope group (`SG-Purview-Pilot`) membership and policy targeting for staged expansion. | **`-WhatIf`** |

## Named objects (created and reused verbatim)

`SG-Purview-Pilot` · labels `Public`, `General`, `Confidential`, `Confidential \ CUI` · label policy
`LP-Purview-Pilot` · auto-labeling `AL-CUI-ServiceSide` · DLP `DLP-CUI-Baseline` /
`DLP-CUI-Baseline-Rule1` · retention `Ret-CUI-7yr`, policies `RP-CUI-7yr-Auto`, `RP-Baseline-Retain`.

## Outcome

A GCC High tenant with a small, owner-approved label taxonomy driving **classification**,
**DLP** (audited then enforced), and **retention/records** — with every parity gap either handled by
a GA alternative or explicitly flagged for verification, and read-only scripts to detect drift.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
