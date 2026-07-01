# 6. Troubleshooting Guide — iOS Lock-Down Profile for Shared & Corporate iPhones

Use `IOSLD-Discovery.ps1` for tenant readiness, `IOSLD-Validation.ps1` for a single device,
`IOSLD-Report.ps1` for the fleet, and `IOSLD-Remediation.ps1` (`-WhatIf` first) for safe fixes.

## A. Enrollment model is wrong
| Symptom | Cause | Remediation |
|---|---|---|
| A shared phone HAS a primary user | Enrolled with the corporate (user-affinity) profile, or a user signed in | Confirm the serial is assigned to `iOS Shared – ADE – Pilot` (no affinity); re-erase and re-enroll, or run `IOSLD-Remediation.ps1 -Apply -DeviceName <name>` to clear the primary user |
| A corporate phone has NO primary user | Enrolled with the shared (no-affinity) profile | Assign the serial to `iOS Corporate – ADE – Pilot`, erase, and re-enroll so the user signs in |
| Phone in the wrong group | Dynamic rule mismatch / static membership | Check membership against the ADE enrollment profile name; fix the group or re-run `IOSLD-Set-DeviceGroupTargeting.ps1` |

## B. Lock-down / kiosk not applying (shared)
| Symptom | Cause | Remediation |
|---|---|---|
| App Store/Safari still available | Restrictions profile not assigned or device not supervised | Confirm `iOS Lock-Down – Shared – Restrictions` is assigned to `iOS – Shared Devices`; confirm **Supervised = Yes** (`IOSLD-Validation.ps1`); **Sync** |
| Kiosk not pinning the app | App not installed before kiosk, or wrong bundle ID | Ensure the role app is **Required** and installed first; re-select it by exact bundle ID in `iOS Kiosk – Shared – Pilot`; **Sync** |
| Profile shows Error | Device not checked in / not supervised | Confirm enrollment, group membership, and supervision; **Sync** |

## C. Corporate baseline issues
| Symptom | Cause | Remediation |
|---|---|---|
| Corporate phone over-restricted | Shared lock-down profile assigned to corporate group | Unassign `iOS Lock-Down – Shared – Restrictions` from corporate; confirm only `iOS Corporate – Baseline – Restrictions` applies |
| Approved apps not installing | App not assigned to `iOS – Corporate Devices`, or not licensed | Assign the app **Required** to the corporate group; confirm VPP licenses; **Sync** |

## D. Sign-in problems
| Symptom | Cause | Remediation |
|---|---|---|
| Shared app sign-in fails | Wrong account (personal used), password rotated, or licensing | Use `iOS Shared – App Sign-in`; confirm its licenses; reset/rotate and update the password store |
| Corporate sign-in loops | User used a shared account, MFA not completing, or non-compliant | Have the user sign in with their **own** Entra ID; complete MFA; make the device compliant (Section E) |

## E. Compliance / Conditional Access blocking access
- Confirm the phone is **compliant** (`IOSLD-Validation.ps1` / Intune → device). Common fixes: update
  iOS to the minimum, set a passcode (corporate), resolve jailbreak detection.
- If `CA – iOS Shared` / `CA – iOS Corporate` block legitimately, keep them **report-only** while you
  remediate, then switch to **On**.

## F. ADE / sync issues
- New serials not appearing: in **ABM → Devices** assign them to the `Intune – iOS MDM` server, then in
  Intune on the ADE token → **Devices → Sync** (Apple rate-limits; allow a few minutes).
- APNs expired: renew with the **same company Apple ID** (Implementation Step 1) — a different Apple ID
  breaks all existing enrollments.

## G. Diagnostics quick reference
- `IOSLD-Discovery.ps1` — tenant building blocks (APNs, ADE, profiles, groups, compliance).
- `IOSLD-Validation.ps1 -DeviceName <name>` — per-device model + supervision + profile.
- `IOSLD-Report.ps1` — fleet shared-vs-corporate classification and mismatches.
- In Intune: **Devices → (device) → Device configuration** shows each profile's apply state; **Sync**
  forces a check-in.

## H. When to escalate
If a phone is correctly enrolled (right model, supervised), in the right group, synced, and the profile
still won't apply, capture the device's configuration status and serial and open a Microsoft Intune
support case (and, for ADE/supervision anomalies, confirm the serial's state in Apple Business Manager).
