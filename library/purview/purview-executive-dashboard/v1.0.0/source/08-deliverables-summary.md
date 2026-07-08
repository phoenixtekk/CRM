# 8. Deliverables Summary — Microsoft Purview Executive Dashboard

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the executive dashboard is, the compliance-posture / data-risk / trend signal stack it summarizes, what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | Dashboard-specific prerequisites (source licensing, least-privilege read roles incl. Insider-Risk separation, S&C PowerShell + Graph toolchain, metric set & thresholds, in-scope set, portal-read values, render/distribution target, pilot & cadence) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess sources, design the metric set/thresholds, configure the definition & schedule, pilot the one-pager, reconcile every number to source, validate, publish, and accrue trend — pilot-first with pass/fail gates and rollback. |
| **5. Testing & Validation** | Ten gates from "sources reachable" to "scheduled refresh & distribution," each with method / pass / fail action. |
| **6. Troubleshooting** | The failure modes that make a dashboard wrong or empty — unreachable/portal-only sources, stale values, wrong denominators, licensing gaps, trend overwrite, Insider-Risk leakage — and their fixes. |
| **7. Best Practices** | Operating principles: report the truth, protect the trend history, least-privilege & Insider-Risk separation, thresholds as governance, licensing/preview reality, validate before distribution, keep it a one-pager. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; the only writes are the metric definition file and the
scheduled task, which require `-Commit`. No credentials or secrets are embedded. Signal collection uses
**Security & Compliance PowerShell** (`Connect-IPPSSession`) and **Microsoft Graph**; the dashboard is
a **reporting layer** and changes no Purview policy.

| Script | Role | Default |
|---|---|---|
| `OPSEXEC-Discovery.ps1` | Assess: which KPI sources are reachable-by-API vs portal-only vs not-licensed (labels, DLP, retention, Content/Activity Explorer, Compliance Manager, Insider Risk, DSPM via Graph `subscribedSkus`). | Read-only |
| `OPSEXEC-Configure.ps1` | Configure: write/update the metric definition (`Exec Metrics – Compliance Signals – Definition`) and register/remove the scheduled collection (`Exec Collector – Purview Signals – Scheduled`). | `-WhatIf` (writes on `-Commit`) |
| `OPSEXEC-Report.ps1` | Report: collect the signals, merge portal-only values, render the one-page dashboard (HTML + CSV, Power BI-ready), and append the monthly snapshot to the trend store. | Read-only (output files only) |
| `OPSEXEC-Validate.ps1` | Validate: confirm every defined KPI is present, cross-check recomputable counts, and flag stale/missing values against the refresh window. | Read-only |
| `OPSEXEC-Scope.ps1` | Scope/health helper: connection/permission/licensing health across sources; list in-scope labels, DLP policies, retention policies, and workloads (coverage denominators). | Read-only |

## Named artifacts created
- One-pager: `Exec Dashboard – Posture-Risk-Trend – OnePage` (pilot: `Exec Dashboard – Pilot – Stage1`).
- Definition: `Exec Metrics – Compliance Signals – Definition`.
- Scheduled collection: `Exec Collector – Purview Signals – Scheduled`.
- Trend store: `Exec Trend – Monthly Snapshot – Baseline`. Distribution: `Exec Dashboard – C-Suite – Distribution`.

## Definition of done
- Every KPI source classified (reachable / portal-read / not-licensed) and the **metric definition** approved with thresholds, in-scope set, and portal-value owners.
- The **pilot one-pager** rendered with all three sections and **every number reconciled** to its Purview source (or honestly labeled *"verify licensing/tenant"*).
- **Validation green** — no missing/stale KPIs; Insider Risk **aggregate/de-identified** with role separation confirmed.
- The **C-suite one-pager** published and delivered via the distribution channel; the **scheduled collection live** and **trend accruing** across at least two snapshots.

> **Boundary:** this solution delivers an **accurate reporting layer**. Whether the posture it reports is
> **adequate** — a good-enough compliance score, sufficient coverage, an acceptable risk level — and any
> **regulatory/records/legal determination** are **deferred to your compliance, records, privacy, and
> legal functions.** Source availability is **licensing-/tenant-dependent and evolving — verify against
> your entitlements and current Microsoft documentation.**
