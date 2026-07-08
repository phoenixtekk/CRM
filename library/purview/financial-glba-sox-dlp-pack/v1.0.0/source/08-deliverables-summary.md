# 8. Deliverables Summary — Financial (GLBA/SOX) DLP Pack (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The financial-DLP model — financial/NPI SITs, EDM, statement fingerprinting, the five locations (email, SharePoint, OneDrive, Teams, endpoint), the GLBA/SOX framing, policy tips/overrides, and the simulate→enforce journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (DLP/Endpoint + advanced-classifier licensing, DLP roles with author/triage separation, finance device onboarding, financial classification intent, EDM/fingerprint source data, finance pilot ring, alert triage owner + evidence access) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → design financial SITs/EDM/fingerprints → build 4 policies **in simulation** → tune false positives → enforce to a finance ring → expand; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — financial/NPI leaks blocked (A), low false-positive rate (B), incidents handled with controlled evidence access (C) — plus simulation-first and rollback checks, all with fake test data. |
| **Troubleshooting Guide** | The common failure modes (policy not matching, endpoint location missing, floods of false positives on GL/reference numbers, no alerts) and how to resolve them. |
| **Best Practices** | Simulate-first discipline, financial false-positive tuning, user-experience design for finance, endpoint specifics, classification hygiene, and GLBA/SOX operations/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No credentials
are stored in code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **DLPFIN-Discovery.ps1** | DLP posture + financial-SIT coverage assessment: existing policies and their mode, built-in financial vs custom SIT coverage, EDM schemas, licensing/endpoint readiness signals. | Read-only |
| 2 | **DLPFIN-Config.ps1** | DLP policy configuration helper: creates/updates a financial/NPI policy **in simulation mode** and reports the intended change. | `-WhatIf` (writes need `-Commit`; never leaves a policy in enforce) |
| 3 | **DLPFIN-Validate.ps1** | Validation runner: checks each expected financial policy exists, is in the intended mode (simulation vs enforce), covers the right locations/SITs, and reports pass/fail against the deployment gates. | Read-only |
| 4 | **DLPFIN-Report.ps1** | DLP match / false-positive tuning report: exports simulation/enforcement matches for TP-vs-FP classification and rate calculation. | Read-only |
| 5 | **DLPFIN-Scope.ps1** | Scope/health helper: reports a policy's scope + endpoint/licensing health signals and (with `-Commit`) narrows a policy to the finance pilot ring. | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- Financial/NPI sensitive information types, EDM schemas, statement fingerprints, and classifiers mapped
  for every in-scope category (built-in + GLBA/Financial-Data templates reused; custom/EDM/fingerprint/
  trainable only for gaps).
- Email, cloud (SPO/OneDrive/Teams), endpoint NPI, and SOX financial-records DLP policies built and
  **proven in simulation**.
- False-positive rate measured and tuned to at/under the agreed threshold across a reporting cycle (Gate B).
- Enforcement live for the finance pilot ring with policy tips + override, then expanded per compliance's
  action determination (Gate A).
- Financial DLP alerts raised, triaged to disposition with controlled evidence access, and evidence trailed
  in Activity Explorer (Gate C).
- Simulation-rollback and safe-by-default scripts verified; change log and compliance sign-offs captured for
  the GLBA safeguards / SOX control record.

> **Boundary:** the solution delivers the technical control and the evidence. **Which data is NPI under
> GLBA, which records are SOX-scoped, which classifiers legally apply, the enforced action per category,
> retention obligations, and the acceptable false-positive threshold** are compliance/records/privacy/legal
> determinations, captured alongside the evidence.
