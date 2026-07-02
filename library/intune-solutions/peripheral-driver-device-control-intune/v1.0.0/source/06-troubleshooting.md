# Troubleshooting

Symptom → likely cause → fix, organized by the three areas. Use `PERIDEV-Validation.ps1` and `PERIDEV-Report.ps1` to confirm state, and remember every change is reversible (unassign the policy or switch device control back to **Audit**, then sync).

---

## Drivers

### A driver never appears under `PERIDEV-DriverUpdates-Pilot` to approve
- **Cause:** devices haven't reported update status yet, or the device isn't using Windows Update for Business.
- **Fix:** allow 24–48 hours after first assignment. Confirm the device is not pointed at WSUS/on-prem updates (requirement R2), reaches `*.windowsupdate.com`, and is Pro/Enterprise/Education (requirement R2). Force a sync (`PERIDEV-Remediation.ps1`).

### Approved driver isn't installing on a pilot device
- **Cause:** make-available date is in the future, the device hasn't synced, or the device already has an equal/newer driver.
- **Fix:** check the **Make available** date on the approval, force a sync, and confirm in Device Manager the device isn't already at/above that version. Verify via Gate 1 in Testing.

### A driver caused a problem after approval
- **Cause:** a bad driver reached the pilot — exactly what the pilot is for.
- **Fix:** on the device, Device Manager → **Roll Back Driver**. In Intune, withdraw/don't-expand the approval. Do **not** approve it to `PERIDEV-DriverUpdates-Prod`. Investigate before re-approving.

### Devices getting drivers you didn't approve
- **Cause:** production policy set to **Automatically approve all** with too small a deferral, or another update policy is competing.
- **Fix:** increase the deferral on `PERIDEV-DriverUpdates-Prod`, or switch it to manual approval. Run `PERIDEV-Discovery.ps1` to find competing update policies.

---

## Peripherals & printers

### Printer from `PERIDEV-Printers-Pilot` doesn't appear on the device
- **Cause (Universal Print):** printer not shared, wrong cloud device ID in the profile, or user lacks access.
- **Cause (queue):** UNC path unreachable, or the mapping package failed.
- **Fix:** re-check the Universal Print printer's shared status and that the exact cloud device ID/name is in the profile (no placeholder text). For a queue, confirm the print server path (for example `\\print-server-01\FINANCE-MFP`) resolves from the device. Force a sync and re-test Gate 2.

### Printer appears but test page fails
- **Cause:** driver missing, or the printer offline.
- **Fix:** confirm the print device is online; if a vendor driver is required, deliver it as a Win32 app alongside the pilot (requirement R3).

### An unexpected peripheral installed (or a needed one is blocked)
- **Cause:** `PERIDEV-Peripherals-DeviceInstall` is too permissive or too strict.
- **Fix:** add the approved setup class/instance ID to the allow list; if using the locked-down "prevent installation of devices not described by other policy settings," ensure every approved peripheral is explicitly allowed. Re-sync.

---

## Device control (USB / removable)

### USB drive is not blocked in the Enforce phase
- **Cause:** policy still in **Audit**, Defender inactive, device not synced, or device outside `SG-PERIDEV-Pilot`.
- **Fix:** confirm `PERIDEV-DeviceControl-USB-Pilot` is set to **Deny** (not Audit) and that **Device Control Enabled = Enabled**. Run `Get-MpComputerStatus` — Defender must be active (requirement R5). Confirm the device is in the pilot group and synced. Re-test Gate 3.

### An approved drive is wrongly blocked
- **Cause:** the device/user isn't in `SG-PERIDEV-USB-Exception`, or the allow rule doesn't match the drive's device ID.
- **Fix:** add the user/device to `SG-PERIDEV-USB-Exception` and confirm the allow rule's device IDs match the approved drive. Re-sync and re-test.

### No audit or block events appear at all
- **Cause:** device control not enabled, or Defender Antivirus disabled/passive.
- **Fix:** set **Device Control Enabled = Enabled**; ensure a Defender Antivirus policy has Defender in **Normal** running mode (requirement R5). If a third-party AV is primary and Defender is off, device control will not enforce.

### Policy shows conflict/error in the report
- **Cause:** two policies set the same removable-storage setting differently (e.g., an Administrative-Template block and a Defender device-control rule).
- **Fix:** run `PERIDEV-Discovery.ps1` to find overlapping removable-storage policies; keep one authoritative surface (Defender device control **or** the Removable Storage Access template), not both. Remove the duplicate and re-sync.

---

## Coverage, assignment, and scripts

### A device is "not covered" in `PERIDEV-Report.ps1`
- **Cause:** device not in the assigned group, or hasn't synced.
- **Fix:** confirm membership of `SG-PERIDEV-Pilot`/`SG-PERIDEV-Production`; run `PERIDEV-Remediation.ps1` (default `-WhatIf`) to review, then `-WhatIf:$false` to assign and sync.

### A script fails to connect to Graph
- **Cause:** SDK not installed, or missing consent for the required scopes.
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`; sign in with an **Intune Administrator** and consent to the scopes listed in each script's HOW TO RUN section.

### Validation shows FAIL but the device looks fine manually
- **Cause:** reporting lag — device configuration state hasn't refreshed in Intune yet.
- **Fix:** force a sync, wait for the device to report, and re-run `PERIDEV-Validation.ps1`. Confirm the gate manually per the Testing guide.

### Rollback needed
- **Cause:** any pilot change caused unacceptable impact.
- **Fix:** remove the group assignment from the affected policy (or switch device control from **Deny** to **Audit**), then force a sync (`PERIDEV-Remediation.ps1` or **Devices → sync**). Nothing in this solution requires an irreversible change.
