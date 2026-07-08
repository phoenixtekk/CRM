# 8. Deliverables Summary — SAP Data Governance: Microsoft Purview

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Registering, scanning, and classifying SAP into the Purview Data Map — the SAP connectors, the safe SHIR/driver/credential model, and how it complements M365 Purview (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: design, SHIR + SAP driver, SAP credential, register, pilot-scan, classify, assign ownership, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Pilot collection | `DGSAP-Collection-Pilot` |
| SAP credential (references the Key Vault secret by name) | `DGSAP-Cred-SAP-KV` |
| Scan rule set | `DGSAP-ScanRuleSet-Pilot` |
| Custom classification rule (as needed) | `DGSAP-Classification-Custom-<name>` |
| Example SAP read user (created in SAP) | `PURVIEW_SCAN` |
| Example SAP authorization role (created in SAP) | `Z_PURVIEW_SCAN` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DGSAP-Discovery.ps1` | Reports readiness: account endpoint reachable, collections + role coverage, registered integration runtimes (looks for a SHIR), and registered SAP source counts (Purview data-plane REST via an Azure token; read-only) |
| `DGSAP-Set-Scope.ps1` | Records the pilot/expansion SAP scope — the SAP system(s), type, connection details, owners, collection, credential name, and scan-rule-set intent — as a scope manifest to configure against (read-only) |
| `DGSAP-Register-SapSource.ps1` | Registers an SAP ECC/S4HANA/BW/HANA source (via the SHIR) and configures a scoped scan; **defaults to `-WhatIf`** (prints the plan), applies only with `-Commit`; credential referenced by name — no secrets in code |
| `DGSAP-Report.ps1` | Scan + classification coverage report for SAP assets: scan run status per source, classified vs unclassified assets, and owner coverage (read-only) |
| `DGSAP-Test-Readiness.ps1` | Consolidated PASS/GAP pilot-gate check across account, roles, SHIR, SAP source registration/Test-connection readiness, scan status, classification coverage, and ownership (read-only) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
SAP data governed from Purview — SAP systems registered into the Data Map, scanned and classified, and
owned — proven on a bounded pilot before you scale, with the SAP blind spot closed and regulatory,
records, and access determinations left to the owners who make them.
