# 8. Deliverables Summary — New-Site Endpoint Rollout Playbook

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The rollout model, the dependency order, naming convention, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Infrastructure) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps plus the go-live checklist |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for the assign-once, repeat-everywhere model |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NEWSITE-Discovery.ps1` | Checks a site's readiness — cloud endpoint reachability, DNS, and time sync (read-only) |
| `NEWSITE-Validation.ps1` | Per-device go-live validation — enrollment, compliance, site apps, site printers (read-only) |
| `NEWSITE-Report.ps1` | Site rollout status report — provisioned / baselined / app-ready counts via Microsoft Graph (read-only) |
| `NEWSITE-Remediation.ps1` | Safe remediation of failed deployments — sync, app/baseline re-evaluation (default `-WhatIf`) |
| `NEWSITE-Set-SiteGroupTargeting.ps1` | Builds the per-site device group and adds the site's devices via Microsoft Graph |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A concrete go-live checklist and a repeatable program following the model: Assess → Configure →
  Pilot → Validate → Expand, with the first site as the pilot.

## Outcome
Every new site opening with endpoints that work on day one — provisioned, baselined, app- and
printer-ready, and validated against a go-live checklist — proven on a pilot site before you repeat
it everywhere.
