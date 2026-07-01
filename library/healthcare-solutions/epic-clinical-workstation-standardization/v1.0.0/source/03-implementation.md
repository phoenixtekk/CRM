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
