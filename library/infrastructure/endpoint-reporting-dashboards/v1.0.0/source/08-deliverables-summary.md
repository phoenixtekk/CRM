# 8. Deliverables Summary — Endpoint Reporting & Dashboards

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The Intune/Configuration Manager data sources, the KPI set, Graph export, the reporting model, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, and the named objects |
| Global Requirements (Infrastructure) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: KPIs, built-in reports, Graph export, dashboard, distribution, validation |
| 5. Testing Guide | Reconciliation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `EPRPT-Discovery.ps1` | Reporting-readiness: confirms it can sign in and read each Intune data source (read-only) |
| `EPRPT-Validation.ps1` | Reconciles report/export counts against the live Intune source counts (read-only) |
| `EPRPT-Report.ps1` | Consolidated endpoint KPI report — patch / compliance / encryption / app / health (read-only) |
| `EPRPT-Export-Scheduled.ps1` | Microsoft Graph `exportJobs` helper; defaults to a dry single run |
| `EPRPT-Set-ReportingScopeTargeting.ps1` | Builds/populates the reporting-scope Entra groups |

## Named objects (reuse verbatim)
- App registration: `Endpoint Reporting Export – Tenant – Prod`
- Reporting-scope groups: `Endpoint Reporting Scope – Pilot – Stage`, `Endpoint Reporting Scope – Fleet – Prod`
- Report definition: `Endpoint KPI Report – Fleet – Prod`
- Distribution schedule: `Endpoint KPI Distribution – Leadership – Prod`

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand**, with a reconciliation
  gate before broad distribution.

## Outcome
Trustworthy, repeatable endpoint reporting — patch, compliance, encryption, app deployment, and
device health across Intune and Configuration Manager — with the same numbers every time, proven on a
pilot before you scale.
