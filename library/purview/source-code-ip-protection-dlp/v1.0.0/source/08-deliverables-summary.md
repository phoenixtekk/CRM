# 8. Deliverables Summary — Source-Code & IP Protection DLP (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | DLP + classifiers detecting and protecting source code / IP across email, collaboration, and endpoints; test mode first, enforce deliberately; how DLP differs from repo security (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess policies + classifiers + endpoint onboarding, design detection + channels + actions, create the policy in test mode on the pilot ring, pilot + tune, validate, enforce deliberately, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| DLP policy | `Source-Code & IP DLP – Policy` |
| Detection rule | `Source-Code Detection Rule` |
| Pilot ring | `Source-Code DLP – Pilot Ring – Stage1` |
| Scope/design map | `Source-Code DLP – Map` |
| Coverage report | `Source-Code DLP – Coverage Report` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DLPCODE-Discover.ps1` | Reports current state: every DLP policy and rule, which channels each covers (Exchange/SharePoint/OneDrive/Teams/Endpoint) and its mode, and a sample of available sensitive information types (with a Source Code classifier / Endpoint DLP reminder) — Security & Compliance PowerShell; read-only |
| `DLPCODE-Check-Prereqs.ps1` | Prerequisite/health helper: module, connection, the DLP/compliance role signal, and existing policies — PASS/GAP per signal; read-only |
| `DLPCODE-Set-DlpPolicy.ps1` | Configuration/Remediation: creates `Source-Code & IP DLP – Policy` + `Source-Code Detection Rule` across the in-scope channels for the pilot ring **in test mode** (`-Action CreatePolicy`, `-UseSourceCodeClassifier`), and — as deliberate separate steps — switches to **enforce** (`-Action Enforce`) or back to **test** (`-Action Test`); **defaults to `-WhatIf`** (prints the plan + reverse action), applies only with `-Commit`; no secrets in code |
| `DLPCODE-Validate.ps1` | Validation: PASS/FAIL that the policy exists, covers the intended channels, its rule matches the source-code/IP detection, and the policy is in **test mode** (not prematurely enforcing) — read-only |
| `DLPCODE-Report.ps1` | Coverage report — each policy/rule, its channels, mode, and match conditions — written to CSV as `Source-Code DLP – Coverage Report`; read-only |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
Source code and IP governed from Purview — detected by classifier and custom types and restricted from
leaving via email, cloud upload, and USB across the in-scope channels — proven in test mode on a developer
pilot ring before any enforcement, with the determination of what is protected IP and which egress is
acceptable left to the security, IP, and legal owners who make it.
