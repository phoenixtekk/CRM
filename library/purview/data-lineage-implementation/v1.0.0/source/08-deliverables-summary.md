# 8. Deliverables Summary — Data Lineage Implementation (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Data lineage in the Purview Data Map / Unified Catalog, the capture model (automatic connectors vs. custom Atlas lineage), the Assess→Design→Configure→Pilot→Validate→Expand approach, limitations, and the naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (Purview Data Governance account, data-plane roles, Az + REST toolchain, registered+scanned sources, connections, custom-lineage plan) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell/REST steps (assess the Data Map, design the coverage/connection map, scan endpoints, connect automatic sources pilot-first, push custom lineage `-WhatIf`→`-Commit`, validate the graph, measure coverage, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DGLINE-Discovery.ps1` | Read-only discovery: enumerates registered **data sources**, their **last-scan status**, and per source whether it is **lineage-capable/connected** (ADF/Synapse/Data Share/Power BI) or **needs custom lineage**. Writes `Data Lineage Source Inventory – DGLINE – Discovery` |
| `DGLINE-Configure.ps1` | Custom-lineage configuration/remediation helper: pushes Atlas **`Process`** entities (inputs/outputs by qualified name) to the catalog data-plane API from a coverage-map CSV; **`-WhatIf` by default**, `-Commit` to apply; prints the created GUID and the reverse `DELETE` for each push |
| `DGLINE-Validate.ps1` | Read-only lineage validation: resolves an asset by qualified name and queries the **Atlas lineage endpoint**, reporting the **upstream/downstream** entities and edge count for a named asset |
| `DGLINE-Report.ps1` | Read-only coverage report: enumerates in-scope assets and reports **with-lineage vs. without-lineage** per collection/source plus last-scan status. Writes `Data Lineage Coverage – DGLINE – Report` |
| `DGLINE-ScopeHealth.ps1` | Read-only scope/health helper: confirms the account endpoint is reachable, acquires a `purview.azure.net` data-plane token, and lists the **collections** the token can enumerate |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit`
to change anything. No credentials or secrets are stored in code; every script uses interactive
modern-auth (`Connect-AzAccount`) and a short-lived Azure AD **data-plane token**
(`Get-AzAccessToken -ResourceUrl 'https://purview.azure.net'`). REST `api-version` values and portal
paths are cited as of authoring — **verify against your tenant.**

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
Data lineage implemented in Microsoft Purview — in-scope sources registered and scanned, automatic
lineage flowing from the connected integration systems, custom lineage pushed for the systems that don't
self-report, the graph validated for correctness on a pilot scope, and **coverage measured** against the
governance target — so that, for the in-scope estate, data can be traced from source to report and
back, defensibly. Regulatory/records determinations and the authoritative-source designation are
deferred to the data-governance, records, privacy, and legal functions.
