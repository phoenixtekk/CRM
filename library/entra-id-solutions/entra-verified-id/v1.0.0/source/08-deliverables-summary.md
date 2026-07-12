# 8. Deliverables Summary — Entra Verified ID — Verifiable Credentials

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, outcome, scope boundary, and what is in the box |
| 1. Solution Overview | What Verified ID is: trust system, DID, domain verification, credential types (rules + display), issuance and verification flows, the Request Service API, benefits, limitations, and how it plugs into `ENTZTCA` / `ENTIGA` / `ENTB2B` (gap-only) |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing, including Key Vault, domain, and app-registration items, with feature/preview/licensing flagged *verify* |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites (tenant, base licensing, admin roles, break-glass, network), published once |
| 3. Implementation Guide | Exact, ordered steps — onboard the service and DID, verify the domain, design a credential type, register the Request Service app, issue to a wallet, verify from a relying party, and revoke — with every object named |
| 5. Testing Guide | Validation procedures with pass/fail gates, including a build-only (no-submit) issuance test |
| 6. Troubleshooting Guide | Symptom -> cause -> fix for the common failures |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (Microsoft Graph + Verified ID Request Service API)
| Script | What it does |
|---|---|
| `ENTVID-Discovery.ps1` | Reports Verified ID availability, the onboarded issuer/authority, and published credential types (read-only) |
| `ENTVID-Validate.ps1` | Confirms prerequisites: Key Vault access, the Request Service app registration and permission, and the domain `did-configuration.json` well-known file (read-only) |
| `ENTVID-Report.ps1` | Issued/revoked credential and credential-type report for governance (read-only, subject to available tenant logging) |
| `ENTVID-New-IssuanceRequest.ps1` | Builds an issuance request payload and only POSTs it to the Request Service API when `-Submit` is passed (build-only by default) |
| `ENTVID-New-PresentationRequest.ps1` | Builds a presentation (verification) request payload and only POSTs it when `-Submit` is passed (build-only by default) |

Discovery, Validate, and Report are read-only against Microsoft Graph / your domain. The two
request-builder scripts call the Verified ID Request Service API **only when `-Submit` is supplied** —
by default they assemble and print the payload so you can review it before anything is issued or
requested.

## What the buyer receives
Delivered as a **Complete Solution Package (PDF + Word + scripts)**:
- This implementation guide as a Word document and PDF (white-label).
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the standard model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
A working Verified ID capability — issue and verify tamper-evident digital credentials for onboarding,
proof of employment, and access, privacy-respecting by design and revocable — proven on a pilot before
you scale.
