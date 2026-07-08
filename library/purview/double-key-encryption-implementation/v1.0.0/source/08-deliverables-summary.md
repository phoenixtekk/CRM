# 8. Deliverables Summary — Double Key Encryption (DKE) Implementation, Microsoft Purview

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What DKE is — the two keys, the customer-held key service, the label wiring — benefits and the deliberate trade-offs |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (licensing, roles, host, .NET toolchain, client platform, audience, determination) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — deploy & secure the key service, register the Entra app, create & publish the DKE label, pilot, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates (key required, permissions, content-service exclusion) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IPDKE-Discovery.ps1` | Reports the tenant's sensitivity labels, flags which use encryption / Double Key Encryption and their endpoint URLs, lists label policies, and shows a DKE licensing signal (read-only) |
| `IPDKE-Validation.ps1` | Confirms the DKE label exists with DKE encryption and the expected endpoint URL, the label policy is published to the pilot group, and the endpoint is reachable (read-only) |
| `IPDKE-Report.ps1` | DKE label usage / coverage summary — DKE labels, their publishing policies and audiences, plus the content-service exclusions (read-only) |
| `IPDKE-Remediation.ps1` | Safe remediation of common gaps (default `-WhatIf`) — enables a published-but-disabled label policy; never creates or alters DKE encryption on a label (a portal decision) |
| `IPDKE-Scope-And-ServiceHealth.ps1` | Scope + health helper — creates/updates the pilot & reader Entra groups (gated by `-Apply`) and probes the DKE endpoint's reachability, TLS, and public-key JSON (read-only probe) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot → Validate →
  Expand**, with endpoint and pilot gates and a documented rollback.

## Outcome
The second key stays under your control in Microsoft Purview — a customer-held DKE key service, an
Entra app registration that secures it, and a Double-Key-Encryption sensitivity label wired to your
endpoint and proven on a pilot before you scale. Which data warrants DKE, and any sovereignty
determination, remain with compliance, records, privacy, and legal.
