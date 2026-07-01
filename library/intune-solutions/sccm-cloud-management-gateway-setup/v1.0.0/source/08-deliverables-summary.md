# 8. Deliverables Summary — Configuration Manager Cloud Management Gateway (CMG)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What a CMG is, the CMG + connection point design, token vs. PKI auth, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: Azure onboarding, CMG service, connection point, MP/SUP, client settings |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CMG-Discovery.ps1` | Reports environment readiness: site version, Azure/Cloud Management onboarding, CMG roles, Enhanced HTTP (read-only) |
| `CMG-Validation.ps1` | Tests CMG public endpoint, certificate, and a client's ability to reach/authenticate to the CMG (read-only) |
| `CMG-Report.ps1` | Internet-client health and reach report: last policy/inventory time and CMG health (read-only) |
| `CMG-Remediation.ps1` | Safe remediation of misconfigured clients (policy/USO triggers, cloud settings); defaults to -WhatIf |
| `CMG-Set-CloudManagementTargeting.ps1` | Cloud-management settings helper: scopes the cloud-management client settings to a collection; defaults to -WhatIf |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess → Configure → Pilot → Validate → Expand.

## Outcome
Internet-based Windows clients fully manageable from Configuration Manager — receiving policy,
software updates, and inventory over a secure Azure front door — proven on a pilot before you scale.
