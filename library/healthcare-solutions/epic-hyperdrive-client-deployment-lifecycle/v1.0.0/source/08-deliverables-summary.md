# 8. Deliverables Summary — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

This solution is delivered as a complete, click-to-implement package: implementation documentation, an
operational PowerShell toolkit, and a hero image.

## Documentation

| Document | Purpose |
|---|---|
| **executive-summary.md** | Business-level overview, value, and approach for decision-makers. |
| **01-solution-overview.md** | What the solution delivers, devices in scope, scope boundaries, and how to use the package. |
| **02-requirements.md** | Epic-deployment-specific requirements (R1–R11), each with Description / Why / Verify / Implement, plus a checklist. |
| **global-requirements-healthcare-solutions.md** | Category-wide prerequisites: tenant + roles, Windows licensing, HIPAA/HITRUST change control, clinical maintenance windows, network, test device, rollback. |
| **03-implementation.md** | Ordered, full-navigation steps: package the Win32 `.intunewin`, version-pinned detection, ring groups, pilot assign, validate, broad deploy, then lifecycle (supersede / retire). |
| **05-testing.md** | Numbered tests with PASS/FAIL gates and the acceptance gate that must pass before expansion. |
| **07-best-practices.md** | Operating practices for version pinning, ring discipline, WebView2, supersedence/retire, and clinical-environment safety. |
| **06-troubleshooting.md** | Fixes for install failures, detection mismatch, version drift, Hyperdrive/WebView2 launch issues, supersedence not upgrading, retire leftovers, and ring/assignment problems. |

## PowerShell toolkit (`scripts\`)

| Script | What it does |
|---|---|
| **EPICCLIENT-Discovery.ps1** | Inventories the installed Epic client version and basic health across managed devices. Read-only. |
| **EPICCLIENT-Validation.ps1** | Verifies a device has the **target version**, the app install state, and launch prerequisites (WebView2 for Hyperdrive); emits PASS/FAIL and an overall verdict. |
| **EPICCLIENT-Report.ps1** | Produces a fleet rollout / version report (per-ring counts, version spread) to **CSV**. |
| **EPICCLIENT-Remediation.ps1** | Safely re-triggers install or uninstall of a **named** Win32 app for a device (MDM sync / install-state nudge). Read-only / `-WhatIf` by default; `-Apply` to act. |
| **EPICCLIENT-Set-DeploymentRings.ps1** | Creates the **`Epic Hyperdrive – Pilot Ring`** and **`Epic Hyperdrive – Broad Ring`** Entra device groups and (optionally) wires ring assignments via Microsoft Graph. Supports `-WhatIf`. |

Each script carries a `.SYNOPSIS` plus **PURPOSE / HOW TO RUN / EXPECTED RESULTS** in its header.

## Visual asset

| Asset | Purpose |
|---|---|
| **EPICCLIENT-hero.png** | Hero image for the solution listing. |

## Named objects you create (reused verbatim across the docs and scripts)

- **Win32 app:** `Epic Hyperdrive – <EPIC_VERSION>` (legacy: `Epic Hyperspace – <EPIC_VERSION>`)
- **Detection rule:** `Epic Client – Version Detection`
- **Supersedence relationship:** `Epic Hyperdrive – Supersede <EPIC_VERSION>→<EPIC_VERSION_NEW>`
- **Entra device groups / rings:** `EPIC – Clinical Workstations`, `Epic Hyperdrive – Pilot Ring`,
  `Epic Hyperdrive – Broad Ring`

> Epic-specific values (`<EPIC_INSTALLER>`, `<EPIC_VERSION>`, `<EPIC_INSTALL_DIR>`, `<EPIC_EXE>`,
> `<EPIC_SILENT_ARGS>`, `<EPIC_UNINSTALL_CMD>`) come from your **Epic build team / Epic UserWeb** and
> are substituted consistently throughout.
