# 8. Deliverables Summary — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, sovereign context, and what's in the box |
| 1. Solution Overview | What Windows 365 Enterprise (Government) is, plus **"Commercial vs GCC High — what's different"** |
| GCC High Parity Notes | Full Commercial→`.us` portal/endpoint map and every cited Windows 365 / Intune parity gap |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, `.us` portals, and the named objects |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps on the government portals (groups, ANC, image, provisioning policy, Intune management + hardening, Conditional Access, pilot, expand) with GCC-High caveats inline |
| 5. Testing Guide | Validation procedures with pass/fail gates, including a GCC-High parity-gap check |
| 6. Troubleshooting Guide | Field issues and remediation, including sovereign-endpoint and parity-gap gotchas |
| 7. Best Practices | Field-proven recommendations for a GCC High deployment |

## PowerShell scripts (Microsoft Graph US Gov — `-Environment USGov`)
| Script | What it does |
|---|---|
| `W365G-Discovery.ps1` | Tenant readiness: Windows 365 Government / Intune / Entra ID P1 license counts, Azure Network Connections, custom images, and provisioning policies (read-only, Graph US Gov) |
| `W365G-Validation.ps1` | Confirms Cloud PCs are provisioned and healthy and that licensing prerequisites are met; flags GCC-High parity considerations (read-only, Graph US Gov) |
| `W365G-Report.ps1` | Fleet inventory (user, status, size/SKU, policy) plus Windows 365 Government license utilization (read-only, Graph US Gov) |
| `W365G-Remediation.ps1` | Safe reprovision / resize / restart helpers for unhealthy Cloud PCs — defaults to -WhatIf (Graph US Gov) |
| `W365G-Set-ScopeTargeting.ps1` | Creates/populates the `W365G – Users – Pilot` / `W365G – Users – Production` targeting groups — defaults to -WhatIf (Graph US Gov) |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** (US Gov Graph endpoints) in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every eligible user with a dedicated, always-on Windows Cloud PC in the US sovereign cloud —
provisioned by policy, secured by Conditional Access, managed in the government Intune instance
alongside physical devices, reached via `windows365.microsoft.us`, with the Commercial pitfalls and
GCC High parity gaps handled, and proven on a pilot before scale.
