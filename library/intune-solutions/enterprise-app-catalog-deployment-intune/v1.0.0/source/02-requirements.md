# 2. Requirements Guide — Enterprise App Catalog Deployment in Microsoft Intune

Verify **every** requirement before deploying a catalog app. Each entry:
**Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Throughout this solution we use a **worked example** so every rule is concrete: a common Windows
application we refer to as **`Sample App`**, selected from the Enterprise App Catalog and deployed to
a fictitious tenant `contoso.com`. Replace `Sample App` with the actual catalog app you choose.
*Whether any specific application is in the catalog is defined by Microsoft — always confirm your app
is present (verify against current Microsoft documentation).*

## 2.1 Licensing
**Description:** An Intune-bearing license plan (e.g. Intune Plan 1). App deployment is a built-in
Intune capability.
**Why:** Intune stores/serves the app content, runs the IME, and reports install state; the
Enterprise App Catalog is delivered through the Intune app-management service.
**Verify:** M365 admin center → **Billing → Licenses**; Intune shows as active.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.
*Whether the Enterprise App Catalog requires any additional licensing entitlement is
Microsoft-defined — verify against current Microsoft documentation for your plan and national cloud.*

## 2.2 Device enrollment and the Intune Management Extension (IME)
**Description:** Targeted Windows devices enrolled in Intune, with the IME present and healthy.
**Why:** Catalog (Win32) apps are installed only by the IME on enrolled Windows devices.
**Verify:** Intune → **Devices → All devices** lists the device; run `ENTAPPCAT-Test-Install.ps1` on a
device (it checks for the `Microsoft Intune Management Extension` service).
**Implement:** Enable automatic enrollment and enroll the device. The IME installs automatically once
a Win32/catalog app or PowerShell script is assigned to the device.

## 2.3 The app is present in the Enterprise App Catalog
**Description:** The application you want to deploy is a **curated, prepackaged** app in the catalog.
**Why:** Only catalog apps get Microsoft's prebuilt package + detection + update management. If the
app is not in the catalog, you must use hand-packaged Win32 or the winget/Store lane instead.
**Verify:** Intune → **Apps → Add** → app type **Enterprise App Catalog app** → **search/browse** for
`Sample App` (exact menu labels *verify against current Microsoft documentation*). Confirm it appears.
**Implement:** If the app is absent, choose another lane: package it as a Win32 `.intunewin`, or use
the **"Winget & Microsoft Store App Management with Microsoft Intune"** product for the winget/Store
route. Do **not** assume an app is in the catalog — the catalog's contents change over time.

## 2.4 Install context decision (system vs user)
**Description:** Whether the app installs per-device (**system** context) or per-user (**user**
context). The catalog package exposes the supported install behavior.
**Why:** Most line-of-business apps install in **system** context; the wrong context causes
per-user reporting confusion or install failures.
**Verify:** Review the install-behavior setting the catalog package presents when you add `Sample
App` (the available options are Microsoft-defined per app — *verify against current documentation*).
**Implement:** Choose **System** unless the app must be per-user. Record the choice — you reuse it in
testing.

## 2.5 Update management understood and decided
**Description:** A decision on whether to enable **update management** for the catalog app, and an
understanding of how updates are applied.
**Why:** Update management is the catalog's headline benefit (apps stay current without re-wrapping),
but the **cadence, version control, and exact behavior are Microsoft-defined** and must be understood
before you rely on them.
**Verify:** Review the update-management option presented when configuring `Sample App` (the toggle
name and behavior *verify against current Microsoft documentation*).
**Implement:** Decide to enable update management (recommended for staying current) or pin a version;
document the choice. Do **not** promise a specific update SLA the service does not guarantee.

## 2.6 Pilot and broad ring groups
**Description:** Two Microsoft Entra security groups to ring the rollout — a small pilot and the broad
fleet.
**Why:** Every deployment is piloted before fleet rollout so a bad rollout is caught early.
**Verify:** Entra → **Groups**; the two groups exist (or run `ENTAPPCAT-Set-Assignment.ps1`, which can
create them — default `-WhatIf`).
**Implement:** Create `Catalog Apps – Pilot Devices – Ring 1` (a few representative devices) and
`Catalog Apps – Broad Devices – Ring 2` (the rest of the fleet). Reuse these exact names everywhere.

## 2.7 Network access and content delivery
**Description:** Outbound HTTPS from targeted devices to the Intune app-content / CDN endpoints.
**Why:** The IME downloads catalog-app content and update content from Microsoft's delivery endpoints.
**Verify:** From a device, confirm access to Microsoft's published Intune/Win32 content-delivery
endpoints (the exact URL & IP ranges are Microsoft-published — *verify against the current Microsoft
list*).
**Implement:** Allow Microsoft's published Intune / Delivery Optimization / CDN URL & IP ranges
through proxy/firewall. Consider **Delivery Optimization** for large fleets to reduce WAN load.

## 2.8 National cloud / Government tenant differences (if applicable)
**Description:** Whether your tenant is Commercial or a US-sovereign cloud (GCC / GCC High / DoD),
which can change portal URLs and feature availability.
**Why:** Admin portal URLs (e.g. `endpoint.microsoft.us`), Enterprise App Catalog availability, and
update-management behavior **may differ or lag** in Government clouds.
**Verify:** Confirm your cloud and portal (Commercial `intune.microsoft.com` vs Government
`endpoint.microsoft.us`), and confirm catalog availability there.
**Implement:** Use the correct portal for your cloud; *verify Enterprise App Catalog availability and
behavior in GCC High / DoD against current Microsoft documentation* before relying on it.

---
## Checklist
- [ ] Intune licensing assigned (catalog entitlement verified with Microsoft)
- [ ] Devices enrolled; IME healthy — `ENTAPPCAT-Test-Install.ps1`
- [ ] `Sample App` confirmed present in the Enterprise App Catalog
- [ ] Install context decided (System vs User)
- [ ] Update-management decision made (behavior verified with Microsoft)
- [ ] `Catalog Apps – Pilot Devices – Ring 1` and `Catalog Apps – Broad Devices – Ring 2` created
- [ ] Network / content-delivery endpoints reachable
- [ ] National-cloud (Government) differences checked if applicable
