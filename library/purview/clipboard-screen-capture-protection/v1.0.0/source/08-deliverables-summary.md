# Deliverables Summary — Clipboard & Screen-Capture Protection in Microsoft Purview

Everything included in this solution, what each piece is for, and how it maps to the deployment model. Use
it as the table of contents and the "did we finish?" checklist.

## Documents

| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | What clipboard & screen-capture Endpoint DLP delivers, the two activities it controls (copy to clipboard, screen capture), onboarding, the simulate-first rule, the complementary label-usage-right lever, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The solution-specific prerequisites (2.1–2.7): Endpoint DLP clipboard/screen-capture licensing (E5 / E5 Compliance; screen capture newer/preview), DLP least-privilege roles, devices onboarded (+ minimum OS build), a classification intent (SITs / labels), allowed-app/browser/network exceptions, a pilot ring + simulation dwell + change control, and an alert-triage owner. Each with Verify / Implement-if-missing. References the category `global-requirements-purview.md`. |
| **03 — Implementation Guide** | The ordered build: connect & baseline → design the classification layer → author the Devices policy with the clipboard+screen-capture rule **in simulation** → measure & tune → enforce to a ring → expand. Every object named, with a pass/fail gate and rollback per phase. |
| **05 — Testing & Validation** | The pass/fail gates: detection & enforcement (A) for clipboard and screen capture, false-positive rate (B), incident/alert handling & evidence (C), simulation-first & rollback validation, and the evidence to capture. |
| **06 — Troubleshooting** | The failures you will actually hit — no endpoint activity, screen capture not available, false positives, the rule not firing, simulation-vs-enforce confusion, restriction-setting errors, empty reports — each with cause and fix. |
| **07 — Best Practices** | How to run it well: simulate-then-enforce discipline, keying on labels first, right-sizing the allowed-app/browser exceptions, tuning for a low false-positive rate, the user experience, evidence/operations, and the honesty about the boundary. |
| **Executive Summary** | The one-page business-level summary for stakeholders and sign-off. |

## PowerShell tools (5)

All are **read-only or `-WhatIf` by default**, use interactive modern-auth (`Connect-IPPSSession` /
`Connect-MgGraph`), and contain **no credentials**. They do **not** onboard devices (onboarding is a
portal/management-tool action), do **not** enforce (the config helper is simulation-only), and do **not**
invent cmdlets. Because **screen-capture restriction is newer / may be in preview** and restriction Setting
names evolve, the tools **read and print** the setting shape and degrade gracefully rather than asserting
availability — **verify your licensing/tenant.**

| Script | Purpose | Safe default |
|---|---|---|
| **DLPCLIP-Discovery.ps1** | Inventory existing DLP policies/rules and **Devices** coverage, flag any rule that already restricts clipboard/screen-capture, read the Endpoint DLP settings, and list labels + sensitive info types — the baseline of what already restricts copy/screenshot on the endpoint. | Read-only |
| **DLPCLIP-Configure.ps1** | Build/update the `DLP - Endpoint Clipboard+Screen - Simulation` policy and its **clipboard + screen-capture** rule **in simulation**; requires `-Commit` to write and supports `-WhatIf`. Never enforces. | `-WhatIf` (preview) |
| **DLPCLIP-Validate.ps1** | Run the configuration gates (policy exists, Devices location, simulation mode, pilot scope, clipboard + screen-capture restrictions, sensitive-content condition) with PASS/FAIL output; screen capture flagged VERIFY where not readable. | Read-only |
| **DLPCLIP-Report.ps1** | Roll up policy modes and, where available, export **clipboard/screen-capture** endpoint events (matches, audits, blocks, overrides) from Activity Explorer to CSV — the operational + evidence view for the false-positive measure. | Read-only |
| **DLPCLIP-ScopeHealth.ps1** | Report device onboarding + Endpoint DLP feature/licensing readiness for clipboard & screen-capture (managed-device signals via Graph, pilot-group membership, policy scope, Endpoint DLP settings readability). | Read-only |

## How it maps to the deployment model

| Phase | Deliverables used |
|---|---|
| **Assess** | 01, 02, `DLPCLIP-Discovery.ps1`, `DLPCLIP-ScopeHealth.ps1` |
| **Design** | 02, 03 (named objects + detectors), 07 |
| **Configure** | 03, `DLPCLIP-Configure.ps1 -WhatIf` then `-Commit` (simulation) |
| **Pilot (simulation)** | 03, 05 (Gate B simulation pass), `DLPCLIP-Report.ps1` |
| **Validate** | 05, `DLPCLIP-Validate.ps1`, `DLPCLIP-Report.ps1` |
| **Expand (enforce)** | 03 (Phase 4/5), 05 (Gate A enforce pass), 06, 07 |

## Definition of done

- Pilot Windows/macOS devices **onboarded** and visible in **Purview → Devices**, meeting the minimum OS
  build for clipboard/screen-capture (screen capture **verified** available, or clipboard delivered first).
- Endpoint DLP settings (allowed/unallowed apps & browsers, service domains, network) defined so sanctioned
  copy-paste and normal screenshots are not caught.
- `DLP - Endpoint Clipboard+Screen - Simulation` with its rule built **in simulation**, all configuration
  gates (A) PASS.
- Behavioural gates (A) PASS in the **simulation pass**, then in the **enforce pass** to the pilot ring;
  the **false-positive gate (B)** meets the agreed threshold; **incident/alert handling (C)** produces a
  dispositioned incident.
- **Evidence pack** captured (baseline, simulation match export + TP/FP classification, enforcement
  screenshots/alerts, dispositioned incident, rollback proof) and stored with the change record.
- Regulatory / policy determinations (which data, and whether the action is audit / block-with-override /
  hard block) recorded by the **compliance / security** owners — not by the administrator.
