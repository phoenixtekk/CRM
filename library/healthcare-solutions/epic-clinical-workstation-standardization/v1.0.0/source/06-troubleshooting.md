# 6. Troubleshooting — Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

Symptom-driven fixes for the standardization, printer-deployment, default-printer, and peripheral
layers. Each entry: **Symptom → Likely cause → Fix.** Start with read-only tools
(`EPICWS-Discovery.ps1`, `EPICWS-Validation.ps1`, `EPICWS-Report.ps1`); only `EPICWS-Remediation.ps1`
and `EPICWS-Set-PrinterDeployment.ps1` change anything, and only with `-Apply` in a maintenance window.

---

## Standardization baseline

**Symptom: The baseline profile shows Error or Conflict in Intune.**
**Likely cause:** A setting in `EPIC – Clinical Workstations – Baseline` or `… – Power & Display`
collides with the Windows security baseline (R8) or another profile.
**Fix:** Intune → **Devices → Configuration → (profile) → Device/Per-setting status** to find the
conflicting setting. Remove the duplicate from this solution's profile in favor of the security
baseline; re-sync (`EPICWS-Remediation.ps1`) and re-check (Test 1).

**Symptom: Profile reports Succeeded but settings aren't actually in effect on the device.**
**Likely cause:** Pending reboot, or the device hasn't synced since assignment.
**Fix:** Run `EPICWS-Remediation.ps1 -Apply` to trigger a sync; reboot in a window if a setting
requires it; re-validate.

## Power / display (device sleeps in a patient room)

**Symptom: A clinical workstation sleeps or the display turns off too soon.**
**Likely cause:** `EPIC – Clinical Workstations – Power & Display` not applied, or another power
profile/GPO is winning.
**Fix:** Confirm the power profile is **Succeeded** (Test 2). On the device, `EPICWS-Discovery.ps1`
shows the active power indices. If a legacy GPO sets power, remove it for clinical OUs. Re-assign and
re-test.

## Printers — presence and order

**Symptom: One of the unit's printers (wristband/script/document) is missing.**
**Likely cause:** The device is not in the unit group `EPIC – Clinical Workstations – <UNIT>`, the
printer-deployment policy didn't apply, or (scripted) the share/IP was unreachable.
**Fix:** Confirm group membership (`EPICWS-Report.ps1` flags devices with no unit group). Confirm the
policy `EPIC – Clinical Workstations – Printers – <UNIT>` is assigned and **Succeeded**. For scripted
install, verify the device can reach `\\<PRINTSERVER>\<SHARE>` / the printer IP, and that the signed
driver installs unattended (R5). Restart the spooler with `EPICWS-Remediation.ps1 -Apply
-RestartSpooler`, re-sync, re-test (Test 3).

**Symptom: Printers appear in the wrong order.**
**Likely cause:** Two deployment sources (Universal Print policy + a script) both add printers.
**Fix:** Pick one delivery method per printer class (R3). Remove the duplicate source; redeploy via
`EPICWS-Set-PrinterDeployment.ps1` so the order is wristband → script → document.

## Default printer wrong

**Symptom: The default printer is not `<UNIT_DEFAULT_PRINTER>` (Epic "just print" goes to the wrong
room).**
**Likely cause:** No default was set, the user/Windows "let Windows manage my default printer" is on,
or two sources fight over the default.
**Fix:** On the device, ensure **Settings → Bluetooth & devices → Printers & scanners → Let Windows
manage my default printer = Off** (set this in the baseline profile to standardize it). Re-assert the
default with `EPICWS-Remediation.ps1 -Apply -SetDefaultPrinter "<UNIT_DEFAULT_PRINTER>"`. Ensure only
one source (Step 10) owns the default per unit. Re-test (Test 4).

## Universal Print vs scripted-install issues

**Symptom: Universal Print printer won't deploy / isn't selectable in the policy.**
**Likely cause:** Printer not registered/shared in Universal Print, missing license, or the connector
isn't running for a legacy printer (R4).
**Fix:** portal.azure.com → **Universal Print → Printers**: confirm **Shared**; confirm Universal
Print licensing; for legacy printers confirm the **Universal Print connector** is healthy. Then
re-select the printer in `EPIC – Clinical Workstations – Printers – <UNIT>`.

**Symptom: Scripted printer-install platform script fails or installs no printer.**
**Likely cause:** Run context (logged-on vs system), 32/64-bit, unreachable share/IP, or missing
driver.
**Fix:** Intune → **Scripts and remediations → Platform scripts → (script) → Device status** for the
error. Confirm **run as system**, **64-bit = Yes**, share/IP reachable, and the driver name in the
generated script matches a signed driver present on the device. Regenerate with
`EPICWS-Set-PrinterDeployment.ps1` and the correct values.

## Clinical peripherals

**Symptom: Signature pad / scanner / badge reader not recognized.**
**Likely cause:** The peripheral's Intune Win32 app didn't install, the detection rule is wrong, or
the device isn't physically connected.
**Fix:** Intune → **Apps → (peripheral app) → Device install status**: confirm **Installed**. If
"Installed" but unrecognized, the detection rule may be false-positive — verify the real driver file/
registry value and fix the rule (Step 7). `EPICWS-Discovery.ps1` lists driver-problem devices and
recognized peripherals; reconnect the hardware and re-test (Test 5).

**Symptom: Badge reader is recognized but a tap does nothing.**
**Likely cause:** The reader (OS recognition) is this solution's job; the **tap behavior** is
Imprivata's (R12) — the boundary between Test 5 and Test 6.
**Fix:** Confirm the Imprivata agent service is running; engage the separate Imprivata solution to fix
tap/SSO. If you don't use Imprivata, the reader being recognized (Test 5) is the expected end state.

## Epic mapping mismatches

**Symptom: Wristband/script/document prints to the wrong physical printer from Epic.**
**Likely cause:** The Epic queue→printer mapping (EPS) doesn't match the printer this solution
deployed — an Epic-side configuration value, not an Intune one.
**Fix:** This is owned by your **Epic Technical Services team / Epic UserWeb** (R7). Confirm
`<EPIC_QUEUE_WRISTBAND>` / `<EPIC_QUEUE_SCRIPT>` / `<EPIC_QUEUE_DOC>` on `<EPS_SERVER>` point at the
printers you deployed for the unit. Do not change Epic-internal values yourself — coordinate with the
Epic team, then re-run the clinical print tests (Tests 7–9).

## Drift and expansion

**Symptom: A re-imaged device lost its standard (no printers / wrong default).**
**Likely cause:** It fell out of `EPIC – Clinical Workstations` and/or its unit group, so no profiles
or printers target it.
**Fix:** Use dynamic device groups keyed on the unit name prefix so re-imaged devices re-join
automatically; otherwise re-add the device to the population and unit groups. `EPICWS-Report.ps1`
surfaces devices missing a unit group. Re-sync and re-validate.

**Symptom: A whole unit is inconsistent after expansion.**
**Likely cause:** The unit's printer policy / default object was never created for that unit.
**Fix:** Repeat Implementation Steps 8–10 to create `EPIC – Clinical Workstations – Printers – <UNIT>`
and the unit default for the missed unit, assigned to its unit group; validate a sample device
(Test 10) before declaring the unit done.
