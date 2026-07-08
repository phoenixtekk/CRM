# 8. Deliverables Summary — Document Fingerprinting (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | How document fingerprinting works — turning a standard form into a fingerprint SIT, wiring it to DLP, what it can and cannot detect, and the simulate→enforce journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (DLP/fingerprint licensing, DLP roles, text-based source templates, form inventory, a form-version refresh process, pilot ring, alert triage owner) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → assemble source forms → create the fingerprint(s) + SIT → build the DLP policy **in simulation** → prove detection → enforce to a pilot ring → expand; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — forms detected (A), specific / low false-positive (B), incidents handled (C) — plus simulation-first, rollback, and refresh checks, all with fake test data. |
| **Troubleshooting Guide** | The common failure modes (fingerprint won't create, form not detected, over-matching, no alerts, refresh drift) and how to resolve them. |
| **Best Practices** | Sourcing the right template, simulate-first discipline, keeping detection specific, fingerprint refresh, user-experience design, classification hygiene, and operations/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No credentials
are stored in code. They connect via `Connect-IPPSSession`. No cmdlets are invented — all are standard
Security & Compliance PowerShell.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **CLSFINGER-Discovery.ps1** | Fingerprint posture assessment: existing document-fingerprint SITs, the DLP policies that reference them and their **mode**, and readiness signals. | Read-only |
| 2 | **CLSFINGER-CreateFingerprint.ps1** | Fingerprint/SIT builder: creates a fingerprint from a text-based template (`New-DlpFingerprint`) and creates/updates the fingerprint **SIT** (`New-/Set-DlpSensitiveInformationType`). Handles PS 5.1 and 7 byte reads. Never touches a DLP policy's enforce state. | `-WhatIf` (writes need `-Commit`) |
| 3 | **CLSFINGER-Validation.ps1** | Wiring validator: confirms the fingerprint SIT exists, that the DLP policy references it, and that the policy is in **simulation** (or reports its mode). | Read-only |
| 4 | **CLSFINGER-Report.ps1** | Detection / false-positive report: exports DLP detections for the fingerprint policy for TP-vs-FP classification and rate calculation. | Read-only |
| 5 | **CLSFINGER-Set-Scope.ps1** | Scope/health helper: reports and (with `-Commit`) adjusts a policy's included/excluded users/groups (e.g. the pilot ring), and reports fingerprint-SIT health. | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- Every in-scope standard form has a text-based template, fingerprinted into a named **fingerprint SIT**
  (related forms grouped where sensible).
- A DLP policy references the fingerprint SIT and has been **proven in simulation** — the filled forms
  detected, unrelated content not.
- False-positive rate measured and at/under the agreed threshold; over-matching resolved by re-sourcing
  or splitting SITs (Gate B).
- Enforcement live for the pilot ring with policy tips + override, then expanded per compliance's action
  determination (Gate A).
- DLP alerts raised, triaged to disposition, and evidence trailed in Activity Explorer (Gate C).
- A **fingerprint refresh process** in place for form-version changes; simulation-rollback and
  safe-by-default scripts verified; change log and compliance sign-offs captured.

> **Boundary:** the solution delivers the technical control and the evidence. The **forms in scope, the
> legal/regulatory obligation for each, and the enforced action per form** are compliance/privacy/legal
> determinations, captured alongside the evidence.
