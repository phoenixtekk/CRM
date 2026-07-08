# 8. Deliverables Summary — PCI-DSS DLP Pack (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The card-data DLP model — the PAN detector (built-in Credit Card Number SIT + optional EDM), the five locations (email, SharePoint, OneDrive, Teams, endpoint), policy tips/overrides, and the simulate→enforce journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (DLP/Endpoint/EDM licensing, DLP roles, device onboarding, card-data classification intent, EDM source PAN table, pilot ring, PAN alert triage owner) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → confirm the PAN detector → build policies **in simulation** → tune false positives → enforce to a pilot ring → expand; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — PAN leaks blocked (A), low false-positive rate (B), incidents handled (C) — plus simulation-first and rollback checks, all with **fake test PANs**. |
| **Troubleshooting Guide** | The common failure modes (policy not matching, endpoint location missing, PAN false positives on internal reference numbers, no alerts) and how to resolve them. |
| **Best Practices** | Simulate-first discipline, PAN-focused false-positive tuning, truncated-PAN/SAD handling, user-experience design, endpoint specifics, CDE-scoping hygiene, and operations/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No credentials
are stored in code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **PURVPCI-Discovery.ps1** | Card-data DLP posture + PAN-detector coverage assessment: existing policies and their mode, the built-in Credit Card Number SIT and any EDM schemas, licensing/endpoint readiness signals. | Read-only |
| 2 | **PURVPCI-Config.ps1** | PAN DLP policy configuration helper: creates/updates a policy **in simulation mode** for the Credit Card Number SIT and reports the intended change. | `-WhatIf` (writes need `-Commit`; never leaves a policy in enforce) |
| 3 | **PURVPCI-EndpointReadiness.ps1** | Endpoint-DLP onboarding/readiness checker: onboarded-device count/state and whether the Devices location is usable for card-data endpoint policies. | Read-only |
| 4 | **PURVPCI-Report.ps1** | PAN match / false-positive tuning report: exports simulation/enforcement matches for TP-vs-FP classification and rate calculation. | Read-only |
| 5 | **PURVPCI-Set-Scope.ps1** | Scope/config helper: reports and (with `-Commit`) adjusts a policy's included/excluded users/groups (e.g. the pilot ring). | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- The built-in **Credit Card Number** SIT confirmed as the PAN detector (EDM added only where near-zero
  false positives on your real PANs are required).
- Email, cloud (SPO/OneDrive/Teams), and endpoint PAN DLP policies built and **proven in simulation**.
- False-positive rate measured and tuned to at/under the agreed threshold (Gate B), with truncated PANs
  and internal reference numbers correctly not matched.
- Enforcement live for the pilot ring with policy tips + override, then expanded per compliance's action
  determination (Gate A).
- PAN alerts raised, triaged to disposition per the incident-response plan, and evidence trailed in
  Activity Explorer (Gate C).
- Simulation-rollback and safe-by-default scripts verified; change log and compliance sign-offs captured
  as assessor evidence.

> **Boundary:** the solution delivers the technical control and the evidence. The **CDE boundary and PCI
> scope, which card-data flows are in scope, the enforced action per flow, the acceptable false-positive
> threshold, and PCI-DSS compliance/attestation** are compliance/PCI/QSA determinations, captured
> alongside the delivered evidence. This solution does not attest to PCI-DSS compliance.
