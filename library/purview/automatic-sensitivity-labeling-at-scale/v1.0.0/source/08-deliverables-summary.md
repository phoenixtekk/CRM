# 8. Deliverables Summary — Automatic Sensitivity Labeling at Scale (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, scope boundary, and what's in the box |
| 1. Solution Overview | What this delivers (client-side + service-side automatic labeling), the two engines and where each applies, the simulation-first model, the licensing caveat, the scope boundary (applies existing published labels), and the naming convention |
| 2. Requirements Guide | Every solution-specific prerequisite with Verify / Implement-if-missing (labels already published, E5/E5 Compliance licensing, Information Protection role, S&C PowerShell, match conditions, in-scope workloads + pilot subset, simulation-first commitment, existing-label behavior) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell steps: assess posture, design conditions, configure client-side (recommend), create service-side SIMULATION policies (SPO/ODB then Exchange), let simulation run, validate precision, enforce on pilot subset, expand tenant-wide, report + health-check — each step with pass/fail gates and rollback |
| 5. Testing Guide | Ten validation procedures with explicit pass/fail, the precision **enforcement gate**, existing-label behavior, and proven rollback |
| 6. Troubleshooting Guide | Field issues (labels missing, condition not visible, simulation empty, surprise encryption, coverage flat) and remediation |
| 7. Best Practices | Field-proven recommendations for labeling accurately and safely at scale |

## PowerShell scripts
All are safe-by-default (read-only, or `-WhatIf` / service-side **simulation** mode unless `-Commit`),
use `Connect-IPPSSession` (Security & Compliance PowerShell) and/or `Connect-MgGraph`, use only
documented cmdlets, and store **no** credentials.
| Script | What it does |
|---|---|
| `IPAUTO-Discovery.ps1` | Read-only inventory of existing sensitivity **labels** (and which carry client-side auto-labeling), **label policies**, and every **service-side auto-labeling policy + rule with its mode**. Confirms the target label exists/is published. Writes `AutoLabel Posture – Estate – Discovery` |
| `IPAUTO-Configure.ps1` | Configuration/remediation helper. Defaults to `-WhatIf`. `-ClientSide` sets a label's client-side auto-labeling conditions (recommend/auto-apply via `Set-Label`); `-ServiceSide` creates a service-side policy **in simulation** (`New-AutoSensitivityLabelPolicy -Mode TestWithoutNotifications`) + rule; `-Enforce -Locations <pilot|All>` flips a validated policy to `Enable` on a location scope; `-BackToSimulation` rolls back; `-UpdateRule` tunes conditions. Every write is gated behind `-Commit` |
| `IPAUTO-Report.ps1` | Read-only. Confirms a service-side policy is still in **simulation**, reports scan/deployment status, and points to the **matched items** (what *would* be labeled) for precision review. Writes `AutoLabel Simulation – <policy> – Review` |
| `IPAUTO-Report.ps1` | Read-only labeling-coverage rollup from Purview auditing (label-applied activity by workload) to confirm coverage is climbing after enforcement. Writes `AutoLabel Coverage – Estate – Report` |
| `IPAUTO-ScopeHealth.ps1` | Read-only scope/health helper: resolves a policy's **locations** (pilot subset vs `All`), reports distribution/deployment status, and confirms sign-in + licensing surface. Writes `AutoLabel Scope Health – <policy> – Check` |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate) →
  Validate → Expand (enforce at scale).**

## Outcome
Sensitive content labeled **automatically and consistently, without the user** — client-side labeling
recommending the right label as content is created, and tuned service-side auto-labeling sweeping
existing data at rest and mail in transit — every service-side policy proven in **simulation** and
enforced by **location subset first, then tenant-wide**. Classification, records, and legal
determinations remain with the organization's governance functions; this solution delivers the
technical method and the evidence that labels apply accurately and at scale.
