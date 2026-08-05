# Application Estate Monitoring, Reporting & Supportability (Microsoft Graph & Power BI) — v1.0.0

| | |
|---|---|
| Category | Intune Solutions |
| Solution code | APPRPT |
| Commercial | $2,495.00 (`PTK-APPRPT-COMM-001`) |
| Non-Profit | $1,497.00 (`PTK-APPRPT-NPO-001`) |
| Government | $2,120.75 (`PTK-APPRPT-GOV-001`) |
| Branding | off (white-label) |
| Pricing tier | T3 — Intune + Graph + Power BI, 3 technologies |
| Government variant | inline (no `source-gov\`) — all scripts + steps target Commercial/USGov/USGovDoD via `-Environment` |

The monitoring, reporting, and supportability layer over an Intune-managed application estate: a fixed
KPI set with healthy ranges, an app-delivery SLO and error budget, a scheduled Microsoft Graph →
storage → Power BI pipeline, a three-view dashboard (executive / operations / per-app drill-down),
Azure Monitor alerting, and an ownership + triage supportability model. Read-only by design; the one
change-making script is `-WhatIf` capable.

**Scope boundary:** this is application *deployment health & supportability* reporting — NOT license/
cost reporting (separate SAM discipline) and NOT per-install troubleshooting (separate INTAPPDX
product).

## What's included

- **Documentation** (Word + PDF): overview, requirements (11), implementation (13 steps), testing (10
  gates), troubleshooting (10 modes), best practices, executive summary, category global requirements.
- **5 PowerShell scripts** (Microsoft Graph SDK; four read-only, one `-WhatIf` bootstrap):
  `APPRPT-Export-AppInstallStatus.ps1`, `APPRPT-Report-TopFailures.ps1`,
  `APPRPT-Report-VersionDrift.ps1`, `APPRPT-Generate-KPISnapshot.ps1`,
  `APPRPT-Bootstrap-ScheduledExport.ps1`.
- **Hero image** + listing (bagisto-products.json, sales-content.md).

## Deliverable files (deliverables/)

- `APPRPT-Solution.pdf` · `APPRPT-Solution.docx` · `APPRPT-Scripts.zip`
- `APPRPT-Complete-Solution.zip` · `APPRPT-hero.png` / `.svg`
