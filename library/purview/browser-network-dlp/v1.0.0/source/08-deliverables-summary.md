# Deliverables Summary — Browser & Network DLP in Microsoft Purview

Everything included in this solution, what each piece is for, and how it maps to the deployment model.
Use it as the table of contents and the "did we finish?" checklist.

## Documents

| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | What Browser & Network DLP delivers, how the Microsoft Purview browser extension + native Edge + unallowed browsers + sensitive service domains control web uploads, the simulate-first rule, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The solution-specific prerequisites (2.1–2.9): Endpoint DLP licensing, least-privilege DLP roles, the S&C PowerShell + Graph toolchain and read scopes, onboarded devices, the browser extension + browser coverage, in-scope labels/SITs, the unsanctioned/personal-cloud destination inventory, and a pilot ring in simulation — each with Verify / Implement-if-missing. References the category `global-requirements-purview.md`. |
| **03 — Implementation Guide** | The ordered build: assess tenant + endpoints → design condition/destinations/action ladder → confirm onboarding + extension → build the sensitive service domain group (Audit) + unallowed browsers → author the policy + upload rule **in simulation** → pilot & tune → validate → escalate to Warn/Block + expand. Every object named, with a pass/fail gate and rollback per phase. |
| **05 — Testing & Validation** | The pass/fail gates: licensing/availability, onboarding + browser coverage, dry-run makes no changes, policy created in simulation, sensitive upload detected (not over-matching), unallowed-browser steering, evidence captured, and a controlled enforcement transition. |
| **06 — Troubleshooting** | The failures you will actually hit — no upload activity at all, Chrome/Firefox invisible, false positives, the rule not firing, simulation-vs-enforce confusion, `New-DlpComplianceRule` errors, empty reports, and emergency rollback — each with cause and fix. |
| **07 — Best Practices** | How to run it well: simulate-then-enforce discipline, keying on sensitive content, curating the domain group and browser coverage, onboarding/extension hygiene, ongoing operation, and role/determination boundaries. |
| **Executive Summary** | The one-page business-level summary for stakeholders and sign-off. |

## PowerShell tools (5)

All are **read-only or `-WhatIf` by default**, use interactive modern-auth
(`Connect-IPPSSession` / `Connect-MgGraph`), and contain **no credentials**. They do **not** onboard
devices, deploy the browser extension, or script the portal-managed browser/domain settings, and do
**not** invent cmdlets.

| Script | Purpose | Safe default |
|---|---|---|
| **DLPBROWSER-Discovery.ps1** | Inventory existing DLP policies/rules and **Devices** coverage, read the Endpoint DLP browser/domain settings (sensitive service domain group + unallowed browsers) via `Get-PolicyConfig`, and list labels/SITs — the baseline of what already controls web uploads. | Read-only |
| **DLPBROWSER-Configure.ps1** | Build/ensure the `Browser & Network DLP – Devices – Pilot` policy and the `Restrict Upload to Unsanctioned Domains – Rule` **in simulation**; requires `-Commit` to write and supports `-WhatIf`. Prints the portal-managed domain-group / unallowed-browser steps. | `-WhatIf` (preview) |
| **DLPBROWSER-Validate.ps1** | Run the configuration gates (policy exists, Devices location, simulation-first, pilot scope, upload rule + content condition, domain-group/unallowed-browser readable) with PASS/FAIL/UNKNOWN output. | Read-only |
| **DLPBROWSER-Report.ps1** | Roll up policy modes and, where available, export **browser/network upload DLP** match & block events from Activity Explorer to CSV — the operational + evidence view. | Read-only |
| **DLPBROWSER-ScopeHealth.ps1** | Report device onboarding, browser-extension, network-path coverage and Endpoint DLP **licensing** readiness flags (Graph SKU + managed-device signals, pilot group, policy scope, checklist). | Read-only |

## How it maps to the deployment model

| Phase | Deliverables used |
|---|---|
| **Assess** | 01, 02, `DLPBROWSER-Discovery.ps1`, `DLPBROWSER-ScopeHealth.ps1` |
| **Design** | 02, 03 (named objects + action ladder), 07 |
| **Configure** | 03, `DLPBROWSER-Configure.ps1 -WhatIf` then `-Commit` (simulation); portal-managed domain group + unallowed browsers |
| **Pilot (simulation)** | 03, 05 (simulation pass), `DLPBROWSER-Report.ps1` |
| **Validate** | 05, `DLPBROWSER-Validate.ps1`, `DLPBROWSER-Report.ps1` |
| **Expand (enforce)** | 03 (Step 8), 05 (enforcement pass), 06, 07 |

## Definition of done

- Pilot devices **onboarded** and visible in **Purview → Devices**; Microsoft Purview browser extension
  deployed on Chrome/Firefox and Edge native coverage confirmed.
- Sensitive service domain group `Unsanctioned & Personal Cloud – Domain Group` built (starting action
  **Audit**) and the unallowed-browsers list set.
- `Browser & Network DLP – Devices – Pilot` with the upload-restriction rule built **in simulation**,
  all configuration gates PASS.
- Simulation pass complete (sensitive uploads detected, not over-matching, unallowed-browser steering
  works); false-positive tuning done; then the **enforcement pass** for Warn/Block per the approved
  design.
- **Evidence pack** (`DLPBROWSER-Report.ps1` export + Activity explorer + validation output) captured
  and stored with the change record.
- Regulatory / policy determinations (which data, which destinations, which action) recorded by the
  **compliance / security** owners — not by the administrator.
