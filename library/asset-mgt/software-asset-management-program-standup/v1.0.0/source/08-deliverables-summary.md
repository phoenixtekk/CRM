# 8. Deliverables Summary — Software Asset Management (SAM) Program Standup & Governance

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What a SAM program is, the lifecycle, roles/RACI, KPIs, system of record, and ITIL v4 alignment (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps to stand up and run the program |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named program artifacts
| Artifact | Name |
|---|---|
| Entitlement register | `SAM Register - Entitlements - System of Record` |
| Request intake | `SAM Intake - Software Requests - Request Stage` |
| RACI | `SAM RACI - Program - All Stages` |
| SOP set | `SAM SOP Set - Program - All Stages` |
| KPI set | `SAM KPI Set - Program - All Stages` |
| Governance forum | `SAM Governance Cadence - Program - Reconciliation & Renewal` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `SAMPROG-Discovery.ps1` | Reports SAM-readiness signals: discovery source, tenant entitlement/usage coverage, managed devices and assigned licenses (Microsoft Graph, read-only) |
| `SAMPROG-Validation.ps1` | Confirms process/data coverage for a scope: register populated, discovery data present, intake live (read-only) |
| `SAMPROG-Report.ps1` | Renders the KPI set and a maturity snapshot, plus an Effective License Position view (Microsoft Graph, read-only) |
| `SAMPROG-Remediation.ps1` | Safe remediation of data gaps; runs with `-WhatIf` by default |
| `SAMPROG-Set-ScopeTargeting.ps1` | Builds the SAM pilot/expansion scope group (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable program following the model: Assess, then Configure, then Pilot, then Validate, then
  Expand.

## Outcome
A deliberate, governed SAM program — defined lifecycle, named owners, documented SOPs, measured KPIs,
and a single system of record — replacing spreadsheet chaos and audit panic, proven on a pilot scope
before you scale.
