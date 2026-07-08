# 8. Deliverables Summary — GDPR / PII DLP Pack (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The personal-data DLP model — SITs/classifiers (the EU/GDPR built-in set, the custom national-ID SIT and EDM, special-category trainable classifiers), the five locations (email, SharePoint, OneDrive, Teams, endpoint), policy tips/overrides, transfer awareness, the GDPR determination boundary, and the simulate→enforce journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (DLP/Endpoint licensing, DLP roles, device onboarding, personal-data classification intent + EU-PII SIT inventory, EDM source data, pilot ring, alert triage owner + DPO/breach hand-off) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → design EU-personal-data SITs → build policies **in simulation** → tune false positives → enforce to a pilot ring → expand; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — personal-data leaks blocked (A), low false-positive rate (B), incidents handled (C) — plus custom-SIT precision, transfer-awareness, evidence-access, simulation-first and rollback checks, all with fabricated test data. |
| **Troubleshooting Guide** | The common failure modes (policy not matching, custom SIT never fires, endpoint location missing, floods of false positives, no alerts) and how to resolve them. |
| **Best Practices** | Simulate-first discipline, EU personal-data classification, false-positive tuning, the GDPR determination boundary, user-experience design, endpoint specifics, and operations/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No credentials are
stored in code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Run mode / default safety |
|---|---|---|---|
| 1 | **DLPGDPR-Discovery.ps1** | DLP posture + EU-PII SIT coverage assessment: existing policies and their mode, built-in vs custom SIT coverage (incl. which EU/GDPR SITs are present and whether a custom national-ID SIT exists), licensing/endpoint readiness signals. | Read-only |
| 2 | **DLPGDPR-Config.ps1** | DLP policy configuration/remediation helper: creates/updates an EU-personal-data policy **in simulation mode** and reports the intended change. | `-WhatIf` (writes need `-Commit`; never leaves a policy in enforce) |
| 3 | **DLPGDPR-Validate.ps1** | Validation checker: confirms the GDPR policy set is in simulation, scoped to the correct locations/SITs, and (optionally) checks endpoint-location/onboarding readiness — reports pass/fail per gate. | Read-only |
| 4 | **DLPGDPR-Report.ps1** | DLP match / false-positive tuning report: exports simulation/enforcement matches for TP-vs-FP classification and rate calculation. | Read-only |
| 5 | **DLPGDPR-Set-Scope.ps1** | Scope/health helper: reports a policy's locations/mode/scope and (with `-Commit`) adjusts the included/excluded users/groups (e.g. the pilot ring). | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- EU-personal-data SITs/classifiers mapped for every in-scope category (EU/GDPR built-in reused;
  `EU National ID – Custom SIT – GDPR` and, where needed, `Data Subject Records – EDM – GDPR` for gaps;
  trainable classifiers for special-category data).
- Email, cloud (SPO/OneDrive/Teams), and endpoint DLP policies built and **proven in simulation**.
- False-positive rate measured and tuned to at/under the agreed threshold (Gate B), with custom-SIT precision
  confirmed.
- Enforcement live for the pilot ring with policy tips + override, then expanded per the DPO function's
  action determination (Gate A).
- DLP alerts raised, triaged to disposition with least-privilege evidence access and a DPO/breach hand-off,
  and evidence trailed in Activity Explorer (Gate C).
- Simulation-rollback and safe-by-default scripts verified; change log and DPO/legal sign-offs captured.

> **Boundary:** the solution delivers the technical control and the evidence. The **data in scope, the lawful
> basis, the special-category treatment, whether a transfer is restricted, the enforced action per category,
> the retention position, and the acceptable false-positive threshold** are data-protection/privacy
> (DPO)/legal determinations, captured alongside the evidence.
