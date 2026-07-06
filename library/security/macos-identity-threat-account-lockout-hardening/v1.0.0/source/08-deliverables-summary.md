# 8. Deliverables Summary — macOS Identity-Threat & Account-Lockout Hardening

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | How macOS auth, saved credentials, keychain, and SecureToken drive failed sign-ins, lockouts, and spray noise, and the hardening model |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Security) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: identify Mac-originated sources, enforce Smart Lockout + MFA, remediate Mac credential/keychain state, validate the reduction, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Identity protection on Macs |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MACLOCK-Discovery.ps1` | Reads Entra sign-in-log failures by device/OS (macOS), user, app, and error code, plus current Smart Lockout / MFA posture (read-only) |
| `MACLOCK-Validation.ps1` | Confirms Smart Lockout + the MFA policy match the desired state and re-reads Mac-originated failures (read-only) |
| `MACLOCK-Report.ps1` | Before/after lockout-and-spray exposure report for the evidence pack (read-only) |
| `MACLOCK-Remediation.ps1` | Safe remediation guidance/actions for Mac-originated failures; defaults to `-WhatIf` |
| `MACLOCK-Set-ScopeTargeting.ps1` | Creates the Mac scope groups (pilot / broad) |

## Named objects (reused verbatim)
- `MACLOCK Sign-in Failure Findings - Mac-Originated - Sources`
- `MACLOCK Lockout & Spray Register - Mac Fleet - Baseline`
- `MACLOCK Remediation Evidence Pack - Mac Credential State`
- `MACLOCK CA - Require MFA - Mac Pilot` (and, if P2, `MACLOCK CA - Risk-Based MFA - Mac Pilot`)
- `MACLOCK Scope - Pilot - Macs` and `MACLOCK Scope - Broad - Macs`

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess → Configure → Pilot → Validate → Expand, on a
  review cadence.

## Outcome
Fewer account lockouts and less password-spray noise from the Mac fleet — Mac-originated sources
identified from the sign-in logs, Smart Lockout + MFA enforced, and stale Mac credential/keychain
state cleaned up — proven on a pilot before you scale it across every Mac.
