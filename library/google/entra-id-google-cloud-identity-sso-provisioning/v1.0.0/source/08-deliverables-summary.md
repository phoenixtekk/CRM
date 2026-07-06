# 8. Deliverables Summary — Entra↔Google SSO & Provisioning

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The identity model: Entra ID as IdP federating to Google (SAML SSO), provisioning via SCIM push or GCDS pull, one source of truth, and how the pieces fit |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (both control planes, source of truth, domain verified in both clouds, SCIM admin / GCDS host, pilot, break-glass) |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Configure Entra→Google SAML SSO (both consoles), provisioning of users+groups via SCIM push (Path A) or GCDS pull (Path B), pilot sign-in + provisioning on a named OU/group, then expand |
| 5. Testing Guide | SSO + provisioning conformance gates with pass/fail (sign-in, create, one source of truth, de-provisioning, break-glass) |
| 6. Troubleshooting Guide | Field issues — SSO failures, provisioning drift, de-provisioning, domain/NameID — and remediation |
| 7. Best Practices | Source-of-truth, lifecycle, and pilot-first recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWSSO-Discovery.ps1` | Identity-readiness discovery — inventories the Entra-side gallery app, its SSO mode, SCIM provisioning job, assigned users/groups, and the tenant's verified custom domains, via Microsoft Graph (read-only) |
| `GWSSO-Validation.ps1` | Per-user SSO + provisioning validation — for scoped users, checks federated SSO is configured (SAML, NameID = mail), the user is on a verified domain, and is assigned/provisioned; reports pass/exception (read-only) |
| `GWSSO-Report.ps1` | Identity coverage / exception report — federated vs not, provisioned vs not, on-domain vs `*.onmicrosoft.com`, and the exception list (read-only) |
| `GWSSO-Remediation.ps1` | Safely fixes scoped Entra-side gaps (assigns a reviewed user/group to the app so provisioning brings them into scope); `-WhatIf` by default |
| `GWSSO-Set-ScopeTargeting.ps1` | Builds and previews the pilot-scope and owner groups for a staged SSO/provisioning rollout; `-WhatIf` / preview by default |

## Identity reference doc — outline
The primary architectural deliverable. Recommended structure:
1. **Purpose & scope** — the domains, OUs, and users covered.
2. **Source-of-truth statement** — which directory masters users/groups and the mechanism (SCIM push /
   GCDS pull / JIT-convenience).
3. **SSO federation design** — Entra IdP → Google relying party, SAML details, NameID = user.mail,
   domain-specific issuer choice.
4. **Domain & identifier map** — verified custom domain(s), UPN ↔ primaryEmail ↔ NameID alignment.
5. **Provisioning design** — attribute mappings, group provisioning, scope (assignment/filter or GCDS
   OU rules), and the de-provisioning behavior.
6. **SSO-profile assignment plan** — pilot OU/group first, break-glass = none, expansion batches.
7. **Break-glass** — the Google super-admin outside SSO and the Entra emergency admins.
8. **Exception register** — deliberate deviations (e.g. service accounts not federated), with owner and
   review date.
9. **Conformance cadence** — how discovery / validation / report run and how new users/OUs are covered.

## What the buyer receives
- This implementation guide and the identity model as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess → Configure → Pilot → Validate → Expand.

## Outcome
One identity across Microsoft and Google — users sign in once against Entra ID and reach Google, with
users, groups, and licensing kept consistent by a single source of truth and a lifecycle that
de-provisions leavers. The identity foundation for coexistence and migration, proven on a named pilot
before it touches the whole organization, and reversible at every step.
