# Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

> **Version 1.0.0** · Category: Healthcare Solutions · Solution code: EPICWS

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

## The problem

Clinical Windows workstations that run Epic — nurse stations, exam-room PCs, medication-room and registration desks — drift apart over time. Each was imaged at a different point, joined by a different technician, and hand-configured with whatever printers and peripherals were near it that day. The result is a fleet where the same Epic workflow behaves differently from one room to the next: a wristband prints to the wrong tray, a script routes to a document printer three doors down, a signature pad is unrecognised at registration, and the workstation a float nurse sits at logs them out before they finish charting. Every inconsistency becomes a help-desk ticket, and in a clinical setting every ticket is a delay at the point of care.

This solution removes that drift. It defines a single, repeatable device baseline for clinical workstations and delivers it entirely through Microsoft Intune — configuration profiles, the settings catalog, power and display behaviour, and a documented reference to the organisation's Windows security baseline. On top of that baseline it builds the **clinical peripheral and printing layer** that Epic workflows depend on: context-aware printer deployment for wristband and label printers, prescription/script printers, and document printers; a correct **default printer per unit or department**; and the supporting peripherals — scanners, signature pads, and badge/proximity readers — installed and validated the same way on every device.

## The approach

The work follows a disciplined, six-phase model — **Assess → Standardize → Deploy Peripherals/Printing → Pilot → Validate → Expand** — so that nothing reaches a live clinical floor before it has been proven on a pilot group. Devices are governed through a single Entra ID group, `EPIC – Clinical Workstations`, and every configuration profile, printer-deployment policy, and printer queue is named to a fixed convention so the fleet is self-documenting. Printer delivery is deliberate about the trade-off between **Universal Print** (cloud-native, no print server, requires the documented licensing and a registered printer or connector) and **scripted printer installation** (works with existing print servers and direct-IP queues), and the solution explains exactly when each applies.

Epic-internal values — the Epic Print Service / EPS configuration, queue names, and workflow-specific print settings — are owned by the customer's Epic Technical Services team and sourced from Epic UserWeb. This solution does not invent those values; it provides the standardization, deployment, and validation mechanics that carry them onto every workstation correctly and prove they landed.

## What you get

A complete, white-label implementation package: a solution overview, a no-assumptions requirements specification (with a category-wide global-requirements companion), a step-by-step implementation guide with full Intune navigation paths, a testing and validation plan, a best-practices reference, a troubleshooting guide, and a deliverables summary. Five production-ready PowerShell scripts handle discovery, per-device validation, fleet reporting, safe remediation, and printer-deployment mapping — all read-only or `-WhatIf` by default, so nothing changes in a clinical environment without an explicit, deliberate action.

## The outcome

Every clinical workstation presents the same Epic environment: the same baseline, the same printers in the same order, the right default printer for the room, and working peripherals — verified, repeatable, and expandable unit by unit across the organisation.


---


# 1. Solution Overview — Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

This solution gives you a single, repeatable way to **standardize clinical Windows workstations for
Epic workflows** using **Microsoft Intune** — a consistent device baseline (configuration profiles,
the settings catalog, power and display behavior) plus the **clinical peripheral and printing layer**
those workflows depend on: context-aware **printer deployment** (wristband/label, prescription/script,
and document printers), a correct **default printer per unit**, and the supporting peripherals —
scanners, signature pads, and badge/proximity readers — installed and validated the same way on every
device.

The work follows the **standard deployment model**: **Assess → Standardize → Deploy
Peripherals/Printing → Pilot → Validate → Expand**. Nothing reaches a live clinical floor before it
has been proven on a pilot group.

---

## What this solution delivers

- A **standardized device baseline** for clinical workstations, delivered through Intune
  **configuration profiles** and the **settings catalog**: power and display behavior tuned for
  always-on shared clinical devices, lock/timeout behavior, and a documented reference to your
  organization's Windows security baseline — all bound to one named device group.
- A **context-aware printer-deployment layer** that puts the **right printers, in the right order,
  with the right default**, on each workstation by unit/department — wristband/label printers,
  prescription/script printers, and document printers — delivered via **Universal Print** or
  **scripted printer installation**, whichever fits your print infrastructure.
- A **clinical peripheral layer**: document **scanners**, **signature pads** (registration /
  consent), and **badge / proximity readers**, with their drivers/apps packaged and deployed through
  Intune and validated on every device.
- A **validation gate** (documented tests plus PowerShell scripts) that confirms the baseline
  applied, the correct printers and default printer are present per unit, and the peripherals are
  recognized — before the rollout is allowed to expand.
- Five PowerShell tools (discovery, per-device validation, fleet reporting, safe remediation, and
  printer-deployment mapping) to operate the standard day to day — all read-only or `-WhatIf` by
  default.

## Devices in scope

- **Clinical workstations** — nurse stations, medication-room and registration desks.
- **Exam-room PCs** and other shared clinical endpoints.
- **Workstations-on-wheels (WOWs)** / mobile carts where they share the same Epic workflows.

These are typically **shared, multi-user, always-on** devices on a clinical network. That is exactly
why a single named baseline, deterministic printer order, a correct per-unit default printer, and a
validated pilot-then-expand rollout matter more here than on a standard office fleet.

## What is in scope vs. referenced only

