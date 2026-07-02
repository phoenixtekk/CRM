# Requirements

Before you configure anything, confirm the prerequisites below. The **category-level global requirements** (Entra tenant, Intune subscription, admin roles, enrollment, supported Windows baseline, network access) are documented separately in *Global Requirements — Intune Solutions* and are assumed here. This page covers the prerequisites **specific to peripheral, driver, and device-control management**.

Each requirement is written as **Description / Why / Verify / Implement if missing.**

---

## R1. Windows devices enrolled and reporting update status

**Description:** The target enterprise desktops are enrolled in Intune and are actively reporting Windows Update / driver status.

**Why:** Windows driver update management only sees and manages devices that check in through Windows Update for Business. A device that is enrolled but not reporting update status cannot be offered or blocked from drivers.

**Verify:** Intune → **Devices → All devices** — the desktops appear and show a recent **Last check-in**. Then **Devices → Windows → Manage updates → Windows Driver updates** — after a policy exists, devices begin appearing under it within 24–48 hours.

**Implement if missing:** Ensure automatic enrollment is on and devices are Entra-joined or hybrid-joined. If update reporting is absent, confirm the devices are not blocked from `*.windowsupdate.com` / `*.delivery.mp.microsoft.com` and that no legacy WSUS or "Do not connect to any Windows Update locations" policy is overriding cloud updates.

---

## R2. Windows edition and licensing for driver update policies

**Description:** Windows 10/11 **Pro, Enterprise, or Education** with an Intune-bearing license; driver update management uses Windows Update for Business.

**Why:** Windows driver update policies are a Windows Update for Business feature; Home edition and devices pointed at WSUS/on-prem-only update sources cannot use them.

**Verify:** On a sample device run `winver` (edition shown) and confirm in Intune the device is not receiving updates from an on-premises source. In Intune, **Devices → Windows → Manage updates → Windows Driver updates** must be available in the console.

**Implement if missing:** Upgrade Home to Pro/Enterprise, remove or scope out any WSUS/on-prem update policy for these devices, and confirm the Intune license (per the global requirements) is assigned.

---

## R3. Driver source strategy (Windows Update vs. vendor packages)

**Description:** A decision on where drivers come from — **Windows Update driver updates** (default for this solution) and, where a device or peripheral needs a driver Windows Update does not publish, a **vendor driver package** delivered as a Win32 app.

**Why:** Most modern drivers are available through Windows Update and are the safest to stage. A few enterprise peripherals (specialized printers, docks, scanners) publish drivers only through the vendor, which then need packaging.

**Verify:** For each critical peripheral, check whether its current driver appears under **Windows Driver updates** in Intune (recommended/other lists) or on the vendor's site only.

**Implement if missing:** Use Windows driver update management for everything Windows Update carries. For the rest, package the vendor driver as a Win32 (`.intunewin`) app and assign it alongside the pilot group — vendor console internals are covered by the vendor's own documentation; the Intune assignment side is what this solution manages.

---

## R4. Printer delivery method (Universal Print or queue package)

**Description:** A chosen method for mapping printers — **Universal Print** (cloud, no print server) or a **printer deployment package** for a traditional queue.

**Why:** Peripheral management includes making the right printers available to the right users without manual setup. Universal Print is the cloud-native path; a package is the fallback where a legacy queue must remain.

**Verify:** If using Universal Print, confirm a Universal Print subscription/licensing is present and at least one printer is registered (Universal Print portal). If using a queue, confirm the print server/queue is reachable from the desktops.

**Implement if missing:** Register printers in Universal Print and assign a Universal Print connector where needed, **or** prepare a small printer-mapping package for Intune. The Intune assignment (to `PERIDEV-Printers-Pilot`) is documented in the Implementation Guide.

---

## R5. Microsoft Defender device-control prerequisites

**Description:** Devices are onboarded to Microsoft Defender (Defender Antivirus running, not in passive/disabled state) and **device control is enabled** so removable-storage and USB rules apply.

**Why:** Defender device control is the engine that enforces allow/audit/deny rules on removable storage and USB. If Defender Antivirus is disabled (e.g., a third-party AV is primary and Defender is off), device-control rules do not enforce.

**Verify:** On a sample device, run `Get-MpComputerStatus` — `AMRunningMode` should be **Normal** (or EDR block mode as appropriate) and `RealTimeProtectionEnabled` **True**. In Intune, **Endpoint security → Antivirus** shows the device as protected.

**Implement if missing:** Deploy a Defender Antivirus policy so Defender is active, then enable device control via the **Defender → Device Control** Settings-Catalog setting (**Device Control Enabled = Enabled**) as part of the device-control policy in the Implementation Guide. If a third-party AV must remain primary, confirm Defender can still run device control before relying on it.

---

## R6. Removable-storage baseline inventory

**Description:** A read-only picture of how removable/USB storage is used today (which devices, whether any block/allow policy already exists).

**Why:** You must not block a workflow that a business unit depends on (e.g., an approved encrypted drive) without an exception. Knowing current usage lets you scope the pilot and define the exception group correctly.

**Verify:** Run `PERIDEV-Discovery.ps1` (read-only) to list existing device-control / removable-storage policies and their assignments; check for existing Administrative-Template "Removable Storage Access" or Defender device-control policies in Intune.

**Implement if missing:** If no baseline exists, that is fine — the Discovery script establishes it. Record any known approved-drive workflows so they can be added to `SG-PERIDEV-USB-Exception`.

---

## R7. Pilot and production security groups

**Description:** Entra security groups that target the rollout: a **pilot** group and a **production** group, plus a **USB exception** group for approved removable-storage users/devices.

**Why:** The whole solution is pilot-first. Groups are how every policy is assigned and expanded. The exception group lets you enforce a strict USB policy fleet-wide while still permitting approved drives for a defined set.

**Verify:** Entra → **Groups** — confirm these exist with the exact names:
- `SG-PERIDEV-Pilot`
- `SG-PERIDEV-Production`
- `SG-PERIDEV-USB-Exception`

**Implement if missing:** Create them (Entra → **Groups → New group → Security**), or run `PERIDEV-Set-ScopeTargeting.ps1` (default `-WhatIf`; re-run with `-Confirm:$true` / `-WhatIf:$false` to apply) to create and populate the pilot targeting. Add a small, representative set of desktops to `SG-PERIDEV-Pilot` first.

---

## R8. A change/rollback window and communications

**Description:** An agreed maintenance window for the pilot and a simple rollback plan (unassign the policy / set device control back to audit).

**Why:** Driver and USB changes are user-visible. A window and a stated rollback step keep the pilot low-risk and reversible.

**Verify:** Confirm with the desktop-operations owner that pilot users know a change is coming and how to report issues.

**Implement if missing:** Schedule the window; document that rollback = remove the pilot assignment (or switch device control from **Deny** to **Audit**) and force a sync. This is expanded in the Best Practices guide.
