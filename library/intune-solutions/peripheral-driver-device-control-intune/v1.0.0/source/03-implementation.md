# Implementation Guide

This guide configures **drivers**, **peripherals/printers**, and **device control (USB/removable)** in Intune, then assigns everything to a **named pilot**, validates it, and expands to production. Follow the steps in order. Every object uses the naming convention from the Solution Overview — **use these names verbatim**.

Sign in to the Microsoft Intune admin center at `https://intune.microsoft.com` as an **Intune Administrator** before you begin.

> **Deployment model:** Assess → Configure → Pilot → Validate → Expand. Do not assign anything to `SG-PERIDEV-Production` until the pilot passes the gates in the Testing guide.

---

## Stage 0 — Assess (read-only)

1. Run `PERIDEV-Discovery.ps1` to capture the current state: existing driver update policies, printer/peripheral configuration profiles, and any removable-storage / Defender device-control policies with their assignments.
2. Note any existing removable-storage policy so you do not conflict with it, and record approved-drive workflows for the exception group.

---

## Stage 1 — Create the groups

If the groups from requirement R7 do not already exist, create them now.

1. Go to `https://entra.microsoft.com` → **Groups → All groups → New group**.
2. Create each of the following as **Security** groups, **Assigned** membership:
   - `SG-PERIDEV-Pilot` — add a small, representative set of desktops (or their users).
   - `SG-PERIDEV-Production` — the full target population (leave empty until Stage 6 if you prefer).
   - `SG-PERIDEV-USB-Exception` — users/devices allowed to use approved removable storage.
3. (Alternative) Run `PERIDEV-Set-ScopeTargeting.ps1` to create/populate the pilot group. It defaults to `-WhatIf`; re-run with `-WhatIf:$false` to apply.

---

## Stage 2 — Configure Windows driver update management

1. In Intune, go to **Devices → Windows → Manage updates → Windows Driver updates**.
2. Click **Create profile**.
3. **Basics:**
   - **Name:** `PERIDEV-DriverUpdates-Pilot`
   - **Description:** `Staged driver updates - pilot ring. Manual approval.`
   - Click **Next**.
4. **Settings:**
   - **Approval method:** select **Manually approve and deploy driver updates**. (Manual approval is the safe pilot behavior — you review each driver before it deploys.)
   - Click **Next**.
5. **Scope tags:** leave default (or add your standard scope tag), **Next**.
6. **Assignments:** click **Add groups** and add **`SG-PERIDEV-Pilot`**. Do **not** add production yet. **Next**.
7. **Review + create** → **Create**.
8. After devices report in (allow 24–48 hours), return to `PERIDEV-DriverUpdates-Pilot`. Under **Driver updates to review**, you will see **Recommended** and **Other** drivers with device counts. For each driver you want to ship to the pilot:
   - Select it → **Approve**.
   - Set a **Make available** date (immediately, or scheduled to your window).
9. Later, for production, create a second profile named **`PERIDEV-DriverUpdates-Prod`** the same way. For production you may choose **Automatically approve all** with a deferral (for example, 7 days) once you trust the source, and assign it to **`SG-PERIDEV-Production`** in Stage 6.

**Gate (record in Testing):** a pilot device shows the approved driver as installed (Device Manager shows the expected version; `PERIDEV-Validation.ps1` reports driver current).

---

## Stage 3 — Configure peripheral device-installation behavior

This keeps peripheral installation predictable and prevents unexpected device classes from installing.

1. In Intune, go to **Devices → Windows → Configuration → Create → New Policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Settings catalog**. Click **Create**.
3. **Basics:**
   - **Name:** `PERIDEV-Peripherals-DeviceInstall`
   - **Description:** `Controls installation of peripheral device classes.`
   - **Next**.
4. **Configuration settings:** click **Add settings** and search **Device Installation**. Add the settings you need, for example:
   - **Allow installation of devices that match any of these device instance IDs** / **setup classes** — to explicitly allow approved peripherals (printers, docks).
   - **Prevent installation of devices not described by other policy settings** — set to **Disabled** for a permissive baseline, or **Enabled** for a locked-down baseline where only approved classes install.
   - Configure conservatively for the pilot; a permissive baseline plus explicit allows is the safest start.
5. **Scope tags:** default, **Next**.
6. **Assignments:** **Add groups → `SG-PERIDEV-Pilot`**. **Next**.
7. **Review + create** → **Create**.

---

## Stage 4 — Deploy printer / peripheral configuration

Choose the method that matches requirement R4.