**In scope (this solution):** the Intune **device standardization** (configuration profiles, settings
catalog, power/display), the **printer-deployment and default-printer-per-unit** layer (Universal
Print vs scripted install), the **peripheral** (scanner / signature pad / badge reader) deployment,
and the validation that proves all of it landed.

**Referenced only (covered in depth by separate solutions):**
- **Epic client packaging and lifecycle** (Hyperdrive/Hyperspace install, version pinning,
  supersedence) — this solution standardizes the *workstation and its peripherals around* the Epic
  client, not the client package itself.
- **Imprivata** single sign-on / badge-tap / EPCS — referenced where a **badge/proximity reader**
  must be recognized by the OS; the SSO configuration itself is a separate solution.
- **The Windows security baseline** — referenced as a named prerequisite to apply alongside this
  baseline, not redefined here.

## Critical accuracy note — get the Epic print specifics from your Epic team

The **Epic Print Service (EPS)** configuration, the **Epic print queue names**, the
**workflow-specific print settings** (which queue a wristband, a script, or a document routes to),
and the mapping of Epic departments to physical printers are defined in **Epic's customer-only
documentation (UserWeb)** and by **your organization's Epic Technical Services / client systems
team**. This solution **does not invent** those Epic-internal values — and you should not either.

Throughout the Implementation Guide you will see placeholders such as `<EPS_SERVER>`,
`<EPIC_QUEUE_WRISTBAND>`, `<EPIC_QUEUE_SCRIPT>`, `<EPIC_QUEUE_DOC>`, and `<UNIT_DEFAULT_PRINTER>`.
**Obtain the real values from your Epic team / Epic UserWeb** and substitute them consistently. The
Intune mechanics around those values — configuration profiles, printer-deployment policy, Universal
Print vs scripted install, driver packaging, and validation — are documented here exactly and
accurately.

## Why this approach

- **Clinical consistency at the point of care:** when every workstation in a unit presents the same
  baseline, the same printers in the same order, and the right default printer for the room, an Epic
  workflow behaves identically wherever a clinician sits — fewer mis-prints, fewer logon surprises,
  fewer tickets.
- **Deterministic printing:** a wristband must print to the wristband printer and a script to the
  script printer, every time. Naming the printer-deployment policy and default per unit, and
  validating it, makes that deterministic rather than incidental.
- **Safe rollout:** pilot-then-expand with a named device group contains the blast radius of any
  baseline or printer change to a small, validated set of clinical endpoints before it reaches the
  floor.

## How to use this package

Read the documents in order:
1. **02 – Requirements** and **global-requirements-healthcare-solutions** — confirm everything is in
   place before you configure anything.
2. **03 – Implementation** — standardize the baseline, deploy printers/peripherals, pilot, validate,
   then expand.
3. **05 – Testing** — the acceptance gate that must pass before expansion.
4. **07 – Best Practices**, **08 – Deliverables Summary**, and **06 – Troubleshooting** as needed.


---


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


---


# Global Requirements — Healthcare Solutions (category-level)

These requirements apply to **every** solution in the **Healthcare Solutions** category. They are
published once at the category level so individual solution listings stay focused. Confirm all of
them are in place before deploying *any* Healthcare Solutions product into a clinical environment.

Each entry: **Description · Why required · How to verify · How to implement if missing.**

> Clinical environments carry obligations (HIPAA, often HITRUST) and uptime expectations that a
> standard office fleet does not. Treat every change as a controlled clinical change, not an ad-hoc
> IT task.

## G1. Microsoft 365 / Intune tenant with admin roles
**Description:** An active Microsoft Entra ID tenant with a Microsoft Intune subscription, and an
operator holding **Intune Administrator** (or **Application Manager** / **Endpoint Security Manager**
as appropriate).
**Why:** Intune is the delivery channel for every configuration and application in this category;
authoring profiles, apps, and assignments requires elevated rights.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows an
active subscription; Entra → **Roles and administrators** shows the operator's role.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1; assign the
operator **Intune Administrator**. Reserve Global Administrator for tenant-wide setup only.

## G2. Windows licensing for managed clinical endpoints
**Description:** Targeted devices run a supported, licensed **Windows 10 / Windows 11**
(Enterprise or Pro) with current cumulative updates.
**Why:** Modern Intune configuration, app-management, and printing features assume a patched,
supported OS.
**Verify:** `winver` on a device, or Intune → device → **Hardware**.
**Implement:** Apply correct Windows licensing; deploy **Update rings**
(Intune → **Devices → Windows → Update rings**) or upgrade devices to a supported build.

## G3. Devices enrolled and identity-joined
**Description:** Clinical endpoints are **Intune-enrolled** and **Microsoft Entra joined** (or
**hybrid Entra joined** where co-managed with Configuration Manager).
**Why:** Policies, profiles, and apps only reach enrolled, identity-bound devices, and assignments
are scoped to Entra device groups.
**Verify:** Intune → **Devices → All devices** (device present, compliant); on the device
`dsregcmd /status` shows `AzureAdJoined : YES` (or `DomainJoined : YES` + `AzureAdJoined : YES` for
hybrid).
**Implement:** Enroll via Autopilot or **Settings → Accounts → Access work or school**; for hybrid,
configure Entra Connect + group policy / co-management.

