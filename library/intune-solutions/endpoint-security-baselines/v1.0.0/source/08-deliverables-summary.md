# 8. Deliverables Summary — Endpoint Security Baselines

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What baselines are, available baselines, how they apply, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps including conflict resolution and version updates |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Conflicts and field issues |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ESB-Discovery.ps1` | Snapshot of the device's current security posture (sample of baseline-relevant settings) |
| `ESB-Validation.ps1` | Confirms representative baseline settings are applied at hardened values |
| `ESB-TenantReport.ps1` | Tenant-wide baseline assignment + per-setting state (Microsoft Graph) |
| `ESB-ConflictCheck.ps1` | Lists security/config policies that may conflict with the baseline (Microsoft Graph) |
| `ESB-Remediation.ps1` | Forces an MDM sync so the baseline re-applies |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the Phoenixtekk model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
An expert, consistent, Microsoft-recommended hardening posture across the fleet — without manual setting-by-setting work.
