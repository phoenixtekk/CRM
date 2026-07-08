# 8. Deliverables Summary — CMMC / CUI DLP Pack (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The CUI DLP model — the `CUI` sensitivity label as primary signal, the marking keyword SIT as backstop, the five locations (email, SharePoint, OneDrive, Teams, endpoint), and the simulate→enforce journey; naming convention; the CMMC/assessment boundary. |
| **Requirements Guide** | Solution-specific prerequisites (CUI marking/label decision, DLP/endpoint & label-based licensing, **GCC High** tenant confirmation, CUI enclave scope, device onboarding, marking-SIT source, pilot ring, alert triage + evidence retention) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/confirm label & tenant → confirm detection layer → build policies keyed on label+marking **in simulation** → tune → enforce to a pilot ring → expand & evidence; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — CUI leaks blocked (A), low false-positive rate (B), incidents handled & evidenced (C) — plus simulation-first and rollback checks, all with fake CUI-marked test data. |
| **Troubleshooting Guide** | The common failure modes (policy not matching CUI, marking SIT over-firing, endpoint location missing, GCC High path differences, no alerts) and how to resolve them. |
| **Best Practices** | Label-first detection, simulate-first discipline, enclave scoping, false-positive tuning, endpoint specifics, GCC High discipline, and evidence/operations. |
| **Executive Summary** | One-page business framing for approvers and contracts stakeholders. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No credentials are
stored in code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **DLPCMMC-Discovery.ps1** | CUI DLP posture assessment: existing DLP policies and their mode, whether a `CUI` sensitivity label and CUI marking SIT are present, and licensing/endpoint/tenant readiness signals. | Read-only |
| 2 | **DLPCMMC-Config.ps1** | CUI DLP policy configuration helper: creates/updates a policy **in simulation mode** keyed on the `CUI` label (and marking SIT) and reports the intended change. | `-WhatIf` (writes need `-Commit`; never leaves a policy in enforce) |
| 3 | **DLPCMMC-Validate.ps1** | Validation-gate checker: confirms the CUI policies exist, are in the expected mode (simulation vs enforce), key off the `CUI` label/marking, and are enclave-scoped — reports pass/fail per gate. | Read-only |
| 4 | **DLPCMMC-Report.ps1** | CUI match / false-positive & evidence report: exports simulation/enforcement matches for TP-vs-FP classification, rate calculation, and the audit evidence trail. | Read-only |
| 5 | **DLPCMMC-Set-Scope.ps1** | Scope/health helper: reports and (with `-Commit`) adjusts a policy's included/excluded users/groups (the CUI enclave / pilot ring). | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- The **`CUI` sensitivity label** is confirmed published and the **marking keyword SIT** is built from your
  real markings and tested.
- Email, cloud (SPO/OneDrive/Teams), and endpoint DLP policies keyed on **label = CUI** (+ marking backstop)
  built and **proven in simulation**, scoped to the **CUI enclave**.
- False-positive rate measured and tuned to at/under the agreed threshold (Gate B).
- Enforcement live for the pilot ring with policy tips + override, then expanded per compliance's action
  determination — block/encrypt where required (Gate A).
- CUI DLP alerts raised, triaged to disposition, and the **evidence trail retained** in Activity Explorer
  (Gate C).
- Simulation-rollback and safe-by-default scripts verified; change log and compliance sign-offs captured.

> **Boundary:** the solution delivers the technical control and the evidence. The **data that is CUI, the
> categories/markings in scope, the enforced action per condition, GCC High residency, DFARS
> incident-reporting, and all CMMC / NIST SP 800-171 control-satisfaction and assessment determinations** are
> **compliance / contracts / legal / C3PAO** decisions, captured alongside the delivered evidence.
