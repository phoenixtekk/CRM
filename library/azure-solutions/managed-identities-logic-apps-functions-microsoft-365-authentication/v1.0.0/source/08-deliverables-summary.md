# 8. Deliverables Summary — Managed Identities for Azure Logic Apps & Functions

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What managed identities are, system- vs user-assigned, the Logic Apps + Functions patterns, pointers to #4 (mailbox scoping) and #1/#2/#3 (mailbox uses); benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — enable identity, grant least-privilege app-role + consent, Logic App Graph call, Function Graph call (code example), validate, migrate |
| 5. Testing Guide | PASS/FAIL validation for both compute types, least privilege, and migration parity |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts (Microsoft.Graph)
| Script | What it does |
|---|---|
| `MIM365-Discovery.ps1` | Read-only — enumerates Logic Apps/Functions and whether each has a managed identity and which application app-roles are assigned |
| `MIM365-Validate.ps1` | PASS/FAIL — target compute has a managed identity with least-privilege app permissions and no leftover secret-based connection |
| `MIM365-Report.ps1` | Identity/permission inventory across the estate, plus a CSV export |
| `MIM365-Find-StoredCredentials.ps1` | Read-only — reports workflows/apps still using stored service-account connections or client secrets (the migration worklist) |
| `MIM365-Set-AppRole.ps1` | The only state-changer — assigns/verifies an application app-role to a managed identity; **defaults to -WhatIf** |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the standard model: **Assess → Configure → Pilot → Validate → Expand** — piloting one workflow before expanding, with a stored-credential worklist as the migration driver and a rollback for every cutover.

## Outcome
Azure automations authenticating to Microsoft 365 with **no stored credential** — Logic Apps and Functions reaching Microsoft Graph through managed identities and least-privilege application permissions, with existing secret-based flows migrated off and retired.
