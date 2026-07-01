# 8. Deliverables Summary — Software Renewals, Contracts & OEM Bundle Tracking

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The renewal lifecycle, repository model, OEM bundle mapping, lead-time alerting, procurement workflow, benefits, and limits |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps to build the repository, calendar, bundle map, alerts, and workflow |
| 5. Testing Guide | Validation procedures with a pilot pass/fail gate |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `SWRENEW-Discovery.ps1` | Seeds the repository from Microsoft Graph subscribed SKUs (where exposed) and reports an existing CSV repository's posture. Read-only. |
| `SWRENEW-Validation.ps1` | Checks every repository record for the fields the renewal lifecycle needs. Read-only. |
| `SWRENEW-Report.ps1` | Builds the renewal calendar (date-ordered, tiered due-soon) and a cost rollup. Read-only. |
| `SWRENEW-Remediation.ps1` | Safe (default `-WhatIf`) fill of missing renewal records and advance of closed renewals; backs up the CSV first. |
| `SWRENEW-Set-ScopeTargeting.ps1` | Builds the pilot and all-products renewal-owner routing groups. |

## Named artifacts produced
- `Contract & Entitlement Repository – All Products – Master`
- `Renewal Calendar – All Products – Live`
- `OEM Bundle Map – Vendor Bundles – Master`
- `Lead-Time Alert Rules – Renewals – Tiered` (T-120 / T-90 / T-60 / T-30)
- `Renewal Decision Workflow – Per Contract – Standard`
- `Renewal Owners – Pilot Scope – Group` and `Renewal Owners – All Products – Group`

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess → Configure → Pilot → Validate → Expand.

## Outcome
Every software renewal a planned decision — a live renewal calendar with tiered lead-time alerts, a
contract and entitlement repository, OEM bundles mapped to one anchor, and a procurement workflow
that routes each renewal to a named owner. No surprise auto-renewals, no lapses that break production.
