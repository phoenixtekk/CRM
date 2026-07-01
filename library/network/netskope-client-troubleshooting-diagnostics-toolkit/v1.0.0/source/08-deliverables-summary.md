# 8. Deliverables Summary — Netskope Client Troubleshooting & Diagnostics Toolkit

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The client from a support view, the four failure classes, diagnose-then-resolve, naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Network) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Stand up diagnostics, build the four runbooks, pilot, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Failure-class runbooks and troubleshooting the solution itself |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NSDIAG-Discovery.ps1` | Read-only. Reports client install state, services, processes, and decryption-cert presence |
| `NSDIAG-Validation.ps1` | Read-only. Checks DNS, TCP reachability, and steering/auth state; clear pass/fail |
| `NSDIAG-Report.ps1` | Read-only. Device context via Microsoft Graph; flags the vendor-deferred client-log handoff |
| `NSDIAG-Remediation.ps1` | Safe remediation (default `-WhatIf`): restart / repair / re-enroll the client |
| `NSDIAG-Set-ScopeTargeting.ps1` | Creates/confirms the `Diagnostics Scope – Help Desk – Pilot` group (default `-WhatIf`) |

## Named artifacts (reused verbatim)
- Runbooks: `Client Triage – Steering – Diagnose/Resolve`, `… – Authentication – …`,
  `… – Performance – …`, `… – Certificate – …`
- Bundle: `Diagnostic Bundle – Endpoint – Collect`
- Group: `Diagnostics Scope – Help Desk – Pilot`

## What the buyer receives
- This guide set as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand.**

## Vendor boundary
Netskope console screens and client-internal log paths are deferred to the official Netskope
documentation and your tenant; this toolkit operates at the failure-class and operating-system level.

## Outcome
Netskope client issues triaged the same way every time — diagnostics that collect the right state and
runbooks that point to root cause — so the help desk resolves at first contact or escalates with facts.
