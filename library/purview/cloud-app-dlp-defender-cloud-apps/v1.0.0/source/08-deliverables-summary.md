# 8. Deliverables Summary — Cloud-App DLP (Defender for Cloud Apps)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The cloud-app DLP model — the two control planes (**file policies** at rest via API connectors, **session/access policies** in real time via Conditional Access App Control), how they reuse Purview SITs/labels, and the pilot→enforce journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (MDCA licensing, MDCA roles, app connectors, Conditional Access App Control routing, SIT/label classification layer, pilot ring, alert triage owner) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → enable the two planes → confirm detection → build policies **in test mode** (alert-only / Monitor-only, CA report-only) → tune false positives → enforce to a pilot ring → expand; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — leaks controlled at rest + real time (A), low false-positive rate (B), incidents handled (C) — plus test-mode-first and rollback checks, all with fake test data. |
| **Troubleshooting Guide** | The common failure modes (file policy not matching, connector unhealthy, session control not engaging, CA App Control not routing, floods of false positives, no alerts) and how to resolve them. |
| **Best Practices** | Test-mode-first discipline, picking the right plane, false-positive tuning, session-control and connector specifics, classification hygiene, and operations/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Microsoft Graph / Security & Compliance PowerShell / MDCA REST (read-only)
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No credentials
are stored in code — the optional MDCA REST API token is read from an environment variable, never hardcoded.
They connect via `Connect-MgGraph`, `Connect-IPPSSession`, and (optionally) the documented MDCA REST API.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **DLPCLOUD-Discovery.ps1** | Cloud-app DLP posture: sensitivity labels + SITs available for content inspection, Conditional Access policies routing sessions to MDCA, and (with an API token) connected app connectors + existing file/session policies. | Read-only |
| 2 | **DLPCLOUD-ConnectorReadiness.ps1** | Two-plane readiness checker: **file plane** (app connectors connected/healthy, via MDCA REST if a token is present) and **session plane** (Conditional Access App Control routing, via Graph) — reports whether each is usable. | Read-only |
| 3 | **DLPCLOUD-FilePolicy.ps1** | File/session policy config helper: validates the referenced SIT/label exist, emits the exact policy specification to enter in the portal, and (with a token) lists current policies read-only. | `-WhatIf` (writes need `-Commit`; never creates an enforcing policy) |
| 4 | **DLPCLOUD-Report.ps1** | Match / false-positive tuning report: exports Cloud-Apps alerts (Graph security API) and, with a token, file-policy matches/activities for TP-vs-FP classification and rate calculation. | Read-only |
| 5 | **DLPCLOUD-SessionScope.ps1** | Session-control scope/health helper: reports the Conditional Access App Control policy's scope (users/groups/apps routed) and its state (report-only vs on), flagging enforcement outside the pilot ring. | Read-only (`-WhatIf` guard on any change guidance) |

## Definition of done
- The two control planes wired: in-scope apps **connected** (file plane) and/or **onboarded to Conditional
  Access App Control** (session plane), with the CA policy started in **report-only**.
- SITs/sensitivity labels confirmed for every in-scope data category (reused from Purview).
- File policies (**alert-only**) and session/access policies (**Monitor only**) built and proven in test mode.
- False-positive rate measured and tuned to at/under the agreed threshold (Gate B).
- Enforcement live for the pilot ring — at-rest governance on, CA policy on, session Block/Protect — then
  expanded per compliance's action determination (Gate A).
- MDCA alerts raised, triaged to disposition, and evidence trailed (Gate C).
- Test-mode rollback (report-only/Monitor) and safe-by-default scripts verified; change log and compliance
  sign-offs captured.

> **Boundary:** the solution delivers the technical control and the evidence. The **apps and data categories
> in scope, the classifiers that legally apply, the governance/session action per category, and the
> acceptable false-positive threshold** are compliance/privacy/legal determinations, captured alongside the
> evidence.
