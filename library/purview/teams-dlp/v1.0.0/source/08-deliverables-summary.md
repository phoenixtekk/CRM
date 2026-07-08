# Deliverables Summary — Teams Chat & Channel DLP in Microsoft Purview

Everything included in this solution, what each piece is for, and how it maps to the deployment
model. Use it as the table of contents and the "did we finish?" checklist.

## Documents

| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | What Teams DLP delivers, the two coverage areas (messages via the Teams-messages location; **files via SharePoint/OneDrive**), the simulate-first rule, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The solution-specific prerequisites (R1–R8): message-DLP licensing, DLP roles, in-scope Teams surfaces, in-scope sensitive content, the three-location understanding, the action + internal/external decision, a pilot group, and policy-tip content — each with Verify / Implement-if-missing. References the category `global-requirements-purview.md`. |
| **03 — Implementation Guide** | The ordered build: design → author the policy across **Teams messages + SharePoint + OneDrive** with two rules **in simulation** → pilot & validate → enforce & expand. Every object named, with a pass/fail gate and rollback per phase. |
| **05 — Testing & Validation** | The pass/fail gates: configuration gates (A, including the three-location check), message + file behavioural tests (B) run in simulation then enforce, false-positive/negative tests (C), and the evidence to capture (D). |
| **06 — Troubleshooting** | The failures you will actually hit — messages covered but files not, message DLP not firing (licensing), external logic wrong, simulation-vs-enforce confusion — each with cause and fix. |
| **07 — Best Practices** | How to run it well: cover messages AND files, simulate-then-enforce discipline, the internal-vs-external logic, keying on sensitive content, a clear policy tip, ongoing operation, and role/determination boundaries. |
| **Executive Summary** | The one-page business-level summary for stakeholders and sign-off. |

## PowerShell tools (5)

All are **read-only or `-WhatIf` by default**, use interactive modern-auth
(`Connect-IPPSSession` / `Connect-MgGraph`), and contain **no credentials**. They do **not** invent
cmdlets.

| Script | Purpose | Safe default |
|---|---|---|
| **DLPTEAMS-Discovery.ps1** | Inventory existing DLP policies/rules and which locations they cover (**Teams / SharePoint / OneDrive**), sensitivity labels, and sensitive info types — the baseline, including any default Teams DLP policy. | Read-only |
| **DLPTEAMS-Configure.ps1** | Build/update the `DLP-Teams-Pilot` policy across the three locations and the message + file rules **in simulation**; requires `-Commit` to write and supports `-WhatIf`. | `-WhatIf` (preview) |
| **DLPTEAMS-Validate.ps1** | Run the configuration gates (policy exists, Teams-messages location, **SharePoint+OneDrive file locations**, simulation-first, pilot scope, two rules, sensitive-content conditions) with PASS/FAIL output. | Read-only |
| **DLPTEAMS-Report.ps1** | Roll up policy modes and, where available, **DLP activity** via Activity-explorer export — the operational + evidence view. | Read-only |
| **DLPTEAMS-ScopeHealth.ps1** | Report pilot-scope health (pilot-group membership via Graph, policy scope) and preview pilot-scope targeting; `-WhatIf` for any scoping change. | `-WhatIf` / read-only |

## How it maps to the deployment model

| Phase | Deliverables used |
|---|---|
| **Assess** | 01, 02, `DLPTEAMS-Discovery.ps1`, `DLPTEAMS-ScopeHealth.ps1` |
| **Design** | 02, 03 (named objects + action matrix), 07 |
| **Configure** | 03, `DLPTEAMS-Configure.ps1 -WhatIf` then `-Commit` (simulation) |
| **Pilot (simulation)** | 03, 05 (Gate B simulation pass), `DLPTEAMS-Report.ps1` |
| **Validate** | 05, `DLPTEAMS-Validate.ps1`, `DLPTEAMS-Report.ps1` |
| **Expand (enforce)** | 03 (Phase 4), 05 (Gate B enforce pass), 06, 07 |

## Definition of done

- `DLP-Teams-Pilot` built **in simulation** spanning **Teams messages + SharePoint + OneDrive**, all
  configuration gates (A) PASS — including the three-location check.
- Both rules (`DLP-Rule-TeamsMessages`, `DLP-Rule-TeamsFiles`) present, conditioned on sensitive
  content, with the internal-vs-external logic on the message rule.
- Behavioural gates (B) PASS in the **simulation pass**, then in the **enforce pass** for the paths the
  R6 decision blocks; false-positive gates (C) PASS.
- **Evidence pack** (D) captured and stored with the change record.
- Regulatory / policy determinations (which data, which action, internal vs external) recorded by the
  **compliance / security** owners — not by the administrator.
