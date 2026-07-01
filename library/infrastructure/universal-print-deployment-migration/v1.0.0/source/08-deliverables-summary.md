# 8. Deliverables Summary — Universal Print Deployment & Print-Server Retirement

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Universal Print is, the connector model, Entra ID sharing, Intune deployment, why retire the server |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, plus the naming convention |
| Global Requirements (Infrastructure) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (license, connector, share, deploy, validate, retire) |
| 5. Testing Guide | Validation procedures with pass/fail and retirement gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `UPRT-Discovery.ps1` | Discovers print servers/queues/drivers via the PrintManagement module (read-only) |
| `UPRT-Validation.ps1` | Universal Print readiness checks + a test print (read-only) |
| `UPRT-Report.ps1` | Printer + deployment inventory across queues and Universal Print (read-only) |
| `UPRT-Remediation.ps1` | Safely fixes failed printer deployments — default `-WhatIf` |
| `UPRT-Set-PrinterDeploymentTargeting.ps1` | Builds the printer-deployment groups and stages membership |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess → Configure → Pilot → Validate → Expand, with a pilot gate before server retirement.

## Outcome
Cloud-delivered printing for every user — printers shared from Entra ID and deployed through Intune,
reachable on or off network — with the old print servers decommissioned, proven on a pilot before scale.
