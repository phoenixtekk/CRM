# 8. Deliverables Summary — SharePoint Online DLP (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | SharePoint/OneDrive DLP for sensitive content and sharing/external access; test mode first, enforce deliberately; how DLP differs from labels and lifecycle (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess policies, design content + sharing + actions, create the policy in test mode on the pilot, pilot + tune, validate, enforce deliberately, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| DLP policy | `SPO-OneDrive DLP – Policy` |
| Detection rule | `SPO DLP – External Sharing Rule` |
| Pilot scope | `SPO DLP – Pilot Sites – Stage1` |
| Scope/design map | `DLP Scope – Map` |
| Coverage report | `SPO DLP – Coverage Report` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DLPSPO-Discover.ps1` | Reports current state: every DLP policy and rule, whether each covers SharePoint/OneDrive, each policy's mode (test/enforce), and the available sensitive information types — Security & Compliance PowerShell; read-only |
| `DLPSPO-Check-Prereqs.ps1` | Prerequisite/health helper: module, connection, the DLP/compliance role signal, and existing policies — PASS/GAP per signal; read-only |
| `DLPSPO-Set-DlpPolicy.ps1` | Configuration/Remediation: creates `SPO-OneDrive DLP – Policy` + `SPO DLP – External Sharing Rule` scoped to the pilot **in test mode** (`-Action CreatePolicy`), and — as deliberate separate steps — switches to **enforce** (`-Action Enforce`) or back to **test** (`-Action Test`); **defaults to `-WhatIf`** (prints the plan + reverse action), applies only with `-Commit`; no secrets in code |
| `DLPSPO-Validate.ps1` | Validation: PASS/FAIL that the policy exists, covers the intended locations, its rule matches the intended content/sharing condition, and the policy is in **test mode** (not prematurely enforcing) — read-only |
| `DLPSPO-Report.ps1` | Coverage report — each policy/rule, its SharePoint/OneDrive locations, mode, and match conditions — written to CSV as `SPO DLP – Coverage Report`; read-only |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
SharePoint and OneDrive sharing governed from Purview — documents inspected for sensitive content and
external sharing restricted where the content warrants it — proven in test mode on a limited pilot before
any enforcement, with the determination of which content is sensitive and which sharing is acceptable left
to the compliance, security, and privacy owners who make it.
