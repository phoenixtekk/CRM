# 2. Requirements Guide — Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

Verify **every** requirement below before you standardize, deploy printers, or deploy peripherals.
Each entry follows the same pattern: **Description · Why required · How to verify · How to implement
if missing.** Do **not** assume any prerequisite already exists.

> Category-wide prerequisites (a tenant, Intune subscription, device enrollment, HIPAA / HITRUST
> change control, clinical maintenance windows, a test device, rollback posture, etc.) are documented
> once in **`global-requirements-healthcare-solutions.md`**. This guide lists what is **specific to**
> standardizing clinical workstations and their peripherals/printing.

---

## R1. Microsoft Intune licensing and configuration + app rights
**Description:** An Intune subscription and an operator with rights to create and assign **device
configuration profiles** and **Windows apps** (Intune Administrator or, scoped, Policy/Profile
Manager + Application Manager).
**Why required:** The baseline is delivered as Intune **configuration profiles / settings catalog**,
and peripherals/printer-install logic are delivered as **Win32 apps** or **platform scripts**;
without these rights you cannot author or assign them.
**How to verify:** `https://intune.microsoft.com` → **Devices → Configuration** shows **+ Create**,
and **Apps → Windows** shows **+ Add**; Entra → **Roles and administrators** shows the operator's
role.
**How to implement if missing:** Assign an Intune-bearing license and the **Intune Administrator**
(or the scoped roles above) to the operator. See global requirement G1.

## R2. The standard clinical-workstation device group
**Description:** A Microsoft Entra **device** group **`EPIC – Clinical Workstations`** containing all
in-scope clinical endpoints, and **per-unit device groups** for printer/default-printer mapping —
named **`EPIC – Clinical Workstations – <UNIT>`** (e.g. `EPIC – Clinical Workstations – ED`,
`EPIC – Clinical Workstations – 4West`).
**Why required:** The baseline profiles assign to `EPIC – Clinical Workstations`; the
**printer-deployment policy and per-unit default printer** assign to the per-unit groups, because the
default printer and the printer set differ by unit.
**How to verify:** Entra → **Groups → All groups**; the population group and one group per in-scope
unit exist with intended membership.
**How to implement if missing:** Create them in Entra (or run **`EPICWS-Set-PrinterDeployment.ps1`**,
which can ensure the per-unit groups). Use dynamic membership rules where a reliable device attribute
(name prefix per unit) exists.

## R3. Printer delivery method decided — Universal Print vs scripted install
**Description:** A decision, per printer class, of **how** printers reach the workstation:
**Universal Print** (cloud-native, no on-prem print server) or **scripted printer installation**
(direct-IP / existing print-server queues via a platform script).
**Why required:** The two paths have different prerequisites and different Intune objects; the
implementation steps and the `EPICWS-Set-PrinterDeployment.ps1` mode depend on which you choose.
**How to verify:** Confirm which is true today: are printers shared from an on-prem print server /
direct IP (scripted install), or registered in Universal Print? Check **Intune → Tenant
administration → Connectors and tokens → Universal Print** and your print-server console.
**How to implement if missing:** Choose per printer class. For Universal Print, satisfy R4. For
scripted install, confirm the print server / printer IPs and drivers (R5, R6).

## R4. Universal Print licensing and registration (only if using Universal Print)
**Description:** **Universal Print** entitlement (included in M365 E3/E5 and equivalents), the
Universal Print **printer share(s)** registered, and — for non-native printers — the **Universal
Print connector** installed against the print queues.
**Why required:** Intune's **Printers → Universal Print** deployment only targets printers that are
registered and shared in Universal Print; without a license/connector there is nothing to deploy.
**How to verify:** Universal Print portal (`https://portal.azure.com` → **Universal Print**) lists
the printer(s) as **Registered/Shared**; Intune → **Devices → … Universal Print** can select them.
**How to implement if missing:** Assign Universal Print–bearing licenses; register native printers or
deploy the **Universal Print connector** for legacy/IP printers; share each printer. Skip this
requirement entirely if you use scripted install for that printer class.

