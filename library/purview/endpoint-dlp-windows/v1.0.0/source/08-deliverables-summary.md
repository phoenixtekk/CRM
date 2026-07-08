# Deliverables Summary — Endpoint DLP for Windows in Microsoft Purview

Everything included in this solution, what each piece is for, and how it maps to the deployment
model. Use it as the table of contents and the "did we finish?" checklist.

## Documents

| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | What Endpoint DLP for Windows delivers, the five egress channels (USB, print, clipboard, network share, cloud egress), onboarding, the simulate-first rule, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The solution-specific prerequisites (R1–R9): endpoint licensing, DLP + onboarding roles, supported devices, an onboarding method, in-scope sensitive content, the endpoint global settings, the browser extension, the per-channel action decision, and a pilot group — each with Verify / Implement-if-missing. References the category `global-requirements-purview.md`. |
| **03 — Implementation Guide** | The ordered build: onboard pilot devices → set endpoint global settings → author the policy + five rules **in simulation** → pilot & validate → enforce & expand. Every object named, with a pass/fail gate and rollback per phase. |
| **05 — Testing & Validation** | The pass/fail gates: configuration gates (A), per-channel behavioural tests (B) run in simulation then enforce, false-positive/negative tests (C), and the evidence to capture (D). |
| **06 — Troubleshooting** | The failures you will actually hit — no endpoint activity, a channel invisible, Chrome/Firefox not covered, false positives, enforcement not applying, simulation confusion — each with cause and fix. |
| **07 — Best Practices** | How to run it well: simulate-then-enforce discipline, keying on sensitive content, maintaining the allow-list groups and browser coverage, onboarding hygiene, ongoing operation, and role/determination boundaries. |
| **Executive Summary** | The one-page business-level summary for stakeholders and sign-off. |

## PowerShell tools (5)

All are **read-only or `-WhatIf` by default**, use interactive modern-auth
(`Connect-IPPSSession` / `Connect-MgGraph`), and contain **no credentials**. They do **not** onboard
devices (onboarding is a portal/management-tool action) and do **not** invent cmdlets.

| Script | Purpose | Safe default |
|---|---|---|
| **DLPWIN-Discovery.ps1** | Inventory existing DLP policies/rules and **Devices** coverage, sensitivity labels, and sensitive info types — the baseline of what already protects the endpoints. | Read-only |
| **DLPWIN-Configure.ps1** | Build/update the `EDLP-Windows-Pilot` policy and the five channel rules **in simulation**; requires `-Commit` to write and supports `-WhatIf`. | `-WhatIf` (preview) |
| **DLPWIN-Validate.ps1** | Run the configuration gates (policy exists, Devices location, simulation-first, pilot scope, five rules, sensitive-content conditions) with PASS/FAIL output. | Read-only |
| **DLPWIN-Report.ps1** | Roll up policy modes and, where available, **endpoint DLP activity** via Activity-explorer export — the operational + evidence view. | Read-only |
| **DLPWIN-ScopeHealth.ps1** | Report onboarding/scope health (managed-device signals via Graph, policy scope) and preview pilot-scope targeting; `-WhatIf` for any scoping change. | `-WhatIf` / read-only |

## How it maps to the deployment model

| Phase | Deliverables used |
|---|---|
| **Assess** | 01, 02, `DLPWIN-Discovery.ps1`, `DLPWIN-ScopeHealth.ps1` |
| **Design** | 02, 03 (named objects + action matrix), 07 |
| **Configure** | 03, `DLPWIN-Configure.ps1 -WhatIf` then `-Commit` (simulation) |
| **Pilot (simulation)** | 03, 05 (Gate B simulation pass), `DLPWIN-Report.ps1` |
| **Validate** | 05, `DLPWIN-Validate.ps1`, `DLPWIN-Report.ps1` |
| **Expand (enforce)** | 03 (Phase 5), 05 (Gate B enforce pass), 06, 07 |

## Definition of done

- Pilot Windows devices **onboarded** and visible in **Purview → Devices**.
- Endpoint global settings (device / printer / network-share groups, browsers, service domains)
  defined.
- `EDLP-Windows-Pilot` with five rules built **in simulation**, all configuration gates (A) PASS.
- Behavioural gates (B) PASS in the **simulation pass**, then in the **enforce pass** for the
  channels the R8 decision blocks/warns; false-positive gates (C) PASS.
- **Evidence pack** (D) captured and stored with the change record.
- Regulatory / policy determinations (which data, which action) recorded by the **compliance /
  security** owners — not by the administrator.
