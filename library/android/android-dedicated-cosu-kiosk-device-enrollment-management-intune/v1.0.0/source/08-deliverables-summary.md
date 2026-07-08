# 8. Deliverables Summary — Android Dedicated (COSU) / Kiosk Device Enrollment & Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The dedicated/COSU model, enrollment methods (QR/token/NFC/zero-touch), single- vs multi-app kiosk, app delivery to user-less devices, OEM at pattern level |
| 2. Requirements Guide | Every dedicated/COSU prerequisite with Verify / Implement-if-missing (category Android GRs referenced, not duplicated) |
| Global Requirements (Android) | Category-wide Android prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune + Graph steps: enrollment profile, dynamic device group, app assignment, kiosk (single/multi), enroll, validate; pilot-first with pass/fail + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Enrollment, kiosk, app-delivery, and remote-management issues by symptom → root cause |
| 7. Best Practices | Field-proven recommendations for a scalable dedicated fleet |

## PowerShell scripts (Microsoft Graph)
| Script | What it does | Safety |
|---|---|---|
| `COSU-Discovery.ps1` | Dedicated-device readiness: managed Google Play binding, enrollment profile(s) + token expiry + enrolled count, managed store apps, blocking enrollment restrictions | Read-only |
| `COSU-Set-Configuration.ps1` | Creates the dedicated enrollment profile and the kiosk / device-restrictions profile (single- or multi-app) | Default `-WhatIf`; `-Apply` to write |
| `COSU-Validation.ps1` | Kiosk / restriction validation: the kiosk **allow-list vs the apps assigned** to the device group — the "only allowed apps" report, mismatches listed | Read-only |
| `COSU-Report.ps1` | Enrolled-fleet health/inventory: dedicated device count, compliance, last check-in, OS version, OEM (manufacturer/model) breakdown | Read-only |
| `COSU-Set-ScopeTargeting.ps1` | Scope/config helper: builds the dynamic device group keyed on the enrollment profile name (and reports kiosk/app assignment targeting) | Default `-WhatIf`; `-Apply` to write |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
A fleet of purpose-built Android **dedicated (COSU)** devices that boot straight to the job — enrolled
at scale by token / QR / NFC / zero-touch, locked to their app(s) via single- or multi-app kiosk, fed
managed Google Play apps to the device, and remotely managed — consistent, tamper-resistant, and proven
on a pilot before you scale.
