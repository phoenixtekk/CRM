# Deliverables Summary — Trainable Classifiers in Microsoft Purview

Everything included in this solution, what each piece is for, and how it maps to the deployment
model. Use it as the table of contents and the "did we finish?" checklist.

## Documents

| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | What trainable classifiers deliver (classify by meaning, not keywords), the seed→train→test→publish lifecycle, built-in vs custom, the critical **wiring** to labels/DLP/retention, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The solution-specific prerequisites (R1–R8): licensing, classifier + control roles, seed content, a separate test set, the target control/label, the built-in catalog review, the accuracy-acceptance decision, and a pilot scope — each with Verify / Implement-if-missing. References the category `global-requirements-purview.md`. |
| **03 — Implementation Guide** | The ordered build: design (built-in vs custom) → **seed/train/test/publish** the classifier (portal) → **wire** it into an auto-labeling policy **in simulation** → pilot & validate → enforce & expand. Every object named, with a pass/fail gate and rollback per phase. |
| **05 — Testing & Validation** | The pass/fail gates: classifier **accuracy** gates (A), **wiring** configuration gates (B), behavioural tests (C) run in simulation then enforce, and the evidence to capture (D). |
| **06 — Troubleshooting** | The failures you will actually hit — classifier won't train/publish, low accuracy, "published but nothing happens" (not wired), simulation-vs-enforce confusion, classifier condition not scriptable — each with cause and fix. |
| **07 — Best Practices** | How to run it well: built-in before custom, seed/test like a data scientist, never publish a failing classifier, wire-in-simulation, the hard-to-reverse nature of labeling, ongoing operation, and role/determination boundaries. |
| **Executive Summary** | The one-page business-level summary for stakeholders and sign-off. |

## PowerShell tools (5)

All are **read-only or `-WhatIf` by default**, use interactive modern-auth
(`Connect-IPPSSession` / `Connect-MgGraph`), and contain **no credentials**. They automate the
**wiring** and reporting; they do **not** create/publish classifiers (a portal action) and do **not**
invent cmdlets.

| Script | Purpose | Safe default |
|---|---|---|
| **CLSTRAIN-Discovery.ps1** | Inventory existing auto-labeling / DLP / retention policies, sensitivity labels, and where a classifier can be wired — the baseline of what could act on a classifier. | Read-only |
| **CLSTRAIN-Configure.ps1** | Build/update the `AL-Classifier-Pilot` auto-labeling policy + rule **in simulation** (the wiring), applying the target label; requires `-Commit` to write and supports `-WhatIf`. | `-WhatIf` (preview) |
| **CLSTRAIN-Validate.ps1** | Run the wiring configuration gates (policy exists, simulation-first, pilot scope, rule present, target label, classifier referenced) with PASS/FAIL output. | Read-only |
| **CLSTRAIN-Report.ps1** | Roll up auto-labeling/DLP policy modes and, where available, **classification activity** via Activity-explorer export — the operational + evidence view. | Read-only |
| **CLSTRAIN-ScopeHealth.ps1** | Report seed/scope health (pilot-group membership via Graph, policy scope) and preview pilot-scope targeting; `-WhatIf` for any scoping change. Reminds you to confirm classifier status + seed site in the portal. | `-WhatIf` / read-only |

## How it maps to the deployment model

| Phase | Deliverables used |
|---|---|
| **Assess** | 01, 02, `CLSTRAIN-Discovery.ps1`, `CLSTRAIN-ScopeHealth.ps1` |
| **Design** | 02, 03 (classifier map + target label), 07 |
| **Configure (seed/train/test/publish + wire)** | 03 (Phase 2 portal + Phase 3 wiring), `CLSTRAIN-Configure.ps1 -WhatIf` then `-Commit` (simulation) |
| **Pilot (simulation)** | 03, 05 (Gate C simulation pass), `CLSTRAIN-Report.ps1` |
| **Validate** | 05 (Gate A accuracy + Gate B wiring), `CLSTRAIN-Validate.ps1`, `CLSTRAIN-Report.ps1` |
| **Expand (enforce)** | 03 (Phase 5), 05 (Gate C enforce pass), 06, 07 |

## Definition of done

- Each needed category mapped to a **built-in** or **custom** classifier; custom classifiers
  **published only after** meeting the **R7 accuracy** threshold (Gate A), signed off by the data owner.
- `AL-Classifier-Pilot` auto-labeling wiring built **in simulation**, all wiring gates (B) PASS,
  referencing the classifier and applying the target label.
- Behavioural gates (C) PASS in the **simulation pass**, then in the **enforce pass**; matching content
  labeled, non-matching untouched.
- **Evidence pack** (D) captured — accuracy results, R7 sign-off, wiring validation, simulation results
  — and stored with the change record.
- Regulatory / policy determinations (which label, what accuracy is acceptable, what is in scope)
  recorded by the **compliance / data-owner** functions — not by the administrator.