## G4. HIPAA / HITRUST data-handling and clinical change control
**Description:** A documented change-control process for clinical endpoints, and data-handling that
keeps **electronic protected health information (ePHI)** in-bounds — no ePHI in logs, exports, or
script output; least-privilege access; auditable changes.
**Why:** Clinical endpoints handle ePHI; uncontrolled changes risk both patient safety and
HIPAA / HITRUST compliance. Every standardization, printer, and peripheral change must be
change-managed and auditable.
**Verify:** Confirm a change ticket / change-advisory-board (CAB) approval exists for the deployment;
confirm the scripts and reports in use do **not** capture patient data (the tools in this category
are read-only over device/printer/app state, not over clinical content).
**Implement:** Route the change through your CAB; record the approved change window, rollback plan,
and back-out criteria; restrict who can run deployment actions; retain change records per your
compliance program.

## G5. Clinical maintenance windows
**Description:** Approved, low-acuity maintenance windows during which clinical endpoints may be
reconfigured, have printers re-mapped, or be rebooted, agreed with clinical operations.
**Why:** Pushing a profile, printer change, or reboot during patient care is unacceptable; shared
clinical devices are often in use around the clock.
**Verify:** A documented maintenance-window schedule exists and is referenced in the change ticket.
**Implement:** Agree windows with clinical operations / nursing leadership; align Intune assignment
**availability** and any restart behavior to those windows.

