# 6. Troubleshooting — Microsoft Intune First-Time Setup for Windows

Work top-down: confirm licensing/roles first, then enrollment scope, then the enrollment-time grouping
owner, then device-side state. Run `INTBASE-Preflight.ps1` to catch the common tenant-side causes fast.

---

## User-driven enrollment issues

### "Access work or school" only adds an account — the PC does not Entra-join
- **Cause:** the user clicked the email box (adds a work account) instead of **Join this device to
  Microsoft Entra ID**.
- **Fix:** in the Connect dialog, click the link **Join this device to Microsoft Entra ID** *under* the
  email box, then sign in with the work account.

### PC Entra-joins but never appears in Intune
- **Cause 1:** the user is **not licensed** for Intune → **Fix:** assign an Intune license (via
  `INTBASE - Windows Users - Pilot`) and re-sync.
- **Cause 2:** automatic enrollment scope excludes the user → **Fix:** **Devices → Enrollment → Windows →
  Automatic Enrollment**, confirm **MDM user scope** includes `INTBASE - Windows Users - Pilot` (or set
  **All**).
- **Cause 3:** Windows **Home** edition → **Fix:** enrollment requires Pro/Enterprise/Education; upgrade
  the edition.
- **Recheck:** on device `dsregcmd /status` → `AzureAdJoined : YES` and a populated `MdmUrl`; force
  **Settings → Access work or school → Info → Sync**.

### Device shows enrolled but **not compliant**
- **Cause:** first compliance evaluation has not completed, or a setting in
  `INTBASE - Compliance - Windows Pilot` is not yet met.
- **Fix:** allow one check-in cycle; open Intune → device → **Device compliance** to see which setting
  failed and remediate. For the pilot, keep the baseline minimal.

---

## Autopilot issues

### Device group is empty after enrollment / profile & ESP never deploy
- **Cause (most common):** the **Intune Provisioning Client** service principal (AppId
  `f1346770-5b25-470b-88bd-d5744ab7952c`) is **not an Owner** of the **Assigned** group
  `INTBASE - Autopilot Devices`. Enrollment-time device grouping requires this principal to *own* the
  group; without it the device never lands in the group and nothing deploys.
- **Fix:** **Entra → Groups → `INTBASE - Autopilot Devices` → Owners → Add owners**, search by **AppId**
  `f1346770-5b25-470b-88bd-d5744ab7952c`, add it. If it does not appear, open the Intune admin center
  once as a **Global Administrator** to provision the principal, then retry. Re-provision the device.

### OOBE shows a normal Windows setup, not the Autopilot/branded flow
- **Cause 1:** the device is **not registered** for Autopilot → **Fix:** **Devices → Enrollment → Windows
  → Devices**; import the hash CSV (from `INTBASE-Get-AutopilotHash.ps1`) and wait for the serial to
  appear; **Sync**.
- **Cause 2:** no profile assigned → **Fix:** confirm `INTBASE - Autopilot - Pilot` is assigned to
  `INTBASE - Autopilot Devices` and the device is a **member** of that group.
- **Cause 3:** the device already passed the network screen before the profile was ready → **Fix:**
  factory-reset and restart OOBE after registration/assignment shows on the device record.

### ESP hangs / device blocked at "Setting up your device"
- **Cause:** `INTBASE - ESP - Pilot` requires apps that are slow or failing to install.
- **Fix:** keep the pilot ESP light — do not require heavy apps; ensure **Allow users to use device if
  installation error occurs = Yes** so the pilot is not stuck. Deep ESP tuning is a separate solution.

### Imported device does not show up
- **Cause:** registration propagation delay, or a malformed CSV.
- **Fix:** click **Sync** and wait a few minutes; confirm the CSV has the required columns (see
  `autopilot-hardware-hash.csv` template) with no extra headers. Re-run
  `INTBASE-Get-AutopilotHash.ps1` elevated if the export was empty.

---

## Script issues

### `Connect-MgGraph` fails or lacks permission
- **Fix:** consent to the read scopes on first connect. For Government tenants use
  `Connect-MgGraph -Environment USGov` (or `USGovDoD`). Preflight/report scripts are read-only.

### `INTBASE-Get-AutopilotHash.ps1` produces no file
- **Fix:** run it **elevated**; it installs and calls Microsoft's `Get-WindowsAutopilotInfo`. Confirm the
  device has internet access to install the script.

### `INTBASE-Remediation.ps1` reports it "would" change something but did not
- **Expected:** it defaults to `-WhatIf` (preview). Review the preview, then re-run with `-Apply` to make
  the change. It only touches the auto-enrollment scope / the group owner it is scoped to.

---

## Government (GCC / GCC High / DoD)
- Use `intune.microsoft.us` / `entra.microsoft.us`; scripts use `Connect-MgGraph -Environment USGov`.
- The Intune Provisioning Client AppId is the same. If an Autopilot/enrollment feature behaves
  differently than documented here, treat it as a **GCC High parity/timing** difference and **verify
  against Microsoft's US sovereign-cloud documentation** rather than assuming Commercial behavior.
