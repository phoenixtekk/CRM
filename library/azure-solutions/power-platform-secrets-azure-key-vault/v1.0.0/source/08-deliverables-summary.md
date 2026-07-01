# 8. Deliverables Summary — Standardize Power Platform Secrets in Azure Key Vault

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The problem, secret types in scope, the four retrieval patterns + decision guide, access model, governance/rotation model |
| 2. Requirements Guide | Every prerequisite with Why / Verify / Implement-if-missing |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps across the Azure, Power Platform admin, and Power Apps maker portals |
| 5. Testing Guide | Validation procedures with pass/fail gates (including no-exposure proofs) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PPKV-Discovery.ps1` | Inventories Key Vaults, secrets, and RBAC assignments; best-effort scan of exported flow/app/connector JSON for hardcoded-secret patterns (read-only) |
| `PPKV-Validation.ps1` | Confirms the Power Platform service principal has `Key Vault Secrets User`, a secret resolves, and the vault uses the RBAC model (read-only) |
| `PPKV-Report.ps1` | Secrets inventory with expiry/rotation status and read/manage access — no values printed (read-only) |
| `PPKV-Remediation.ps1` | Safe remediation (defaults to `-WhatIf`): assigns `Key Vault Secrets User`, sets secret expiry |
| `PPKV-Set-RotationOwnership.ps1` | Sets rotation/expiry and ownership tags on secrets (defaults to `-WhatIf`) |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every Power Platform secret centralized in Azure Key Vault, retrieved through an approved pattern,
with no hardcoded credentials left in apps, flows, connectors, exports, or logs — and rotation that
never requires an app rebuild, proven on a pilot before you scale.
