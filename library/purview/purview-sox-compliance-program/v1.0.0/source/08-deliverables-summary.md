# 8. Deliverables Summary — Microsoft Purview SOX Compliance Program

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What a SOX-aligned Purview program is, the Purview→ITGC control map, the evidence runbooks, what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | SOX-specific prerequisites (compliance licensing, least-privilege roles with SoD, S&C + Exchange + Graph toolchain, unified audit, defined financial scope & records schedule, Compliance Manager, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess, map controls, enable audit, configure label / DLP-in-simulation / retention / audit-retention, map in Compliance Manager, build evidence runbooks, validate, expand to enforce — pilot-first with pass/fail gates and rollback. |
| **5. Testing & Validation** | Eleven gates from "audit on" to "program scorecard green," each with method / pass / fail action. |
| **6. Troubleshooting** | The failure modes that break SOX evidence — DLP enforcing too early, latency, truncation, licensing, endpoint confusion, retention scoping — and their fixes. |
| **7. Best Practices** | Defensible-program operating principles: evidence as the deliverable, explicit control mapping, DLP-in-simulation, deliberate classification/retention, SoD, drift monitoring. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`. No credentials or secrets are
embedded. Label / DLP / retention / audit-retention cmdlets use **Security & Compliance PowerShell**
(`Connect-IPPSSession`); audit search/config uses **Exchange Online PowerShell**
(`Connect-ExchangeOnline`); licensing/role reads use **Microsoft Graph**.

| Script | Role | Default |
|---|---|---|
| `PURVSOX-Scope.ps1` | Assess/health: connectivity, Purview role groups + SoD review, licensing (E5/E5-Compliance), Compliance Manager/DLP reachability, pilot scope. | Read-only |
| `PURVSOX-Discovery.ps1` | Assess: unified-audit state, existing labels / DLP (+ Mode) / retention / audit-retention policies, which named artifacts already exist. | Read-only |
| `PURVSOX-ConfigureControls.ps1` | Configure/Remediate: enable unified audit; create/update/remove the label, DLP (**simulation/test first**), retention, and audit-retention controls. | `-WhatIf` (writes on `-Commit`) |
| `PURVSOX-Validate.ps1` | Validate: confirm each control exists and is in its expected state (audit on, label published, **DLP in Test mode**, retention scoped, audit-retention present). | Read-only |
| `PURVSOX-EvidenceReport.ps1` | Report: control-to-evidence scorecard + run the evidence runbooks (paged `Search-UnifiedAuditLog`, no silent truncation) and export. | Read-only |

## Named artifacts created
- Controls: `Financial – SOX Reporting – Confidential` (label), `DLP – SOX Financial Data – Simulation` (DLP, simulation-first), `Retention – SOX Financial Records – Governed` (retention), `Audit Retention – Financial Data Access – SOX` (audit retention).
- Control mapping: `SOX ICFR – Purview Controls – Assessment` (Compliance Manager).
- Evidence runbooks: `Evidence – Financial Data Access – Runbook`, `Evidence – Control Change Management – Runbook`, `Evidence – Access Provisioning – Runbook`.
- Program export: `SOX Program – Purview Controls – Report`. Pilot scope: `SOX Pilot – Finance Ring – Stage1`.

## Definition of done
- Unified audit logging **on** (the evidence foundation), enabled before the review period.
- The financial-data **label** published to the pilot and applying to test content.
- The financial-data **DLP** policy in **simulation**, registering matches — then moved to **enforce** after the pilot passes and exposure is reviewed.
- The SOX **retention** policy scoped with the records-function's duration; the **audit-retention** policy in place.
- The controls **mapped in Compliance Manager** with linked evidence, **SoD** separation documented, and each **evidence runbook** proven to produce its artifact.
- The **program scorecard green** for the pilot — then expanded to the agreed scope with a monitoring cadence scheduled.

> **Boundary:** this solution delivers the technical configuration and evidence. **SOX control-design
> adequacy, operating-effectiveness conclusions, materiality, record-retention schedules, and legal
> holds are deferred to your management, internal-audit, records, and legal functions** — it is not an
> audit or an attestation. Feature availability is **licensing-/tenant-dependent and evolving — verify
> against your entitlements and current Microsoft documentation.**