### Option A — Universal Print (cloud, recommended)
1. Register the printer(s) in **Universal Print** (Universal Print portal) and share them.
2. In Intune, go to **Devices → Windows → Configuration → Create → New Policy → Settings catalog**.
3. **Name:** `PERIDEV-Printers-Pilot`, **Description:** `Maps approved printers to pilot desktops (Universal Print).`
4. **Add settings** → search **Printer Provisioning** and add the **Universal Print** printer-provisioning settings, supplying the shared printer's cloud device ID and name (use the exact values from the Universal Print portal — no angle-bracket placeholders).
5. **Assignments:** **Add groups → `SG-PERIDEV-Pilot`**. **Review + create → Create**.

### Option B — Traditional queue (fallback)
1. Prepare a small printer-mapping package (script or Win32 app) that connects the desktop to the existing print queue by its UNC path (for example `\\print-server-01\FINANCE-MFP`).
2. In Intune, go to **Apps → Windows → Add → Windows app (Win32)**, upload the `.intunewin`, and set install/uninstall commands.
3. **Name:** `PERIDEV-Printers-Pilot`.
4. **Assignments:** **Required → `SG-PERIDEV-Pilot`**. Save.

**Gate (record in Testing):** a pilot desktop shows the printer mapped and can print a test page (`PERIDEV-Validation.ps1` reports printer mapped).

---

## Stage 5 — Configure device control (USB / removable storage)

Pick the surface that matches your requirement. For a pilot, **start in Audit** so you see impact before enforcing.

### Option A — Defender device control (rich rules, exceptions) — recommended
1. In Intune, go to **Endpoint security → Attack surface reduction** (or **Devices → Windows → Configuration → Create → New Policy → Settings catalog**).
2. **Platform:** Windows 10 and later. **Profile type:** **Settings catalog** (Defender Device Control). Click **Create**.
3. **Basics:**
   - **Name:** `PERIDEV-DeviceControl-USB-Pilot`
   - **Description:** `Removable-storage control - pilot. Audit first, then Deny write.`
   - **Next**.
4. **Configuration settings:** **Add settings** → search **Device Control**:
   - **Device Control Enabled** → **Enabled** (this turns the engine on — see requirement R5).
   - Configure a rule for the **Removable storage** device family:
     - For the initial pilot, set the removable-storage access to **Audit** (write/read/execute audited) so you observe usage without blocking.
     - When ready to enforce, change to **Deny write** (block writing to removable storage, still allow read) or **Deny all** per your requirement.
   - If you need an exception (approved encrypted drives for `SG-PERIDEV-USB-Exception`), define an **allow** rule/group for those device IDs so the exception group retains access while everyone else is denied.
5. **Scope tags:** default, **Next**.
6. **Assignments:** **Add groups → `SG-PERIDEV-Pilot`**. **Next**.
7. **Review + create** → **Create**.

### Option B — Administrative Templates / Settings Catalog "Removable Storage Access" (simple blanket block)
Use this when you only need a blanket control and no per-device exceptions.
1. **Devices → Windows → Configuration → Create → New Policy → Settings catalog.**
2. **Name:** `PERIDEV-DeviceControl-USB-Pilot`.
3. **Add settings** → search **Removable Storage Access** and set, for example, **Removable Disks: Deny write access = Enabled** (and Deny read/execute as required).
4. **Assignments:** **Add groups → `SG-PERIDEV-Pilot`**. **Review + create → Create**.

**Gate (record in Testing):** on a pilot device, inserting a non-approved USB drive is audited (Audit phase) or blocked (Enforce phase); an approved drive for `SG-PERIDEV-USB-Exception` still works. `PERIDEV-Validation.ps1` reports USB policy enforced.

---

## Stage 6 — Validate, then expand to production

1. **Validate the pilot** against all three gates using the Testing guide and `PERIDEV-Validation.ps1`:
   - Driver current (Stage 2 gate)
   - Printer mapped (Stage 4 gate)
   - USB policy enforced (Stage 5 gate)
2. Run `PERIDEV-Report.ps1` to confirm coverage across the pilot group.
3. If all gates **pass**, switch the device-control policy from **Audit** to **Deny** on the pilot and re-validate the USB gate.
4. **Expand:**
   - Create `PERIDEV-DriverUpdates-Prod` (Stage 2, step 9) and assign to **`SG-PERIDEV-Production`**.
   - Duplicate the peripheral, printer, and device-control policies as **`...-Prod`** (or add `SG-PERIDEV-Production` to the assignment) and assign to **`SG-PERIDEV-Production`**.
   - Keep `SG-PERIDEV-Pilot` ahead of production for all future changes.
5. Run `PERIDEV-Report.ps1` again against production to confirm coverage after expansion.

> **Rollback at any point:** remove the pilot/production assignment from the affected policy (or switch device control from **Deny** back to **Audit**) and force a device sync (**Devices → sync**, or `PERIDEV-Remediation.ps1`). Nothing in this solution requires an irreversible change.
