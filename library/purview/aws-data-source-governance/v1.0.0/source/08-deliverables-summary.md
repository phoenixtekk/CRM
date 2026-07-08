# 8. Deliverables Summary — AWS Data-Source Governance (S3/RDS): Microsoft Purview

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Registering, scanning, and classifying AWS S3 and RDS into the Purview Data Map — the two connectors, the safe trust/credential model, and how it complements M365 Purview (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: design, S3 trust + RDS credential, register, pilot-scan, classify, assign ownership, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Pilot collection | `DGAWS-Collection-Pilot` |
| S3 role credential (references the IAM role ARN by name) | `DGAWS-Cred-S3-Role` |
| RDS credential (references the Key Vault secret by name) | `DGAWS-Cred-RDS-KV` |
| Scan rule set | `DGAWS-ScanRuleSet-Pilot` |
| Custom classification rule (as needed) | `DGAWS-Classification-Custom-<name>` |
| Example S3 IAM role (created in AWS) | `PurviewScanRole-S3` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DGAWS-Discovery.ps1` | Reports readiness: account endpoint reachable, collections + role coverage, registered integration runtimes, and registered AWS (S3/RDS) source counts (Purview data-plane REST via an Azure token; read-only) |
| `DGAWS-Set-Scope.ps1` | Records the pilot/expansion AWS scope — the S3 buckets / RDS databases, owners, collection, and scan-rule-set intent — as a scope manifest to configure against (read-only) |
| `DGAWS-Register-AwsSource.ps1` | Registers an Amazon S3 or Amazon RDS source and configures a scoped scan; **defaults to `-WhatIf`** (prints the plan), applies only with `-Commit`; credentials referenced by name — no secrets in code |
| `DGAWS-Report.ps1` | Scan + classification coverage report for AWS assets: scan run status per source, classified vs unclassified assets, and owner coverage (read-only) |
| `DGAWS-Test-Readiness.ps1` | Consolidated PASS/GAP pilot-gate check across account, roles, AWS source registration/Test-connection readiness, scan status, classification coverage, and ownership (read-only) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
AWS data governed from Purview — S3 buckets and RDS databases registered into the Data Map, scanned and
classified, and owned — proven on a bounded pilot before you scale, with the AWS blind spot closed and
regulatory, records, and access determinations left to the owners who make them.
