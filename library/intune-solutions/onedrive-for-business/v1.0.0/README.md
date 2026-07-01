# OneDrive for Business — v1.0.0

**Category:** Intune Solutions · **Slug:** `onedrive-for-business` · **SOL code:** `ODFB`
**Status:** generated (not yet published) · **Created:** 2026-06-13

## Products
| Product | SKU | Price |
|---|---|---|
| Commercial | `PTK-ODFB-COMM-001` | $1,495.00 |
| Non-Profit | `PTK-ODFB-NPO-001` | $897.00 (40% below commercial) |

## What's inside this folder
- `source\` — authored markdown (overview, requirements, global requirements, implementation, testing, troubleshooting, best practices, deliverables summary, executive summary).
- `scripts\` — 5 PowerShell scripts (Get-TenantId, Discovery, Validation, TenantReport, Remediation).
- `deliverables\` — **buyer files**: `ODFB-Solution.docx`, `ODFB-Solution.pdf` (branded guide), `ODFB-Scripts.zip`, plus `ODFB-hero.svg/.png` (product image).
- `listing\` — `bagisto-products.json` (publish contract) + `hero.json` + `sales-content.md`.
- `solution.meta.json` — metadata (drives the library index).

## Deployment model
Windows devices, Intune-managed, OneDrive configured via the **Settings Catalog** — Silent Sign-In
+ Known Folder Move + Files On-Demand. Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand**.

## Next step
Review the deliverables, then publish:
```
/publish-solution onedrive-for-business
```

## Rebuild deliverables / hero (after editing source/scripts/hero.json)
```
python tools\build-deliverables.py --solution-dir "library/intune-solutions/onedrive-for-business/v1.0.0"
python tools\build-hero.py        --solution-dir "library/intune-solutions/onedrive-for-business/v1.0.0"
```
