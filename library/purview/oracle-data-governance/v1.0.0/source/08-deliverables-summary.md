# 8. Deliverables Summary — Oracle Data Governance: Microsoft Purview

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Registering, scanning, and classifying Oracle databases into the Purview Data Map — the connector, the safe Key Vault credential + SHIR model, and how it complements M365 Purview (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: design, read login, Key Vault credential, SHIR + network + driver, register, pilot-scan, classify, assign ownership, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Pilot collection | `DGORACLE-Collection-Pilot` |
| Oracle credential (references the Key Vault secret by name) | `DGORACLE-Cred-Oracle-KV` |
| Self-hosted integration runtime | `DGORACLE-SHIR` |
| Scan rule set | `DGORACLE-ScanRuleSet-Pilot` |
| Custom classification rule (as needed) | `DGORACLE-Classification-Custom-<name>` |
| Example read-only Oracle login (created in Oracle) | `PURVIEW_SCAN` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DGORACLE-Discovery.ps1` | Reports readiness: account endpoint reachable, collections + role coverage, registered integration runtimes (SHIR), and registered Oracle source counts (Purview data-plane REST via an Azure token; read-only) |
| `DGORACLE-Set-Scope.ps1` | Records the pilot/expansion Oracle scope — the host/service, port, in-scope schemas, owners, collection, credential name, and scan-rule-set intent — as a scope manifest to configure against (read-only) |
| `DGORACLE-Register-OracleSource.ps1` | Registers an Oracle source and configures a scoped scan; **defaults to `-WhatIf`** (prints the plan), applies only with `-Commit`; credential referenced by name — no secrets in code |
| `DGORACLE-Report.ps1` | Scan + classification coverage report for Oracle assets: scan run status, classified vs unclassified assets, and owner coverage (read-only) |
| `DGORACLE-Test-Readiness.ps1` | Consolidated PASS/GAP pilot-gate check across account, roles, SHIR, Oracle source registration/Test-connection readiness, scan status, classification coverage, and ownership (read-only) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
Oracle data governed from Purview — databases and schemas registered into the Data Map, scanned and
classified, and owned — proven on a bounded pilot before you scale, with the Oracle blind spot closed
and regulatory, records, and access determinations left to the owners who make them.
