# Windows Hello for Business — v1.0.0

**Category:** Intune Solutions · **Slug:** `windows-hello-for-business` · **SOL code:** `WHFB`
**Status:** generated (not yet published) · **Created:** 2026-06-13

## Products
| Product | SKU | Price |
|---|---|---|
| Commercial | `PTK-WHFB-COMM-001` | $1,495.00 |
| Non-Profit | `PTK-WHFB-NPO-001` | $897.00 (40% below commercial) |

## What's inside this folder
- `source\` — authored markdown (overview, requirements, global requirements, implementation, testing, troubleshooting, best practices, deliverables summary, executive summary).
- `scripts\` — 5 PowerShell scripts (Discovery, Validation, TenantReport, Remediation, Enable-EntraKerberos).
- `deliverables\` — **buyer files**: `WHFB-Solution.docx`, `WHFB-Solution.pdf` (19-page branded guide), `WHFB-Scripts.zip`.
- `listing\` — `bagisto-products.json` (publish contract) + `sales-content.md`.
- `solution.meta.json` — metadata (drives the library index).

## Deployment model
Microsoft Entra–joined devices, Intune-managed, **Cloud Kerberos Trust** (no PKI/NDES/certs).
Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand**.

## Next step
Review the deliverables, then publish:
```
/publish-solution windows-hello-for-business
```

## Rebuild deliverables (after editing source/scripts)
```
python tools\build-deliverables.py --solution-dir "library/intune-solutions/windows-hello-for-business/v1.0.0"
```
