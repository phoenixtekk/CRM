# 8. Deliverables Summary — Risk & Compliance Dashboard (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The consolidated-dashboard model, the eight Purview signals, live vs owner-captured sources, privacy-by-design for HR-sensitive feeds |
| 2. Requirements Guide | Every dashboard prerequisite with Verify / Implement-if-missing (category Purview GRs referenced, not duplicated) |
| Global Requirements (Purview) | Category-wide Purview prerequisites, published once |
| 3. Implementation Guide | Exact, ordered S&C PowerShell + Graph + portal steps: discover signals, author config, pilot collect/render read-only, reconcile, schedule, distribute; `-Commit` write gated + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates (readiness / build / trust) |
| 6. Troubleshooting Guide | Signal, audit, reconciliation, privacy, and scheduling issues by symptom → root cause |
| 7. Best Practices | Field-proven recommendations for a trustworthy, low-maintenance dashboard |

## PowerShell scripts (Security & Compliance PowerShell / Microsoft Graph)
| Script | What it does | Safety |
|---|---|---|
| `CMPDASH-Discovery.ps1` | Signal-availability readiness: which of the eight Purview signals are present/enabled, E5 gating, DLP/label/retention policy counts, unified audit-log ingestion state | Read-only |
| `CMPDASH-Set-Configuration.ps1` | Writes `RiskComplianceDashboard.config.json` (tiles/RAG thresholds/cadence/sources) and a schedule scaffold; optionally enables audit-log ingestion | Default `-WhatIf`; `-Commit` to write |
| `CMPDASH-Validation.ps1` | Reconciles live tiles against the source (policy counts, DLP volume tolerance, audit state) and flags stale owner-captured figures | Read-only |
| `CMPDASH-Report.ps1` | The consolidated dashboard generator: collects live signals + merges owner-captured figures → `RiskComplianceDashboard.data.json` and renders `RiskComplianceDashboard.html` + `.csv` with RAG + source badges | Read-only |
| `CMPDASH-Scope.ps1` | Scope/health helper: which feeds the current identity can read (role separation check) and each feed's freshness/health | Read-only |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
A **consolidated risk & compliance dashboard** across Microsoft Purview signals — Compliance Manager,
DLP, sensitivity labels, retention/records, Insider Risk, Communication Compliance, Audit, and DSPM —
rendered as an owned HTML/CSV artifact with RAG status and honest source badges, piloted read-only,
reconciled against the portal, and refreshed on a schedule. HR-sensitive feeds are **aggregate-only and
role-separated**, and all regulatory/records/legal determinations remain **deferred to the governance
functions**.
