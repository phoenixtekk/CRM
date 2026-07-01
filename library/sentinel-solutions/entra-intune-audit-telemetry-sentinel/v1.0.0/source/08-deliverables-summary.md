# 8. Deliverables Summary — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

## Documentation

| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The telemetry pipeline (Entra ID/Intune logs -> Log Analytics -> Sentinel), log categories, retention, baseline analytics, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Sentinel Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal steps (diagnostic setting, connector, Intune routing, retention, analytics, RBAC) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts

| Script | What it does |
|---|---|
| `SENTLOG-Discovery.ps1` | Reports telemetry readiness — workspace, Sentinel, existing Entra ID diagnostic settings, and Intune presence (read-only) |
| `SENTLOG-Validation.ps1` | Confirms ingestion: the Entra ID connector is connected and the pilot tables are receiving data (read-only) |
| `SENTLOG-Report.ps1` | Log-coverage and retention report across the workspace tables, with ingestion volume (read-only) |
| `SENTLOG-Remediation.ps1` | Safe remediation (default `-WhatIf`); adds a missing Entra ID diagnostic setting routing logs to the workspace |
| `SENTLOG-Set-WorkspaceScopeTargeting.ps1` | Workspace/RBAC scoping helper — reports and applies scoped Sentinel roles |

## What the buyer receives

- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the standard model: `Assess -> Configure -> Pilot -> Validate -> Expand`.

## Outcome

Identity and device audit telemetry centralized in Microsoft Sentinel — routed, retained, and alert-ready — validated on a pilot before fleet-wide expansion.
