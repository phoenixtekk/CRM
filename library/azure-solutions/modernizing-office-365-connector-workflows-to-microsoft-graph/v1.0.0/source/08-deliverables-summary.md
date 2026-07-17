# 8. Deliverables Summary — Modernizing Office 365 Connector Workflows to Microsoft Graph

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Why this is a program not a one-off — the inventory→classify→migrate→govern arc, the per-flow playbook that leans on siblings #1/#2/#3/#5 and defers scoping to #4, benefits, limitations, and the Logic-Apps-vs-Power-Automate reality |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (read access for both platforms, rights to create managed identities + grant/consent Graph permissions, a pilot cohort) |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | The program runbook — inventory, classify, configure pilot targets, pilot cutover, pilot gate, wave expansion, govern |
| 5. Testing Guide | PASS/FAIL gates — inventory completeness, per-flow parity, no residual credentials, scoped permission, rollback, no regression |
| 6. Troubleshooting Guide | Field issues — missed flow, parity break, Power Automate can't take a managed identity, permission/consent gaps, regression |
| 7. Best Practices | Field-proven recommendations for the program |

## PowerShell scripts
| Script | What it does |
|---|---|
| `O365GRAPH-Discovery.ps1` | Read-only — enumerates Logic Apps using Office 365 connectors and how each authenticates; flags where Power Automate data must be supplied (enumeration method: verify) |
| `O365GRAPH-Classify.ps1` | Read-only — scores each discovered flow by risk + Graph-migratability and writes the `Migration-Register – Estate – Program.csv` |
| `O365GRAPH-Validate.ps1` | PASS/FAIL — a migrated flow uses managed identity + Graph and has no stored-credential connection |
| `O365GRAPH-Report.ps1` | Program dashboard — total connector flows, migrated, remaining, risk buckets + CSV |
| `O365GRAPH-Set-AppRole.ps1` | The only state-changer — assigns/verifies an application app-role on a migrated flow's managed identity; **defaults to `-WhatIf`** |

## What the buyer receives
- This program runbook as a **Word** document and **PDF** (cover, table of contents, page numbers, scripts appendix).
- All five **PowerShell scripts** in a single ZIP.
- A repeatable program following the standard model — **Assess → Configure → Pilot → Validate → Expand** — with a pilot-first gate and a documented per-flow rollback.

## Outcome
An Office 365 connector estate migrated at scale onto managed-identity Microsoft Graph workflows — inventoried, risk-ranked, migrated with a repeatable per-flow playbook that leans on the sibling products, parity-validated, and governed so it ends **credential-free** and stays that way.
