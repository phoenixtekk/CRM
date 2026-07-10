# 8. Deliverables Summary — Passwordless & Passkey (FIDO2) Rollout for Microsoft Entra

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | How passwordless works in Entra — FIDO2/WebAuthn, passkeys vs. security keys, the authentication methods policy, registration campaign, and phishing-resistant Conditional Access |
| 2. Requirements Guide | Every solution-specific prerequisite with Verify / Implement-if-missing |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (groups, assess, TAP, enable FIDO2/passkey, registration campaign, phishing-resistant CA report-only, pilot, validate, enforce + expand in waves, retire weak methods last, recovery) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations + where to go next |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ENTPASSKEY-Discovery.ps1` | Reads the authentication methods policy — which methods are enabled and targeted (FIDO2, Passkey/Authenticator, TAP, SMS, Voice), the registration campaign state, and the CA policies requiring MFA (read-only) |
| `ENTPASSKEY-Validate.ps1` | Confirms FIDO2 + Passkey are enabled/targeted, TAP is enabled, the phishing-resistant CA policies exist with break-glass excluded, and (report-only) that they evaluate (read-only) |
| `ENTPASSKEY-Report.ps1` | Passwordless adoption report — per group, who has registered a phishing-resistant method versus who is still on password + weak MFA; the number that gates weak-method retirement (read-only) |
| `ENTPASSKEY-Set-MethodsPolicy.ps1` | Safely enables FIDO2 + Passkey (Authenticator) and targets them at the rollout groups; `-WhatIf` by default (preview), gated apply |
| `ENTPASSKEY-Set-ScopeTargeting.ps1` | Builds and previews the pilot / admin / wave / registration-campaign groups |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand.

Delivered as a Complete Solution Package (PDF + Word + scripts).

## Outcome
Phishing-resistant, passwordless sign-in across the tenant — admins and sensitive apps passwordless
first, weak methods retired only after adoption, and a Temporary Access Pass + lost-key runbook so
the rollout never locks anyone out.
