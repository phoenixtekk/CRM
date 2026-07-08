# 8. Deliverables Summary — Sensitivity Label Migration Project

## What you receive
A complete, self-guided package to **map** legacy/third-party classifications to Microsoft Purview
sensitivity labels and **reclassify** the content onto them — detection, mapping matrix, auto-labeling
in simulation, precision measurement, and enforcement — using only the Microsoft Purview portal and
Security & Compliance PowerShell.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The migration model (legacy value → mapped Purview label → detection → reclassify), the mapping dimensions, naming convention, honest limits (detectability, E5 gating, no auto-convert), and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites (auto-labeling licensing, target labels already published, a legacy export from the source tool, per-value detectability, Information Protection role, S&C PowerShell/Graph, a pilot scope + simulation-first commitment, and a residual-marking reconciliation decision) on top of the Purview Global Requirements. |
| **Implementation Guide** | Ordered steps: inventory both sides → build the mapping matrix + author detection SITs → create reclassification auto-labeling **in simulation** (`-WhatIf`→commit) → run simulation + measure precision → validate coverage → **enforce from simulation to reclassify** the pilot → expand location-by-location + reconcile markings + decommission the source tool. Each step named, gated, and reversible. |
| **Testing & Validation Guide** | 10 pass/fail tests — inventory, mapping completeness, SIT detection, simulation-only posture, match report, precision sign-off (the enforcement gate), enforced==simulation, encryption/marking behavior, residual-marking reconciliation, and coverage/health. |
| **Best Practices** | Mapping, detection, simulation/precision, enforcement/protection, reconciliation/decommission, program/change-management, and safety guidance. |
| **Troubleshooting Guide** | The common failure modes (SIT doesn't detect, simulation stuck/empty, wrong-label matches, surprise encryption, double-marking, policy enforcing early) with resolutions. |

## PowerShell tools (5)
All run through `Connect-IPPSSession` (Security & Compliance PowerShell); read-only or `-WhatIf` by
default, writes gated behind `-Commit` and enforcement behind an explicit `-EnforceFromSimulation`. No
credentials in code.

| Script | Role | Default |
|---|---|---|
| `IPMIG-Discovery.ps1` | **Two-sided inventory** — the target Purview estate (labels, label policies, auto-labeling policies + mode, custom SITs) cross-referenced against the legacy classification values exported from the source tool. | Read-only |
| `IPMIG-Set-Migration.ps1` | **Reclassification config/remediation helper** — from the mapping CSV, create the reclassification auto-labeling policies + rules **in simulation** (SIT → mapped label), then enforce-from-simulation, return-to-simulation, add locations, or remove a policy. | `-WhatIf` |
| `IPMIG-Validation.ps1` | **Simulation & health helper** — report a reclassification policy's simulation mode/progress and the items it would reclassify (`-SimReport`), and run a full label/policy/auto-label health check (`-Full`). | Read-only |
| `IPMIG-Report.ps1` | **Coverage & precision report** — every legacy value → mapped/unmapped, detection SIT present, policy simulation vs enforced, and simulated match count; CSV export. | Read-only |
| `IPMIG-Scope-Health.ps1` | **Mapping-health check** — flag legacy values with no mapping, mappings referencing a missing SIT or target label, and policies enforcing before sign-off. | Read-only |

## Outcomes
- A signed-off **mapping matrix** — every legacy/third-party classification value mapped to one existing
  Microsoft Purview sensitivity label.
- **Detection** proven per value in **simulation**, with precision measured and accepted before any
  content is touched.
- Content **reclassified** onto the mapped Purview labels by enforced auto-labeling — one classification
  scheme the platform actually governs.
- Residual legacy markings **reconciled** and the source tool **decommissioned** on a controlled
  schedule.
- Repeatable read-only tooling to re-baseline coverage and catch new legacy values over the migration's
  life.

## Explicitly out of scope (deferred)
- **Target-label protection determinations** — whether a mapped label encrypts or reproduces the legacy
  tool's protection is owned by records/security/compliance/legal; this solution provides the mapping
  method and evidence, not the determination.
- **Building the destination taxonomy, DLP, and retention** — the target labels are assumed to exist
  (see the sensitivity & retention labels implementation and other Purview solutions).
- Any capability your **licensing/tenant** does not include — service-side auto-labeling (the
  reclassification engine) is E5-gated; verify before relying on it.
- **Making an undetectable legacy marking detectable** — where the source tool wrote to an opaque store,
  the fix is source-tool remediation or manual re-labeling, not an invented detection.
