# 8. Deliverables Summary — macOS Compliance & Conditional Access for Zero-Trust Access

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | macOS compliance signals → Conditional Access; the Zero-Trust model for Macs |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — build compliance, map to a Report-only CA policy, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates (compliant → allowed; non-compliant → denied) |
| 6. Troubleshooting Guide | Field issues, failing signals, and lockout recovery |
| 7. Best Practices | Grace periods and safe Zero-Trust rollout |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MACCA-Discovery.ps1` | Inventories enrolled Macs and their macOS compliance policies + CA policies (Microsoft Graph, read-only) |
| `MACCA-Validation.ps1` | Confirms pilot Macs are Compliant + Entra-registered and break-glass accounts are excluded — the pre-enforcement check |
| `MACCA-Report.ps1` | Per-Mac compliance state mapped to the would-be / actual access decision (allow/deny) |
| `MACCA-Remediation.ps1` | Safe, `-WhatIf`-by-default fixes for common compliance gaps (e.g. re-sync, re-target a Mac) |
| `MACCA-Set-ScopeTargeting.ps1` | Builds/updates the pilot & rollout group membership from the Mac inventory (`-WhatIf` by default) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the standard model: **Assess → Configure → Pilot → Validate → Expand.**

## Named objects this solution creates
- Compliance policy: **`macOS - Zero-Trust Compliance`**
- Conditional Access policy: **`CA - macOS - Require Compliant Device`**
- Pilot group: **`macOS-ZeroTrust-Pilot`** (optional exclusions group `macOS-ZeroTrust-Exclusions`)

## Outcome
Only compliant, trusted Macs reach corporate resources — Mac-specific compliance signals (encryption,
OS version, firewall, Defender risk) wired to a named Conditional Access policy under Zero-Trust —
proven on a pilot in Report-only before you scale.
