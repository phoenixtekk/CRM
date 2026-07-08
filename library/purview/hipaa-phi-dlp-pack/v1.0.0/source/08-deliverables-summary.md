# 8. Deliverables Summary — HIPAA / PHI DLP Pack (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The PHI DLP model — HIPAA-relevant SITs/classifiers, the five locations (email, SharePoint, OneDrive, Teams, endpoint), policy tips/overrides/encryption, and the simulate→enforce journey; naming convention; and the clear boundary that breach determination is deferred. |
| **Requirements Guide** | Solution-specific prerequisites (DLP/Endpoint licensing, DLP roles, device onboarding, PHI classification intent + HIPAA SIT map, EDM source data, pilot ring, alert triage owner + Privacy/Security escalation) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → design HIPAA SITs (+ MRN/EDM) → build policies **in simulation** → tune PHI false positives (co-occurrence) → enforce to a pilot ring (encrypt PHI mail) → expand; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — PHI leaks blocked (A), low false-positive rate (B), incidents handled + escalated (C) — plus simulation-first and rollback checks, all with fake PHI test data. |
| **Troubleshooting Guide** | The common failure modes (policy not matching, PHI over-matching, endpoint location missing, no alerts) and how to resolve them. |
| **Best Practices** | Simulate-first discipline, PHI-as-a-combination tuning, clinical-audience UX, endpoint specifics, classification hygiene, and HIPAA-facing operations/evidence/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`, and the
config helper is **simulation-only** (it never leaves a policy in enforce). No credentials are stored in
code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **PHIDLP-Discovery.ps1** | DLP posture + HIPAA-SIT coverage assessment: existing policies and their mode, presence of the HIPAA-relevant built-in SITs (SSN, ICD-9-CM, ICD-10-CM, DEA Number), custom-SIT coverage, licensing/endpoint readiness signals. | Read-only |
| 2 | **PHIDLP-Config.ps1** | PHI DLP policy configuration/remediation helper: creates/updates a policy **in simulation mode** with the chosen PHI SITs and reports the intended change. | `-WhatIf` (writes need `-Commit`; simulation-only, never enforce) |
| 3 | **PHIDLP-Validate.ps1** | Validation checker: for each expected policy, reports mode (simulation vs enforce), whether the PHI SITs are attached, and the location scope — the pass/fail gate before and after enforcement. | Read-only |
| 4 | **PHIDLP-Report.ps1** | PHI DLP match / false-positive tuning report: exports simulation/enforcement matches for TP-vs-FP classification and rate calculation. | Read-only |
| 5 | **PHIDLP-ScopeHealth.ps1** | Scope/health helper: reports a policy's included/excluded scope plus endpoint/licensing health signals, and (with `-Commit`) sets the pilot-ring scope. | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- HIPAA-relevant SITs/classifiers mapped for every in-scope PHI category (built-in HIPAA SITs reused;
  custom MRN / EDM / trainable only for gaps).
- Email, cloud (SPO/OneDrive/Teams), and endpoint PHI DLP policies built and **proven in simulation**.
- False-positive rate measured and tuned (with **co-occurrence** where it fits) to at/under the agreed
  threshold (Gate B).
- Enforcement live for the pilot ring with policy tips + override + **encryption of outbound PHI email**,
  then expanded per compliance's action determination (Gate A).
- DLP alerts raised, triaged to disposition, **escalated to the Privacy/Security Officer** where a
  disclosure may be reportable, and evidence trailed in Activity Explorer (Gate C).
- Simulation-rollback and safe-by-default scripts verified (`PHIDLP-Validate.ps1` green); change log and
  compliance sign-offs captured as the HIPAA control record.

> **Boundary:** the solution delivers the technical control and the evidence. The **data that is PHI,
> the classifiers that legally apply, the enforced action per category, the acceptable false-positive
> threshold, evidence retention, and whether any event is a reportable HIPAA breach** are
> compliance/privacy/legal determinations, captured alongside the evidence.
