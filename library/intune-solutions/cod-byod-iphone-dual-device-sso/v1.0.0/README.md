# Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On — v1.0.0

| | |
|---|---|
| **Category** | Intune Solutions |
| **Solution code** | IOSDD |
| **Version** | 1.0.0 |
| **Slug** | `cod-byod-iphone-dual-device-sso` |
| **Commercial** | $2,495.00 (SKU `PTK-IOSDD-COMM-001`) |
| **Non-Profit** | $1,497.00 (SKU `PTK-IOSDD-NPO-001`, 40% off) |

**Lineage:** **Forked (`+1`) from `cod-byod-dual-device-sso` v1.0.0** as a separate product — the
source products are unchanged and still live. This variant specializes the dual-device + single
sign-on design to **iOS iPhones**: a **corporate iPhone (COD)** and a **personal iPhone (BYOD)** under
one identity.

**Shaping notes:** _"The solution must allow a single user account to sign in on both the COD and BYOD
device for scenarios where a user has 2 devices, a Personal and Corporate Owned device."_
→ Designed around **one Microsoft Entra identity** signed in across the user's **personal iPhone (App
Protection / MAM)** and **corporate iPhone (supervised full MDM via ABM + ADE)**, with **single
sign-on** on both (Microsoft Authenticator broker + iOS Enterprise SSO extension), unified by
ownership-based targeting and a single Conditional Access policy. (Internal authoring guidance — not
printed verbatim in the customer deliverables.)

## What it is
For the employee who carries **two iPhones** — a personal iPhone (BYOD) and a company iPhone (COD).
One Entra account signs in on **both**, with **single sign-on**; the corporate iPhone gets supervised
full MDM (compliance + configuration) via Apple Business Manager + ADE, the personal iPhone gets App
Protection (MAM) for corporate data without device takeover. Ownership-based **device filters** route
the right policy to each iPhone, and one **Conditional Access** policy grants access from a compliant
corporate iPhone *or* an app-protected personal iPhone.

## What's included
**Documentation (Word + PDF):** Executive Summary · Solution Overview · Requirements (+ category
Global Requirements) · Implementation (7 phases) · Testing · Troubleshooting · Best Practices ·
Deliverables Summary.

**PowerShell scripts (`IOSDD-Scripts.zip`):**
- `IOSDD-Discovery.ps1` — tenant readiness (APNs, ADE, restrictions, compliance, app protection, filters, CA).
- `IOSDD-Validation.ps1` — prove one user owns both a Corporate and a Personal iPhone.
- `IOSDD-DeviceReport.ps1` — ownership inventory + users with both a corporate and personal iPhone.
- `IOSDD-Remediation.ps1` — safe ownership fixes (read-only by default).
- `IOSDD-Set-OwnershipBasedTargeting.ps1` — create the `iPhone – Corporate`/`iPhone – Personal` device filters.

**Hero image:** `IOSDD-hero.png` (1200×1200).

## Files
```
source/        executive-summary, 01-overview, 02-requirements, global-requirements, 03-implementation,
               05-testing, 06-troubleshooting, 07-best-practices, 08-deliverables-summary
scripts/       IOSDD-Discovery, IOSDD-Validation, IOSDD-DeviceReport, IOSDD-Remediation, IOSDD-Set-OwnershipBasedTargeting
listing/       bagisto-products.json, hero.json, sales-content.md
deliverables/  IOSDD-Solution.docx, IOSDD-Solution.pdf, IOSDD-Scripts.zip, IOSDD-hero.svg/.png
solution.meta.json
```

## Next
Build deliverables + hero, then `/publish-solution cod-byod-iphone-dual-device-sso`.
