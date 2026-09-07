# Requirements

Confirm each prerequisite before you begin. Each lists **why** it is required, **how to verify**, and
**how to implement** if missing.

## 1. Windows 11 24H2 or later on the target devices

- **Description:** Windows Protected Print mode and the `ConfigureWindowsProtectedPrint` CSP require
  **Windows 11, version 24H2 or later** — **Pro, Enterprise, Education, or IoT Enterprise**.
- **Why required:** The setting does not exist on earlier builds; targeting them is a no-op.
- **How to verify:** `winver`, or `Get-ComputerInfo -Property OsName,OsBuildNumber` (24H2 = build 26100+).
  The included **`WPPRINT-Get-WPPState.ps1`** reports the build and eligibility.
- **How to implement if missing:** Update devices to 24H2 first; scope WPP only to eligible devices (use
  an Intune **filter** on OS version).

## 2. Intune administrator + device configuration rights

- **Description:** **Intune Administrator** (or a least-privilege role that can create device
  configuration profiles and assignments).
- **Why required:** You create the Custom OMA-URI profile and assign it to pilot/production groups.
- **How to verify:** Sign in to **Intune admin center** (`intune.microsoft.com`; GCC High:
  `intune.microsoft.us`) → **Devices → Configuration**.
- **How to implement if missing:** Have an admin grant the role.

## 3. A printer/driver compatibility inventory

- **Description:** A per-device inventory of **installed print drivers** (V3/V4, third-party vs the
  Microsoft IPP Class Driver) and **printers**, plus each printer's **Mopria/IPP** and **scan (eSCL)**
  readiness.
- **Why required:** WPP **removes** incompatible printers and their drivers. You must know what would be
  removed **before** you enable it.
- **How to verify:** Run **`WPPRINT-Get-PrintDriverInventory.ps1`** and **`WPPRINT-Test-MopriaReadiness.ps1`**
  across a representative sample (and **`WPPRINT-Test-ScanCapability.ps1`** where multifunction scanning
  matters).
- **How to implement if missing:** Run the assessment scripts first; that inventory drives the whole plan.

## 4. Mopria-certified / IPP-capable printers (with IPP enabled)

- **Description:** Target printers must be **Mopria-certified** and reachable over **IPP/IPPS**, so the
  Microsoft IPP Class Driver can print to them driverlessly.
- **Why required:** Under WPP the PC prints **only** through Windows Ready Print to compatible printers.
- **How to verify:** Check the vendor's Mopria certification and that **IPP Printing / IPPS Printing** are
  **enabled** in the printer's own settings; `WPPRINT-Test-MopriaReadiness.ps1` probes reachability.
- **How to implement if missing:** Enable IPP/IPPS on the device, replace non-Mopria hardware, or route it
  through **Universal Print**; devices that can't comply are **excluded** from WPP scope.

## 5. A target printing path (Ready Print direct and/or Universal Print)

- **Description:** A decision, per printer population, between **direct IPP/Mopria** and **Universal Print**
  (Microsoft cloud printing) as the modern replacement for legacy print-server/Point-and-Print delivery.
- **Why required:** WPP blocks third-party Point-and-Print; you need the modern path in place first.
- **How to verify:** Universal Print licensing/connector status (if used); direct IPP reachability from
  the client subnets.
- **How to implement if missing:** Stand up **Universal Print** (or confirm direct IPP) for the printers
  that need it before removing the legacy path. **Sovereign clouds: confirm Universal Print availability.**

## 6. Pilot group + change approval

- **Description:** A small, representative **pilot ring** (mix of printer models, at least one
  multifunction/scanner) and an approved change record.
- **Why required:** WPP changes printing for **every user** on a device; it is staged, not flipped.
- **How to verify:** Pilot Entra group created; change ticket approved naming the assessment findings.
- **How to implement if missing:** Build the pilot group and raise the change with the assessment output.

## 7. Windows PowerShell for assessment and validation

- **Description:** The included scripts (Windows PowerShell 5.1+) inventory drivers, test Mopria/IPP and
  scan readiness, read WPP state, and validate the deployment.
- **Why required:** They turn compatibility and post-deployment validation into evidence.
- **How to verify:** `$PSVersionTable.PSVersion`; the scripts run elevated on the target devices.
- **How to implement if missing:** Run them via an Intune **platform script** / Proactive Remediation, or
  locally elevated on sample devices.

> **Category-wide prerequisites** common to every Intune solution are listed in
> `global-requirements-intune-solutions.md`. Vendor-side printer configuration (enabling IPP/IPPS,
> confirming Mopria certification) and Universal Print connector setup are referenced, not rebuilt.
