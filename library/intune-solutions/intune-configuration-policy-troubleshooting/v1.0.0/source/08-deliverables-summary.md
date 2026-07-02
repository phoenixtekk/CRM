# 8. Deliverables Summary — Intune Device Configuration & Policy Troubleshooting

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | How a policy travels assignment→scope→sync→CSP apply→report; the layered model behind the tree |
| 2. Requirements Guide | Every prerequisite with Description / Why / Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Diagnostic Playbook | The symptom-driven decision tree — exact checks per branch and the layer each isolates |
| 5. Testing Guide | Pass/fail gates confirming each layer's fix worked |
| 6. Troubleshooting Guide | Deeper edge cases and escalation |
| 7. Best Practices | Naming, filters, and conflict-free policy design |

## PowerShell scripts
| Script | What it does |
|---|---|
| `INTCFG-Discovery.ps1` | Lists device-configuration/settings-catalog policies with their assignments and bound filters (read-only, Graph) |
| `INTCFG-Validation.ps1` | Per-device applied-state check: MDM enrollment health, last sync, and local CSP/policy status (read-only) |
| `INTCFG-Report.ps1` | Assignment + conflict coverage report — overlapping settings across assigned policies and their target groups (read-only, Graph) |
| `INTCFG-Remediation.ps1` | Safe re-sync / fix for a stuck device (forces MDM check-in); default `-WhatIf` |
| `INTCFG-Set-ScopeTargeting.ps1` | Creates/populates the pilot scope groups for clean targeting; default `-WhatIf` |

## What the buyer receives
- This diagnostic method and playbook as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP (Discovery/Validation/Report are read-only;
  Remediation and Set-ScopeTargeting default to `-WhatIf`).
- A repeatable, layered root-cause process: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
The reason a policy isn't applying, isolated to **one layer** — assignment, filter, conflict, sync,
or CSP — with a repeatable method and scripts you keep and reuse, instead of blind re-pushing.
