# Executive Summary — Android Dedicated (COSU) / Kiosk Device Enrollment & Management (Microsoft Intune)

Frontline, warehouse, retail, logistics, and clinical devices exist to do **one job** — scan, sign,
display, capture — and nothing else. Left as ordinary tablets they wander into personal use, get set up
inconsistently, and are hard to lock down and scale. The fix is Android Enterprise's **dedicated
(COSU)** model in **Microsoft Intune**: company-owned, user-less devices that **boot straight into a
kiosk** and stay locked to their allowed app(s).

This solution stands that up end to end: the **dedicated enrollment profile**, enrollment by **token /
QR / NFC / zero-touch**, the **kiosk** (single-app or multi-app), **device restrictions**, **managed
Google Play** app delivery to devices that have no signed-in user, and **remote management** — all
validated on a pilot before you scale. It is a complete, **deploy-it-today** package written for an
administrator with no prior dedicated-device experience.

## What you get
- A plain-language **Solution Overview** of the dedicated/COSU model, the four enrollment methods
  (token/QR/NFC/zero-touch), single- vs multi-app kiosk, and how apps reach a user-less device.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (the category
  Android requirements — Intune tenant, managed Google Play binding, roles, network, pilot — are
  referenced, not repeated).
- An **Implementation Guide** of precise, ordered **Intune admin center + Microsoft Graph** steps:
  enrollment profile, dynamic device group, app assignment, the kiosk profile, enrollment, and
  validation — pilot-first, each artifact named, with pass/fail gates and rollback.
- Five **PowerShell scripts** for readiness discovery, safe configuration (`-WhatIf`), the
  only-allowed-apps kiosk validation, fleet health/inventory reporting, and scope targeting.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
Purpose-built Android devices **enrolled at scale** by the method that fits the fleet, **locked to their
app(s)** by single- or multi-app kiosk, **fed managed Google Play apps** to the device with no user,
and **remotely managed** — consistent and tamper-resistant. OEM/rugged devices (Zebra, Samsung) are
supported at the pattern level via OEMConfig.

## The deployment model
**Assess → Design → Configure → Pilot → Validate → Expand** — build the profile and kiosk, prove them on
a handful of devices, then roll out in waves.

## An honest note
Dedicated is for **corporate-owned, single-purpose** devices only; reversing the enrollment model
requires a factory reset. The **AMAPI transition and whether a change forces re-enrollment are actively
evolving** — where behavior is version-dependent, this package flags **"verify against current Microsoft
guidance / your tenant"** rather than asserting it.

## Outcome
A fleet of Android dedicated (COSU) devices that boot straight to the job, enrolled consistently, locked
to their apps, and remotely managed — validated before you scale.
