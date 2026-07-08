# 8. Deliverables Summary — Enterprise DLP Assessment & Strategy (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The assess→roadmap model — posture baseline, sensitive-data discovery (Content Explorer for data at rest, a monitor-only simulation policy for data in motion), exposure ranking, and a prioritized rollout roadmap; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (discovery-surface licensing, read-heavy roles incl. Content Explorer viewers, audit logging, classification intent + candidate-category shortlist, approval for one simulation policy, scope/dwell/sign-off path) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: baseline posture → discover data at rest → stand up a monitor-only **simulation** policy → measure movement → rank exposure and build the roadmap → ratify and hand off; each phase named, gated, and reversible — **nothing is enforced**. |
| **Testing & Validation** | Pass/fail gates for the four outcomes — posture baselined (A), sensitive data discovered rest+motion (B), exposure ranked / roadmap sound (C), nothing enforced & reversible (D) — with fake test data only. |
| **Troubleshooting Guide** | The common failure modes (Content Explorer empty/denied, simulation policy not matching, no movement data, roadmap can't be ranked) and how to resolve them. |
| **Best Practices** | Discover-before-design discipline, non-enforcing/reversible assessment, ranking by exposure, roadmap shaped for an enforcement project, and licensing/privacy boundaries. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only** except the simulation-baseline helper, which is **`-WhatIf` by default** and
requires an explicit `-Commit` (and only ever creates a **simulation** policy). No credentials are stored in
code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **DLPASSESS-Discovery.ps1** | DLP posture baseline: existing policies and their mode, built-in vs custom SIT coverage, sensitivity/retention labels, audit/Content-Explorer readiness signals. | Read-only |
| 2 | **DLPASSESS-DataScan.ps1** | Sensitive-data discovery (data at rest): exports Content Explorer results per SIT/label — item counts and locations across Exchange/SPO/OneDrive/Teams. | Read-only |
| 3 | **DLPASSESS-Validation.ps1** | Readiness & non-enforcement gate: audit logging on, Content Explorer roles held, discovery surfaces available, and no unintended enforcing policy. | Read-only |
| 4 | **DLPASSESS-Baseline.ps1** | Monitor-only simulation baseline helper: creates/updates (or removes) the one `DLP Baseline – All Locations – Simulation` policy that measures movement. **Never** creates an enforcing policy. | `-WhatIf` (writes need `-Commit`) |
| 5 | **DLPASSESS-Report.ps1** | Exposure/movement report: aggregates simulation DLP matches by SIT, workload, volume, and external exposure — the ranking input for the roadmap. | Read-only |

## Definition of done
- Current DLP **posture baselined** — every policy, its mode, and SIT/label coverage recorded (Gate A).
- **Sensitive data discovered** — a data-at-rest map (Content Explorer) and a data-in-motion report
  (simulation baseline + Activity Explorer), reconciled, with coverage gaps documented (Gate B).
- **Exposure ranked** and a **prioritized, simulation-first rollout roadmap** produced — every step gated
  and reversible, detector gaps captured, governance determinations flagged **[to be ratified]** (Gate C).
- **Nothing enforced** — the only Purview object created is a simulation policy with zero user impact,
  proven removable; scripts safe-by-default (Gate D).
- The roadmap **ratified** by compliance/privacy/legal/records and **handed off** to a DLP enforcement
  project, with the detector-build backlog attached.

> **Boundary:** the solution delivers the assessment, the discovery evidence, and the recommended roadmap.
> The **data categories in scope, the classifiers that legally apply, and the enforced action per category**
> are compliance/privacy/legal determinations, captured alongside the evidence.
