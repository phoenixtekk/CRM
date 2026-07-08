# 1. Solution Overview — Android Enterprise App Management via Managed Google Play (Intune)

## What this solution is
On **Android Enterprise**, all apps are delivered through **managed Google Play** — there is no
sideloading in the managed profile, and the Google Play Store app in a work profile / fully managed
device shows only the apps IT has **approved**. This solution covers doing that well in **Microsoft
Intune**: choosing the right **app type**, applying **managed configuration**, adding **app
protection**, controlling the **update track**, and **assigning** each app to the right devices by
enrollment model and group.

## App types on managed Google Play
- **Store apps (managed Google Play store apps)** — public apps (e.g. Outlook, Chrome) approved from
  the managed Google Play iframe inside Intune and synced back as `androidManagedStoreApp` objects.
- **Private / line-of-business (LOB) apps** — your own `.apk` published privately to your organization
  through the managed Google Play **Publishing / Custom app** flow, so only your tenant sees them.
- **Web apps (web links)** — a URL packaged by managed Google Play into an installable web-app icon.
- **OEMConfig apps** — a vendor's OEMConfig app (Samsung Knox Service Plugin, Zebra OEMConfig, etc.)
  is a *store app* that carries a **managed configuration schema** to drive OEM-specific settings
  (integrated at the **pattern level** — the schema and keys come from the OEM's documentation).

## The four levers this solution manages
1. **Approval + assignment** — approve the app in managed Google Play; assign it in Intune with an
   **intent** (**Required**, **Available for enrolled devices**, **Available with/without enrollment**,
   or **Uninstall**) to a **group**, scoped by **enrollment model**.
2. **Managed app configuration (app config policies)** — push app settings/keys (managed
   configurations) to the app so it arrives pre-configured (accounts, servers, feature flags, OEM keys)
   with no user setup.
3. **App protection policies (APP / MAM)** — data-protection controls (encryption, copy/paste and
   save-as restrictions, PIN, conditional launch) applied to the app's corporate data. On enrolled
   devices these complement device policy; on unenrolled devices they are the primary control (MAM-only).
4. **Update-track control** — choose which **release track** (Production, Beta, or a custom closed
   track you publish to) and **auto-update mode** an app follows via its assignment settings.

## How assignment intent maps to enrollment model
- **Work profile (BYOD)** — apps land in the **work profile**; **Available** intents let users pull
  apps from the work Play Store; **app protection** matters most here (personal side is untouched).
- **Fully managed / corporate-owned work profile** — **Required** apps are pushed silently; the whole
  device (or work profile) is corporate.
- **Dedicated / COSU (kiosk)** — apps are **Required** and surfaced through the kiosk/managed home
  screen; user-initiated installs are typically disabled.

> **Managed configuration and update tracks are set in the app's *assignment*.** The same app can be
> assigned to different groups with **different managed configs and different tracks** — that is how you
> pilot a Beta track to a test group while Production stays on the stable track.

## Automation included
Five **PowerShell (Microsoft Graph)** tools — **read-only or `-WhatIf` by default** — inventory the
managed Google Play apps and their assignment posture, stage app assignment + managed configuration,
stage an Android app protection policy, validate that delivery/config is in place, and check the
managed Google Play binding and scope health. No credentials or secrets are stored in the scripts.

## Limitations (be honest with buyers)
- Managed Google Play publishing (private LOB apps, custom web apps, closed test tracks) happens in the
  **managed Google Play / Google Play Console** surfaces — Intune approves and assigns, but the app is
  published on the Google side first. Those consoles evolve; steps are flagged where they may drift.
- The **assignment `assign` action replaces *all* of an app's assignments** — partial edits must
  re-send the full set. The scripts read current state and gate writes behind `-Commit` to prevent
  accidental clobbering.
- Whether adding an account, changing the connector, or the **AMAPI** transition triggers
  **re-enrollment** is version-dependent — **verify against current Microsoft guidance / your tenant**.
- OEM (Samsung Knox, Zebra) and third-party app specifics are handled at the **pattern level**; the
  authoritative schema/keys live in the vendor's documentation.

## The standard deployment model
> **Assess → Design → Configure → Pilot → Validate → Expand** — approve and assign to a **pilot group**
> first, prove delivery + config + protection + track, then expand in waves with pass/fail gates and a
> documented rollback (unassign / revert config) for every production change.
