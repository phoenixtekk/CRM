# 8. Deliverables Summary — Attack Surface Reduction (ASR) Rules

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What ASR rules block, rule modes, the high-value rules, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps — Audit-first, exclusions, then Block |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and exclusion handling |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ASR-Discovery.ps1` | Defender AV state and the device's current ASR rule configuration |
| `ASR-Validation.ps1` | Confirms each configured rule is in the expected mode (Audit/Block) |
| `ASR-AuditReport.ps1` | Parses Defender ASR audit/block events (1121/1122) for review |
| `ASR-Remediation.ps1` | Safe remediation; ensures Defender AV active and forces a sync |
| `ASR-RuleReference.ps1` | Prints the ASR rule GUID → friendly-name map for reference |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the Phoenixtekk model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Behavior-based malware prevention across the fleet — rolled out without breaking line-of-business apps.