## G6. Network access to Microsoft and clinical service endpoints
**Description:** Outbound HTTPS from clinical endpoints to **Microsoft 365 / Entra / Intune** service
URLs and **Universal Print** endpoints, plus reachability to any **on-premises print servers /
direct-IP printer queues** and the **Epic Print Service (EPS)** host the workflows use.
**Why:** Enrollment, policy sync, profile and app delivery, Universal Print, and scripted printer
installation all depend on these network paths.
**Verify:** From a device, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`; for Universal Print reach `*.print.microsoft.com`; for
scripted install, confirm the print server / printer IP is reachable; confirm profile and app
deployments report **Succeeded** in Intune.
**Implement:** Allow Microsoft's published Office 365 / Intune / Universal Print URL & IP ranges, and
the print-server / printer / EPS endpoints your build team specifies, through proxy / firewall.

## G7. A non-production / test clinical device
**Description:** At least one **dedicated test device** representative of the clinical fleet (ideally
one of each form factor — a fixed workstation and a WOW), in a representative **unit**, that is
**not in live patient care**.
**Why:** Every baseline, printer-deployment, and peripheral change is proven on a test device before
any pilot or broad assignment touches a device used for care.
**Verify:** The test device is enrolled, in the pilot group, located in (or representing) the target
unit, and flagged as non-production.
**Implement:** Set aside a representative device; add it to the pilot group used by the solution.

## G8. Rollback posture
**Description:** A defined back-out plan for every change: how to revert a configuration profile, how
to restore the previous printer-deployment / default-printer mapping, and the criteria that trigger a
rollback.
**Why:** In a clinical setting a failed change must be reversible quickly to protect care delivery.
**Verify:** The change ticket includes a rollback plan and names the previously-validated profile /
printer mapping to revert to.
**Implement:** Keep the prior validated profile assignments and printer-deployment policy (export the
settings catalog profile and record the prior per-unit default printer); document the revert steps
(re-assign prior profile / remove the new assignment) before deploying the new one.

---
**The standard deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.**
For workstation-standardization solutions in this category this is realized as
**Assess → Standardize → Deploy Peripherals/Printing → Pilot → Validate → Expand**.


---


# 3. Implementation Guide — Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

This guide is ordered. Follow the phases in sequence:
**Assess → Standardize → Deploy Peripherals/Printing → Pilot → Validate → Expand.** Every step gives
the **full Intune admin center navigation path** and names every object to a fixed convention so the
fleet stays self-documenting. Do not skip the requirements check (**02-requirements.md** +
**global-requirements-healthcare-solutions.md**) before starting.

> **Named objects (reused verbatim throughout):**
> - **Device group (population):** `EPIC – Clinical Workstations`
> - **Per-unit device groups:** `EPIC – Clinical Workstations – <UNIT>`
> - **Standardization profile:** `EPIC – Clinical Workstations – Baseline` (settings catalog)
> - **Power/display profile:** `EPIC – Clinical Workstations – Power & Display`
> - **Printer-deployment policy:** `EPIC – Clinical Workstations – Printers – <UNIT>`
> - **Default-printer setting:** `EPIC – Clinical Workstations – Default Printer – <UNIT>`
> - **Peripheral apps:** `EPIC – Peripheral – Signature Pad`, `EPIC – Peripheral – Document Scanner`,
>   `EPIC – Peripheral – Badge Reader`
>
> **Epic-specific values** (`<EPS_SERVER>`, `<EPIC_QUEUE_WRISTBAND>`, `<EPIC_QUEUE_SCRIPT>`,
> `<EPIC_QUEUE_DOC>`, `<UNIT_DEFAULT_PRINTER>`) and **print endpoints** (`\\<PRINTSERVER>\<SHARE>` /
> direct-IP) come from your **Epic team / print team** — substitute them; never invent them.

---

## Phase A — Assess

### Step 1 — Confirm prerequisites and capture the baseline state
**Description:** Verify the requirements and record the current state of a representative device.
**Why:** You cannot prove standardization worked without a documented "before."
**Verify / Implement:** Walk **02-requirements.md** R1–R12. On the test device run
**`EPICWS-Discovery.ps1`** to inventory installed printers, default printer, peripheral
drivers/services, and current power/timeout settings. Save the output as the pre-change baseline and
attach it to the change ticket (G4).

### Step 2 — Confirm the device groups exist
**Description:** Ensure the population group and the per-unit groups exist.
**Why:** Baseline profiles target the population group; printers and the default printer target the
per-unit groups.
**Implement:** Intune admin center (`https://intune.microsoft.com`) → **Groups → All groups** →
confirm **`EPIC – Clinical Workstations`** and **`EPIC – Clinical Workstations – <UNIT>`** for each
in-scope unit. If missing, **+ New group** → **Security**, membership type **Dynamic Device** (rule on
the unit's device-name prefix) or **Assigned**, enter the name and description, **Create**. (R2)

### Step 3 — Decide and record printer delivery method per printer class
**Description:** For wristband/label, script, and document printers, decide **Universal Print** or
**scripted install** (R3).
**Why:** The objects you create in Phase C differ by method.
**Implement:** Record the decision per class. If Universal Print, confirm registration: **portal.azure.com
→ Universal Print → Printers** shows each printer **Shared** (R4). If scripted, confirm the share
path / IP and the signed driver are ready (R5).

---

## Phase B — Standardize (the device baseline)

### Step 4 — Create the standardization profile (settings catalog)
**Description:** Build the baseline device-experience profile.
**Why:** This is the single source of the consistent clinical-workstation experience.
**Implement:**
1. Intune admin center → **Devices → Configuration** → **+ Create** → **New Policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Settings catalog**. **Create**.
3. **Name:** `EPIC – Clinical Workstations – Baseline`. **Description:** "Standard clinical workstation
   experience for Epic — power/display/lock behavior. Managed by the standard deployment model." **Next.**
4. **Configuration settings → + Add settings.** Add the agreed clinical settings (examples — confirm
   against your security baseline, R8): screen-lock / inactivity timeout aligned to clinical policy,
   notification/UX suppression, and any required local-experience settings. Do **not** duplicate
   settings already owned by the security baseline.
5. **Next** through Scope tags → **Assignments**: do not assign yet (Phase D pilots first). **Next →
   Create.**

### Step 5 — Create the power & display profile
**Description:** Tune power/sleep/display so always-on shared clinical devices do not sleep mid-shift.
**Why:** A workstation that sleeps or turns off the display in a patient room interrupts care and
generates tickets; this must be identical across the fleet.
**Implement:**
1. **Devices → Configuration → + Create → New Policy** → Windows 10 and later → **Settings catalog**
   → **Create**.
2. **Name:** `EPIC – Clinical Workstations – Power & Display`. **Description** as above. **Next.**
3. **+ Add settings** → search **Power** → set, for plugged-in clinical workstations: turn off
   display after the clinically agreed interval (not 0/never unless policy requires), **never sleep**,
   disable hibernate, and the agreed lid/idle behavior for WOWs. **Next.**
4. Scope tags → **Assignments**: leave unassigned for now → **Next → Create.**

### Step 6 — Confirm the security baseline is applied (do not redefine it)
**Description:** Verify the Windows security baseline is present alongside this baseline (R8).
**Why:** This solution layers experience settings on top of, never instead of, security.
**Implement:** **Endpoint security → Security baselines** → open your assigned baseline → confirm it
targets `EPIC – Clinical Workstations` and reports compliant. Resolve any conflict with Steps 4–5 in
favor of the security baseline. If missing, deploy it first.

---

## Phase C — Deploy Peripherals / Printing

### Step 7 — Deploy clinical peripheral drivers/apps
**Description:** Make every workstation recognize the scanner, signature pad, and badge reader (R6).
**Why:** Standardization means these peripherals are installed and validated the same way everywhere.
**Implement (per peripheral):**
1. Intune admin center → **Apps → Windows** → **+ Add** → app type **Windows app (Win32)**.
2. Upload the vendor's `.intunewin` (wrap the signed driver/installer with the Microsoft Win32 Content
   Prep Tool first). **Next.**
3. **Name** the app exactly: `EPIC – Peripheral – Signature Pad` (repeat for
   `EPIC – Peripheral – Document Scanner`, `EPIC – Peripheral – Badge Reader`). **Next.**
4. **Program:** silent **Install command** and **Uninstall command** from the vendor. **Next.**
5. **Requirements:** Windows 10/11, x64 (R9). **Next.**
6. **Detection rules:** the vendor's installed file/version or registry key (the value
   `EPICWS-Validation.ps1` checks). **Next** through Dependencies/Supersedence.
7. **Assignments → Required** → **+ Add group** → `EPIC – Clinical Workstations`. **Next → Create.**

### Step 8 — Deploy printers via Universal Print (if chosen, R3/R4)
**Description:** Push the registered Universal Print printers to each unit's devices.
**Why:** Universal Print gives a cloud-native printer deployment with no print server.
**Implement (per unit):**
1. Intune admin center → **Devices → Windows → (Manage devices) → Configuration** → **+ Create** →
   Windows 10 and later → **Templates** → **Universal Print printer** → **Create**. *(If your tenant
   surfaces it under **Apps → Universal Print** or **Printers**, use that blade — the object is the
   same.)*
