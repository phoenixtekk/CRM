# 6. Troubleshooting Guide — Workspace ONE to Intune (Windows Device Migration)

Use `WS1WIN-Discovery.ps1` / `WS1WIN-Validation.ps1` for device state, `WS1WIN-Report.ps1` for fleet
status, and `WS1WIN-Remediation.ps1` (defaults to `-WhatIf`) for safe fixes to dual/failed enrollment.
Workspace ONE-side actions (unenroll/retire) are deferred to the official VMware Workspace ONE
documentation.

## A. Dual management (managed by both)
| Symptom | Cause | Remediation |
|---|---|---|
| Device shows both a Workspace ONE and an Intune enrollment | Enrolled in Intune before Workspace ONE was fully removed | Unenroll from Workspace ONE per VMware docs, then run `WS1WIN-Remediation.ps1` to clear the stale enrollment and resync; confirm with `WS1WIN-Discovery.ps1` |
| Conflicting/flapping policy on the device | Two MDM authorities | Resolve to single MDM (Intune) as above; re-validate parity with `WS1WIN-Validation.ps1` |

## B. Device left unmanaged
| Symptom | Cause | Remediation |
|---|---|---|
| Removed from Workspace ONE but never appears in Intune | Automatic enrollment off, or device not Entra-joined | Confirm `Devices > Windows > Windows enrollment > Automatic enrollment` MDM user scope; ensure Entra join; trigger enroll/sync; run `WS1WIN-Remediation.ps1` |
| Device enrolled but no policy | Not a member of a migration group | Add to `Group – Migration Pilot – Windows` / `Group – Migration Broad – Windows` (use `WS1WIN-Set-MigrationRingTargeting.ps1`); sync |

## C. Parity not applied
| Symptom | Cause | Remediation |
|---|---|---|
| Migrated device missing settings it had under Workspace ONE | `Parity Configuration – Windows – Migration` not assigned to the device's group, or a setting was not recreated | Confirm assignment to both migration groups; check the parity target covers the setting; sync and re-run `WS1WIN-Validation.ps1` |
| Profile shows `Error`/`Conflict` in Intune | Conflicting profile or unsupported setting | Open `Configuration > Parity Configuration – Windows – Migration > Device status`; resolve the conflicting policy; re-sync |

## D. Compliance stuck
| Symptom | Cause | Remediation |
|---|---|---|
| Device `Not evaluated` | Compliance policy not assigned, or device just enrolled | Confirm `Compliance Policy – Windows – Migration` assignment; allow a policy cycle; sync; re-check `WS1WIN-Report.ps1` |
| Device `Not compliant` | A compliance rule is failing (e.g. BitLocker, firewall) | Identify the failing rule in `Compliance > … > Device status`; remediate the setting via the parity profile; re-evaluate |

## E. Access broken after cutover
- Confirm the user/device is in scope of `Conditional Access Continuity – Windows – Migration` and the
  device is `Compliant` — a non-compliant device will be blocked by the `require compliant device`
  grant. Check the Entra sign-in log for the policy result.
- If you switched the policy to `On` before the device was compliant, return it to `Report-only`,
  bring the device compliant, then re-enable.

## F. Enrollment fails on a specific device
- Run `WS1WIN-Discovery.ps1` — confirm the source MDM is gone, the OS build is supported, and Entra
  join succeeded. A leftover Workspace ONE enrollment is the most common blocker; remove it per VMware
  docs first.

## G. Diagnostics quick reference
```powershell
dsregcmd /status                # Entra join + MDM enrollment state
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -Recurse -EA SilentlyContinue   # enrollment(s)
Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -EA SilentlyContinue  # MDM sync tasks
```

## H. When to escalate
- For Workspace ONE unenroll/retire behavior that will not complete, escalate to VMware Workspace ONE
  support per their documentation — those internals are outside this solution's scope.
- For Intune enrollment that still fails after the source MDM is confirmed gone, the build is
  supported, Entra join succeeded, and a sync has run, collect `dsregcmd /status` output and open a
  Microsoft support case.
