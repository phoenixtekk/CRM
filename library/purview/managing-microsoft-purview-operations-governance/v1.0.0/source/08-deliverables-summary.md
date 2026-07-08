# 8. Deliverables Summary — Managing Microsoft Purview: Operations & Governance

Everything included in this solution and exactly how each piece is used to **run Microsoft Purview as an
operated, measured program**.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The Purview operating model — policy lifecycle, Compliance Manager cadence, alert triage + reporting, role/access reviews, change control, and KPI dashboards — and where governance determinations stay with compliance/legal. |
| **Requirements Guide** | The nine operations-specific prerequisites (implemented foundation, role-separated ops roles, toolchain + Graph security scopes, policy baseline, Compliance Manager export, approved role list, alert-triage SLAs, KPI set, change control) — each with Verify / Implement-if-missing — over the six category requirements. |
| **Operating Guide** | Part A to stand up the operating model once; Part B the recurring heartbeat as five named runbooks (RB-01…RB-05) with pass/fail and rollback. |
| **Testing & Validation Guide** | Six tests with explicit pass/fail + rollback and an acceptance gate proving the model actually runs (drift caught, `-WhatIf` safe, alerts roll up, access diff flags, KPIs render, cadences fire). |
| **Troubleshooting Guide** | The common operating failures — connection/scope errors, drift false alarms, empty rollups, Compliance Manager export parsing, role-diff mismatches — with causes and fixes. |
| **Best Practices** | Durable practices for lifecycle/change control, triage/tuning, the CM cadence, access reviews, KPIs, and automation safety. |
| **Executive Summary** | A one-page brief for leadership on operating Purview as a measured program and why it de-risks compliance over time. |

## PowerShell tools (5) — Security & Compliance PowerShell / Microsoft Graph
All are **read-only or `-WhatIf` by default**; the one that writes gates every change behind `-Commit` and a
change record. None contain credentials or secrets — they use interactive modern auth.

| Script | Role | What it does | Default |
|---|---|---|---|
| **PURVOPS-Discovery.ps1** | Discovery / drift | Inventories every DLP, sensitivity-label, label-policy, auto-labeling, and retention policy with its mode; saves a baseline and reports **drift** against it. | Read-only |
| **PURVOPS-Report.ps1** | Reporting | Rolls up triggered alerts from Microsoft Graph (`/security/alerts_v2`) across DLP / insider-risk / information-protection / audit by category, severity, status, and triage time. | Read-only |
| **PURVOPS-Validation.ps1** | Validation | Enumerates Purview role groups and members and diffs them against an approved-membership baseline for the quarterly access review. | Read-only |
| **PURVOPS-KpiReport.ps1** | Reporting / KPIs | Composes the program-health KPI dashboard from live telemetry plus the Compliance Manager improvement-action export (no public API — CSV in). | Read-only |
| **PURVOPS-Remediation.ps1** | Config / remediation | Operational config helper — promotes a piloted policy to enforce or rolls it back — `-WhatIf` first, `-Commit` writes and stamps the change record. | `-WhatIf` (safe) |

## Named operating artifacts (created and reused verbatim)
`Policy Register – Purview – Governance` · `Policy Baseline – Purview – <date>` · `Change Record – Purview –
ChangeControl` · `Improvement Actions – Compliance Manager – Cadence` · `Alert Triage – Purview – Ops` ·
`Alert Rollup – Purview – Report` · `Access Review – Purview Roles – Quarterly` · `KPI Dashboard – Purview –
ProgramHealth` · `Review Calendar – Purview – Operating`.

## Operating cadences
Daily alert triage · weekly policy-drift + alert rollup · monthly Compliance Manager burn-down + KPI refresh
· quarterly role/access review + live-policy review · annual program-health review and scope reassessment.

## Outcome
Microsoft Purview run as a **living program** — policies piloted then enforced and reviewed on a cadence,
alerts triaged and tuned, improvement actions burned down, roles attested, and KPIs proving health — so the
program stays **effective, tuned, and defensible** year over year. Regulatory, records, and legal
determinations remain with the accountable governance functions; this solution supplies the technical
operating method, the runbooks, and the evidence.

## Boundaries (what this solution does not decide)
- **Retention schedules, records file plans, and legal holds** — determined by records/legal; this operates
  and evidences the technical policies.
- **Insider-risk / communication-compliance case outcomes** — HR/legal determinations; operations triages
  and routes under role separation and privacy-by-design.
- **Regulatory applicability and the compliance score's obligations** — compliance/legal own the
  determination; the cadence tracks and evidences the technical actions.
- **Capability availability** — Purview is heavily licensing-gated and evolving; verify each feature and
  portal path for your own tenant.