## R5. Print queues / printer endpoints and drivers (only if using scripted install)
**Description:** The reachable **print-server share paths** (`\\<PRINTSERVER>\<SHARE>`) or
**direct-IP** addresses and ports of the wristband/label, script, and document printers, plus the
**signed printer drivers** (or the printer's built-in driver) packaged for unattended install.
**Why required:** Scripted printer installation adds these named queues and installs the matching
driver; without the exact paths/IPs and drivers the script cannot create the printer.
**How to verify:** From the test device, reach the share / ping the printer IP and confirm the driver
installs unattended once by hand; run **`EPICWS-Discovery.ps1`** to inventory currently installed
printers and drivers.
**How to implement if missing:** Obtain the queue paths / IPs from your print team and the signed
drivers from the vendor; stage the driver in the Win32/script package. Record them for the
Implementation Guide.

## R6. Clinical peripheral drivers/apps — scanners, signature pads, badge/proximity readers
**Description:** The vendor **drivers/applications** for the in-scope clinical peripherals — document
**scanners**, **signature pads** (registration/consent), and **badge / proximity readers** — packaged
for unattended deployment via Intune (Win32 app or platform script), with their **detection** signal.
**Why required:** Signature pads and many badge readers need a vendor driver/runtime before Epic (or
the OS / Imprivata) recognizes them; standardizing means deploying these the same way on every device.
**How to verify:** On the test device confirm each peripheral is recognized (Device Manager shows no
unknown device; the signature pad / badge reader responds); run **`EPICWS-Validation.ps1`** which
checks for the expected peripheral driver/service.
**How to implement if missing:** Obtain signed vendor drivers/installers, wrap them as Intune Win32
apps with silent switches and a detection rule, and assign to `EPIC – Clinical Workstations`. For
badge-tap SSO behavior beyond OS recognition, engage the separate Imprivata solution.

## R7. Epic print mapping values — from Epic Technical Services / UserWeb
**Description:** The **Epic Print Service (EPS)** host, the **Epic print queue names**, and the
**workflow-to-printer mapping** (which Epic queue a wristband, a script, and a document route to per
department), plus the intended **default printer per unit**.
**Why required:** These define which physical/Universal Print printer each Epic workflow targets and
which printer is the per-unit default; they are **Epic-specific and customer-only** and must not be
guessed.
**How to verify:** Confirm with your **Epic Technical Services / client systems team** (sourced from
**Epic UserWeb**) the EPS host, the exact queue names, and the per-department/per-unit printer
mapping. Print a test wristband, script, and document on the test device and confirm each lands on the
intended physical printer.
**How to implement if missing:** Request these from your Epic team / Epic UserWeb and record them as
the placeholders `<EPS_SERVER>`, `<EPIC_QUEUE_WRISTBAND>`, `<EPIC_QUEUE_SCRIPT>`, `<EPIC_QUEUE_DOC>`,
and `<UNIT_DEFAULT_PRINTER>` used throughout the Implementation Guide.

## R8. Windows security baseline (apply alongside this baseline)
**Description:** Your organization's approved **Windows security baseline** (Intune security baseline
or settings-catalog equivalent), applied to clinical workstations.
**Why required:** This solution's baseline tunes power/display/timeout and the clinical experience; it
**references** but does not redefine the security baseline. Both must be present and must not conflict.
**How to verify:** Intune → **Endpoint security → Security baselines** (or your settings-catalog
security profile) is assigned to `EPIC – Clinical Workstations` and reports compliant; confirm no
setting collides with this solution's power/timeout settings.
**How to implement if missing:** Deploy the approved security baseline first, then layer this
solution's standardization profile, resolving any setting conflicts in favor of the security
baseline. See global requirement G2/G4.

## R9. Target operating system — Windows 10 / Windows 11
**Description:** Clinical endpoints run a supported, patched **Windows 10 (21H2+)** or **Windows 11**,
x64.
**Why required:** The settings catalog, Universal Print, and modern driver delivery require a current,
supported Windows build; profile **applicability/filter rules** will target these OS versions.
**How to verify:** `winver` on a device, or Intune → device → **Hardware**.
**How to implement if missing:** Patch via Update rings or upgrade devices. See global requirement G2.

## R10. A test clinical device (not in patient care), in a representative unit
**Description:** A representative, enrolled, non-production clinical device (ideally one fixed
workstation and one WOW) in a representative **unit**, added to the pilot group.
**Why required:** The baseline, printer order, per-unit default printer, and peripheral recognition
must be proven before any device in care receives them.
**How to verify:** The device is enrolled, compliant, in the pilot group, and in (or representing)
the target unit's per-unit group.
**How to implement if missing:** Set aside the device and add it to the pilot and per-unit groups.
See global requirement G7.

## R11. Approved clinical change window and rollback plan
**Description:** A change-control approval, an agreed **clinical maintenance window** for the expand
phase, and a documented **rollback** (revert to the previously validated profile + printer mapping).
**Why required:** Standardizing and re-mapping printers touches patient-care devices; it must be
change-managed, windowed, and reversible.
**How to verify:** A CAB-approved change ticket exists with window and back-out plan, naming the
previously validated profile and per-unit default printer to revert to.
**How to implement if missing:** Route through your CAB; keep the prior validated profile export and
printer mapping for rollback. See global requirements G4, G5, G8.

## R12. Imprivata present (only if badge readers feed SSO / badge-tap)
**Description:** If your clinical endpoints use **Imprivata** for single sign-on / badge-tap, confirm
the Imprivata agent is installed and healthy on the test device, so that the **badge/proximity
reader** this solution deploys is consumed correctly.
**Why required:** This solution makes the OS recognize the badge reader; Imprivata is what turns a tap
into a logon. You must confirm the reader is recognized and tap-to-launch still works after the
peripheral deployment. (Imprivata configuration itself is a separate solution.)
**How to verify:** On the test device, confirm the badge reader enumerates, the Imprivata agent
service is running, and a badge tap behaves as expected (Testing §, Test 6).
**How to implement if missing:** Engage the separate Imprivata solution / your Imprivata
administrators. If you do **not** use Imprivata, this requirement is N/A for SSO — the reader is still
deployed and validated as a recognized device.

---

## Requirements checklist (use before standardizing)
- [ ] **R1** Intune configuration + app rights (Intune Administrator / scoped roles)
- [ ] **R2** `EPIC – Clinical Workstations` + per-unit groups `EPIC – Clinical Workstations – <UNIT>`
- [ ] **R3** Printer delivery method decided per class (Universal Print vs scripted install)
- [ ] **R4** Universal Print licensed + printers registered/shared (if using Universal Print)
- [ ] **R5** Print queue paths / IPs + signed drivers (if using scripted install) — `EPICWS-Discovery.ps1`
- [ ] **R6** Peripheral drivers/apps packaged (scanner, signature pad, badge reader) — `EPICWS-Validation.ps1`
- [ ] **R7** Epic EPS host + queue names + workflow/printer mapping + per-unit default from Epic TS/UserWeb
- [ ] **R8** Windows security baseline applied alongside this baseline
- [ ] **R9** Supported, patched Windows 10/11 (x64)
- [ ] **R10** Test clinical device (fixed + WOW) in a representative unit + pilot group
- [ ] **R11** CAB-approved change window + rollback to prior validated profile/mapping
- [ ] **R12** Imprivata agent healthy on test device (only if badge readers feed SSO)
