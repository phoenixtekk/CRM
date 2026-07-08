# 8. Deliverables Summary — Inactive & Legacy Data Cleanup & Storage Optimization (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The identify→clean-up-defensibly model — ROT/inactive/legacy discovery, retention labels (retain / retain-then-delete / delete-only / disposition-review), retention & deletion policies, static vs adaptive scopes, the in-scope workloads (Exchange, SharePoint, OneDrive, Teams, Groups), and why deletion is hold-checked and never automatic; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (E3-vs-E5 lifecycle licensing, records/lifecycle roles, storage/ROT baseline signals, the **complete hold inventory**, the records-schedule decision source, limited pilot scope + adaptive-scope attributes, disposition review board) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: baseline retention+holds and size ROT → design labels/scopes with the records function → publish/auto-apply **in simulation** and pilot the delete policy on a **limited scope** → **validate no held item is deletable** → pilot with `-WhatIf` + disposition review → expand under change control; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the four headline outcomes — right data identified/scoped (A), **no held item deletable** (B), controlled cleanup + disposition evidence (C), savings measured + reversible (D) — all with fabricated/safe pilot data. |
| **Troubleshooting Guide** | The common failure modes (nothing deleted, wrong content targeted, held content unexpectedly in scope, adaptive scope mis-selecting, disposition/label not applying, reports empty) and how to resolve them. |
| **Best Practices** | Check-holds-first discipline, never-auto-delete, simulation + disposition-review gates, retention precedence, static-vs-adaptive scoping, ROT/savings measurement, and platform-latency realities. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Exchange Online / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. **None permanently
deletes content** — deletion stays a hold-checked portal/policy action. No credentials are stored in code. They
connect via `Connect-IPPSSession`, `Connect-ExchangeOnline`, and/or `Connect-MgGraph`.

| # | Script | Role | Run mode / default safety |
|---|---|---|---|
| 1 | **DLCCLEAN-Discovery.ps1** | Storage/ROT & stale-data posture: existing retention policies/labels/label policies and their scope, **all holds in force** (litigation, eDiscovery case, retention), inactive-mailbox inventory, and mailbox/site/OneDrive last-activity + storage signals. | **Read-only** |
| 2 | **DLCCLEAN-Config.ps1** | Config helper: creates/updates a retention/deletion policy or label on a **named limited scope** (simulation/pilot first). Safe by default; never broad-enforces or auto-deletes. | **`-WhatIf`** (writes need `-Commit`; never deletes content) |
| 3 | **DLCCLEAN-Validate.ps1** | Validation checker: confirms the policy is scoped correctly (not "All"), the action/period match design, and — the safety gate — **cross-checks every hold** so no in-scope item under hold would be deleted. Per-gate pass/fail. | **Read-only** |
| 4 | **DLCCLEAN-Report.ps1** | Storage-savings / candidate-ROT / disposition report: sized stale-data candidates and a disposition preview for review. | **Read-only** |
| 5 | **DLCCLEAN-Set-Scope.ps1** | Scope/health helper: reports a policy's locations/scope/mode; with `-Commit` adjusts included/excluded locations or binds an adaptive scope. Never changes the retain/delete action or deletes content. | **`-WhatIf`** (writes need `-Commit`) |

## Definition of done
- Storage/ROT baseline captured and the **complete hold inventory** enumerated; stale/inactive/legacy candidates
  **identified and sized**.
- Retention labels mapped to every in-scope class with a **records-approved** action/period; cleanup targets
  mapped to named static (pilot) or adaptive scopes.
- Auto-apply proven **in simulation**; the deletion policy piloted on a **limited scope** and previewed with
  `-WhatIf`.
- **Hold cross-check clean** — proven that no in-scope item under hold would be deleted (Gate B) — before any
  enforcement, and re-checked at every expansion.
- Cleanup acted **only** where intended; record-value deletions passed through **disposition review** with the
  **approval evidence** captured (Gate C); measured **storage savings** recorded (Gate D).
- Safe-by-default, non-destructive scripts verified; change log and records/legal **deletion authorization**
  captured.

> **Boundary:** the solution delivers the technical method and the evidence — candidates identified and sized,
> controls configured, no held item deletable, disposition evidence produced. The **retention schedule (how
> long), records status, legal-hold state, and the authorization to delete** are records / compliance / privacy
> / legal determinations, captured alongside the evidence.
