# 8. Deliverables Summary — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The dual-ecosystem governance model — what's governed in Vault vs Purview, and how holds/retention/discovery are coordinated across both |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Google) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: inventory, matched matter/case, Vault retention + hold, Purview parallel hold + retention, cross-system discovery, pilot, expand |
| 5. Testing Guide | Validation gates with coexistence and discovery probes and pass/fail criteria |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for defensible eDiscovery across both ecosystems |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GWVAULT-Discovery.ps1` | Read-only: retention/hold discovery across the estate — Vault matters, holds, and retention rules (per service), with Purview-side coverage flagged to confirm |
| `GWVAULT-Validation.ps1` | Read-only: per-scope retention/hold validation — Vault hold present in the matter across in-scope services, retention matches the approved schedule; Purview side flagged to confirm |
| `GWVAULT-Report.ps1` | Read-only: coverage/gap report — which custodians are held/retained in Vault vs Purview, so no custodian is held on only one ecosystem |
| `GWVAULT-Remediation.ps1` | Safe remediation (default `-WhatIf`): applies a Vault hold to matched custodians in a matter to close a coverage gap; reports Purview-side gaps for parallel action |
| `GWVAULT-Set-ScopeTargeting.ps1` | Creates the pilot custodian scope group / matched matter scope (idempotent, default `-WhatIf`) for controlled rollout |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Scope note
This package delivers the **technical mapping** of governance across Google Vault and Microsoft
Purview. Retention *periods*, hold *triggers*, and what "defensible" requires for a specific matter
are **legal/records-counsel determinations**, engaged as a named stakeholder throughout. Vendor
specifics (Vault's Gemini-app hold/retention support, the evolving Purview eDiscovery experience) are
cited from current documentation or flagged **"verify in your tenant,"** never invented.

## Outcome
Defensible eDiscovery, legal hold, and retention across **both** Google Vault and Microsoft Purview —
what's governed where is mapped, Vault holds and retention are configured and mirrored to Purview in
parallel, retention is aligned to the longer schedule, discovery runs across both and reconciles into
one production, and the whole loop is proven on a pilot custodian scope before the full population
depends on it — with no compliance gap during coexistence.
