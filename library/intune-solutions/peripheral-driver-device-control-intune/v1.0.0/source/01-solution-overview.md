# Solution Overview

## What this solution does

Enterprise desktops depend on three things that are easy to break and hard to control at scale: **drivers**, **peripherals and printers**, and **removable/USB device access**. A single bad driver can knock over a fleet; a mismapped printer generates a steady stream of help-desk tickets; and an uncontrolled USB port is a data-exfiltration and malware risk that regulators care about.

This solution gives you a **repeatable, pilot-first way to manage all three from Microsoft Intune**:

1. **Drivers** — using **Windows driver update management** in Intune (the Windows Autopatch / Windows Update for Business **driver update policy**) to review, approve, and stage driver and firmware updates safely rather than letting every device pull whatever Windows Update offers.
2. **Peripherals and printers** — using Intune **configuration profiles** (Settings Catalog and templates) to control how devices connect to printers and peripherals, plus a Win32/Universal-Print-friendly approach to mapping printers where needed.
3. **Device control (removable/USB access)** — using **Microsoft Defender device control** and the **Administrative Templates / Settings Catalog removable-storage** settings, deployed through Intune, to allow, audit, or block removable storage and USB devices by policy.

Everything is deployed **to a named pilot group first**, validated against **pass/fail gates**, and only then expanded to production — so a mistake never reaches the whole fleet at once, and every change is rollback-ready.

## How Intune manages each area

### Drivers — Windows driver update management
Windows Update for Business (surfaced in Intune as **Driver update policies** under **Devices → Windows → Manage updates → Windows Driver updates**) lets you choose between two approval modes:

- **Automatically approve all** driver updates (with an optional deferral), or
- **Manually approve and deploy** specific driver updates after review.

For enterprise desktops the safe pattern is **manual approval for the pilot ring**, then automatic (or reviewed) approval for production once a driver has soaked. Intune shows you which drivers are **recommended** vs **other**, how many devices need each, and lets you approve a driver with a scheduled make-available date. This replaces "hope Windows Update does the right thing" with an auditable, staged process.

### Peripherals and printers
Peripheral behavior is controlled with **configuration profiles**:

- A **Settings Catalog** profile controls connection and device-installation behavior (for example, allowing or restricting installation of devices by setup class, and controlling USB behavior that affects peripherals).
- **Printer mapping** is delivered either through **Universal Print** (cloud printing, no print server) or, where a traditional queue is required, a small deployment package. This solution documents the Intune-side assignment and the settings that keep peripheral installation predictable.

### Device control — removable storage / USB access
Two complementary Intune surfaces control removable and USB devices:

- **Defender device control** (endpoint security / Settings Catalog **Defender → Device Control** settings) provides rich **allow / audit / deny** rules for removable storage, printers, and other device families, with **read / write / execute** granularity and per-group exceptions.
- The **Administrative Templates / Settings Catalog "Removable Storage Access"** settings provide a simpler blanket **deny write / deny read / deny execute** control when you don't need per-device rules.

You choose the surface that matches your requirement: a blanket "block USB write" is a template setting; "block all removable storage except approved encrypted drives for the Finance group" is a Defender device-control policy with an exception group.

## The standard deployment model

Every part of this solution follows the same lifecycle, with a **pass/fail gate** at each stage:

**Assess → Configure → Pilot → Validate → Expand**

- **Assess** — inventory current driver state, printers/peripherals in use, and existing removable-storage exposure (the Discovery script does this read-only).
- **Configure** — create the named policies, profiles, and groups in Intune (nothing assigned to production yet).
- **Pilot** — assign everything to the **pilot group** (`SG-PERIDEV-Pilot`) only.
- **Validate** — confirm the pass/fail gates on pilot devices: drivers current, printer mapped, USB policy enforced.
- **Expand** — assign to the **production group** (`SG-PERIDEV-Production`) once the gates pass; keep the pilot ahead of production for future changes.

## Object naming convention (used verbatim throughout)

To keep the tenant clean and the scripts predictable, this solution uses one naming convention and **reuses these exact names** in every guide and script:

| Object | Name |
| --- | --- |
| Pilot security group | `SG-PERIDEV-Pilot` |
| Production security group | `SG-PERIDEV-Production` |
| USB exception (allowed-drives) group | `SG-PERIDEV-USB-Exception` |
| Driver update policy — pilot | `PERIDEV-DriverUpdates-Pilot` |
| Driver update policy — production | `PERIDEV-DriverUpdates-Prod` |
| Printer/peripheral config profile — pilot | `PERIDEV-Printers-Pilot` |
| Peripheral device-installation profile | `PERIDEV-Peripherals-DeviceInstall` |
| Device-control (USB) policy — pilot | `PERIDEV-DeviceControl-USB-Pilot` |
| Device-control (USB) policy — production | `PERIDEV-DeviceControl-USB-Prod` |

Wherever a later document says "assign `PERIDEV-DeviceControl-USB-Pilot`," it means exactly that object — do not rename it.

## What you get

- Click-by-click Intune configuration for drivers, peripherals/printers, and device control.
- A requirements guide that tells you how to **verify** and **implement** each prerequisite.
- Five PowerShell scripts (Graph) for discovery, per-device validation, coverage reporting, safe remediation, and pilot-group targeting.
- Testing pass/fail gates and a troubleshooting guide.
- Best practices for staged driver rollout and handling exceptions.
