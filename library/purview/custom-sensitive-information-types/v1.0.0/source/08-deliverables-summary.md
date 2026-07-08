# 8. Deliverables Summary — Custom Sensitive Information Types (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, the detector-not-action model, and what's in the box |
| 1. Solution Overview | What a custom SIT is, the building blocks (primary element, supporting evidence, proximity, confidence), how it works, reuse across policies, limitations, and the naming convention |
| 2. Requirements Guide | Every custom-SIT-specific prerequisite with Verify / Implement-if-missing (identifier format, positive/negative samples, SIT-management role, toolchain, primary-element/confidence design, data owner, consuming policy + pilot) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + Security & Compliance PowerShell steps — design, build (portal or rule-package XML), validate against samples, pilot in a simulation policy, tune, enforce and reuse; determinations deferred |
| 5. Testing Guide | Validation procedures with pass/fail gates (build, detector precision on positives/negatives, proximity, simulation on real content, evidence, safe defaults) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven, precision-first recommendations |

## PowerShell scripts
| Script | Purpose | Default safety |
|---|---|---|
| `CLSCUSTOM-Discovery.ps1` | Readiness + SIT-cmdlet check; inventories existing **custom** SITs and rule packages (vs built-ins) and writes the `Custom SIT Inventory – Evidence` snapshot | **Read-only** |
| `CLSCUSTOM-Configuration.ps1` | Imports/updates a custom SIT from a **rule-package XML** (validates the XML, composes `New/Set-DlpSensitiveInformationTypeRulePackage`) | **`-WhatIf`** (needs `-Commit`) |
| `CLSCUSTOM-Validation.ps1` | Runs **`Test-DataClassification`** for the SIT against the positive/negative sample sets and writes `Custom SIT Validation – Report` (true/false positives, false negatives, confidence) | **Read-only** |
| `CLSCUSTOM-Report.ps1` | Inventory + **where-used** report — SIT patterns/confidence and every DLP/auto-label policy that references it | **Read-only** |
| `CLSCUSTOM-Set-Scope.ps1` | Rule-package helper — **export/back up** the current rule-package XML and apply an updated one | **`-WhatIf`** (needs `-Commit`) |

All scripts run through **Security & Compliance PowerShell** (`Connect-IPPSSession`) and/or **Microsoft
Graph** with interactive modern-auth; **no credentials or secrets are embedded**. The two configuration
scripts are **safe-by-default** (`-WhatIf`) and only change the tenant when `-Commit` is supplied — after
the validation gate passes.

## Artifacts this solution creates (naming convention)
| Artifact | Name |
|---|---|
| Custom SIT (pilot) | `Custom SIT – Employee ID – Pilot` |
| Custom SIT rule package | `Custom SIT Rule Package – Pilot` |
| Positive validation sample set | `Custom SIT Test – Positive` |
| Negative validation sample set | `Custom SIT Test – Negative` |
| Validation result report | `Custom SIT Validation – Report` |
| SIT inventory / evidence snapshot | `Custom SIT Inventory – Evidence` |
| Consuming DLP policy (simulation) | `Custom SIT DLP – Simulation` |
| Consuming DLP policy (enforced) | `Custom SIT DLP – Enforce` |

## Outcome
Your organization's **unique identifiers detected in Microsoft Purview** — custom SITs built from regex,
keywords, and confidence design, **validated against positive and negative samples**, piloted in
simulation, and tuned for precision — a reusable detector that makes every downstream DLP, labeling,
retention, Insider Risk, and DSPM policy sharper, with the enforcement action and any governance
determination owned by the consuming policy and the relevant functions.
