# Deliverables Summary — USB & Removable-Media DLP in Microsoft Purview

Everything included in this solution, what each piece is for, and how it maps to the deployment
model. Use it as the table of contents and the "did we finish?" checklist.

## Documents

| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | What USB / removable-media DLP delivers, the **two control layers** (content-aware Endpoint DLP + device-aware device control), onboarding, the simulate/audit-first rule, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The solution-specific prerequisites (R1–R9): endpoint/device-control licensing, DLP + onboarding + device-control roles, supported devices, an onboarding method, in-scope sensitive content, the removable-storage device group, the device-control surface, the per-layer action decision, and a pilot group — each with Verify / Implement-if-missing. References the category `global-requirements-purview.md`. |
| **03 — Implementation Guide** | The ordered build: onboard pilot devices → define `USBG-Corporate` → author the Endpoint DLP policy + rule **in simulation** → deploy device control **audit-first** → pilot & validate → enforce & expand. Every object named, with a pass/fail gate and rollback per phase. |
| **05 — Testing & Validation** | The pass/fail gates: configuration gates (A), per-layer behavioural tests (B) run in simulation/audit then enforce, false-positive/negative tests (C), and the evidence to capture (D). |
| **06 — Troubleshooting** | The failures you will actually hit — no removable-media activity, device-control not applying, false positives, corporate USB blocked, simulation-vs-enforce confusion — each with cause and fix. |
| **07 — Best Practices** | How to run it well: run both layers with intent, simulate/audit-then-enforce discipline, curating `USBG-Corporate`, keying the content rule on sensitive content, onboarding hygiene, ongoing operation, and role/determination boundaries. |
| **Executive Summary** | The one-page business-level summary for stakeholders and sign-off. |

## PowerShell tools (5)

All are **read-only or `-WhatIf` by default**, use interactive modern-auth
(`Connect-IPPSSession` / `Connect-MgGraph`), and contain **no credentials**. They do **not** onboard
devices or deploy the device-control policy (both are portal/management-tool actions) and do **not**
invent cmdlets.

| Script | Purpose | Safe default |
|---|---|---|
| **DLPUSB-Discovery.ps1** | Inventory existing DLP policies/rules and **Devices** coverage, the removable-storage device groups it can read, sensitivity labels, and sensitive info types — the baseline of what already protects removable media. | Read-only |
| **DLPUSB-Configure.ps1** | Build/update the `EDLP-USB-Pilot` policy and the `EDLP-Rule-USB` removable-media rule **in simulation**; requires `-Commit` to write and supports `-WhatIf`. | `-WhatIf` (preview) |
| **DLPUSB-Validate.ps1** | Run the configuration gates (policy exists, Devices location, simulation-first, pilot scope, removable-media rule, sensitive-content condition, allow-list group) with PASS/FAIL output. | Read-only |
| **DLPUSB-Report.ps1** | Roll up policy modes and, where available, **removable-media DLP activity** via Activity-explorer export — the operational + evidence view. Reminds you to pair with the device-control audit from your management tool. | Read-only |
| **DLPUSB-ScopeHealth.ps1** | Report onboarding/scope health (managed-device signals via Graph, policy scope) and preview pilot-scope targeting; `-WhatIf` for any scoping change. | `-WhatIf` / read-only |

## How it maps to the deployment model

| Phase | Deliverables used |
|---|---|
| **Assess** | 01, 02, `DLPUSB-Discovery.ps1`, `DLPUSB-ScopeHealth.ps1` |
| **Design** | 02, 03 (named objects + action decision), 07 |
| **Configure** | 03, `DLPUSB-Configure.ps1 -WhatIf` then `-Commit` (simulation) + device-control audit-first in your management tool |
| **Pilot (simulation/audit)** | 03, 05 (Gate B simulation/audit pass), `DLPUSB-Report.ps1` |
| **Validate** | 05, `DLPUSB-Validate.ps1`, `DLPUSB-Report.ps1` |
| **Expand (enforce)** | 03 (Phase 6), 05 (Gate B enforce pass), 06, 07 |

## Definition of done

- Pilot devices **onboarded** and visible in **Purview → Devices**.
- `USBG-Corporate` removable-storage device group defined and populated.
- `EDLP-USB-Pilot` with `EDLP-Rule-USB` built **in simulation**, all configuration gates (A) PASS.
- `DC-RemovableStorage-Pilot` device-control policy deployed **audit-first** in your management tool.
- Behavioural gates (B) PASS in the **simulation/audit pass**, then in the **enforce pass** for the
  actions the R8 decision blocks/warns/read-only; false-positive gates (C) PASS.
- **Evidence pack** (D) captured and stored with the change record.
- Regulatory / policy determinations (which data, which media, which action) recorded by the
  **compliance / security** owners — not by the administrator.
