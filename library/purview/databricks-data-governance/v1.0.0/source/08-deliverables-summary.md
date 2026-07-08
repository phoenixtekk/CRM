# 8. Deliverables Summary — Databricks Data Governance (Unity Catalog / lakehouse): Microsoft Purview

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Registering, scanning, classifying, and cataloging Azure Databricks / lakehouse (Unity Catalog) assets into the Purview Data Map with lineage — the connectors, the safe credential/network model, and how it complements M365 Purview (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: design, Key Vault credential + network, register, pilot-scan, classify, review lineage, curate catalog, assign ownership, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Pilot collection | `DGDBX-Collection-Pilot` |
| Databricks scan credential (references the Key Vault secret by name) | `DGDBX-Cred-Databricks-KV` |
| Scan rule set | `DGDBX-ScanRuleSet-Pilot` |
| Custom classification rule (as needed) | `DGDBX-Classification-Custom-<name>` |
| Self-hosted integration runtime (private workspace) | `DGDBX-SHIR` |
| Governance domain (Unified Catalog) | `DGDBX-Domain-Lakehouse` |
| Curated data product (as published) | `DGDBX-DataProduct-<name>` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DGDBX-Discovery.ps1` | Reports readiness: account endpoint reachable, collections + role coverage, registered integration runtimes, Key Vault connection presence, and registered Azure Databricks / lakehouse source counts (Purview data-plane REST via an Azure token; read-only) |
| `DGDBX-Set-Scope.ps1` | Records the pilot/expansion Databricks scope — workspace, in-scope catalog/schema, owners, collection, credential name, scan-rule-set intent, and schedule — as a scope manifest; previews the schedule by default, applies it only with `-Commit` (read-only unless `-Commit`) |
| `DGDBX-Register-DatabricksSource.ps1` | Registers an Azure Databricks (Unity Catalog / lakehouse) source and configures a scoped scan; **defaults to `-WhatIf`** (prints the plan), applies only with `-Commit`; credential referenced by name — no secrets in code |
| `DGDBX-Report.ps1` | Exports cataloged Databricks assets, classification results, and lineage coverage to CSV: per-source scan status, classified vs unclassified assets, and lineage/ownership coverage (read-only) |
| `DGDBX-Test-Readiness.ps1` | Consolidated PASS/GAP gate across account reachability, roles, integration runtime, credential, Databricks source registration/Test-connection readiness, scan status, classification coverage, and ownership (read-only) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
Databricks / lakehouse data governed from Purview — the Unity Catalog workspace registered into the Data
Map, scanned, classified, cataloged with lineage, and owned — proven on a bounded pilot before you scale,
with the lakehouse blind spot closed and regulatory, records, and access determinations left to the owners
who make them.
