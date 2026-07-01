# 8. Deliverables Summary — Forcepoint Neo to Netskope Migration (Legacy Web Filtering)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The migration model, policy translation, agent coexistence and steering conflicts, staged cutover and decommission, and why it matters |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Network) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: inventory, translate, coexist, cut over per ring, validate parity, remove legacy agent, decommission |
| 5. Testing Guide | Validation procedures with pass/fail and parity gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NSMIG-Discovery.ps1` | Detects the Forcepoint Neo agent and current web-steering state on a device (read-only) |
| `NSMIG-Validation.ps1` | Confirms coexistence/cutover state: which agents are present and which is steering (read-only) |
| `NSMIG-Report.ps1` | Fleet coverage and conflict report from Intune (agents present, steering owner, legacy estate) via Microsoft Graph (read-only) |
| `NSMIG-Remediation.ps1` | Safe remediation; removes the legacy Forcepoint Neo agent (defaults to `-WhatIf`) |
| `NSMIG-Set-MigrationRingTargeting.ps1` | Builds/populates the migration-ring, coexistence, and enforce Entra groups via Microsoft Graph |

## Named artifacts (reused verbatim)
- `Translated Web Filtering Policy - Org - Netskope`
- `Migration Ring - Pilot - Cutover`
- `Migration Ring - Broad - Cutover`
- `Legacy Estate - Forcepoint Neo - Inventory`
- `Steering Group - Netskope - Enforce`
- `Coexistence Group - Netskope - Passive`

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: `Assess -> Configure -> Pilot -> Validate -> Expand.`

## Outcome
Web filtering moved off Forcepoint Neo to Netskope with no gap in protection — policy translated,
agents coexisting then cut over in stages, parity validated, and the legacy platform decommissioned
after a final parity gate.
