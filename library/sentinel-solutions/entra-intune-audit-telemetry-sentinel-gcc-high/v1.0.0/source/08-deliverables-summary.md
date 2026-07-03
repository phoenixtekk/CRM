# 8. Deliverables Summary — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

## Documentation

| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box (GCC High edition) |
| 1. Solution Overview | The telemetry pipeline (Entra ID/Intune logs -> Log Analytics -> Sentinel) in Azure Government, plus a **Commercial vs GCC High — what's different** section, log categories, retention, baseline analytics, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, using the `.us` sovereign portals |
| Global Requirements (Sentinel Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal steps in the Gov portals (diagnostic settings, connector, Intune routing, retention, analytics, RBAC) with GCC-High caveats inline |
| gcc-high-parity-notes.md | Cited Commercial-vs-GCC-High feature parity reference for this pipeline |
| 5. Testing Guide | Validation procedures with pass/fail gates (including a sovereign-cloud check) |
| 6. Troubleshooting Guide | Field issues and remediation, including GCC-High-specific gotchas |
| 7. Best Practices | Field-proven recommendations for the sovereign cloud |

## PowerShell scripts (all target US Gov endpoints)

| Script | What it does |
|---|---|
| `SENTLOGG-Discovery.ps1` | Reports telemetry readiness — workspace, Sentinel, existing Entra ID diagnostic settings, and Intune presence (read-only; `-Environment AzureUSGovernment`) |
| `SENTLOGG-Validation.ps1` | Confirms ingestion: the Entra ID connector is connected and the pilot tables (incl. `IntuneAuditLogs`) are receiving data (read-only) |
| `SENTLOGG-Report.ps1` | Log-coverage and retention report across the workspace tables, with ingestion volume (read-only) |
| `SENTLOGG-Remediation.ps1` | Safe remediation (default `-WhatIf`); adds a missing Entra ID diagnostic setting routing logs to the Azure Government workspace |
| `SENTLOGG-Set-ScopeTargeting.ps1` | Workspace/RBAC scoping helper — reports and applies scoped Sentinel roles (default `-WhatIf`) |

## What the buyer receives

- This implementation guide as a Word document and PDF (Government / GCC High edition).
- All five PowerShell scripts in a single ZIP — each connecting to US Gov Graph / Azure US Gov endpoints.
- A repeatable process following the standard model: `Assess -> Configure -> Pilot -> Validate -> Expand`.
- A cited GCC High parity reference so no Commercial-only feature is promised on a Gov tenant.

## Outcome

Identity and device audit telemetry centralized in Microsoft Sentinel **inside Azure Government** — routed, retained, and alert-ready, with the sovereign portals/endpoints and Commercial-vs-GCC-High parity gaps handled — validated on a pilot before fleet-wide expansion.
