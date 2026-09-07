# Troubleshooting Guide

Symptom → most likely cause → verify → fix, for a Windows Ready Print / WPP deployment through Intune.

---

## A. The Custom OMA-URI profile shows "Error" or "Not applicable"

| Cause | Verify | Fix |
|---|---|---|
| Device isn't **Windows 11 24H2+** | `winver` / `WPPRINT-Get-WPPState.ps1` | Update to 24H2, or scope the profile with an OS-version filter so ineligible devices aren't targeted |
| Unsupported **edition** | `Get-ComputerInfo OsName` | WPP supports Pro/Enterprise/Education/IoT Enterprise — Home is not supported |
| **OMA-URI/data type** wrong | Re-open the row | Must be exactly `./Device/Vendor/MSFT/Policy/Config/Printers/ConfigureWindowsProtectedPrint`, **String**, value `<enabled/>` |

> "Not applicable" is almost always the **24H2 gate** — add the filter and it resolves.

---

## B. A printer disappeared after WPP was enabled
- **Expected if** it relied on a **third-party driver** — WPP removes those printers and their drivers.
- **Verify:** it's on the Phase-1 third-party list; `WPPRINT-Get-PrintDriverInventory.ps1` before/after.
- **Fix:** reinstall it as a **Mopria/IPP** printer via Windows Ready Print, or add it to **Universal
  Print**. If it truly can't go driverless, that **device** belongs in the **exception** set (out of WPP
  scope) until the hardware is replaced.

---

## C. Can't print at all on a WPP device
- **Likely cause:** the printer isn't reachable over **IPP/IPPS**, or **Mopria/IPP isn't enabled** on the
  printer, so the IPP class driver has nothing to bind to.
- **Verify:** `WPPRINT-Test-MopriaReadiness.ps1`; confirm **IPP Printing / IPPS Printing** are enabled in
  the printer's own settings; confirm network reachability to the printer.
- **Fix:** enable IPP/IPPS on the device, correct the network path, or route via Universal Print.

---

## D. Scanning stopped working on a multifunction device
- **Likely cause:** the scanner relied on a vendor driver / WSD; WPP's driverless model needs
  **Mopria/eSCL** scan support.
- **Verify:** `WPPRINT-Test-ScanCapability.ps1`.
- **Fix:** use the device's **eSCL** scan path if supported; if not, keep that device **out of WPP scope**
  until the scanner is replaced with an eSCL-capable model. Don't enable WPP fleet-wide over a scanner
  gap — scope around it.

---

## E. A legacy "software" printer (vendor PDF/"print to" tool) is gone
- **Expected:** WPP can remove legacy software printers.
- **Fix:** use the built-in **Microsoft Print to PDF**, or a Ready-Print-compatible replacement. Update
  any workflow/documentation that named the old software printer.

---

## F. Point-and-Print printer install now fails
- **Expected under WPP:** third-party Point and Print is **blocked** by design.
- **Fix:** deliver the printer through the **modern path** (direct IPP/Mopria or Universal Print) instead
  of print-server Point and Print. Remove the legacy mapped-printer/GPO logic for migrated populations.

---

## G. WPP didn't change anything / you want to revert
- **Verify:** `WPPRINT-Get-WPPState.ps1` — is the registry value actually set?
- **Revert:** set the OMA-URI value to `<disabled/>` (or remove the assignment). Note that reverting does
  **not** automatically restore removed third-party drivers — they must be reinstalled by the modern path
  or, where unavoidable, redeployed deliberately.

---

## H. Sovereign cloud (GCC High / DoD)
- **Symptom:** portal paths or Universal Print options don't match.
- **Fix:** use `intune.microsoft.us`; the CSP and method are identical. **Universal Print availability
  differs by sovereign cloud** — confirm for yours before designing a cloud-print path.

---

## Escalation
Open a Microsoft support case only after: the profile applies but WPP state won't set on a confirmed
24H2 device; a Mopria-certified printer with IPP enabled still won't print via the class driver; or a
suspected platform issue. Attach the WPP-state output, the driver inventory, and the profile
configuration.
