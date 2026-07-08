# 8. Deliverables Summary — Microsoft Purview Communication Compliance

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, the responsible-oversight model, and what's in the box |
| 1. Solution Overview | What Communication Compliance is, how it works, the detection dimensions, the role-separation model, limitations, the CC-vs-Insider-Risk distinction, and the naming convention |
| 2. Requirements Guide | Every CC-specific prerequisite with Verify / Implement-if-missing (licensing, role separation, HR/legal + lawful basis, privacy controls, channels, classifiers, toolchain, pilot) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + Security & Compliance PowerShell steps — guardrails first, pilot-in-simulation policy, reviewer/remediation workflow, validate, tune, expand; outcomes deferred to HR/legal |
| 5. Testing Guide | Validation procedures with pass/fail gates (separation, privacy, detection accuracy, reviewer workflow, evidence, safe defaults) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven, privacy-first recommendations |

## PowerShell scripts
| Script | Purpose | Default safety |
|---|---|---|
| `PURVCC-Discovery.ps1` | Readiness + **role-separation** + privacy/scope assessment; prints the separation evidence snapshot and any existing policies | **Read-only** |
| `PURVCC-Configuration.ps1` | Policy + classifier/condition config helper — composes the `SupervisoryReview` policy/rule for the pilot | **`-WhatIf`** (needs `-Commit`) |
| `PURVCC-ReviewerWorkflow.ps1` | Reviewer-workflow / remediation setup — sets policy reviewers and the role-group membership that enforces separation | **`-WhatIf`** (needs `-Commit`) |
| `PURVCC-Report.ps1` | Alert/review **rollup report** — policy/rule inventory, reviewer assignments, role membership, and CC activity from the audit log | **Read-only** |
| `PURVCC-Set-Scope.ps1` | Scope/config helper — adjust a policy's supervised users, reviewers, and conditions | **`-WhatIf`** (needs `-Commit`) |

All scripts run through **Security & Compliance PowerShell** (`Connect-IPPSSession`) and/or **Microsoft
Graph** with interactive modern-auth; **no credentials or secrets are embedded**. The three
configuration scripts are **safe-by-default** (`-WhatIf`) and only change the tenant when `-Commit` is
supplied — after HR/legal sign-off.

## Artifacts this solution creates (naming convention)
| Artifact | Name |
|---|---|
| Pilot detection policy (simulation) | `Comms Policy – Pilot – Simulation` |
| Broad detection policy (enforced) | `Comms Policy – Broad – Enforce` |
| Supervised in-scope population (pilot) | `Comms In-Scope – Pilot` |
| Supervised in-scope population (broad) | `Comms In-Scope – Broad` |
| Excluded / out-of-scope (privacy) group | `Comms Excluded – Privacy` |
| Reviewer assignment record | `Comms Reviewers – Pilot` |
| Alert/review rollup report | `Comms Review Rollup – Report` |
| Role-separation evidence snapshot | `Comms Role Separation – Evidence` |

## Outcome
Communication risk surfaced **responsibly** — policies tuned to real violations, reviewers actioning a
sustainable queue, and **privacy plus role separation enforced and evidenced** — oversight without
surveillance, with **HR, privacy, and legal in control of every outcome**.
