# Deliverables Summary

This solution is a self-contained package for building the monitoring, reporting, and supportability
layer over your Intune-managed application estate. Everything below is delivered as downloadable files
you keep and reuse across unlimited devices and rollouts.

## Documentation (Word + PDF)

| Section | What it gives you |
|---|---|
| **Solution Overview** | The measurement model (delivery / velocity / currency / value + data quality), the `App Estate KPI Set – v1` with healthy ranges, the app-delivery SLO and error budget, the five data sources, the pipeline diagram, and the supportability model. |
| **Requirements** | 11 requirements, each with Description / Why / Verify / Implement-if-missing — Intune roles, the export app registration, exact Graph scopes (delegated and application), Power BI Pro licensing, storage, Log Analytics + diagnostic settings, PowerShell, and the Government-cloud endpoint table. |
| **Implementation** | The exact ordered build: cloud selection, KPI/SLO sign-off, pilot scope group, storage, the least-privilege export identity, first manual export, the console trust gate, the Power BI dataset + three-view report, publish + scheduled refresh, the nightly export task, Azure Monitor alerting, the supportability model, and estate-wide expansion. Every object named. |
| **Testing & Validation** | 10 pass/fail gates from "extractor authenticates" through "supportability loop closes," plus the pilot→expand exit criteria. |
| **Troubleshooting** | The common failure modes of the pipeline itself — empty exports, console/export mismatch, refresh failures, unattended-auth failures, throttling, and Government-endpoint issues. |
| **Best Practices** | The alert-vs-review split, KPI ownership table, the evidence-pack definition, dashboard-honesty rules, least privilege, retention, and cost. |
| **Executive Summary** | The one-page business case for non-technical stakeholders. |

## PowerShell scripts (ZIP)

Five scripts using the Microsoft Graph PowerShell SDK. The four report/extract scripts are
**read-only**; the bootstrap script makes changes and is **-WhatIf capable**, previewing every action.
All five accept `-Environment Global | USGov | USGovDoD` to target Commercial or US Government clouds.

| Script | What it does |
|---|---|
| `APPRPT-Export-AppInstallStatus.ps1` | The backbone extractor — per-device install/detection status for every app → CSV/JSON for the Power BI dataset. Read-only. |
| `APPRPT-Report-TopFailures.ps1` | Ranks the estate's worst deployment failures by app and rate; flags anything above the 3% healthy range. The daily triage queue. Read-only. |
| `APPRPT-Report-VersionDrift.ps1` | Version histogram, drift %, and patch currency (n-1) for a named app against an approved version; lists outdated devices. Read-only. |
| `APPRPT-Generate-KPISnapshot.ps1` | Rolls the whole estate into one `App Estate KPI Set – v1` snapshot row with PASS/FAIL verdicts; append per run to build the trend. Read-only. |
| `APPRPT-Bootstrap-ScheduledExport.ps1` | One-time setup: creates the read-only export app registration, grants least-privilege application scopes, and registers the nightly export task. Makes changes; `-WhatIf` capable. |

## What you achieve

A living, trustworthy view of application delivery health — install success, failure by app and ring,
detection mismatch, time-to-deploy, version drift, adoption, and stale devices — measured the same way
every time, refreshed automatically, alerting on the two conditions that can't wait, and wrapped in an
ownership and triage model so every red number lands on a named owner's queue with the evidence
already attached. Built once for the pilot, then widened to the whole estate.
