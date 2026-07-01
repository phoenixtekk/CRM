# Corporate-Owned (COD) & BYOD Device Management — v1.0.0

| | |
|---|---|
| **Category** | Intune Solutions |
| **Solution code** | CODBYOD |
| **Version** | 1.0.0 |
| **Commercial** | $2,495.00 (SKU `PTK-CODBYOD-COMM-001`) |
| **Non-Profit** | $1,497.00 (SKU `PTK-CODBYOD-NPO-001`, 40% off) |

**Shaping notes:** _"The solution must allow a single user account to sign in on both device types."_
→ Designed around **one Microsoft Entra identity** spanning corporate-owned (full MDM) and personal
(App Protection / MAM) devices, unified by ownership-based targeting and a single Conditional Access
policy. (Internal authoring guidance — not printed verbatim in the customer deliverables.)

## What it is
Unifies two device-ownership models in Intune under a single user identity: corporate-owned devices
get full MDM (compliance + configuration); personal/BYOD devices get App Protection (MAM) for
corporate data without device takeover. Ownership-based **device filters** route the right policy to
each, and one **Conditional Access** policy grants access from a compliant COD *or* an app-protected
BYOD device.

## What's included
**Documentation (Word + PDF):** Executive Summary · Solution Overview · Requirements (+ category
Global Requirements) · Implementation (6 phases) · Testing · Troubleshooting · Best Practices ·
Deliverables Summary.

**PowerShell scripts (`CODBYOD-Scripts.zip`):**
- `CODBYOD-Discovery.ps1` — tenant readiness (restrictions, compliance, app protection, filters, CA).
- `CODBYOD-Validation.ps1` — prove one user owns both a Corporate and a Personal device.
- `CODBYOD-DeviceReport.ps1` — ownership inventory + users with both COD and BYOD.
- `CODBYOD-Remediation.ps1` — safe ownership fixes (read-only by default).
- `Set-OwnershipBasedTargeting.ps1` — create the Corporate/Personal device filters.

**Hero image:** `CODBYOD-hero.png` (1200×1200).

## Files
```
source/        executive-summary, 01-overview, 02-requirements, global-requirements, 03-implementation,
               05-testing, 06-troubleshooting, 07-best-practices, 08-deliverables-summary
scripts/       CODBYOD-Discovery, CODBYOD-Validation, CODBYOD-DeviceReport, CODBYOD-Remediation, Set-OwnershipBasedTargeting
listing/       bagisto-products.json, hero.json, sales-content.md
deliverables/  CODBYOD-Solution.docx, CODBYOD-Solution.pdf, CODBYOD-Scripts.zip, CODBYOD-hero.svg/.png
solution.meta.json
```

## Next
Build deliverables + hero, then `/publish-solution cod-and-byod-device-management`.
