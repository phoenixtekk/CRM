# 8. Deliverables Summary — Enterprise Integration Patterns

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The pattern-catalog approach — the five integration dimensions, the P1–P7 reference patterns, and the anti-patterns the catalog exists to kill |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | The reference patterns: Entra↔Google federation + provisioning (P1–P3), M365 coexistence (P4), third-party apps ServiceNow/SAP/Databricks (P5/P6), and API/data access (P7) — recommended authN/authZ + data access, standards, and anti-patterns |
| 5. Testing Guide | Pattern-conformance gates with pass/fail |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWINTEG-Discovery.ps1` | Inventories the Entra-side integration estate — SSO/federation apps, SCIM provisioning jobs, service principals, app-role assignments, delegated OAuth grants, and credentials — via Microsoft Graph (read-only) |
| `GWINTEG-Validation.ps1` | Checks pattern conformance — federation present, one source of truth for provisioning, federated app SSO, scoped API access — and reports non-conforming integrations (read-only) |
| `GWINTEG-Report.ps1` | Integration coverage / exception report — classifies each integration against the P1–P7 catalog and lists snowflakes, over-broad scopes, and credential risk (read-only) |
| `GWINTEG-Remediation.ps1` | Safely brings a reviewed snowflake toward its target pattern (e.g. revokes over-broad grants); `-WhatIf` by default |
| `GWINTEG-Set-ScopeTargeting.ps1` | Builds and previews the pilot scope and pattern-owner groups for a staged rollout |

## Integration-Patterns reference doc — outline
The primary architectural deliverable. Recommended structure:
1. **Purpose & scope** — the estate covered (Entra, Google, M365 coexistence, named third-party apps).
2. **The five integration dimensions** — federation, provisioning, app SSO, API/data access, coexistence.
3. **Pattern catalog (P1–P7)** — for each: intent, authN, authZ, data access, standard, anti-pattern.
4. **IdP-direction table** — per workload/app: chosen IdP, relying party, protocol (SAML/OIDC).
5. **Provisioning map** — per object type: source of truth and mechanism (SCIM P2 / GCDS P3 / JIT).
6. **Third-party app capability matrix** — per app: SSO protocol, provisioning mechanism, role model,
   and "verify in tenant" flags.
7. **Coexistence cutover plan** — per workload: IdP owner and cutover order.
8. **Standards & anti-patterns** — the consistent authN/authZ/data-access rules and what to avoid.
9. **Exception register** — deliberate deviations, with owner and review date.
10. **Conformance cadence** — how discovery/report run and how new integrations are classified.

## What the buyer receives
- This implementation guide and the pattern catalog as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess → Configure → Pilot → Validate → Expand.

## Outcome
A consistent, standards-based integration estate — Entra↔Google federation and provisioning, M365
coexistence, and third-party apps all built to a named pattern with consistent authentication,
authorization, and data access — snowflakes and credential sprawl designed out, exceptions visible and
few, proven on a pilot before scaling across the estate.
