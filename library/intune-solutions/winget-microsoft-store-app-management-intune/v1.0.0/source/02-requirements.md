# 2. Requirements Guide — Winget & Microsoft Store App Management with Microsoft Intune

Verify **every** requirement before deploying. Each entry:
**Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Throughout this solution we use two **worked example apps** so every rule is concrete:
- A **Microsoft Store app** the whole team needs — **Adobe Acrobat Reader** (publisher **Adobe Inc.**),
  deployed **Required**.
- A **winget long-tail app** some users want — **VLC media player** (publisher **VideoLAN**), deployed
  **Available** for self-service.

Replace these names with your own apps. Confirm each app's **exact catalog listing and package
identifier** in your tenant before you deploy — **verify against current Microsoft documentation**,
because catalog contents and identifiers change.

## 2.1 Licensing
**Description:** An Intune-bearing license (Intune Plan 1). Store and winget app management is a
built-in Intune capability.
**Why:** Intune stores the app assignment, installs via the Intune Management Extension, and reports
install/update state.
**Verify:** M365 admin center → **Billing → Licenses**; confirm an Intune plan is assigned to the
users you will target.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 Device enrollment and the Intune Management Extension (IME)
**Description:** Targeted Windows devices enrolled in Intune, with the IME present and healthy.
**Why:** Store (new) / winget-backed apps are installed by the IME on enrolled devices.
**Verify:** Intune → **Devices → All devices** lists the device; run `WINGETSTORE-Discovery.ps1` (checks
for the `Microsoft Intune Management Extension` service on-device context and lists deployed apps).
**Implement:** Enable automatic enrollment and enroll the device. The IME installs automatically once a
Store/winget or Win32 app or PowerShell script is assigned to the device.

## 2.3 The Microsoft Store app (new) type is available in your tenant
**Description:** The **Microsoft Store app (new)** app type (winget-backed) in **Apps → Windows → Add**.
**Why:** This is the type that deploys public-catalog apps without packaging; the older "Microsoft
Store app (legacy)" type is deprecated.
**Verify:** Intune → **Apps → Windows → Add → App type** dropdown lists **Microsoft Store app (new)**.
**Exact type name and its availability are verify-with-Microsoft** — the portal label and behavior
change over time.
**Implement:** No action if present. If absent or renamed, confirm the current app type name and its
prerequisites in Microsoft's current documentation for your cloud (Commercial vs Government may differ —
see §2.9).

## 2.4 Company Portal deployed (for self-service / Available apps)
**Description:** The **Company Portal** app installed on targeted Windows devices and users signed in.
**Why:** **Available** (self-service) app assignments only appear to users **inside Company Portal**;
without it there is nowhere for an on-demand install to surface.
**Verify:** On a pilot device, open **Company Portal** and confirm it launches and shows the signed-in
user's assigned apps.
**Implement:** Deploy Company Portal (itself a Microsoft Store app) to your devices, or confirm it is
delivered via your enrollment configuration. **The exact recommended delivery method is
verify-with-Microsoft** for your tenant.

## 2.5 The exact app catalog listing and package identifier
**Description:** For each app you deploy, the **exact publisher and the package/catalog identifier**
Intune resolves when you search — so you add the right app and not a look-alike.
**Why:** Public-catalog search returns multiple near-identical results; the exact publisher + identifier
is what guarantees you deploy (and later detect/report) the correct app.
**Verify:** In **Apps → Windows → Add → Microsoft Store app (new) → Search**, confirm the result's
**publisher** matches (e.g. **Adobe Inc.** for Acrobat Reader, **VideoLAN** for VLC) before selecting.
Record the identifier Intune shows.
**Implement:** If unsure which listing is authoritative, confirm the publisher and package identifier
against **current Microsoft / winget documentation** — do not guess from the display name alone.

## 2.6 Supported Windows baseline
**Description:** Windows 10/11 on a currently supported build with recent updates.
**Why:** The new Store app type and winget support depend on modern Windows components.
**Verify:** `winver` on a pilot device, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to a supported build. **The exact minimum Windows
build required for the new Store app type is verify-with-Microsoft.**

## 2.7 Winget prerequisites present on the device
**Description:** The **Windows Package Manager (winget)** components (App Installer) present on targeted
devices for winget-backed installs.
**Why:** Winget-backed Store apps and any winget-wrapped Win32 apps rely on the winget/App Installer
runtime being available in system context.
**Verify:** On a pilot device, confirm **App Installer** is present (Store → Library, or check for the
`winget` command). **Whether Intune requires you to deploy App Installer explicitly, or it is present by
default, is verify-with-Microsoft.**
**Implement:** If missing, deploy **App Installer** (a Microsoft Store app) to the fleet before relying
on winget installs. Confirm the current supported approach in Microsoft's documentation.

## 2.8 Pilot and broad user groups
**Description:** Microsoft Entra security groups for the pilot users and the broad fleet.
**Why:** Every app is piloted before fleet rollout; Available (self-service) apps target **users**, so
user groups are the natural scope.
**Verify:** Entra → **Groups**; the pilot and broad groups exist.
**Implement:** Create them per Implementation Step 1 (or run `WINGETSTORE-Set-Assignment.ps1`, which can
reference existing groups). Name them `Store & Winget Apps – Pilot – Ring 1` and
`Store & Winget Apps – Broad – Ring 2`.

## 2.9 Government cloud differences (if applicable)
**Description:** Government tenants (GCC / GCC High / DoD) can differ from Commercial for app catalog
availability, the new Store app type, and portal URLs.
**Why:** The Store/winget public catalog and the new Store app type may have different availability,
timing, or endpoints in US-sovereign clouds; a Commercial procedure can be wrong for Government.
**Verify:** Confirm the app type, catalog availability, and admin portal URL (e.g. `intune.microsoft.us`
vs `intune.microsoft.com`) for your cloud.
**Implement:** **Verify against Microsoft's US-sovereign-cloud documentation.** Do not assume the
Commercial catalog/behavior applies to GCC High / DoD.

---
## Checklist
- [ ] Intune licensing assigned to targeted users
- [ ] Devices enrolled; IME healthy — `WINGETSTORE-Discovery.ps1`
- [ ] Microsoft Store app (new) type available in the tenant *(verify-with-Microsoft)*
- [ ] Company Portal deployed for self-service apps
- [ ] Exact publisher + package identifier confirmed per app *(verify-with-Microsoft)*
- [ ] Supported Windows baseline confirmed
- [ ] Winget / App Installer prerequisites present *(verify-with-Microsoft)*
- [ ] `Store & Winget Apps – Pilot – Ring 1` and `– Broad – Ring 2` groups created
- [ ] Government-cloud differences checked (if applicable) *(verify-with-Microsoft)*
