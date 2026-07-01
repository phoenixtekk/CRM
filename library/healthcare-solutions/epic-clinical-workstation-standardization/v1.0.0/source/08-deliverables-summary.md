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
