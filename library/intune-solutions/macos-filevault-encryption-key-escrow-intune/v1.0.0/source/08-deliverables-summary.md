# 8. Deliverables Summary — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | FileVault + SecureToken on Apple Silicon/T2, personal vs institutional keys, Intune escrow, recovery model |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered, click-by-click Intune steps |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation (SecureToken / FileVault) |
| 7. Best Practices | Field-proven recommendations (key rotation, recovery) |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MACFV-Discovery.ps1` | Tenant/device readiness: APNs certificate, enrolled Macs, macOS-version spread, existing FileVault/disk-encryption policies (Graph, read-only) |
| `MACFV-Validation.ps1` | Per-device check: Intune sees the Mac as encrypted and a personal recovery key is escrowed (Graph, read-only) |
| `MACFV-Report.ps1` | Fleet encryption + escrow coverage, and retrieval of a device's escrowed personal recovery key (Graph, read-only) |
| `MACFV-Remediation.ps1` | Safe remediation of unencrypted/unescrowed Macs — re-applies the FileVault policy via device sync (defaults to -WhatIf) |
| `MACFV-Set-ScopeTargeting.ps1` | Builds/adjusts pilot or production group membership for staged rollout (defaults to -WhatIf) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every Mac encrypted with FileVault and every **personal recovery key escrowed and rotatable** in
Intune — device-loss protection with no lock-out you can't recover, proven on a pilot before you scale.
