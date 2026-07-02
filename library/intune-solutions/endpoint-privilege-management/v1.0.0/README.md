# Endpoint Privilege Management (EPM) — v1.0.0

**Category:** Intune Solutions · **Slug:** `endpoint-privilege-management` · **SOL code:** `EPM`
**Status:** generated (not yet published) · **Created:** 2026-06-14

## Products
| Product | SKU | Price |
|---|---|---|
| Commercial | `PTK-EPM-COMM-001` | $1,495.00 |
| Non-Profit | `PTK-EPM-NPO-001` | $897.00 (40% below commercial) |

## What's inside this folder
- `source\` — authored markdown (overview, requirements, global requirements, implementation, testing, troubleshooting, best practices, deliverables summary, executive summary).
- `scripts\` — 5 PowerShell scripts (Discovery, Validation, ElevationReport, Remediation, New-EpmElevationRule).
- `deliverables\` — **buyer files**: `EPM-Solution.docx`, `EPM-Solution.pdf` (branded guide), `EPM-Scripts.zip`, plus `EPM-hero.svg/.png`.
- `listing\` — `bagisto-products.json` (publish contract) + `sales-content.md` + `hero.json`.
- `solution.meta.json` — metadata (drives the library index).

## Deployment model
Intune-managed, Microsoft Entra–joined Windows devices. EPM enabled via a base policy and governed
by **certificate/hash-based elevation rules** (User confirmed by default). Observe real elevations
with reporting first, then remove standing local-admin rights.
repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**.

> **Licensing:** Requires the Microsoft Intune Suite or the standalone Endpoint Privilege Management
> add-on (not in base Intune Plan 1).

## Next step
Review the deliverables, then publish:
```
/publish-solution endpoint-privilege-management
```

## Rebuild deliverables (after editing source/scripts)
```
python tools\build-deliverables.py --solution-dir "library/intune-solutions/endpoint-privilege-management/v1.0.0"
python tools\build-hero.py        --solution-dir "library/intune-solutions/endpoint-privilege-management/v1.0.0"
```
