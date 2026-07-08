# 8. Deliverables Summary — Snowflake Data Governance (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Registering, scanning, and classifying Snowflake in the Purview Data Map + catalog; Key Vault-backed credential, pilot-scoped scan; how cataloging differs from DLP (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess collections/runtimes, design the approach, prepare the Key Vault-backed credential + register the source, create and run the scan on a pilot database, validate, expand + schedule + curate |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Collection | `Snowflake – Collection` |
| Registered source | `Snowflake – Source` |
| Scan | `Snowflake – Scan` |
| Scan rule set | `Snowflake – Scan Rule Set` |
| Credential (Key Vault-backed) | `Snowflake – Scan Credential` |
| Pilot scope | `Snowflake – Pilot Scope – Stage1` |
| Design map | `Snowflake Governance – Map` |
| Coverage report | `Snowflake – Coverage Report` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DGSNOW-Discover.ps1` | Reports current state: Data Map collections, existing registered sources and scans, and registered integration runtimes — PowerShell/REST against the Purview Data Map; read-only |
| `DGSNOW-Check-Prereqs.ps1` | Prerequisite/health helper: Az module + connection, the Purview-account and Data-Map read signals, and reminders to confirm the Key Vault linkage, SHIR, and roles — PASS/GAP per signal; read-only |
| `DGSNOW-Register-Source.ps1` | Registration/Scan: registers `Snowflake – Source` under the collection (`-Action RegisterSource`), creates `Snowflake – Scan` referencing the Key Vault-backed credential **by name** and scoped to the pilot database (`-Action CreateScan`), and triggers/deletes scans (`-Action RunScan`/`DeleteScan`); **defaults to `-WhatIf`** (prints the plan + reverse action), applies only with `-Commit`; **no secret in code** |
| `DGSNOW-Validate.ps1` | Validation: PASS/FAIL that the source is registered under the collection, the scan exists, the last scan completed, and assets/classifications are present for the pilot scope — read-only |
| `DGSNOW-Report.ps1` | Coverage report — the source, its scans, last-run status, and a classification summary — written to CSV as `Snowflake – Coverage Report`; read-only |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
Snowflake governed from Purview — registered in the Data Map, scanned on a schedule, and its sensitive
assets classified in the catalog — proven on a pilot database before scanning the account, with the
credential Key Vault-backed (no secret in code) and the classification scheme, data ownership, and glossary
left to the data-governance owners who make them.
