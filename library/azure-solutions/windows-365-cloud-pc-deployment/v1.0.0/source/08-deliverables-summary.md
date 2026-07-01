# 8. Deliverables Summary — Windows 365 Cloud PC Deployment & Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Windows 365 Enterprise is — provisioning policies, network models, images, Intune management, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing and the named objects |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (groups, ANC, image, provisioning policy, Intune management, Conditional Access, pilot, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `W365-Discovery.ps1` | Tenant readiness: Windows 365 / Intune / Entra ID P1 license counts, Azure Network Connections, custom images, and provisioning policies (read-only, Graph) |
| `W365-Validation.ps1` | Confirms Cloud PCs are provisioned and healthy and that licensing prerequisites are met (read-only, Graph) |
| `W365-Report.ps1` | Fleet inventory (user, status, size/SKU, policy) plus Windows 365 license utilization (read-only, Graph) |
| `W365-Remediation.ps1` | Safe reprovision / resize / restart helpers for unhealthy Cloud PCs — defaults to -WhatIf |
| `W365-Set-ProvisioningTargeting.ps1` | Creates/populates the `W365 – Users – Pilot` / `W365 – Users – Production` targeting groups (Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every eligible user with a dedicated, always-on Windows Cloud PC — provisioned by policy, secured by
Conditional Access, managed in Intune alongside physical devices, and proven on a pilot before scale.
