# 8. Deliverables Summary — Data Estate Insights & Data Quality (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Data Estate Insights (estate health reporting) and Data Quality (rules + scoring across the governed estate), how a pilot works, and how it complements the Data Map/catalog foundation (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: design scope, baseline insights, author rules, pilot-scan scoring, review, health tracking, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Pilot governance domain | `DGI-Domain-Pilot` |
| Pilot data product | `DGI-DataProduct-Pilot` |
| Critical data element | `DGI-CDE-<name>` |
| Data-quality rule set | `DGI-DQ-Ruleset-Pilot` |
| Data-quality rule | `DGI-DQ-Rule-<Dimension>-<CDE>` |
| Insights baseline | `DGI-Insights-Baseline` |
| Health control set (if available) | `DGI-Health-Controls-Pilot` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DGINSIGHT-Discovery.ps1` | Reports readiness: account endpoint reachable, catalogued asset / governance-domain / data-product counts, whether the Data Quality surface responds (feature available), and role coverage (Purview data-plane REST via an Azure token; read-only) |
| `DGINSIGHT-Set-Scope.ps1` | Records the pilot/expansion scope — domain, data product, critical data elements, and per-CDE dimension/rule/threshold — as a scope manifest to configure against (read-only) |
| `DGINSIGHT-Configure-Quality.ps1` | Authors data-quality rules and runs the scoring scan for a data product; **defaults to `-WhatIf`** (prints the plan), applies only with `-Commit`; `-RunScan`/`-Remove` gated the same way; no secrets in code |
| `DGINSIGHT-Report.ps1` | Data Estate Insights + data-quality scoring report: asset/classification/ownership distribution and per-rule/per-data-product quality scores vs threshold, with a baseline for trend tracking (read-only) |
| `DGINSIGHT-Scope-Health.ps1` | Scope + estate-health helper: coverage gaps (data products without owners, CDEs without rules, stale scans) for a domain — reports the same checks whether or not health-controls is enabled (read-only) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
A measured, defensible data estate — health reported through Data Estate Insights (asset,
classification, and ownership coverage) and data quality scored through Unified Catalog rules across the
governed estate's critical data — piloted on a bounded data product and validated before scale, with
thresholds and remediation left to the owners who make them.
