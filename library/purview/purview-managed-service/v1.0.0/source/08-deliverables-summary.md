# 8. Deliverables Summary — Microsoft Purview Managed Service

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the managed-service operating model is — monitoring, triage, tuning, reporting, improvement — how it operates (not re-implements) the capability solutions, benefits and limitations |
| 2. Requirements Guide | Every managed-service prerequisite with Verify / Implement-if-missing (licensing, operational roles, service scope + SLOs/cadences, capability-to-owner map, monitoring signals, change control, reporting/escalation) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Ordered steps: baseline + capability map, design the operating model (SLOs/cadences/runbooks), configure monitoring/triage, pilot the cadence (tuning piloted in owning capability), validate SLOs, run continuously + improve |
| 5. Testing Guide | Ten pass/fail gates from baseline through triage, safe tuning, posture-only, SLOs, reporting, and the improvement loop |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for running Purview continuously |

## PowerShell scripts
| Script | What it does |
|---|---|
| `OPSMANAGED-Discovery.ps1` | Estate + operational-signal inventory (the monitoring baseline): DLP policies + modes, labels + policies, retention, audit status, alert-policy presence, IRM presence/posture, role groups; read-only |
| `OPSMANAGED-Monitor.ps1` | Monitoring/triage sweep: pulls recent DLP/alert/activity from the unified audit log into a triage view grouped by workload/severity, confirms audit is on; read-only |
| `OPSMANAGED-Validation.ps1` | Health/validation checker: pass/fail lines — audit on, no intended policy missing/disabled/stuck, alert signals readable, roles present — for the pilot and each cycle; exit code |
| `OPSMANAGED-Remediation.ps1` | Safe remediation (default `-WhatIf`): enables a disabled label/retention policy; **never** auto-enforces DLP or any high-impact change — those are routed to the owning capability and piloted there |
| `OPSMANAGED-Report.ps1` | Service-report rollup: policy-health counts, alert/activity volume, and SLO-adherence input from a cycle's triage CSV; exports the service report / baseline for the next cycle |

## Named artifacts (verbatim — used across docs, scripts, and tests)
- **`Managed Service – Monitoring Baseline`**, **`Managed Service – Capability Map`**, **`Managed Service
  – SLO Targets`**, **`Managed Service – Cadence Calendar`** (Daily/Weekly/Monthly/Quarterly)
- **`Managed Service – Run Book`** (Alert Triage · DLP Tuning · Health Monitoring · New-Workload
  Onboarding), **`Managed Service – Triage Queue`**, **`Managed Service – Tuning Log`**
- **`Managed Service – Service Report`**, **`Managed Service – Improvement Backlog`**

## What the buyer receives
- This operating-model guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable operating model following the model: **Assess → Design → Configure → Pilot (the cadence)
  → Validate → Expand (run continuously)**, with high-impact changes piloted in their owning capability
  and a documented rollback.

## Outcome
Microsoft Purview **run continuously** — a monitoring baseline watched for drift, DLP/alert activity
triaged with severity and an owner, tuning piloted safely in the owning capability, a regular service
report reconciled with the portal, and an improvement backlog that trends the estate healthier over time.
**High-impact changes are piloted in their owning capability solution; regulatory, records, legal, and
insider-risk determinations remain with compliance/records/privacy/legal.**
