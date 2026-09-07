# Implementation

Work the phases in order. Phase 1 inventories Jamf and confirms Intune/ABM/VPP readiness; Phase 2
builds the Intune target; Phase 3 pilots a small wave across all three platforms; Phase 4 runs
production waves; Phase 5 decommissions Jamf. Every object is named — reuse the names verbatim in
later phases, testing, and the scripts.

Paths use `intune.microsoft.com`; for **GCC High / DoD** use `intune.microsoft.us` — the steps are
otherwise identical.

---

## Phase 1 — Assess: inventory Jamf and confirm readiness

### Step 1.1 — Export the Jamf inventory and build the mapping worksheet
1. Run **`JAMFMIG-Export-JamfInventory.ps1`** (Jamf Pro API). It exports computers, mobile devices,
   **PreStage enrollments**, configuration profiles, smart groups, and scoped apps to a CSV.
2. In the CSV, map each Jamf item to its Intune equivalent (profile → Intune Settings Catalog policy,
   smart group → Entra group, policy/package → Intune app or script). This worksheet drives Phase 2.

### Step 1.2 — Confirm Intune Apple enrollment readiness
1. Run **`JAMFMIG-Get-IntuneReadiness.ps1`**. Confirm the **Apple MDM push certificate** is valid and
   not near expiry, at least one **ADE (enrollment program) token** is present, and the **VPP (Apps
   and Books) token** is connected.
2. Fix any gap before continuing (a lapsed push cert would unenroll the whole Apple fleet).

### Step 1.3 — See where devices are assigned in ABM
1. Run **`JAMFMIG-Get-ABMAssignments.ps1`** to report which serials are assigned to the Intune ADE
   token versus still assigned elsewhere (Jamf).
2. In **business.apple.com → Devices**, confirm you can filter by MDM server and select devices to
   re-assign.

### Step 1.4 — Create the wave and platform groups
1. In **Entra admin center → Groups → New group**, create `PILOT – Jamf Migration – Wave1`,
   `MIG – macOS – Corp`, `MIG – iPadOS – Shared`, and `MIG – iOS – Users`.

---

## Phase 2 — Build the Intune target (per platform)

### Step 2.1 — Create the ADE enrollment profiles
1. **Intune admin center → Devices → Enrollment → Apple → Enrollment program tokens →** open your
   token **→ Profiles → Create profile → macOS**. **Name:** `ADE – macOS – Corp`. Set Setup Assistant
   options, and (for supervised) supervision + locked enrollment. **Save.**
2. Repeat **→ Create profile → iOS/iPadOS**: create `ADE – iPadOS – Shared` and `ADE – iOS – Users`
   with the appropriate Setup Assistant, supervision, and (for shared iPad) Shared iPad options.

### Step 2.2 — Rebuild configuration and compliance from the mapping worksheet
1. **Devices → Configuration → Create** the profiles that replace the Jamf configuration profiles —
   e.g. `Config – macOS – Restrictions`, `Config – iOS – Restrictions`, Wi-Fi, per-app VPN, web clips,
   home-screen layout, and (iOS shared/kiosk) Autonomous Single App Mode — assigned to the platform
   groups.
2. **Devices → Compliance policies → Create** the compliance policies per platform, assigned to the
   platform groups.

### Step 2.3 — macOS specifics
1. **Disk encryption:** create a **FileVault** disk-encryption policy (`Config – macOS – FileVault`) so
   the recovery key is **escrowed to Intune** (the Jamf-escrowed key does not transfer).
2. **SSO:** deploy **Platform SSO** (macOS 13+) or the **Enterprise SSO app extension**
   (`Config – macOS – SSO`) to replace Jamf Connect.
3. **Apps:** add App Store apps via **VPP**, and packaged apps as **Intune macOS apps** (unmanaged
   PKG/DMG) or **shell scripts**, per the mapping worksheet.
4. **Defender:** re-onboard **Microsoft Defender for Endpoint for macOS** if in use.

### Step 2.4 — iOS/iPadOS specifics
1. **Certificates:** deploy **SCEP/PKCS** certificate profiles via the Intune connectors to replace
   Jamf-issued certs.
2. **Apps:** re-add the VPP apps and any store apps, assigned to the platform groups.
3. **Restrictions / Wi-Fi / per-app VPN / kiosk:** created in Step 2.2.

### Step 2.5 — Connect and reconcile VPP
1. Ensure the **VPP (Apps and Books) token** is connected in Intune (Step 1.2). Plan to **revoke** the
   app licenses in Jamf as each wave migrates so Intune can re-assign them (one license per device per
   app).

---

## Phase 3 — Pilot wave (a few macOS + iPad + iPhone)

### Step 3.1 — Supervised / ADE devices (wipe-and-enroll)
1. In **business.apple.com → Devices**, select the pilot **supervised** devices and **re-assign** them
   to the **Intune** MDM server (the ADE token).
2. In Intune, ensure those devices' ADE profile assignment resolves to `ADE – macOS – Corp` /
   `ADE – iPadOS – Shared` / `ADE – iOS – Users` (assign the profile to the device group).
3. **Erase** each device (**Erase All Content and Settings**) — locally, or push a **Wipe** from Jamf
   before removing it. On reboot, **Setup Assistant** shows **Remote Management** and the device
   **auto-enrolls into Intune** with the ADE profile.
4. Confirm the device appears in **Intune → Devices** managed and receives its profiles/apps.

### Step 3.2 — BYOD / user-enrolled devices (no wipe)
1. **Unenroll from Jamf** (remove the MDM/enrollment profile — via Jamf, or Settings → General → VPN &
   Device Management → remove the management profile).
2. **Re-enroll into Intune** via the **Company Portal** (device enrollment) or **account-driven user
   enrollment** (BYOD). No wipe.

### Step 3.3 — Validate the pilot
1. Run **`JAMFMIG-Validate-Migration.ps1`**: the pilot devices show enrolled in Intune by platform,
   compliant, with primary apps installed.
2. Verify per platform: macOS FileVault key **escrowed to Intune**, SSO works; iOS/iPad apps (VPP),
   Wi-Fi, per-app VPN, and certificates all present; the device no longer checks in to Jamf.
3. Run **`JAMFMIG-Track-Waves.ps1`** to confirm the pilot devices show **migrated**.

---

## Phase 4 — Production waves

1. Move each wave group (`MIG – macOS – Corp`, `MIG – iPadOS – Shared`, `MIG – iOS – Users`, sub-scoped
   by ring) through the same re-assign → wipe/re-enroll → validate flow.
2. For each wave: ABM re-assign the supervised devices, schedule the wipe window, unenroll/re-enroll
   the BYOD devices, **revoke the VPP licenses in Jamf**, and re-validate with
   `JAMFMIG-Validate-Migration.ps1` and `JAMFMIG-Track-Waves.ps1`.
3. Keep Jamf running for all **un-migrated** devices until their wave completes.

---

## Phase 5 — Decommission Jamf

1. When `JAMFMIG-Track-Waves.ps1` shows **zero pending** devices and all are validated in Intune,
   remove the Jamf configuration profiles and PreStage enrollments, and **remove the Jamf MDM server
   assignment** from ABM (set the default MDM server to Intune).
2. Cancel Jamf licensing per your contract. Keep the final inventory export and validation reports as
   the migration record.

---

## Rollback (per wave, before sign-off)

- **BYOD:** unenroll from Intune and re-enroll into Jamf.
- **Supervised:** re-assign the device to the **Jamf** MDM server in ABM and **erase** again to
  re-enroll into Jamf (supervised rollback requires another wipe — which is why each wave is validated
  before the next begins).
