# 8. Deliverables Summary — Microsoft 365 → Google Workspace Migration Program & Wave Plan

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The migration operating model (discovery → design → coexistence → waves → cutover → hypercare), workstream sequencing, and the named program artifacts (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: baseline, design, coexistence, wave plan, per-wave cutover runbooks, go/no-go gates, hypercare |
| 5. Testing Guide | Per-wave validation gates with pass/fail criteria |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Executing waves without rework |

## Named program artifacts
| Artifact | Name |
|---|---|
| Source estate baseline | `GWMIGPROG Discovery - Source Estate - Baseline` |
| Target & tooling design | `GWMIGPROG Design - Target & Tooling - Program` |
| Coexistence design | `GWMIGPROG Coexistence - Mail & Calendar - Transition` |
| Wave plan | `GWMIGPROG Wave Plan - Segmentation - 150k` |
| Per-wave cutover runbook | `GWMIGPROG Runbook - Cutover - Per Wave` |
| Go/no-go gate | `GWMIGPROG Gate - Go/No-Go - Per Wave` |
| Program cadence & RACI | `GWMIGPROG Cadence & RACI - Program - All Stages` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWMIGPROG-Discovery.ps1` | Baselines the Microsoft 365 source estate for wave planning: user/mailbox counts, licensed users, shared mailboxes, resource/room mailboxes, and groups (Microsoft Graph, read-only) |
| `GWMIGPROG-Validation.ps1` | Confirms per-wave readiness: the wave's users are provisioned, licensed, and coexistence/target signals are in place (read-only) |
| `GWMIGPROG-Report.ps1` | Renders migration progress/coverage: waves complete, users migrated vs total, and per-wave coverage (Microsoft Graph, read-only) |
| `GWMIGPROG-Remediation.ps1` | Safe remediation of wave-readiness data gaps; runs with `-WhatIf` by default |
| `GWMIGPROG-Set-ScopeTargeting.ps1` | Builds a wave's target group in Microsoft Entra from a members CSV; runs with `-WhatIf` by default |

## The Migration-Program playbook (outline)
A single reusable playbook the program runs from, assembled from the artifacts above:

1. **Program charter** — scope (150k users, in-scope services), the operating model's six stages,
   and `GWMIGPROG Cadence & RACI - Program - All Stages`.
2. **Discovery baseline** — `GWMIGPROG Discovery - Source Estate - Baseline`: counts, data volumes,
   shared/resource mailboxes, groups, and mail-touching integrations.
3. **Target & tooling design** — `GWMIGPROG Design - Target & Tooling - Program`: target architecture,
   identity/provisioning model, and the per-service tooling pattern (mail, Drive, chat), tool-agnostic.
4. **Coexistence design** — `GWMIGPROG Coexistence - Mail & Calendar - Transition`: mail routing
   (split/dual delivery), calendar interop, and the intended decommission point.
5. **Wave plan** — `GWMIGPROG Wave Plan - Segmentation - 150k`: Wave 0 pilot, coherent business-unit
   waves, data-heavy users spread, one user per wave.
6. **Per-wave cutover runbook** — `GWMIGPROG Runbook - Cutover - Per Wave`: readiness → mail-flow/DNS →
   data move → validation → rollback.
7. **Go/no-go gate** — `GWMIGPROG Gate - Go/No-Go - Per Wave`: the criteria each wave clears before the
   next starts.
8. **Hypercare & decommission** — per-wave hypercare, wave closure, and end-of-program coexistence and
   source-tenant decommission.

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable migration program following the model: Assess, then Configure, then Pilot, then
  Validate, then Expand.

## Outcome
150k+ users moved from Microsoft 365 to Google Workspace wave by wave — coexistence managed, cutovers
governed by go/no-go gates, and the cutover runbook proven on a pilot wave — so waves execute without
architectural rework and the transition state is decommissioned only when the estate is fully migrated.
