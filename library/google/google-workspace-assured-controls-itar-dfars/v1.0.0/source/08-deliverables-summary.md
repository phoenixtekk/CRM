# 8. Deliverables Summary — Regulated Google Workspace: Assured Controls, ITAR & DFARS

Everything included in this solution and how the pieces fit the **Assess → Configure → Pilot →
Validate → Expand** model. The solution delivers the **technical configuration and evidence** for
controlled data; **regulatory interpretation is deferred to legal/compliance**.

## Documentation
| Doc | Purpose |
|---|---|
| **01 — Solution Overview** | How Assured Controls, data regions, and access-management/approval controls map to ITAR/DFARS controlled-data requirements; scope and limits |
| **02 — Requirements Guide** | Prerequisites (add-on/edition, legal/compliance stakeholders, data classification, data regions, CSE readiness, admin roles, pilot, evidence destination) — each with Description · Why · Verify · Implement |
| **03 — Implementation Guide** | Click-by-click: configure data-region residency, Access Management, Access Approvals, the evidence surface, and (if legal-required) CSE; pilot, validate, remediate, expand |
| **05 — Testing & Validation** | Pass/fail tests per control against the required posture, with a pilot-exit sign-off gate |
| **06 — Troubleshooting** | Symptom → cause → fix for the common configuration issues |
| **07 — Best Practices** | Evidence-and-audit discipline: named configs, scope, Access Transparency, coverage snapshots, safe operations |
| **executive-summary** | One-page business framing for compliance/security leadership |

## Scripts (5)
All PowerShell, driven by a Google super-admin OAuth token (read-only scopes for the read-only
scripts). Read-only scripts change nothing; state-changing scripts default to **`-WhatIf`**.

| Script | Role | Safety |
|---|---|---|
| **GWREG-Discovery.ps1** | Controlled-data posture discovery — data region, CSE, Access Management/Approvals state, controlled OU layout | Read-only |
| **GWREG-Validation.ps1** | Per-scope validation of each control **against the required posture**, pass/fail | Read-only |
| **GWREG-Report.ps1** | Compliance **coverage / evidence** report across scopes | Read-only |
| **GWREG-Remediation.ps1** | Bring a scope to the required posture (region / Access Management / Approvals) | **`-WhatIf` default** |
| **GWREG-Set-ScopeTargeting.ps1** | Create/grow the controlled-data pilot OU/group targeting | **`-WhatIf` default** |

## How they fit the deployment model
- **Assess** — `GWREG-Discovery.ps1` baselines posture; stakeholders confirm the required target.
- **Configure** — Implementation Steps 1–5 (Data regions, Access Management, Access Approvals,
  evidence, CSE), scoped with `GWREG-Set-ScopeTargeting.ps1`.
- **Pilot / Validate** — `GWREG-Validation.ps1` + `GWREG-Report.ps1`; legal/compliance sign-off gate.
- **Remediate** — `GWREG-Remediation.ps1` (`-WhatIf` → approved execute).
- **Expand** — apply the named configs fleet-wide; re-validate and snapshot coverage.

## Outcome
Google Workspace configured for controlled data — **U.S. (or required-region) residency**,
**support-access limited by location/eligibility and gated by approval**, an **Access-Transparency
evidence trail**, and (where legal relies on it) **CSE** — **proven on a pilot** and **signed off by
legal/compliance** before fleet-wide rollout, with named, reusable configurations and a documented
rollback. The determination that this satisfies ITAR/DFARS remains **legal/compliance's**, made on the
evidence this solution produces.
