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
