# 8. Deliverables Summary — Microsoft Purview Data Governance: Data Map, Scanning & Unified Catalog

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The Data Map, scanning + classification, the Unified Catalog (domains, data products, glossary, data quality), lineage, and how it complements M365 Purview (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: design, register, pilot-scan, curate, wire lineage, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Pilot collection | `DG-Collection-Pilot` |
| Pilot governance domain | `DG-Domain-Pilot` |
| Scan rule set | `DG-ScanRuleSet-Pilot` |
| Custom classification rule (as needed) | `DG-Classification-Custom-<name>` |
| Business glossary term set | `DG-Glossary-Pilot` |
| Data product | `DG-DataProduct-Pilot` |
| Data-quality rule set (if available) | `DG-DQ-Ruleset-Pilot` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PURVGOV-Discovery.ps1` | Reports data-governance readiness: account endpoint reachable, collections + role coverage, registered integration runtimes, and known source/asset counts (Purview data-plane REST via an Azure token; read-only) |
| `PURVGOV-Register-Source.ps1` | Registers a data source and configures a scoped scan; **defaults to `-WhatIf`** (prints the plan), applies only with `-Commit`; no secrets in code |
| `PURVGOV-Curate-Catalog.ps1` | Unified Catalog curation helper for a glossary term, a classification association, or a data product; **`-WhatIf` by default**, writes only with `-Commit` |
| `PURVGOV-Report.ps1` | Scan + classification coverage and catalog-health report: scan run status, classified vs unclassified assets, glossary/data-product/ownership coverage (read-only) |
| `PURVGOV-Set-Scope.ps1` | Records the pilot/expansion scope — the source set, governance domain, and data-product intent — as a scope manifest to configure against (read-only) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
A governed data estate — sources mapped, assets scanned and classified, the Unified Catalog curated
with domains, data products, glossary, and owners, and lineage wired — discoverable and governed far
beyond Microsoft 365, proven on a pilot scope before you scale.
