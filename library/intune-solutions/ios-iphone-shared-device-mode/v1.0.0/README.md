# iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling — v1.0.0

| | |
|---|---|
| **Category** | Intune Solutions |
| **Solution code** | IOSSDM |
| **Version** | 1.0.0 |
| **Slug** | `ios-iphone-shared-device-mode` |
| **Commercial** | $1,995.00 (SKU `PTK-IOSSDM-COMM-001`) |
| **Non-Profit** | $1,197.00 (SKU `PTK-IOSSDM-NPO-001`, 40% off) |

**Shaping notes:** _"The solution must enable shared devices in Lock down mode, Organization accounts
used for login. Devices should be able to be enrolled via the Device Enrollment Manager accounts. The
iOS iPhone devices should be provisioned with the Cisco WebEx App for making calls."_
→ Designed as **shared, no-user-affinity iOS iPhones** enrolled via a **Device Enrollment Manager
(DEM)** account, **supervised** via ABM + ADE, **kiosk-locked** to the **Cisco Webex** app for calling,
with staff signing in via a **shared organization account**. (Internal authoring guidance — not
printed verbatim in the customer deliverables.)

## What it is
For pooled, shared iPhones (nurses' station, warehouse, front desk, loaner fleet). Each device is
enrolled with **no owner** (DEM, no user affinity), **supervised** via Apple Business Manager + ADE,
locked down with a **kiosk** profile that exposes only **Cisco Webex**, and signed into Webex with a
**shared organization account**. Assign every policy once to one shared-device group; add a phone to
the group and it inherits the whole configuration.

## What's included
**Documentation (Word + PDF):** Executive Summary · Solution Overview · Requirements (+ category
Global Requirements) · Implementation (5 phases) · Testing · Troubleshooting · Best Practices ·
Deliverables Summary.

**PowerShell scripts (`IOSSDM-Scripts.zip`):**
- `IOSSDM-Discovery.ps1` — tenant readiness (APNs, ADE, shared group, kiosk/restrictions, Webex, compliance).
- `IOSSDM-Validation.ps1` — prove a shared iPhone is DEM-enrolled, no primary user, supervised, Webex installed.
- `IOSSDM-DeviceReport.ps1` — shared-fleet inventory (enrollment, supervision, compliance, last sync).
- `IOSSDM-Remediation.ps1` — safe fixes (audit + clear a stray primary user). Read-only by default.
- `IOSSDM-Set-SharedDeviceTargeting.ps1` — create the dynamic `iOS – Shared Devices` group.

**Hero image:** `IOSSDM-hero.png` (1200×1200).

## Files
```
source/        executive-summary, 01-overview, 02-requirements, global-requirements, 03-implementation,
               05-testing, 06-troubleshooting, 07-best-practices, 08-deliverables-summary
scripts/       IOSSDM-Discovery, IOSSDM-Validation, IOSSDM-DeviceReport, IOSSDM-Remediation, IOSSDM-Set-SharedDeviceTargeting
listing/       bagisto-products.json, hero.json, sales-content.md
deliverables/  IOSSDM-Solution.docx, IOSSDM-Solution.pdf, IOSSDM-Scripts.zip, IOSSDM-hero.svg/.png
solution.meta.json
```

## Next
Build deliverables + hero, then `/publish-solution ios-iphone-shared-device-mode`.
