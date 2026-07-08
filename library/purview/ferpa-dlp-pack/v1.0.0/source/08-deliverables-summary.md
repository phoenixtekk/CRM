# 8. Deliverables Summary — FERPA DLP Pack (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The education-record DLP model — SITs/classifiers (including the Student ID custom SIT and EDM), the five locations (email, SharePoint, OneDrive, Teams, endpoint), policy tips/overrides, the directory-vs-non-directory boundary, and the simulate→enforce journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (DLP/Endpoint licensing incl. A3/A5, DLP roles, device onboarding, education-record classification intent + student-ID SIT inventory, EDM source data, pilot ring, alert triage owner) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → design education-record SITs → build policies **in simulation** → tune false positives → enforce to a pilot ring → expand; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — record leaks blocked (A), low false-positive rate (B), incidents handled (C) — plus student-ID precision, evidence-access, simulation-first and rollback checks, all with fabricated test data. |
| **Troubleshooting Guide** | The common failure modes (policy not matching, student-ID SIT never fires, endpoint location missing, floods of false positives, no alerts) and how to resolve them. |
| **Best Practices** | Simulate-first discipline, student-identifier classification, false-positive tuning, the directory/non-directory boundary, user-experience design, endpoint specifics, and operations/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No credentials are
stored in code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **DLPFERPA-Discovery.ps1** | DLP posture + education-record SIT coverage assessment: existing policies and their mode, built-in vs custom SIT coverage (incl. whether a student-ID SIT exists), licensing/endpoint readiness signals. | Read-only |
| 2 | **DLPFERPA-Config.ps1** | DLP policy configuration/remediation helper: creates/updates an education-record policy **in simulation mode** and reports the intended change. | `-WhatIf` (writes need `-Commit`; never leaves a policy in enforce) |
| 3 | **DLPFERPA-Validate.ps1** | Validation checker: confirms the FERPA policy set is in simulation, scoped to the correct locations/SITs, and (optionally) checks endpoint-location/onboarding readiness — reports pass/fail per gate. | Read-only |
| 4 | **DLPFERPA-Report.ps1** | DLP match / false-positive tuning report: exports simulation/enforcement matches for TP-vs-FP classification and rate calculation. | Read-only |
| 5 | **DLPFERPA-Set-Scope.ps1** | Scope/health helper: reports a policy's locations/mode/scope and (with `-Commit`) adjusts the included/excluded users/groups (e.g. the pilot ring). | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- Education-record SITs/classifiers mapped for every in-scope category (built-in reused; `Student ID – Custom
  SIT – FERPA` and, where needed, `Student Records – EDM – FERPA` for gaps).
- Email, cloud (SPO/OneDrive/Teams), and endpoint DLP policies built and **proven in simulation**.
- False-positive rate measured and tuned to at/under the agreed threshold (Gate B), with student-ID precision
  confirmed.
- Enforcement live for the pilot ring with policy tips + override, then expanded per the FERPA function's
  action determination (Gate A).
- DLP alerts raised, triaged to disposition with least-privilege evidence access, and evidence trailed in
  Activity Explorer (Gate C).
- Simulation-rollback and safe-by-default scripts verified; change log and FERPA/registrar sign-offs captured.

> **Boundary:** the solution delivers the technical control and the evidence. The **records in scope, the
> directory-vs-non-directory treatment, the classifiers that legally apply, the enforced action per category,
> and the acceptable false-positive threshold** are FERPA-compliance/registrar/privacy/legal determinations,
> captured alongside the evidence.
