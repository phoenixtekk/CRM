# 8. Deliverables Summary — Software License Usage Reporting & Cost Dashboards (Power BI)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The license/spend reporting model, data sources, the KPI set, and the refresh cycle |
| 2. Requirements Guide | Every prerequisite with Verify and Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps in Power BI Desktop, the service, and Excel |
| 5. Testing Guide | Validation procedures with pass/fail gates, including the reconciliation gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `LICRPT-Discovery.ps1` | Reports available license (subscribed SKU) and usage report sources via Microsoft Graph; confirms reporting readiness (read-only) |
| `LICRPT-Validation.ps1` | Reconciles entitlement and usage counts against the source and reports variance vs. tolerance (read-only) |
| `LICRPT-Report.ps1` | Produces the license KPI set (deployment, usage, expirations, cost-per-seat, savings) independently of Power BI (read-only) |
| `LICRPT-Export-Scheduled.ps1` | Exports the license/usage extract that feeds the Power BI dataset; single dry run by default |
| `LICRPT-Set-ScopeTargeting.ps1` | Builds/updates the reporting-scope and audience groups for distribution |

## Named artifacts (reuse verbatim)
- KPI set: `License KPI Set – Software Assets – v1`
- Dataset: `License Usage & Cost – Software Assets – Dataset`
- Report: `License Usage & Cost – Software Assets – Report`
- Workspace: `License Reporting – Software Assets – Workspace`
- Dashboard pages: `Deployment & Usage – Page`, `Expirations Timeline – Page`, `Reharvesting Opportunities – Page`, `Cost Efficiency – Page`
- Refresh schedule: `License Refresh – Software Assets – Daily`
- Audience group: `License Reporting – Leadership & Procurement – Audience`

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess to Configure to Pilot to Validate to Expand, with a reconciliation gate before broad distribution.

## Outcome
License usage and spend made visible — deployment, expirations, reharvesting, and cost-efficiency
dashboards refreshed on a schedule and proven on a pilot scope before you scale.
