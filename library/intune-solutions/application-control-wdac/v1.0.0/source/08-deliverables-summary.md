# 8. Deliverables Summary — Application Control (WDAC)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What WDAC is, trust models, modes, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — Audit-first, add trust, Enforce, with recovery |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and recovery from over-strict policies |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WDAC-Discovery.ps1` | Reports OS support and current code-integrity/App Control status |
| `WDAC-Validation.ps1` | Confirms an App Control policy is active and its enforcement mode |
| `WDAC-AuditReport.ps1` | Parses Code Integrity events (3076/3077) to find blocked/would-block code |
| `WDAC-Remediation.ps1` | Recovery: clears/refreshes local policy and forces a sync |
| `WDAC-PolicyReport.ps1` | Tenant-wide App Control policy assignment report (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the Phoenixtekk model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Strong, kernel-enforced protection against untrusted code — deployed safely with audit-first validation and a clear recovery path.
