# 8. Deliverables Summary — iOS Lock-Down Profile for Shared & Corporate iPhones

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The shared-vs-corporate model, what an iOS lock-down profile is, the two provisioning models, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps — APNs/ADE, both enrollment profiles, lock-down + baseline, compliance, access, pilot/expand |
| 4. Use & Login Guide | End-user guide: using/handing back a shared phone, and provisioning/signing in to a corporate phone |
| 5. Testing Guide | Validation procedures with pass/fail gates for both models |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IOSLD-Discovery.ps1` | Tenant/device readiness: APNs, ADE token, both enrollment profiles, supervised state, lock-down + baseline profiles, groups, compliance (read-only) |
| `IOSLD-Validation.ps1` | Per-device: confirms the enrollment model is correct (shared = no user / corporate = user), supervised, and the right profile applied (read-only) |
| `IOSLD-Report.ps1` | Fleet shared-vs-corporate posture report with supervision/compliance and model-mismatch flags (read-only, CSV) |
| `IOSLD-Remediation.ps1` | Safe drift fixes / re-assignment; defaults to `-WhatIf` |
| `IOSLD-Set-DeviceGroupTargeting.ps1` | Builds the shared and corporate device groups as dynamic groups keyed on ADE enrollment profile name (supports `-WhatIf`) |

## What the buyer receives
- These guides as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the Phoenixtekk model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Shared iPhones locked down to exactly what the job needs, corporate iPhones kept light and user-owned,
both provisioned through Apple Business Manager + ADE, and staff who know how to provision, sign in to,
and use each — managed at fleet scale in Intune and proven on a pilot before you scale.
