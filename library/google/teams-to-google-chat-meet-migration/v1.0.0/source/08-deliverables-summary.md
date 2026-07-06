# 8. Deliverables Summary — Microsoft Teams → Google Chat & Meet Migration & Coexistence

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The Teams → Chat/Meet model (channels→spaces, meetings→Meet, files, coexistence), the honest message-history scope, and the named artifacts (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: baseline, map channels→spaces, decide the path, meeting coexistence, wave plan, per-wave cutover runbook, go/no-go gates, hypercare |
| 5. Testing Guide | Per-wave validation gates with pass/fail criteria (spaces created, meetings work, users active) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Adoption and coexistence without stranding users |

## Named artifacts
| Artifact | Name |
|---|---|
| Source Teams estate baseline | `GWCHAT Discovery - Teams Estate - Baseline` |
| Channel → space mapping | `GWCHAT Mapping - Channels to Spaces - Program` |
| Meetings transition design | `GWCHAT Meetings - Teams to Meet - Transition` |
| Coexistence design | `GWCHAT Coexistence - Chat & Meet - Transition` |
| Wave plan | `GWCHAT Wave Plan - Segmentation - Teams` |
| Per-wave cutover runbook | `GWCHAT Runbook - Cutover - Per Wave` |
| Go/no-go gate | `GWCHAT Gate - Go/No-Go - Per Wave` |
| Adoption & comms plan | `GWCHAT Adoption - Change & Comms - Program` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWCHAT-Discovery.ps1` | Baselines the Microsoft Teams source estate for the migration: teams, standard channels per team, channel membership, and group signals (Microsoft Graph, read-only) |
| `GWCHAT-Validation.ps1` | Confirms per-wave/per-team migration & coexistence readiness: the wave's users are provisioned, licensed, and Chat/Meet-enabled, and mapping/interop signals are asserted (read-only) |
| `GWCHAT-Report.ps1` | Renders coverage/adoption: spaces created vs channels mapped, users active, and per-wave coverage (read-only) |
| `GWCHAT-Remediation.ps1` | Safe remediation of wave/space readiness data gaps in a members/mapping CSV; runs with `-WhatIf` by default |
| `GWCHAT-Set-ScopeTargeting.ps1` | Builds a wave's target group in Microsoft Entra from a members CSV; runs with `-WhatIf` by default |

## The Migration playbook (outline)
A single reusable playbook the migration runs from, assembled from the artifacts above:

1. **Charter** — scope (teams/channels/meetings in scope), the honest history scope, the operating
   model's stages, and the governance owners.
2. **Discovery baseline** — `GWCHAT Discovery - Teams Estate - Baseline`: teams, channels, membership,
   meeting/file signals, and integrations.
3. **Channel → space mapping** — `GWCHAT Mapping - Channels to Spaces - Program`: space name, member
   source, Drive location, and history decision per channel, plus the chosen migration path.
4. **Meetings transition** — `GWCHAT Meetings - Teams to Meet - Transition`: re-issue recurring meetings
   on Meet and the interop (calendar sync + Meet↔Teams) with its decommission point.
5. **Wave plan** — `GWCHAT Wave Plan - Segmentation - Teams`: Wave 0 pilot, teams kept intact, coherent
   business-unit waves, one user per wave.
6. **Per-wave cutover runbook** — `GWCHAT Runbook - Cutover - Per Wave`: readiness → spaces & history →
   meetings/interop → validation → rollback.
7. **Go/no-go gate** — `GWCHAT Gate - Go/No-Go - Per Wave`: the criteria each wave clears before the
   next starts.
8. **Adoption, hypercare & decommission** — `GWCHAT Adoption - Change & Comms - Program`, per-wave
   hypercare, and end-of-program interop decommission with the Teams source retained for legal hold.

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable Teams → Chat/Meet migration following the model: Assess, then Configure, then Pilot, then
  Validate, then Expand.

## Outcome
Collaboration moved from Teams to Chat and Meet — channels mapped to spaces, meetings transitioned to
Meet, users kept active through coexistence, and the honest history scope set and met — proven on a
pilot wave before scaling, with the Teams source retained for legal hold until the estate is fully
migrated.
