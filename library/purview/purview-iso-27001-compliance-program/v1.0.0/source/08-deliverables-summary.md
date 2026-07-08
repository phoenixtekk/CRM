# 8. Deliverables Summary — Microsoft Purview ISO 27001 Compliance Program

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The program model — mapping in-scope Annex A controls to Purview capabilities, the Compliance Manager assessment spine, the supporting technical controls (labels, DLP, retention, audit, encryption), and the Assess→Design→Configure→Pilot(simulate/test)→Validate→Expand journey; naming convention and the Annex A→Purview mapping table. |
| **Requirements Guide** | Solution-specific prerequisites (licensing for the ISO template + advanced controls, the SoA/risk inputs from the ISMS function, Compliance Manager role separation, roles for labels/DLP/retention/audit, unified audit enabled, classification intent, pilot ring, evidence owner) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: baseline → map Annex A (from SoA) → stand up the assessment spine → configure technical controls **in simulation/test** → validate evidence and enforce to a pilot ring → expand and operate; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — controls mapped (A), evidence collected (B), technical controls behave and were piloted (C) — plus simulate-first and rollback checks, all with fake test data. |
| **Troubleshooting Guide** | The common failure modes (ISO template missing, no evidence collected, controls not behaving, audit gaps, no alerts) and how to resolve them. |
| **Best Practices** | SoA-driven mapping, simulate-first discipline, evidence automation, segregation of duties, classification/DLP/retention hygiene, privacy-by-design for insider-risk signals, and continual improvement. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit` and never leave
a policy in enforce. No credentials are stored in code. They connect via `Connect-IPPSSession` and/or
`Connect-MgGraph`. **Compliance Manager has no broad public API** — the scripts assess readiness, roles,
and the technical evidence behind controls; they do not create assessments (that is done in the portal).

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **ISO27001-Discovery.ps1** | Posture + control-coverage assessment: unified-audit state, existing DLP/label/retention objects and their mode, and licensing signals that gate the ISO template and advanced controls. | Read-only |
| 2 | **ISO27001-Config.ps1** | Supporting-control configuration helper: creates/updates a DLP/retention control **in simulation/test mode** and reports the intended change. | `-WhatIf` (writes need `-Commit`; never leaves a policy in enforce) |
| 3 | **ISO27001-ControlEvidence.ps1** | Evidence collector: for each mapped Annex A control, confirms the technical state (audit, DLP+mode, labels, retention, licensing/CA signals) and builds the evidence register. | Read-only |
| 4 | **ISO27001-Report.ps1** | Control-coverage + evidence-gap report and logging/monitoring evidence pull from the unified audit log. | Read-only |
| 5 | **ISO27001-Set-Scope.ps1** | Scope helper: reports and (with `-Commit`) adjusts a policy's included/excluded users/groups (e.g. the pilot ring). | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- Every **in-scope, applicable Annex A control** (from the SoA) mapped to a Purview capability — or marked
  out-of-Purview — in `ISO27001 Control Map – AnnexA-to-Purview`, signed off by the ISMS function.
- The **ISO/IEC 27001 assessment** stood up in Compliance Manager with an owned, dated improvement-action
  / evidence plan and role separation snapshotted.
- The supporting technical controls (**labels, DLP, retention/disposition**) configured and **proven in
  simulation/test**, then enforced to the pilot ring; **unified audit** and **encryption** evidence
  confirmed.
- The **evidence register** and **coverage report** complete — every mapped control with owner, date, test
  status, and no unexplained gap.
- Simulate-first, ring-only enforcement, and safe-by-default scripts verified; change log and ISMS/
  compliance sign-offs captured; the continual-improvement cadence running.

> **Boundary:** the solution delivers the **configured technical controls and the audit-ready evidence**.
> The **ISMS scope, the risk assessment and treatment, the Statement of Applicability (which Annex A
> controls apply), the management-system clauses (4–10), retention schedules / records file plans, and the
> certification determination** are ISMS / risk / compliance / records / legal / certification-body
> determinations, captured alongside the delivered evidence.
