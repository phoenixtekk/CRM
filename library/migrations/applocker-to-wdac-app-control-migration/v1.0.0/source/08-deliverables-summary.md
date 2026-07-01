# 8. Deliverables Summary — AppLocker to WDAC (App Control for Business) Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Why WDAC beats AppLocker, the translate-to-audit-to-enforce model, coexistence, managed installer / ISG |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, plus the naming convention |
| Global Requirements (Migrations) | Category-wide migration prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps: export AppLocker, author WDAC, audit, close gaps, enforce by ring, retire AppLocker |
| 5. Testing Guide | Validation procedures with the audit gate and pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WDACMIG-Discovery.ps1` | Captures the effective AppLocker policy + current WDAC/code-integrity and managed-installer state (read-only) |
| `WDACMIG-Validation.ps1` | Confirms the WDAC policy is applied and reports Audit vs Enforced (read-only) |
| `WDACMIG-Report.ps1` | Migration coverage + would-block report from Code Integrity audit events, and tenant policy/ring assignments via Graph (read-only) |
| `WDACMIG-Remediation.ps1` | Safe revert to audit mode after unassigning the enforce policy; default -WhatIf |
| `WDACMIG-Set-MigrationRingTargeting.ps1` | Builds/populates the migration ring groups and assigns the audit/enforce profiles (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess to Configure to Pilot to Validate to Expand, with a mandatory audit
  gate before enforcement and rollback at every stage.

## Outcome
Application control moved from AppLocker to WDAC — translated, audited, and enforced in rings with no
user lockouts — and AppLocker retired, proven on a pilot before you scale.
