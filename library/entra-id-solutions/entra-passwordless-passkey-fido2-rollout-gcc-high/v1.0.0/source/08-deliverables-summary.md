# 8. Deliverables Summary — Passwordless & Passkey (FIDO2) Rollout for Microsoft Entra — Government (GCC High)

> **Government (GCC High) edition** — the commercial passwordless/passkey solution adapted for
> Microsoft's US Government national cloud (Azure Government / GCC High), with US Gov portals/endpoints
> and a dedicated national-cloud parity + compliance note. Satisfies the OMB M-22-09 phishing-resistant
> MFA mandate and CMMC 2.0 authentication drivers. For US public-sector and defense-industrial-base tenants.

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| GCC High Parity & Compliance Notes | National-cloud endpoints, GCC High/DoD passkey/FIDO2 feature-parity considerations, and FedRAMP High / DoD IL4-IL5 / CMMC 2.0 / OMB M-22-09 / ITAR context (`gcc-high-parity-notes.md`) |
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
| `ENTPASSKEYG-Discovery.ps1` | Reads the authentication methods policy — which methods are enabled and targeted (FIDO2, Passkey/Authenticator, TAP, SMS, Voice), the registration campaign state, and the CA policies requiring MFA (read-only) |
| `ENTPASSKEYG-Validate.ps1` | Confirms FIDO2 + Passkey are enabled/targeted, TAP is enabled, the phishing-resistant CA policies exist with break-glass excluded, and (report-only) that they evaluate (read-only) |
| `ENTPASSKEYG-Report.ps1` | Passwordless adoption report — per group, who has registered a phishing-resistant method versus who is still on password + weak MFA; the number that gates weak-method retirement (read-only) |
| `ENTPASSKEYG-Set-MethodsPolicy.ps1` | Safely enables FIDO2 + Passkey (Authenticator) and targets them at the rollout groups; `-WhatIf` by default (preview), gated apply |
| `ENTPASSKEYG-Set-ScopeTargeting.ps1` | Builds and previews the pilot / admin / wave / registration-campaign groups |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand.

Delivered as a Complete Solution Package (PDF + Word + scripts).

## Outcome
Phishing-resistant, passwordless sign-in across the tenant — admins and sensitive apps passwordless
first, weak methods retired only after adoption, and a Temporary Access Pass + lost-key runbook so
the rollout never locks anyone out.
