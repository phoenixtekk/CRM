# 8. Deliverables Summary — Microsoft Purview Reporting & Power BI Framework

Everything included in this solution, and what "done" looks like.

## Documents
| Document | Purpose |
|---|---|
| 01 · Solution Overview | What the reporting framework is, the sources, the naming convention, the deployment model |
| 02 · Requirements Guide | Solution-specific prerequisites (licensing, roles, toolchain, Power BI, storage, privacy) with verify/implement steps, referencing category GR1–GR6 |
| 03 · Implementation Guide | The ordered build — Assess → Design → Configure → Pilot (validate) → Validate → Expand — with named artifacts, pass/fail gates, and rollback |
| 05 · Testing & Validation | The T1–T12 gate matrix and the portal reconciliation method |
| 06 · Troubleshooting | Symptom → cause → resolution for the common pipeline, licensing, and refresh failures |
| 07 · Best Practices | Lineage, least-privilege, privacy-by-design, pilot-before-broad, freshness, licensing reality |
| Executive Summary | One-page business framing for decision-makers |

## PowerShell tools (5)
All are safe-by-default: read-only against Purview/Graph, with writes (storage, workspaces, schedule)
gated behind `-Commit` (default `-WhatIf`). No credentials or secrets are stored in code; auth is
interactive modern-auth (`Connect-IPPSSession` / `Connect-MgGraph`).

| Script | Role | Default | Purpose |
|---|---|---|---|
| `OPSREPORT-Discovery.ps1` | Discovery | Read-only | Inventory reachable reporting sources, consented scopes, and per-source licensing/role readiness |
| `OPSREPORT-Configuration.ps1` | Configuration/Remediation | `-WhatIf` | Create export storage, pilot/production Power BI workspaces, and the daily refresh schedule (writes only with `-Commit`) |
| `OPSREPORT-Report.ps1` | Reporting | Read-only export | Pull all in-scope sources into the contract-conformant export set (`Purview Data Export – AllSources – Report`) |
| `OPSREPORT-Validation.ps1` | Validation | Read-only | Reconcile each dashboard figure against its Purview/Graph source for the same window |
| `OPSREPORT-Set-ScopeHealth.ps1` | Scope/health helper | Read-only | Record the reporting scope and run the pipeline health check (freshness, row counts, connections) |

## Named artifacts this solution creates
- `Reporting Scope – Purview – Config` — the in-scope capabilities, workloads, and date window
- `Purview Compliance Dataset – Report` — the dataset column contract
- `Purview Data Export – AllSources – Report` / `Purview Exports – <yyyyMM> – Report` — the export set + storage
- `Purview Reporting – Pilot – Stage1` / `Purview Reporting – Prod – Stage2` — the Power BI workspaces
- `Purview Refresh – Daily – Recurring` — the scheduled export + dataset refresh
- `Purview Pipeline Health – Report` — the health-check log

## Definition of done
- Every intended source is **available** (or explicitly marked *not licensed — verify tenant*).
- The export set is **contract-conformant** and produced on schedule.
- Every dashboard figure **reconciles** to its portal source within a documented tolerance.
- HR-sensitive sources are **aggregate-only**, with role separation verified.
- The **pilot** was validated and signed off before production; production refreshes on cadence and the
  leadership audience can view it.
- Interpretation and any action on the numbers remain with compliance/records/privacy/legal.

## Explicitly out of scope (deferred)
- Regulatory, records-retention, and legal **determinations** (what the numbers mean or require).
- Insider-risk / communication-compliance **case content** — only aggregate counts are reported.
- Any change to Purview **policies** — this framework reports; it does not configure the underlying
  compliance controls.
