# 8. Deliverables Summary — Tier-1 Publisher License & Audit-Risk Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | Tier-1 publisher landscape, the metrics (Oracle Processor/NUP, IBM PVU, SAP named-user & digital access), why audit risk is high, and the defensible-position approach |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: scope, metric, mapping, position, gap closure, controls, audit prep |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `TIER1LIC-Discovery.ps1` | Reads inventory exports / CSV and assembles the deployment inventory for a publisher (host, edition, cores, virtualization host/cluster, users). Read-only |
| `TIER1LIC-Validation.ps1` | Maps each deployment to its licensing metric and flags rows that cannot be mapped. Read-only |
| `TIER1LIC-Report.ps1` | Calculates per-publisher position (consumption vs entitlement) and writes the exposure register. Read-only |
| `TIER1LIC-Remediation.ps1` | Proposes safe gap-closure actions for over-deployment; runs in `-WhatIf` by default and changes nothing without approval |
| `TIER1LIC-Set-ScopeTargeting.ps1` | Builds the publisher-scope group (hosts/users in scope) from the inventory |

## Artifacts produced (named, reused per publisher)
- Per-publisher position worksheet — metric, entitlement, and consumption per product.
- Deployment-to-metric mapping — each install mapped to its metric quantity.
- Per-publisher exposure register — shortfall/headroom, severity, owner, disposition.
- Tier-1 publisher controls — where high-risk software may run and who may deploy it.
- Audit evidence pack — the assembled, current proof handed to an auditor.

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess to Configure to Pilot to Validate to Expand, proven on one publisher
  before expanding.

## Outcome
The highest-risk publishers under control — Oracle, IBM, and SAP positions calculated against their
own metrics, exposure identified before an auditor finds it, and controls in place so a tier-1 audit
holds no surprises.
