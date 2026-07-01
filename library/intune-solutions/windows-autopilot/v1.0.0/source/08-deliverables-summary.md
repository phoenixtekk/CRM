# 8. Deliverables Summary — Windows Autopilot

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Autopilot is, how it works, modes, benefits, limitations, the deployment model |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered, click-by-click Intune steps |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `Get-AutopilotHash.ps1` | Collects the device hardware hash CSV for Autopilot registration |
| `Autopilot-Discovery.ps1` | Device readiness: OS, TPM, network, Entra state |
| `Autopilot-Validation.ps1` | Confirms Autopilot registration, Entra join, and Intune enrollment |
| `Autopilot-TenantReport.ps1` | Tenant-wide Autopilot device + profile status (Microsoft Graph) |
| `Autopilot-Remediation.ps1` | Safe remediation; re-sync and re-trigger enrollment |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the Phoenixtekk model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Zero-touch device provisioning — consistent builds, faster onboarding, and no technician imaging.
