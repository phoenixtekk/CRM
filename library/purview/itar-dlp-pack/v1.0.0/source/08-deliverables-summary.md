# 8. Deliverables Summary — ITAR DLP Pack (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The ITAR technical-data DLP model — the export-marking classification (custom SIT / keyword dictionary), the optional `Export Controlled // ITAR` sensitivity label, the egress control across email, SharePoint, OneDrive, Teams, and endpoint, the evidence artifact, and the simulate→enforce journey; naming convention and the export-determination boundary. |
| **Requirements Guide** | Solution-specific prerequisites (DLP/Endpoint/EDM licensing and the correct cloud environment, least-privilege DLP roles, in-scope workloads, the technical-data classification intent, the pilot ring, Empowered Official / export-compliance stakeholders, and alert/evidence routing) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: assess + scope/licensing → design the technical-data detection (prefer the label) → build the policy `ITAR Technical-Data Egress – AllWorkloads – Pilot` **in simulation/test** → pilot & tune → validate gates → (approval) promote to **enforce** → expand → run the evidence cadence; each artifact named, each phase gated with a rollback. |
| **Testing & Validation** | Pass/fail gates covering discovery, scope/coverage, simulation matching, tuned false-positive rate, validation-before-enforce, enforced-action verification, and rollback — all exercised with **synthetic/fabricated** technical-data test content only. |
| **Troubleshooting Guide** | The common failure modes (classification not firing or over-firing, policy mode/scope wrong, egress not restricted, endpoint activities missed, false-positive floods, no alert/empty report, connectivity) and how to resolve them. |
| **Best Practices** | Simulate-first discipline, marking-and-label-based detection, false-positive tuning, the egress-vs-deemed-export boundary, sovereign-cloud considerations, endpoint specifics, evidence cadence, and change governance. |
| **Executive Summary** | One-page business framing for approvers and the export-compliance function. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`, and the config
tool never enforces without `-PromoteToEnforce -Commit`. No credentials are stored in code. They connect via
`Connect-IPPSSession` (use the `-ConnectionUri` for your cloud — Commercial / GCC High / DoD) and/or Graph.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **DLPITAR-Discovery.ps1** | DLP posture + technical-data classification assessment: existing policies/rules and their mode, available sensitive-information-types, whether a technical-data classification already exists; writes/compares the policy baseline (`-SaveBaseline` / `-CompareBaseline`) for drift detection. | Read-only |
| 2 | **DLPITAR-Set-Policy.ps1** | Configuration/remediation helper: creates the policy `ITAR Technical-Data Egress – AllWorkloads – Pilot` and rule `Technical-Data Egress Rule – Markings+Label – v1` **in simulation/test**; `-PromoteToEnforce` enables enforcement, `-Disable` rolls back. | `-WhatIf` (writes need `-Commit`; enforce only via `-PromoteToEnforce -Commit`) |
| 3 | **DLPITAR-Scope-Health.ps1** | Scope/health helper: produces `Workload Scope – ITAR DLP – Map` — which workloads are in scope, endpoint onboarding status, and which DLP surfaces the licensing unlocks. | Read-only |
| 4 | **DLPITAR-Validation.ps1** | Validation checker: confirms the policy is in the expected mode, scoped to the intended workloads, and that the rule references the technical-data classification with an external-egress scope/action — reports pass/fail per gate. | Read-only |
| 5 | **DLPITAR-Report.ps1** | Evidence report: produces `ITAR DLP Evidence – Egress – Report` — matches by workload/recipient scope and admin action, from the unified audit log, for TP/FP tuning and export-compliance evidence. | Read-only |

## Definition of done
- Technical-data detection defined for the markings/identifiers in scope (custom SIT / keyword dictionary,
  and where used the `Export Controlled // ITAR` label; EDM where licensed and needed).
- The ITAR DLP policy built across the in-scope workloads and **proven in simulation/test** on
  `ITAR Pilot Ring – Stage1`.
- False-positive rate measured with `DLPITAR-Report.ps1` and tuned to a level export-compliance accepts;
  routine engineering work not flagged.
- Validation gates green (`DLPITAR-Validation.ps1`) and simulation results signed off before enforcement.
- Enforcement live (external send/share restricted; endpoint channels added as licensing allows), with a
  verified single-command rollback to test/disabled.
- Evidence artifact (`ITAR DLP Evidence – Egress – Report`) produced on cadence with least-privilege access;
  drift monitored via `-CompareBaseline`; change log captured in `Change Record – ITAR DLP – ChangeControl`.

> **Boundary:** the solution delivers the technical DLP control and the evidence. Whether an item **is**
> ITAR-controlled technical data, **who is a foreign person**, USML categorization, jurisdiction
> (ITAR vs EAR), authorization/licensing, and **deemed-export** access are **Empowered Official /
> export-compliance / legal** determinations — captured alongside the evidence, not decided by this pack.
