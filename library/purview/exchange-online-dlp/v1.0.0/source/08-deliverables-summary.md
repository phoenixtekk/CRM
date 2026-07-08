# Deliverables Summary — Exchange Online DLP in Microsoft Purview

Everything included in this solution, what each piece is for, and how it maps to the deployment model.
Use it as the table of contents and the "did we finish?" checklist.

## Documents

| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | What Exchange Online DLP delivers, the five email scenarios (SIT→external high/low, labeled→external, SIT→internal, partner exception), policy tips, transport-rule interaction, the simulate-first rule, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The solution-specific prerequisites (R1–R8): DLP-capable licensing (+ message encryption), DLP/mail-flow roles, in-scope SITs/labels and thresholds, the recipient-scope + partner-domain decision, the per-scenario action decision, the policy-tip/notification plan, transport-rule reconciliation, and a pilot sender group — each with Verify / Implement-if-missing. References the category `global-requirements-purview.md`. |
| **03 — Implementation Guide** | The ordered build: assess → design (name every object + action matrix) → author the policy + five rules **in simulation** → pilot & validate → enforce & expand. Every object named, with a pass/fail gate and rollback per phase. |
| **05 — Testing & Validation** | The pass/fail gates: configuration gates (A), per-scenario behavioural tests (B) run in simulation then enforce, false-positive/negative tests (C) incl. the partner exception and transport-rule coexistence, and the evidence to capture (D). |
| **06 — Troubleshooting** | The failures you will actually hit — no match, tips not showing, false positives, enforce-not-blocking, encryption not applying, transport-rule conflict, empty report — each with cause and fix, referencing the five scripts by name. |
| **07 — Best Practices** | How to run it well: simulate-then-enforce discipline, keying on sensitive content + recipient scope, maintaining the partner exception, policy tips as education, transport-rule reconciliation, ongoing operation, and role/determination boundaries. |
| **Executive Summary** | The one-page business-level summary for stakeholders and sign-off. |

## PowerShell tools (5)

All are **read-only or `-WhatIf` by default**, use interactive modern-auth (`Connect-IPPSSession`),
and contain **no credentials**. They use standard Security & Compliance PowerShell cmdlets and do
**not** invent cmdlets.

| Script | Purpose | Safe default |
|---|---|---|
| **DLPEXO-Discovery.ps1** | Inventory existing DLP policies/rules scoped to **Exchange** (with mode), the transport-rule interaction, and the sensitivity labels + sensitive info types available to key on — the baseline of what already protects email. | Read-only |
| **DLPEXO-Configure.ps1** | Build/update the `DLPEXO-Pilot` policy and the five scenario rules **in simulation**; previews with `-WhatIf` and writes nothing unless you pass `-Commit`. Never enforces. | `-WhatIf` (preview) |
| **DLPEXO-Validate.ps1** | Run the configuration gates (policy exists, Exchange location, simulation-first, pilot scope, five rules, sensitive-content conditions, partner exception) with PASS/FAIL output. | Read-only |
| **DLPEXO-Report.ps1** | Roll up policy modes and, where available, **DLP rule-match / policy-tip / block events** via Activity-explorer export — the operational + evidence view. | Read-only |
| **DLPEXO-ScopeHealth.ps1** | Report Exchange DLP scope health — mail-flow coverage, policy precedence/overlap with other DLP + transport rules, and licensing-readiness flags — and preview any scope change with `-WhatIf`. | `-WhatIf` / read-only |

## How it maps to the deployment model

| Phase | Deliverables used |
|---|---|
| **Assess** | 01, 02, `DLPEXO-Discovery.ps1`, `DLPEXO-ScopeHealth.ps1` |
| **Design** | 02, 03 (named objects + action matrix), 07 |
| **Configure** | 03, `DLPEXO-Configure.ps1 -WhatIf` then `-Commit` (simulation) |
| **Pilot (simulation)** | 03, 05 (Gate B simulation pass), `DLPEXO-Report.ps1` |
| **Validate** | 05, `DLPEXO-Validate.ps1`, `DLPEXO-Report.ps1` |
| **Expand (enforce)** | 03 (Phase 4), 05 (Gate B enforce pass), 06, 07 |

## Definition of done

- Transport-rule interaction **reconciled** (R7) and in-scope SITs/labels + thresholds confirmed.
- `DLPEXO-Pilot` on the **Exchange** location with five rules built **in simulation**, scoped to the
  pilot senders, all configuration gates (A) PASS.
- Behavioural gates (B) PASS in the **simulation pass**, then in the **enforce pass** for the scenarios
  the R5 decision blocks/encrypts; false-positive gates (C) — including the **partner exception** —
  PASS.
- **Evidence pack** (D) captured and stored with the change record.
- Regulatory / policy determinations (which data, which action, which domains are trusted) recorded by
  the **compliance / security** owners — not by the administrator.
