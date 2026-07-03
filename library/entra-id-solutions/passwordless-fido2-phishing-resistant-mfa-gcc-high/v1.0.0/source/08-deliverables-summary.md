# 8. Deliverables Summary — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys — Government (GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box (GCC High edition) |
| 1. Solution Overview | What passwordless/phishing-resistant auth is; FIDO2 vs. Windows Hello vs. certificate-based (CAC/PIV); authentication strengths; **Commercial vs GCC High — what's different**; benefits; limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, on the `*.us` plane |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered **sovereign** Entra steps with GCC-High caveats inline |
| 5. Testing Guide | Validation procedures with pass/fail gates (incl. sovereign + CBA-as-MFA tests) |
| 6. Troubleshooting Guide | Field issues and remediation, GCC-High-specific gotchas |
| 7. Best Practices | Field-proven recommendations for a US Gov tenant |
| GCC High Parity Notes | Cited confirmed/differs/verify reference for US Gov vs Commercial |

## PowerShell scripts (US Gov Graph — `-Environment USGov`)
| Script | What it does |
|---|---|
| `FIDO2G-Discovery.ps1` | Reports tenant authentication-method policy state (FIDO2 / Windows Hello / certificate-based enabled + targeting) — read-only |
| `FIDO2G-Validation.ps1` | Confirms a user has a phishing-resistant method registered (and as default) — read-only |
| `FIDO2G-Report.ps1` | Tenant credential-method coverage report from registration details (US Gov Graph) — read-only |
| `FIDO2G-Remediation.ps1` | Safe remediation for weak-method users (default `-WhatIf`); flags users lacking a phishing-resistant method |
| `FIDO2G-Set-ScopeTargeting.ps1` | Builds/populates the pilot and rollout Entra groups for staged targeting (default `-WhatIf`) |

All scripts connect to Microsoft Graph **US Gov** endpoints (`-Environment USGov`, or `USGovDoD` for
DoD). Discovery, Validation, and Report are strictly read-only; Remediation and Set-ScopeTargeting
default to `-WhatIf` and make no change until you pass `-Execute`.

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Users signing in passwordless with phishing-resistant credentials — FIDO2 keys, Windows Hello for
Business, and CAC/PIV smart cards — and weak methods blocked by a Conditional Access authentication
strength, all configured on the **US sovereign (`*.us`) cloud** and proven on a pilot before fleet
rollout.
