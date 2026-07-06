# 3. Implementation — macOS App Deployment & Apple VPP with Microsoft Intune

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against
the **`PILOT – macOS App Deployment`** group first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and
Apple Business Manager at `https://business.apple.com` unless noted.

---

## Phase 1 — Acquire licenses and connect VPP to Intune

### Step 1. Acquire the app licenses in Apple Business Manager
1. In ABM, go to **Apps** (older tenants: **Content → Apps**).
2. Search the App Store app you want to deploy (e.g. a reader or productivity app).
3. Select your **location** — this solution uses **Location A**.
4. Set a **quantity** (paid apps) — free apps are effectively unlimited but must still be acquired.
5. Click **Get**. The app now shows a license count under Location A. Repeat for each app.

> Acquire **every** app you intend to deploy under the **same location** so a single token covers them.

### Step 2. Download the location's VPP token
1. In ABM, open **Preferences (your name, bottom-left) → Payments and Billings** (or the location's
   **Apps** area).
2. Under the location, **Download** the **VPP server token** — a `.vpptoken` file. **Record the
   managed Apple ID** shown as the token owner (you reuse it at every renewal — Requirements R4).

### Step 3. Connect the VPP token in Intune
1. In Intune, go to **Tenant administration → Connectors and tokens → Apple VPP tokens** (or
   **Apps → macOS → …** VPP area).
2. Click **Create / Add**.
3. **Basics:** enter the **Apple ID** (the managed Apple ID that owns the token) and **Browse** to the
   `.vpptoken`.
4. **Settings:** name it **`VPP – Corporate (Location A)`**; set the **country/region** to match the
   location; choose the **default license type** to reflect this solution's default — **device**.
   Accept the terms.
5. **Review + Create.** The token appears as **Active/Valid** with a future expiration.

### Step 4. Sync licenses from Apple
1. On the token **`VPP – Corporate (Location A)`**, click **Sync**.
2. Wait for the sync to complete (Apple rate-limits syncs; allow a few minutes).
3. Confirm the acquired apps now appear in Intune → **Apps → macOS** as available App Store apps with
   license counts.

> Prefer to confirm from the command line? Run **`MACVPP-Discovery.ps1`** — it reports the token
> status/expiry and synced app/license counts.

---

## Phase 2 — Add and assign the App Store (VPP) app

### Step 5. Add the App Store (VPP) app to Intune
1. Go to **Apps → macOS → Add**.
2. **App type:** choose **macOS app (App Store)** (the VPP-licensed store app type). Click **Select**.
3. **Search** the App Store and pick the app you acquired in Step 1 (or select it from the synced
   list). Confirm the correct **bundle ID** and publisher.
4. Complete **App information** (name, publisher, category, logo as desired) → **Next**.

### Step 6. Assign the store app to the pilot — device-licensed
1. On the app's **Assignments** tab, under **Required**, click **Add group**.
2. Choose **`PILOT – macOS App Deployment`**.
3. Set **License type = Device** (this solution's default — silent, no Apple ID needed).
4. Leave uninstall-on-unassign per your policy → **Review + Save**.

> Use **Available** (instead of Required) if you want the app to appear in Company Portal for
> on-demand install; keep **Required** for hands-off delivery. For **user** licensing, set
> **License type = User** and ensure users have accepted VPP terms (Requirements R8).

---

## Phase 3 — Add and assign an enterprise (LOB) app

### Step 7. Add the enterprise app (signed `.pkg`)
1. Go to **Apps → macOS → Add**.
2. **App type:** choose **macOS line-of-business (LOB) app** for a signed `.pkg` (or **macOS app
   (DMG)** for a signed `.dmg`). Click **Select**.
3. **Upload** the signed package (Requirements R7). For a `.pkg`, provide the app's **bundle ID** and
   **build/version** and any **child/included app bundle IDs** Intune prompts for (used to detect
   install). → **Next**.
4. Complete **App information** → **Next**.

> Can't produce a managed `.pkg`? Use **macOS app (PKG) — unmanaged** instead: install-once, no
> license tracking, no managed uninstall. Prefer the managed types when possible.

### Step 8. Assign the enterprise app to the pilot
1. On the app's **Assignments** tab, under **Required**, click **Add group**.
2. Choose **`PILOT – macOS App Deployment`** → **Review + Save**.

> LOB/DMG/PKG apps are **not** VPP-licensed, so there is no license type to choose — assignment is
> group-based only.

---

## Phase 4 — Pilot, validate, expand

### Step 9. Trigger and observe install on a pilot Mac
1. On a pilot Mac (a member of `PILOT – macOS App Deployment`), open **Company Portal** or
   **System Settings → General → Device Management** and **Sync**, or wait for the next check-in.
2. Confirm the **App Store (VPP)** app installs **silently** (device licensing needs no Apple ID) and
   the **enterprise `.pkg`** installs to `/Applications`.

### Step 10. Validate installation and licensing
1. Run **`MACVPP-Validation.ps1 -Serial <serial>`** (or `-DeviceName`): confirm the device is
   **managed macOS**, the **VPP app is installed and licensed to the device**, and the **LOB app is
   installed**, with a clear PASS/FAIL verdict.
2. In Intune, cross-check **Apps → (the app) → Device install status** = **Installed**, and
   **Apps → (the VPP app) → (VPP licenses)** shows a license **consumed** for the device.

### Step 11. Confirm license consumption and headroom
1. Run **`MACVPP-Report.ps1`** for a tenant-wide view: per-app **total vs. consumed** VPP licenses,
   install counts, and any app **out of licenses**.
2. Confirm enough license headroom before widening (acquire more in ABM if needed, then **Sync**).

### Step 12. Expand in waves
1. Once the pilot passes, broaden targeting: add production groups to the app **Required** assignments
   (or retarget the pilot group to your wave/all-devices group) using
   **`MACVPP-Set-ScopeTargeting.ps1`** (defaults to **-WhatIf** — preview first, then apply).
2. Keep **device** licensing as the default; monitor consumption with `MACVPP-Report.ps1` each wave.
3. Roll out in waves, validating each wave with `MACVPP-Validation.ps1` before widening.

---

## Ongoing — token renewal (do not skip)
The **VPP token expires annually**. A lapsed token **stops license sync and new installs**. Before
expiry: in ABM download a **fresh** `.vpptoken` for **Location A** (same managed Apple ID), then in
Intune open **`VPP – Corporate (Location A)` → Renew** and upload it. Run `MACVPP-Discovery.ps1`
regularly — it flags the token when it is within 30 days of expiry.
