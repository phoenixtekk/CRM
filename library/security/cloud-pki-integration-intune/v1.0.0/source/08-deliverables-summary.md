# 8. Deliverables Summary — Cloud PKI Integration with Intune

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What a cloud PKI + Intune integration is, why modernize off the on-prem CA, SCEP vs PKCS, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (cloud-PKI product specifics deferred to vendor) |
| Global Requirements (Security solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps: connect cloud PKI, trust chain, SCEP/PKCS profiles, scenario, pilot, migrate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CPKI-Discovery.ps1` | Reports certificate connector health and existing SCEP/PKCS/trusted-cert profiles; cloud-PKI readiness (read-only) |
| `CPKI-Validation.ps1` | Per-device certificate issuance + trust-chain validation (read-only) |
| `CPKI-Report.ps1` | Certificate coverage + expiry across the fleet, incl. legacy-vs-cloud issuer (read-only) |
| `CPKI-Remediation.ps1` | Safe remediation of failed issuance (sync + re-evaluate); defaults to `-WhatIf` |
| `CPKI-Set-ScopeTargeting.ps1` | Creates/assigns the certificate-scope Entra groups (devices/users, pilot/broad) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Certificates issued to Intune-managed devices from a cloud PKI — trust chain deployed,
Wi-Fi/VPN/auth validated, and the on-prem CA dependency reduced or retired — proven on a pilot
before you scale.
