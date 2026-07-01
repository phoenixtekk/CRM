# 8. Deliverables Summary — Zero Trust Network Access (ZTNA) with Netskope Private Access

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What ZTNA / Netskope Private Access is, the why vs the VPN, how it works, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, plus the naming convention |
| Global Requirements (Network) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Ordered steps: publishers, private apps, least-privilege policy, pilot, validate, expand, cutover |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and safe remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NSZTNA-Discovery.ps1` | Read-only: endpoint posture, current VPN routes/hosts, and candidate `publisher` hosts |
| `NSZTNA-Validation.ps1` | Read-only: client state, entitlement-group membership, posture, and published-app reachability |
| `NSZTNA-Report.ps1` | Read-only: entitlement and usage report (who reaches which apps, posture, ZTNA usage) |
| `NSZTNA-Remediation.ps1` | Safe fixes (default `-WhatIf`): repair broken app access, e.g. add a user to an entitlement group |
| `NSZTNA-Set-AccessGroupTargeting.ps1` | Builds/updates the Entra `Access Group` entitlement groups and their membership |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess to Configure to Pilot to Validate to Expand, with a pilot gate, a VPN
  coexistence-then-cutover migration, and an access-affecting rollback note.

## Outcome
Users reach only the private apps they are entitled to — least-privilege, identity- and
posture-based access with no network exposure — and the legacy VPN is retired, proven on a pilot
before scaling.