2. **Name:** `EPIC – Clinical Workstations – Printers – <UNIT>`. **Description:** "Unit printer set —
   wristband/script/document — Universal Print. Standard deployment model." **Next.**
3. **+ Add printer** → select the unit's **wristband/label**, **script**, and **document** printers
   (the Universal Print shares mapped to `<EPIC_QUEUE_WRISTBAND>` / `<EPIC_QUEUE_SCRIPT>` /
   `<EPIC_QUEUE_DOC>` per R7). **Next.**
4. Scope tags → **Assignments → + Add group** → `EPIC – Clinical Workstations – <UNIT>`. **Next →
   Create.** Repeat per unit.

### Step 9 — Deploy printers via scripted install (if chosen, R3/R5)
**Description:** Install the unit's printers from print-server shares / direct IP with a platform
script.
**Why:** Scripted install works with existing print servers and direct-IP clinical printers without
Universal Print.
**Implement (per unit):**
1. Generate the per-unit script with **`EPICWS-Set-PrinterDeployment.ps1 -Unit <UNIT> -Mode Script
   -WhatIf`** (preview), then without `-WhatIf` to emit the install script naming each queue
   (`\\<PRINTSERVER>\<SHARE>` or `Add-Printer -PortName IP_<addr>`), in **wristband → script →
   document** order, and setting `<UNIT_DEFAULT_PRINTER>` as default.
2. Intune admin center → **Devices → Windows → Scripts and remediations → Platform scripts** → **+
   Add → Windows 10 and later**.
3. **Name:** `EPIC – Clinical Workstations – Printers – <UNIT>`. **Next.**
4. Upload the generated script; **Run this script using the logged-on credentials = No** (run as
   system for machine-wide printers); **Enforce script signature check** per your policy; **Run script
   in 64-bit** = Yes. **Next.**
5. Scope tags → **Assignments → + Add group** → `EPIC – Clinical Workstations – <UNIT>`. **Next →
   Add.** Repeat per unit.

### Step 10 — Set the correct default printer per unit
**Description:** Make the right printer the default for each unit's workstations.
**Why:** The default printer is what an Epic document/print dialog targets when the clinician does not
choose — it must be the unit's intended default (`<UNIT_DEFAULT_PRINTER>`, R7), or work routes to the
wrong room.
**Implement:**
- **Universal Print path:** in the unit's printer-deployment policy (Step 8) mark
  `<UNIT_DEFAULT_PRINTER>` as the **default**.
- **Scripted path:** the generated script (Step 9) already issues the default-printer command; confirm
  it names `<UNIT_DEFAULT_PRINTER>`.
- Either way create/confirm the tracking object name `EPIC – Clinical Workstations – Default Printer –
  <UNIT>` so the mapping is documented per unit.

---

## Phase D — Pilot

### Step 11 — Assign everything to the pilot
**Description:** Assign the baseline, power/display, peripherals, and one unit's printers to the pilot
device only.
**Why:** Prove the full standard on a non-production device (G7, R10) before any device in care
receives it.
**Implement:**
1. For `EPIC – Clinical Workstations – Baseline` and `EPIC – Clinical Workstations – Power & Display`:
   **Devices → Configuration** → open each → **Properties → Assignments → Edit** → add a **pilot**
   group (or add only the test device to `EPIC – Clinical Workstations` initially). **Review + save.**
2. Confirm the peripheral apps (Step 7) and the pilot unit's printer policy (Step 8/9) reach the test
   device.
3. On the test device run `gpupdate`-equivalent sync: **Settings → Accounts → Access work or school →
   Info → Sync**, or in Intune open the device → **Sync**.

### Step 12 — Wait for apply and observe
**Description:** Let policies, apps, and printers land; watch for failures.
**Why:** Catch errors on one device, not the floor.
**Implement:** Intune → **Devices → All devices →** test device → **Device configuration** (profiles
**Succeeded**), **Managed Apps** (peripheral apps **Installed**), and the printer policy status.
Investigate anything not **Succeeded/Installed** before validating.

---

## Phase E — Validate

### Step 13 — Run the validation gate on the pilot device
**Description:** Confirm the standard actually landed.
**Why:** Validation is the gate; do not expand on a partial result.
**Implement:** On the pilot device run
**`EPICWS-Validation.ps1 -Unit <UNIT> -ExpectedDefault "<UNIT_DEFAULT_PRINTER>"`**. It checks:
baseline/power settings applied, the unit's wristband/script/document printers present in the right
order, the **default printer** equals `<UNIT_DEFAULT_PRINTER>`, and the scanner / signature pad /
badge reader recognized. Then perform the clinical print tests in **05-testing.md** (a real wristband,
script, and document from Epic land on the intended physical printers, per `<EPS_SERVER>` mapping).
The overall verdict must be **PROVISIONED** with all clinical tests PASS before Phase F.

### Step 14 — Capture the validated state as the rollback reference
**Description:** Record the proven configuration for back-out (G8, R11).
**Why:** A clinical change must be reversible.
**Implement:** Export the two settings-catalog profiles (**… → Export JSON** where available, or
record settings), and run **`EPICWS-Report.ps1`** to CSV for the pilot. File both with the change
ticket as the "known-good" reference.

---

