# 8. Deliverables Summary — Google Cloud Data-Source Governance: Microsoft Purview

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The Data Map, the Google BigQuery connector, scanning + classification, collections & roles, and how it complements M365 Purview (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: design, service-account credential, SHIR/network, register, pilot-scan, review, assign owners, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Pilot collection | `DGGCP-Collection-Pilot` |
| Scan rule set | `DGGCP-ScanRuleSet-Pilot` |
| BigQuery service-account credential (Key Vault, by name) | `DGGCP-Cred-BQ-KV` |
| Custom classification rule (as needed) | `DGGCP-Classification-Custom-<name>` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DGGCP-Discovery.ps1` | Reports Google Cloud governance readiness: account endpoint reachable, collections + role coverage, registered integration runtimes (SHIR for BigQuery), and registered data-source count (Purview data-plane REST via an Azure token; read-only) |
| `DGGCP-Set-Scope.ps1` | Records the pilot/expansion scope — the BigQuery project/dataset set with owners and the scan-rule-set intent — as a local scope manifest to register against (read-only) |
| `DGGCP-Register-GcpSource.ps1` | Registers a Google BigQuery source and configures a scoped scan; **defaults to `-WhatIf`** (prints the plan), applies only with `-Commit`; references the Key Vault credential by name — no secrets in code |
| `DGGCP-Report.ps1` | Scan + classification coverage report: per-source last scan status, classified vs unclassified assets with coverage %, and owner coverage (read-only) |
| `DGGCP-Test-Readiness.ps1` | Consolidated PASS/GAP pilot-gate check: account reachable, roles present, source registered, scan Succeeded, classification coverage > 0, owners assigned (read-only) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
Google Cloud data — BigQuery projects, datasets, and tables — registered, scanned, and classified in
the same Purview Data Map that governs the rest of the estate, with named owners and a pilot-proven
scan pattern before you scale.
