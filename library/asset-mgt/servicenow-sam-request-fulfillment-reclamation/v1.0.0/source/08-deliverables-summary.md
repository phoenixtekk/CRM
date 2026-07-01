# 8. Deliverables Summary — ServiceNow SAM Request Fulfillment & License Reclamation Workflow

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The request lifecycle (intake to reclamation), catalog items, workflows, entitlement matching, KPIs, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: groups, catalog items, triage/entitlement/fulfillment/reclamation flows, KPI set |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell / integration scripts
| Script | What it does |
|---|---|
| `SNOWSAM-Discovery.ps1` | Reads request, entitlement, and usage records via the ServiceNow Table API (read-only) |
| `SNOWSAM-Validation.ps1` | Confirms catalog items, flows, software models, and entitlement records are present and consistent (read-only) |
| `SNOWSAM-Report.ps1` | Builds the request and reclamation KPI report; CSV export (read-only) |
| `SNOWSAM-Remediation.ps1` | Safe remediation of stale entitlements/assignments; default `-WhatIf` (preview only) |
| `SNOWSAM-Set-ScopeTargeting.ps1` | Records/expands which products and groups are in scope for the workflow |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell / integration scripts in a single ZIP.
- A repeatable process following the model: Assess to Configure to Pilot to Validate to Expand.

## Outcome
Software requests and reclamation run as a clean, auditable ServiceNow workflow — intake to fulfillment
to reclamation — measured by a single KPI set and validated on a pilot before fleet-wide rollout.
