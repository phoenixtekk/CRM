# 8. Deliverables Summary — Scoping Application-Permission Mailbox Access

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | The exposure (tenant-wide app mail permission), what's in the box, and the outcome |
| 1. Solution Overview | The exposure, the **two scoping models** (Application Access Policy & Graph RBAC for Exchange Online), when each applies, the decision path, how the boundary is proven, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (Exchange Online, admin role, app/managed identity, mail-enabled security group, scope object, PowerShell modules) |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Decision path up front, then exact ordered steps for **both** models — Model A (group → access policy) and Model B (scope → scoped role assignment) — every object named, every cmdlet flagged verify-with-Microsoft |
| 5. Testing Guide | Boundary proof with PASS/FAIL gates: in-scope read succeeds, out-of-scope read DENIED, evidence captured |
| 6. Troubleshooting Guide | Field issues — no effect / propagation, still reads all mailboxes, out-of-scope not denied, group membership, RBAC errors |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MBXRBAC-Discovery.ps1` | Read-only — lists apps/managed identities holding mail-capable application permissions (Mail.Read/Mail.Send/etc.) and whether each is **scoped** or **tenant-wide** |
| `MBXRBAC-Validate.ps1` | PASS/FAIL — confirms the target app/identity is **scoped** (not tenant-wide) to the intended mailbox(es) |
| `MBXRBAC-Report.ps1` | Reports every app-permission-to-mailbox scoping (or lack of it) across the tenant + CSV — the audit artifact |
| `MBXRBAC-Test-Boundary.ps1` | Read-only — proves the in-scope read works and the out-of-scope read is denied (the boundary proof) |
| `MBXRBAC-Set-AccessPolicy.ps1` | The only state-changer — creates/verifies the Application Access Policy (or RBAC assignment); **defaults to `-WhatIf`** |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the standard model: **Assess → Configure → Pilot → Validate → Expand** — with the **boundary proof as the gate** and a documented rollback.

## Outcome
Every application and managed identity that reads or sends mail is scoped to exactly the mailboxes it is allowed to touch — least privilege, with both scoping models explained and a tested, auditable boundary — instead of a tenant-wide permission that can reach every mailbox in the organization.
