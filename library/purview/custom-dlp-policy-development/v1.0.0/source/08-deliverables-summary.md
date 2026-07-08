# 8. Deliverables Summary — Custom DLP Policy Development (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | How custom DLP fits your data — conditions (SITs, confidence, instance count, labels, recipients), actions, exceptions, the simulate-first tuning loop, limitations, and the naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (DLP licensing, least-privilege role, S&C PowerShell, workloads, the SITs/labels the conditions need, data-protection intent, pilot + change control) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + S&C PowerShell steps: assess, design conditions/actions/exceptions, create the policy in simulation, pilot, validate & tune against matches, expand to enforcement — each policy/rule named, `-WhatIf` first, pass/fail + rollback |
| 5. Testing Guide | Validation procedures with simulation / tuning / enforcement pass-fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DLPCUSTOM-Assess-DlpEnvironment.ps1` | **Discovery** (read-only): inventories existing DLP policies + rules and their **mode**/locations (`Get-DlpCompliancePolicy`/`Get-DlpComplianceRule`), lists available **sensitive info types** (`Get-DlpSensitiveInformationType`), and reports DLP-relevant licensing. Writes `Custom DLP – Discovery – Assess` |
| `DLPCUSTOM-New-DlpPolicy.ps1` | **Configuration / remediation** (`-WhatIf` by default, `-Commit` to apply): creates a custom DLP policy **in simulation** (`New-DlpCompliancePolicy -Mode TestWithoutNotifications`) with its rule (conditions, exceptions, actions) from a design file; `-Update` tunes an existing policy/rule and `-Mode` stages it toward enforcement. Prints the exact reverse command for every change |
| `DLPCUSTOM-Test-DlpPolicy.ps1` | **Validation** (read-only): confirms a policy/rule's **mode**, locations, conditions, and exceptions match the design and that it is in a test mode before enforcement. Writes `Custom DLP – Simulation – Validate` |
| `DLPCUSTOM-Report-DlpMatches.ps1` | **Reporting** (read-only): pulls simulation/enforcement **matches** for a policy from the DLP reporting / Activity Explorer surface into a CSV for false-positive/negative tuning. Writes `Custom DLP – Matches – Report` |
| `DLPCUSTOM-Scope-Health.ps1` | **Scope / health helper** (read-only): confirms the in-scope M365 workloads, reports endpoint device-onboarding readiness, and checks that the SITs/labels the design references exist. Writes `Custom DLP – Scope – Map` |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit` to
change anything, and every policy is created **in simulation/test mode**, never straight to enforcement. No
credentials or secrets are stored in code; every script uses interactive modern-auth (`Connect-IPPSSession`).

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate) → Validate →
  Expand (enforce).**

## Outcome
Custom DLP policies tuned to your exact data in Microsoft Purview — tailored conditions, sensitive info
types, exceptions, and staged actions — piloted in **simulation** with no user impact, tuned against real
match evidence, and promoted to enforcement under change control, so the protection is in place, credible,
and defensible. Determinations about what is sensitive and which regulations apply are deferred to
compliance, privacy, and legal.
