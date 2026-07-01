# 6. Troubleshooting Guide — Endpoint Imaging, Inventory & Hardware Lifecycle Management

Use `IMGLIFE-Validation.ps1` / `IMGLIFE-Discovery.ps1` for device state, `IMGLIFE-Report.ps1` for
fleet inventory and reconciliation, and `IMGLIFE-Remediation.ps1` for a safe retire/wipe (preview by
default).

## A. Autopilot provisioning problems
| Symptom | Cause | Remediation |
|---|---|---|
| Device skips Autopilot at OOBE | Hardware identity not registered, or no profile assigned | Confirm the device is in Devices → Enrollment → Windows Autopilot → Devices; assign the deployment profile to a group the device is in; run `IMGLIFE-Validation.ps1` |
| Profile assigned but not applied | Profile not yet synced to the device record | Wait for assignment to show Assigned; reset the device and retry OOBE |
| Wrong join type / OOBE options | Profile settings differ from intent | Edit the Autopilot deployment profile (join type, OOBE) and reassign |

## B. Imaging (Configuration Manager) problems
| Symptom | Cause | Remediation |
|---|---|---|
| Task sequence fails / device won't PXE | Boot media, distribution point, or content missing | Confirm the OS image and task sequence are distributed to the distribution point and the device can reach PXE/boot media |
| Imaged device not in Intune | Enrollment step skipped after imaging | Ensure the task sequence (or post-image step) Entra-joins and auto-enrolls the device |

## C. Device enrolled but not reporting hardware
- Confirm the device is in Devices → All devices and recently checked in; force a sync from the
  device (Settings → Accounts → Access work or school → Info → Sync), then re-run
  `IMGLIFE-Validation.ps1`.

## D. Inventory and reconciliation gaps
| Symptom | Cause | Remediation |
|---|---|---|
| Purchased device not in inventory | Bought but never enrolled | Provision/enroll the device, or mark it `Device Lifecycle – Procurement – Procured`; re-run `IMGLIFE-Report.ps1` |
| Device in Intune but not on the books | Procurement list incomplete | Add the serial to the procurement record; reconcile again |
| Stale/duplicate records | Retired device not removed | Remove the device record and de-register from Autopilot after wipe |

## E. Retire / wipe issues
- Wipe pending forever: the device must be online to receive the command; confirm it checks in. If
  it will never return, after the documented hold period remove the record so inventory stays clean.
- Wrong device almost wiped: always run `IMGLIFE-Remediation.ps1` in its default WhatIf mode first
  and confirm the serial/name before applying.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select-Object CsManufacturer, CsModel, BiosSeralNumber
dsregcmd /status        # Entra join + MDM enrollment state
Get-Service -Name dmwappushservice, IntuneManagementExtension -ErrorAction SilentlyContinue
```
For the cloud-side device, Autopilot, and inventory state, use `IMGLIFE-Discovery.ps1` and
`IMGLIFE-Report.ps1` (Microsoft Graph).

## G. When to escalate
If a device is registered to Autopilot, assigned a profile, online, and synced, yet still fails to
provision or never reports hardware after a full reset and sync, collect the device's enrollment
diagnostics (Settings → Accounts → Access work or school → Export) and open a Microsoft support
case.
