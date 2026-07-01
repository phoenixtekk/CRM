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
