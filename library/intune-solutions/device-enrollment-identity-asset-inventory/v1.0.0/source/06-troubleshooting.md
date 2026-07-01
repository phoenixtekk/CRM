# 6. Troubleshooting Guide — Device Enrollment, Identity Association & Asset Inventory

Use `ENROLLID-Validation.ps1` / `ENROLLID-Discovery.ps1` for device/tenant posture,
`ENROLLID-Report.ps1` for inventory reconciliation, and `ENROLLID-Remediation.ps1` for safe fixes.

## A. Device won't enroll
| Symptom | Cause | Remediation |
|---|---|---|
| Enrollment fails for a user | Automatic enrollment scope excludes them | Intune → **Devices → Enrollment → Automatic Enrollment**; add the user to MDM scope |
| "This platform is blocked" | Enrollment restriction blocks the platform/ownership | Review `Enrollment Restriction – Supported Platforms – Production`; allow the needed type |
| "You've reached the device limit" | Device-limit restriction hit | Raise `Enrollment Restriction – Device Limit – Production` or retire the user's stale devices |
| No Intune license | Enrolling user unlicensed | Assign Intune license (Requirement 2.1), retry |

## B. Wrong or missing primary user
| Symptom | Cause | Remediation |
|---|---|---|
| Service desk can't find a user's device | Primary user wrong or blank | Device → **Properties → Primary user**; set the daily user, or run `ENROLLID-Remediation.ps1` |
| Device enrolled by a technician | Primary user = the tech, not the owner | Correct primary user to the assigned user |
| Shared device tied to one person | Primary user set on a shared device | Remove primary user (set **None**); ensure it's in `Enrollment – Shared Devices – Production` |

## C. Autopilot / enrollment status page issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device doesn't get the Autopilot profile | Hardware not registered to the tenant | **Devices → Enrollment → Windows → Devices**; register/import the hardware hash |
| Desktop usable before setup finishes | ESP not blocking, or unassigned | Confirm `Enrollment Status Page – Corporate Windows – Production` blocks use and is assigned |
| ESP times out | App/profile install too slow or stuck | Raise the ESP timeout; check the blocking app's install status |

## D. Inventory reconciliation gaps
| Symptom | Cause | Remediation |
|---|---|---|
| Stale devices in the count | Retired hardware never removed | Retire the records in Intune; re-run `ENROLLID-Report.ps1` |
| Duplicate records (same serial) | Device re-enrolled without cleanup | Remove the obsolete duplicate; keep the current record |
| Expected device missing | Never enrolled | Enroll it (Autopilot / Entra join); confirm it appears, then reconcile |

## E. Diagnostics quick reference
```powershell
dsregcmd /status        # Entra join + MDM enrollment state on the device
ENROLLID-Discovery.ps1  # tenant enrollment posture + primary-user coverage (read-only)
ENROLLID-Validation.ps1 # this device: enrolled? primary user correct? (read-only)
ENROLLID-Report.ps1     # reconcile Intune inventory against a "should exist" CSV
```
On the device, enrollment state also shows under **Settings → Accounts → Access work or school**.

## F. When to escalate
If a device is Entra-joined and synced, the user is licensed and in the automatic-enrollment scope,
no enrollment restriction blocks the platform, and it still won't enroll, collect `dsregcmd /status`
and the enrollment event log (`Applications and Services Logs → Microsoft → Windows → DeviceManagement-Enterprise-Diagnostics-Provider`)
and open a Microsoft support case.
