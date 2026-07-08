# 8. Deliverables Summary — Microsoft Purview HIPAA Compliance Program

What you receive, what it produces, and what stays a governance determination.

## Documents
| Document | What it gives you |
|---|---|
| **01 · Solution Overview** | What the HIPAA program is in Purview, the safeguard → control map, the role-separation model, limitations, the naming convention, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **02 · Requirements Guide** | Every HIPAA-program prerequisite — licensing (HIPAA/HITECH + HITRUST templates), separated Compliance Manager roles, named HIPAA owners, in-scope ePHI + safeguard map, action owners/evidence, automatic-testing decision, toolchain, pilot + change control — each with Verify / Implement-if-missing, referencing the category global requirements. |
| **03 · Implementation Guide** | The exact ordered steps: baseline → roles → design the assessment/scope/safeguard-map → create the HITECH pilot → build the action plan + evidence register → enable automatic testing → validate the technical evidence → expand — every artifact named, each step with a pass/fail gate and rollback. |
| **05 · Testing Guide** | Ten safe/read-only or pilot-scoped tests validating role separation, licensing, the assessment/score, ownership + mapping + evidence, automatic-testing accuracy, no-false-pass, shared-control mapping, the posture report, and safe automation defaults — with a gate to expand. |
| **06 · Troubleshooting** | The common failure modes (template not available, role/permission gaps, connection issues, false pass/fail, no write API expectations) and how to resolve them. |
| **07 · Best Practices** | Operating principles — governance boundary, risk-analysis anchor, evidence-once-score-many, least-privilege, pilot-first, evidence/audit-readiness, HR/privacy-sensitive controls, and lifecycle maintenance. |
| **Executive Summary** | The one-page business case: outcome, model, and the governance boundary — for the sponsor and the HIPAA officers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Microsoft Graph
All safe-by-default (read-only, or **`-WhatIf`** until `-Commit`); **no credentials in code** — interactive
modern-auth sign-in. Compliance Manager is **portal-managed**; these scripts assess readiness/roles and the
**technical evidence** behind the safeguards and structure the plan/evidence artifacts — they do not create
assessments.

| Script | Purpose | Default |
|---|---|---|
| **CMPHIPAA-Discovery.ps1** | Reports licensing SKUs (HIPAA/HITECH + advanced-control entitlement), Compliance Manager role-group membership (`HIPAA Roles – Separation Evidence`, flags admin-also-contributor), and the current state of the common technical safeguards (audit, DLP, retention, labels). | Read-only |
| **CMPHIPAA-Configuration.ps1** | Builds/validates the local tracking artifacts — `HIPAA Action Plan – Pilot`, `HIPAA Evidence – Register`, `HIPAA Control Map – Safeguards`, `HIPAA Scope – Record` — from the owner-provided action list (owner, target date, status, mapped safeguard, evidence source). Makes **no tenant changes**. | `-WhatIf` (write local files with `-Commit`) |
| **CMPHIPAA-Validation.ps1** | Read-only check of the **underlying technical safeguards** behind the mapped actions — unified audit ingestion (§164.312(b)), DLP/retention/sensitivity-label presence for ePHI, Conditional Access / MFA (§164.312(a),(d)) — so you know which auto-test and which need manual evidence. | Read-only |
| **CMPHIPAA-Report.ps1** | Produces the `HIPAA Posture – Report` — score context, safeguard-status rollup (Administrative/Physical/Technical), evidence register, role separation, licensing — a management rollup alongside the portal's authoritative export. | Read-only |
| **CMPHIPAA-Set-Scope.ps1** | Scope/health helper — manages Compliance Manager role-group membership (`Add-/Remove-RoleGroupMember`) for least-privilege separation. | `-WhatIf` (apply with `-Commit`) |

## Named artifacts this program creates/tracks
`HIPAA Assessment – HITECH – Pilot` · `HIPAA Assessment – Security Rule – Production` · `HIPAA Assessment –
HITRUST CSF – Production` · `HIPAA Control Map – Safeguards` · `HIPAA Action Plan – Pilot` · `HIPAA
Evidence – Register` · `HIPAA Automatic Testing – Setting` · `HIPAA Posture – Report` · `HIPAA Roles –
Separation Evidence` · `HIPAA Scope – Record`.

## Outcomes
- A **scored, control-by-control HIPAA program** in Compliance Manager (HIPAA/HITECH, and HITRUST CSF
  where entitled), with a safeguard → Purview control map.
- An **auditor-ready evidence register** — owners, implementation status, test status/date, and proof per
  safeguard — with automatic testing where eligible.
- **Least-privilege role separation** proven and snapshotted.
- A **posture report** and a **maintenance cadence** (re-test, re-evidence, review owners, annual
  evaluation), leaning on shared controls to expand efficiently.

## Explicitly out of scope (governance determinations, not technical outputs)
- **Which HIPAA safeguards apply, how each addressable specification is met, the risk-analysis outcome,
  and whether the evidence satisfies the obligation** — compliance/privacy/legal.
- **The high-impact technical controls a mapped action recommends** (new DLP/label/retention/CA policy) —
  separate, piloted-in-simulation changes owned by their own solution.
- **Records-retention schedules, legal holds, and breach-notification decisions** — records/privacy/legal.