## Phase F — Expand

### Step 15 — Expand to the rest of the unit, then unit by unit
**Description:** Broaden assignment from the pilot to full units, in the change window.
**Why:** Controlled expansion contains risk; each unit needs its own default printer and printer set.
**Implement:**
1. In your approved **maintenance window** (G5, R11), change the baseline / power profile assignments
   to target the full `EPIC – Clinical Workstations` group.
2. For each additional unit, repeat Steps 8–10 to create
   `EPIC – Clinical Workstations – Printers – <UNIT>` and the unit default, assigned to
   `EPIC – Clinical Workstations – <UNIT>`.
3. After each unit, re-run **`EPICWS-Validation.ps1 -Unit <UNIT>`** on a sample device and a clinical
   print test before moving to the next unit.

### Step 16 — Operationalize
**Description:** Move from project to steady state.
**Why:** Standardization only holds if drift is monitored.
**Implement:** Schedule **`EPICWS-Report.ps1`** (CSV) periodically to detect drift (wrong default
printer, missing peripheral, profile not applied); triage with **`EPICWS-Remediation.ps1`** (read-only
/ `-WhatIf` first, `-Apply` in a window). See **07-best-practices.md**.

---

> **Reminder:** the Epic Print Service host, queue names, and workflow/printer mapping
> (`<EPS_SERVER>`, `<EPIC_QUEUE_*>`, `<UNIT_DEFAULT_PRINTER>`) come from your Epic team / Epic
> UserWeb. The Intune standardization, printer-deployment (Universal Print vs scripted), peripheral
> deployment, and validation mechanics above are exact; substitute the Epic/print values consistently.


---


# 5. Testing & Validation — Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

This is the **acceptance gate**. Run every test on the **pilot device** (Implementation Phase E)
before expanding, and re-run the unit-specific tests on a sample device after each unit in Phase F.
Each test has an explicit **PASS / FAIL** condition. The rollout may expand only when **all tests
PASS** (or are justified N/A).

> The PowerShell tool **`EPICWS-Validation.ps1`** automates Tests 1–5; the **clinical print tests**
> (Tests 7–9) and the **Imprivata tap test** (Test 6) require a person at the device because they
> confirm an Epic workflow lands on a physical printer. Tools report device/printer state only — never
> patient data (G4).

---

## Test 1 — Standardization baseline applied
**Goal:** The `EPIC – Clinical Workstations – Baseline` settings-catalog profile applied.
**Steps:** Intune → **Devices → All devices →** device → **Device configuration**; and run
`EPICWS-Validation.ps1`.
**PASS:** Profile status **Succeeded**; the validation script reports the baseline settings present.
**FAIL:** Profile **Error/Conflict**, or settings not present → resolve conflict (often the security
baseline, R8) and re-sync.

