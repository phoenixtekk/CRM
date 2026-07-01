# 6. Troubleshooting Guide — Workspace ONE to Intune: Android Enterprise Device Migration

Use `WS1DROID-Discovery.ps1` and `WS1DROID-Validation.ps1` for connection and per-device state,
`WS1DROID-Report.ps1` for migration/parity status, and `WS1DROID-Remediation.ps1` (defaults to
`-WhatIf`) for safe fixes.

## A. No apps deploy to migrated devices
| Symptom | Cause | Remediation |
|---|---|---|
| Device enrolls but no work apps install | Managed Google Play not connected, or binding broken | Run `WS1DROID-Discovery.ps1`; reconnect at Devices > Android > Enrollment > Connectors and tokens > Managed Google Play |
| Some apps missing | App not approved / not assigned, or wrong package id | Run `WS1DROID-Report.ps1` for the parity gap; approve and assign the correct managed Google Play app by exact package id |
| Internal app unavailable | Not published as a managed Google Play private app | Publish it as a private app, then add/assign it |

## B. Device landed in the wrong management mode
| Symptom | Cause | Remediation |
|---|---|---|
| Corporate device shows as work profile (or vice versa) | Enrolled with the wrong method; mode is fixed at enrollment | Factory reset and re-enroll using the correct profile's token / QR (`Android Enrollment Profile – Fully Managed – Migration` or `– Dedicated – Migration`); confirm with `WS1DROID-Validation.ps1` |
| Wanted fully managed, got nothing on reset | Corporate fully-managed enrollment not allowed in Intune | Devices > Android > Enrollment > Corporate-owned, fully managed user devices > set to Yes; re-run enrollment |

## C. Enrollment fails or hangs
| Symptom | Cause | Remediation |
|---|---|---|
| Token / QR rejected | Expired or wrong-mode token | Regenerate the enrollment token for the correct dedicated/fully-managed profile |
| Still managed by old authority | Device not un-enrolled from Workspace ONE | Complete the source un-enrollment / enterprise wipe (VMware docs) before enrolling into Intune |
| Enrollment loops | Account / Google Play services issue on device | Run `WS1DROID-Remediation.ps1` (preview with `-WhatIf`); for corporate modes, factory reset and re-enroll |

## D. Configuration / connectivity broken after migration
- A device with no Wi-Fi/email/VPN after re-enrollment is missing
  `Config Parity – Android Estate – Migration` — confirm the profiles target the device's ring group
  and the correct Android Enterprise profile type for its mode; check certificate (SCEP/PKCS)
  delivery first, since Wi-Fi and VPN often depend on it.

## E. Compliance or access problems
- Device blocked from resources after migration: confirm it is compliant under
  `Compliance Baseline – Android Estate – Migration` and that Conditional Access now targets the
  migration ring groups, not the old Workspace ONE groups.

## F. Rollback (pilot or wave fails)
- Re-enroll the affected devices back into Workspace ONE (source action — VMware docs) and revert
  their migration-group membership so the parity/compliance artifacts no longer target them. Do not
  expand to the next ring until the gate in Section 5 passes.

## G. When to escalate
If managed Google Play is connected, the device un-enrolled cleanly from the source, the correct
enrollment profile/token was used, and the device still will not enroll or stay in the right mode
after a factory reset, capture the device enrollment details and open a Microsoft support case;
for source-side un-enrollment issues, engage VMware support.
