# Dual-Device (Personal + Corporate) Management with Single Sign-On — v1.0.0

| | |
|---|---|
| **Category** | Intune Solutions |
| **Solution code** | DUALDEV |
| **Version** | 1.0.0 |
| **Commercial** | $2,495.00 (SKU `PTK-DUALDEV-COMM-001`) |
| **Non-Profit** | $1,497.00 (SKU `PTK-DUALDEV-NPO-001`, 40% off) |

**Lineage:** **Forked (`+1`) from `cod-and-byod-device-management` v1.0.0** as a separate product —
the original COD/BYOD product is unchanged and still live. This variant specializes in the
**one-user / two-physical-devices** scenario with **single sign-on** across both.

**Shaping notes:** _"The solution must allow a single user account to sign in on both the COD and BYOD
device for scenarios where a user has 2 devices, a Personal and Corporate Owned device."_
→ Designed around **one Microsoft Entra identity** signed in across the user's **personal (App
Protection / MAM)** and **corporate-owned (full MDM)** devices, with **single sign-on** on both,
unified by ownership-based targeting and a single Conditional Access policy. (Internal authoring
guidance — not printed verbatim in the customer deliverables.)

## What it is
For the employee who carries **two devices** — a personal phone/tablet (BYOD) and a corporate laptop
(COD). One Entra account signs in on **both**, with **single sign-on**; corporate-owned devices get
full MDM (compliance + configuration), personal devices get App Protection (MAM) for corporate data
without device takeover. Ownership-based **device filters** route the right policy to each of the
user's devices, and one **Conditional Access** policy grants access from a compliant COD *or* an
app-protected BYOD device.

## What's included
**Documentation (Word + PDF):** Executive Summary · Solution Overview · Requirements (+ category
Global Requirements) · Implementation (6 phases) · Testing · Troubleshooting · Best Practices ·
Deliverables Summary.

**PowerShell scripts (`DUALDEV-Scripts.zip`):**
- `DUALDEV-Discovery.ps1` — tenant readiness (restrictions, compliance, app protection, filters, CA).
- `DUALDEV-Validation.ps1` — prove one user owns both a Corporate and a Personal device.
- `DUALDEV-DeviceReport.ps1` — ownership inventory + users with both COD and BYOD.
- `DUALDEV-Remediation.ps1` — safe ownership fixes (read-only by default).
- `Set-OwnershipBasedTargeting.ps1` — create the Corporate/Personal device filters.

**Hero image:** `DUALDEV-hero.png` (1200×1200).

## Files
```
source/        executive-summary, 01-overview, 02-requirements, global-requirements, 03-implementation,
               05-testing, 06-troubleshooting, 07-best-practices, 08-deliverables-summary
scripts/       DUALDEV-Discovery, DUALDEV-Validation, DUALDEV-DeviceReport, DUALDEV-Remediation, Set-OwnershipBasedTargeting
listing/       bagisto-products.json, hero.json, sales-content.md
deliverables/  DUALDEV-Solution.docx, DUALDEV-Solution.pdf, DUALDEV-Scripts.zip, DUALDEV-hero.svg/.png
solution.meta.json
```

## Next
Build deliverables + hero, then `/publish-solution cod-byod-dual-device-sso`.