## Test 2 — Power & display behavior correct
**Goal:** The workstation does not sleep / turn off display contrary to clinical policy.
**Steps:** Confirm `EPIC – Clinical Workstations – Power & Display` is **Succeeded**; on the device
check `powercfg /q` (or the script's power read) for never-sleep and the agreed display timeout.
**PASS:** Sleep disabled, hibernate disabled, display timeout = the clinically agreed value.
**FAIL:** Device sleeps or display times out off-policy → correct the profile and re-test.

## Test 3 — Unit printers present in the correct order
**Goal:** The wristband/label, script, and document printers for the unit are installed.
**Steps:** Run `EPICWS-Validation.ps1 -Unit <UNIT>`; or `Get-Printer` on the device.
**PASS:** All three printer classes present, named to the unit's mapping, in **wristband → script →
document** order.
**FAIL:** A printer missing or mis-ordered → re-check the Step 8/9 deployment for that unit and
re-sync.

## Test 4 — Default printer equals the unit default
**Goal:** The default printer is `<UNIT_DEFAULT_PRINTER>` for this unit.
**Steps:** Run `EPICWS-Validation.ps1 -Unit <UNIT> -ExpectedDefault "<UNIT_DEFAULT_PRINTER>"`; or
`Get-CimInstance Win32_Printer | ? Default`.
**PASS:** Default printer = `<UNIT_DEFAULT_PRINTER>`.
**FAIL:** Wrong default → re-apply Step 10 for the unit and re-test.

## Test 5 — Clinical peripherals recognized
**Goal:** The scanner, signature pad, and badge/proximity reader are installed and recognized.
**Steps:** Run `EPICWS-Validation.ps1` (peripheral driver/service checks); confirm Device Manager
shows no unknown device for these peripherals.
**PASS:** Each in-scope peripheral's driver/service present; no unknown device.
**FAIL:** A peripheral unrecognized → confirm its Win32 app shows **Installed** (Step 7) and the
device is connected; re-deploy/re-test.

## Test 6 — Badge reader feeds SSO (only if using Imprivata, R12)
**Goal:** The deployed badge/proximity reader is consumed by Imprivata for tap behavior.
**Steps:** With the Imprivata agent running, tap an enrolled badge at the device.
**PASS:** The tap behaves as configured (logon / fast-user-switch) and tap-to-launch into Epic works.
**FAIL:** Reader recognized (Test 5) but tap does nothing → engage the separate Imprivata solution. If
not using Imprivata, mark **N/A** (Test 5 still governs reader recognition).

## Test 7 — Epic wristband prints to the wristband printer
**Goal:** A real Epic wristband print job lands on the wristband/label printer.
**Steps:** From Epic on the device, print a test wristband to the workflow's wristband queue
(`<EPIC_QUEUE_WRISTBAND>` via `<EPS_SERVER>`).
**PASS:** The wristband prints on the unit's **wristband/label** printer, correctly formatted.
**FAIL:** Wrong printer or no output → re-check the Epic queue→printer mapping (R7) with your Epic team
and the printer deployment.

## Test 8 — Epic script/prescription prints to the script printer
**Goal:** A script/prescription job lands on the script printer.
**Steps:** From Epic, print a test script to `<EPIC_QUEUE_SCRIPT>`.
**PASS:** The script prints on the unit's **prescription/script** printer.
**FAIL:** Wrong printer → re-verify mapping (R7) and deployment; re-test.

## Test 9 — Epic document prints to the document printer / default
**Goal:** A general document job lands on the document printer (the unit default).
**Steps:** From Epic, print a test document to `<EPIC_QUEUE_DOC>` (and a no-queue-specified print to
confirm it uses the default).
**PASS:** The document prints on the unit's **document** printer; default-routed jobs use
`<UNIT_DEFAULT_PRINTER>`.
**FAIL:** Wrong printer/default → re-verify Steps 8–10 and mapping; re-test.

## Test 10 — Repeatability across form factors
**Goal:** A fixed workstation **and** a WOW in the same unit produce identical results.
**Steps:** Repeat Tests 1–9 on one of each form factor.
**PASS:** Both devices present the same baseline, printers, default, and recognized peripherals.
**FAIL:** Divergence → reconcile group membership/assignment so both are in the same unit/population
groups; re-test.

---

## Acceptance gate (must hold before Phase F expansion)
- [ ] **T1** Baseline profile **Succeeded** / settings present
- [ ] **T2** Power/display per clinical policy (never-sleep, agreed display timeout)
- [ ] **T3** Unit printers present, correct order
- [ ] **T4** Default printer = `<UNIT_DEFAULT_PRINTER>`
- [ ] **T5** Scanner + signature pad + badge reader recognized
- [ ] **T6** Badge tap feeds SSO (or N/A)
- [ ] **T7** Wristband → wristband printer
- [ ] **T8** Script → script printer
- [ ] **T9** Document → document printer; default-routed → unit default
- [ ] **T10** Fixed workstation and WOW identical

`EPICWS-Validation.ps1` must report **PROVISIONED**, and Tests 6–10 must PASS (or be justified N/A),
before any device in patient care is added in Phase F.


---


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


---


# 7. Best Practices — Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

Operating practices that keep clinical workstations standardized, printing deterministic, and changes
safe in a live clinical environment. They assume the named objects and phase model from
**03-implementation.md**.

---

## Naming and self-documentation
- **Reuse the naming convention verbatim**: `EPIC – Clinical Workstations` (population),
  `EPIC – Clinical Workstations – <UNIT>` (per-unit), `EPIC – Clinical Workstations – Baseline`,
  `… – Power & Display`, `… – Printers – <UNIT>`, `… – Default Printer – <UNIT>`, and
  `EPIC – Peripheral – <Device>`. The pattern `<Purpose> – <Scope> – <Stage>` makes the fleet
  auditable at a glance.
- **One profile, one purpose.** Keep baseline experience separate from power/display and separate from
  the security baseline. Mixed-purpose profiles are hard to roll back cleanly.

## Standardize through groups, not per-device clicks
- Bind everything to **device groups**; never hand-configure a printer or setting on an individual
  clinical workstation. The whole value of the standard is that it is reproducible.
- Prefer **dynamic device groups** keyed on a reliable unit naming prefix so a re-imaged device lands
  back in the right unit (and gets the right default printer) automatically.

## Printer delivery — choose deliberately, document the choice
- **Universal Print** when you want cloud-native delivery with no print server; budget for the
  licensing and either native Universal Print printers or the connector. **Scripted install** when you
  must work with existing print servers / direct-IP clinical printers. Record which method each
  printer class uses (R3) so troubleshooting starts from the right place.
- Deploy printers in a **deterministic order** — wristband → script → document — so the printer list a
  clinician sees is identical on every device in the unit.

## The default printer is a patient-safety control
- A wrong default printer routes a clinician's "just print" to the wrong room. Treat
  `<UNIT_DEFAULT_PRINTER>` as a controlled value per unit, validate it (Test 4) on every device, and
  monitor for drift with `EPICWS-Report.ps1`.
- Never let a Universal Print policy and a scripted script **both** set a default on the same device —
  pick one owner of the default per unit.

## Peripherals: package once, deploy everywhere
- Wrap each peripheral (signature pad, scanner, badge reader) as a **named Win32 app with a real
  detection rule** so Intune reports true install state. A peripheral that "works on the bench" but
  has no detection rule will silently fail to standardize.
- For **badge/proximity readers**, deploying the reader driver (OS recognition) and configuring
  **Imprivata** (tap behavior) are two separate jobs — keep them in their own solutions and validate
  the boundary (Test 5 vs Test 6).

## Respect the Epic / print-team boundary
- Never invent the EPS host, Epic queue names, or workflow→printer mapping. Source them from **Epic
  Technical Services / UserWeb** (R7) and substitute the placeholders consistently. Your job is the
  Intune + printer + peripheral mechanics that carry those values onto every device correctly.

## Clinical-environment safety
- **Pilot before expand, always.** Prove the full standard (baseline + printers + default +
  peripherals) on a non-production device before any device in care receives it.
- **Change windows and rollback.** Make assignment changes in approved maintenance windows (G5); keep
  the exported profile and prior per-unit default printer as the named rollback reference (G8) before
  each change.
- **Read-only first.** Run `EPICWS-Discovery.ps1`, `EPICWS-Validation.ps1`, and `EPICWS-Report.ps1`
  freely; run `EPICWS-Remediation.ps1` and `EPICWS-Set-PrinterDeployment.ps1` with `-WhatIf` first and
  only `-Apply` in a window.
- **No ePHI in tooling output.** The scripts report device/printer/app state only. Keep it that way —
  never extend them to read clinical content (G4).

## Hold the line against drift
- Schedule `EPICWS-Report.ps1` to CSV on a cadence and review for: profile not applied, missing
  printer, wrong default, missing peripheral. Drift is normal on shared clinical devices; catching it
  early is what keeps the fleet standardized.
- Re-validate after **any** unit change, re-image, or printer-infrastructure change.


---


# 8. Deliverables Summary — Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

This solution is delivered as a complete, click-to-implement package: implementation documentation, an
operational PowerShell toolkit, and a hero image.

## Documentation

| Document | Purpose |
|---|---|
| **executive-summary.md** | Business-level overview, value, and approach for decision-makers. |
| **01-solution-overview.md** | What the solution delivers, devices in scope, scope boundaries, and how to use the package. |
| **02-requirements.md** | Standardization/peripheral/printing-specific requirements (R1–R12), each with Description / Why / Verify / Implement, plus a checklist. |
| **global-requirements-healthcare-solutions.md** | Category-wide prerequisites: tenant + roles, Windows licensing, HIPAA/HITRUST change control, clinical maintenance windows, network (incl. Universal Print + print servers + EPS), test device, rollback. |
| **03-implementation.md** | Ordered, full-navigation steps: standardize the baseline + power/display, deploy peripherals, deploy printers (Universal Print or scripted) with a per-unit default, pilot, validate, then expand. |
| **05-testing.md** | Numbered tests with PASS/FAIL gates — baseline, power, printer order, default printer, peripherals, and live Epic wristband/script/document print tests — plus the acceptance gate. |
| **07-best-practices.md** | Operating practices for naming, group-driven standardization, Universal-Print-vs-scripted choice, the default printer as a safety control, peripheral packaging, and clinical-environment safety. |
| **06-troubleshooting.md** | Fixes for profile conflicts, devices that sleep, missing/mis-ordered printers, wrong default printer, Universal Print vs scripted issues, unrecognized peripherals, badge-reader/SSO boundary, and Epic-mapping mismatches. |

## PowerShell toolkit (`scripts\`)

| Script | What it does |
|---|---|
| **EPICWS-Discovery.ps1** | Inventories a device's installed printers, default printer, peripheral drivers/services, and power/timeout settings. Read-only. |
| **EPICWS-Validation.ps1** | Verifies the baseline applied, the unit's printers are present in order, the **default printer** equals the unit default, and the scanner/signature pad/badge reader are recognized; emits PASS/FAIL and an overall verdict. |
| **EPICWS-Report.ps1** | Produces a fleet standardization/drift report (per-device baseline, default printer, peripheral status) to **CSV**. |
| **EPICWS-Remediation.ps1** | Safely re-triggers an MDM sync / re-applies a named profile or app install-state nudge for a device. Read-only / `-WhatIf` by default; `-Apply` to act. |
| **EPICWS-Set-PrinterDeployment.ps1** | Generates/maps the per-unit printer deployment (Universal Print selection or a scripted-install script) and the per-unit default printer. Supports `-WhatIf`. |

Each script carries a `.SYNOPSIS` plus **PURPOSE / HOW TO RUN / EXPECTED RESULTS** in its header.

## Visual asset

| Asset | Purpose |
|---|---|
| **EPICWS-hero.png** | Hero image for the solution listing. |

## Named objects you create (reused verbatim across the docs and scripts)

- **Device groups:** `EPIC – Clinical Workstations`, `EPIC – Clinical Workstations – <UNIT>`
- **Configuration profiles:** `EPIC – Clinical Workstations – Baseline`,
  `EPIC – Clinical Workstations – Power & Display`
- **Printer-deployment policy:** `EPIC – Clinical Workstations – Printers – <UNIT>`
- **Default-printer object:** `EPIC – Clinical Workstations – Default Printer – <UNIT>`
- **Peripheral apps:** `EPIC – Peripheral – Signature Pad`, `EPIC – Peripheral – Document Scanner`,
  `EPIC – Peripheral – Badge Reader`

> Epic/print-specific values (`<EPS_SERVER>`, `<EPIC_QUEUE_WRISTBAND>`, `<EPIC_QUEUE_SCRIPT>`,
> `<EPIC_QUEUE_DOC>`, `<UNIT_DEFAULT_PRINTER>`, and print endpoints `\\<PRINTSERVER>\<SHARE>` /
> direct-IP) come from your **Epic team / print team** and are substituted consistently throughout.
