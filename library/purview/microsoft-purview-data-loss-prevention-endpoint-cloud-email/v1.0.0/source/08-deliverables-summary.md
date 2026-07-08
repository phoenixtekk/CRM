# 8. Deliverables Summary — Microsoft Purview Data Loss Prevention (DLP)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The DLP model — SITs/classifiers, the five locations (email, SharePoint, OneDrive, Teams, endpoint), policy tips/overrides, and the simulate→enforce journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (DLP/Endpoint licensing, DLP roles, device onboarding, classification intent, EDM source data, pilot ring, alert triage owner) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → design SITs → build policies **in simulation** → tune false positives → enforce to a pilot ring → expand; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — leaks blocked (A), low false-positive rate (B), incidents handled (C) — plus simulation-first and rollback checks, all with fake test data. |
| **Troubleshooting Guide** | The common failure modes (policy not matching, endpoint location missing, floods of false positives, no alerts) and how to resolve them. |
| **Best Practices** | Simulate-first discipline, false-positive tuning, user-experience design, endpoint specifics, classification hygiene, and operations/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No credentials
are stored in code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **PURVDLP-Discovery.ps1** | DLP posture + sensitive-info-type coverage assessment: existing policies and their mode, built-in vs custom SIT coverage, licensing/endpoint readiness signals. | Read-only |
| 2 | **PURVDLP-Config.ps1** | DLP policy configuration helper: creates/updates a policy **in simulation mode** and reports the intended change. | `-WhatIf` (writes need `-Commit`; never leaves a policy in enforce) |
| 3 | **PURVDLP-EndpointReadiness.ps1** | Endpoint-DLP onboarding/readiness checker: onboarded-device count/state and whether the Devices location is usable. | Read-only |
| 4 | **PURVDLP-Report.ps1** | DLP match / false-positive tuning report: exports simulation/enforcement matches for TP-vs-FP classification and rate calculation. | Read-only |
| 5 | **PURVDLP-Set-Scope.ps1** | Scope/config helper: reports and (with `-Commit`) adjusts a policy's included/excluded users/groups (e.g. the pilot ring). | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- Sensitive information types/classifiers mapped for every in-scope data category (built-in reused; custom/
  EDM/trainable only for gaps).
- Email, cloud (SPO/OneDrive/Teams), and endpoint DLP policies built and **proven in simulation**.
- False-positive rate measured and tuned to at/under the agreed threshold (Gate B).
- Enforcement live for the pilot ring with policy tips + override, then expanded per compliance's action
  determination (Gate A).
- DLP alerts raised, triaged to disposition, and evidence trailed in Activity Explorer (Gate C).
- Simulation-rollback and safe-by-default scripts verified; change log and compliance sign-offs captured.

> **Boundary:** the solution delivers the technical control and the evidence. The **data categories in
> scope, the classifiers that legally apply, the enforced action per category, and the acceptable
> false-positive threshold** are compliance/privacy/legal determinations, captured alongside the evidence.
