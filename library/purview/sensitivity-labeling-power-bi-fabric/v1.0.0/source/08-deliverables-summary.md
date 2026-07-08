# 8. Deliverables Summary — Sensitivity Labeling for Power BI & Microsoft Fabric (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Sensitivity labeling for Power BI/Fabric artifacts and their exports, with source and export inheritance; how analytics honors your existing Purview labels (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess labels + tenant settings, design intent, publish labels to pilot creators, enable the information-protection tenant settings, pilot on real content, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Sensitivity labels (existing) | `General`, `Confidential`, `Highly Confidential` |
| Label policy publishing to BI creators | `Analytics Labels – Policy` |
| Tenant-setting delegation group | `BI Labeling – Enabled Users` |
| Pilot ring (users) / pilot workspace | `Analytics Labels – Pilot Ring – Stage1` |
| Scope/design map | `Analytics Scope – Map` |
| Coverage report | `Analytics Labels – Coverage Report` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IPPBI-Discover.ps1` | Reports current state: every sensitivity label and its publishing policy, the in-scope Power BI/Fabric workspaces, and the information-protection tenant-setting checklist to confirm — Security & Compliance PowerShell + read-only Power BI; read-only |
| `IPPBI-Check-Prereqs.ps1` | Prerequisite/health helper: modules, connections, roles, the label and Power BI Pro/PPU signals, and whether labels are published — PASS/GAP per signal; read-only |
| `IPPBI-Set-InfoProtection.ps1` | Configuration/Remediation: publishes/points `Analytics Labels – Policy` at the pilot (or expansion) creators and prints the exact Power BI/Fabric tenant-setting checklist to apply; **defaults to `-WhatIf`** (prints the plan + reverse action), applies only with `-Commit`; tenant settings are completed in the admin portal; no secrets in code |
| `IPPBI-Validate.ps1` | Validation: PASS/FAIL that the labels exist and are published in `Analytics Labels – Policy` to the intended creators, plus the printed tenant-setting gates to confirm — read-only |
| `IPPBI-Report.ps1` | Coverage report — each label, its publication/target coverage, and the in-scope workspaces — written to CSV as `Analytics Labels – Coverage Report`; read-only |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
Analytics content and its exports protected from Purview — Power BI/Fabric artifacts labeled, labels
inherited from labeled sources and carried into Excel/PowerPoint/PDF exports with their encryption —
proven on a pilot before you scale, with the determination of which content is sensitive left to the
owners who make it.
