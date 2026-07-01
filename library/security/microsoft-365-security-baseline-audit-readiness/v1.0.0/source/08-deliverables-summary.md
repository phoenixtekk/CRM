# 8. Deliverables Summary — Microsoft 365 Security Baseline & Audit Readiness

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The M365 secure-configuration baseline, Secure Score, Compliance Manager, and the control-evidence model |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Security) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess, configure services, map controls, capture evidence, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `M365SEC-Discovery.ps1` | Reads Secure Score, secure-score control profiles, and key service configuration (read-only) |
| `M365SEC-Validation.ps1` | Confirms the tenant matches the baseline register (baseline compliance, read-only) |
| `M365SEC-Report.ps1` | Secure Score summary + control-evidence report for the evidence pack (read-only) |
| `M365SEC-Remediation.ps1` | Safe remediation of baseline gaps; defaults to `-WhatIf` |
| `M365SEC-Set-ScopeTargeting.ps1` | Creates the baseline scope groups (pilot / broad) |

## Named objects (reused verbatim)
- `M365 Security Baseline Register – Tenant Services – Baseline`
- `Compliance Assessment – Target Framework – Mapping`
- `Control Evidence Pack – Tenant Baseline – Audit`
- `M365 Baseline Scope – Pilot – Users` and `M365 Baseline Scope – Broad – Users`

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the Phoenixtekk model: Assess to Configure to Pilot to Validate to
  Expand, on a review cadence.

## Outcome
A Microsoft 365 tenant hardened to a documented baseline with an improving Secure Score, controls
mapped to your framework, and evidence maintained — so audits are a report, not a fire drill.
