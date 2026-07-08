# 8. Deliverables Summary — OneDrive for Business DLP (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The OneDrive DLP model — SITs/classifiers, the two things a policy controls (sensitive content at rest and risky external sharing), policy tips/overrides, and the simulate→enforce journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (DLP/classifier licensing, DLP roles, OneDrive provisioned + sharing posture, classification intent, EDM source data, pilot ring, alert triage owner) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → design SITs → build the at-rest and external-share policies **in simulation** → tune false positives → enforce to a pilot ring → expand; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — content/shares caught (A), low false-positive rate (B), incidents handled (C) — plus simulation-first and rollback checks, all with fake test data. |
| **Troubleshooting Guide** | The common failure modes (policy not matching, external-share condition not firing, floods of false positives, no alerts) and how to resolve them. |
| **Best Practices** | Simulate-first discipline, separating at-rest from shared, false-positive tuning, user-experience design, tenant-sharing coordination, classification hygiene, and operations/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No credentials
are stored in code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **DLPOD-Discovery.ps1** | OneDrive DLP posture + sensitive-info-type coverage assessment: existing policies that touch OneDrive and their mode, built-in vs. custom SIT coverage, EDM schemas. | Read-only |
| 2 | **DLPOD-Config.ps1** | OneDrive DLP policy configuration/remediation helper: creates/updates a policy **in simulation mode** (optionally with the *shared externally* condition via `-ExternalShareOnly`) and reports the intended change. | `-WhatIf` (writes need `-Commit`; never leaves a policy in enforce) |
| 3 | **DLPOD-Validate.ps1** | Validation reporter: checks the OneDrive policies' mode, location scope, and sharing conditions against the expected pass/fail gates and emits a validation record. | Read-only |
| 4 | **DLPOD-Report.ps1** | DLP match / false-positive tuning report: exports OneDrive simulation/enforcement matches for TP-vs-FP classification and rate calculation. | Read-only |
| 5 | **DLPOD-Scope.ps1** | Scope/health helper: reports a policy's OneDrive scope + tenant external-sharing signal and (with `-Commit`) sets the pilot-ring included scope. | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- Sensitive information types/classifiers mapped for every in-scope data category (built-in reused;
  custom/EDM/trainable only for gaps).
- OneDrive **at-rest** and **external-share** DLP policies built and **proven in simulation**.
- False-positive rate measured and tuned to at/under the agreed threshold (Gate B).
- Enforcement live for the pilot ring with policy tips + override, then expanded per compliance's action
  determination — including restricting sensitive external/"anyone" shares (Gate A).
- DLP alerts raised, triaged to disposition, and evidence trailed in Activity Explorer (Gate C).
- Simulation-rollback and safe-by-default scripts verified; change log and compliance sign-offs captured.

> **Boundary:** the solution delivers the technical control and the evidence. The **data categories in
> scope, the classifiers that legally apply, the enforced action per category (e.g. block external
> sharing vs. warn-and-override), and the acceptable false-positive threshold** are compliance/privacy/
> legal determinations, captured alongside the evidence.
