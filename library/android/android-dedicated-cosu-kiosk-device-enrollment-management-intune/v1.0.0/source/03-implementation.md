# 3. Implementation Guide — Android Dedicated (COSU) / Kiosk Device Enrollment & Management

Follow these steps **in order**. The **Intune admin center** and **Microsoft Graph** steps are given
click-by-click / cmdlet-exact. **OEM** specifics (Samsung Knox, Zebra) and the **zero-touch reseller
portal** are named and deferred to the vendor's documentation. The **managed Google Play binding**
(category G2) is assumed already in place (Requirement 2.1).

Consoles used:
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Managed Google Play** (approve apps) — reached from inside Intune's Android app surface
- **Android zero-touch portal / OEM consoles** — deferred to Google/reseller/OEM docs

> **Model:** Configure the enrollment profile, kiosk, restrictions, and app assignments; **pilot-enroll
> a few devices**; validate the locked-down experience; then expand in waves.
> **Assess → Design → Configure → Pilot → Validate → Expand.**

> **Artifact names (use verbatim):** enrollment profile `Android Dedicated - COSU - Pilot`; kiosk /
> device-restrictions profile `Android Dedicated - Kiosk - Pilot`; dedicated device group
> `Android Dedicated - Devices - Pilot` (dynamic, keyed on the enrollment profile name); enrollment
> restriction `Android Dedicated - Enrollment Restriction - Pilot`.

> **Risk + rollback (read first):** Dedicated enrollment makes a device a **device owner with no user**
> — reversing the **enrollment model** requires a **factory reset and re-enrollment**. Kiosk and
> restriction changes flow to enrolled devices; **whether a specific change forces re-enrollment or a
> reboot is version-dependent — verify against current Microsoft guidance / your tenant.** **Rollback:**
> to stop new enrollments, **delete/expire the enrollment profile token**; to relax the lockdown on
> already-enrolled devices, **unassign** `Android Dedicated - Kiosk - Pilot` from the device group
> (policy reverts on next check-in); a device already provisioned as dedicated returns to normal only by
> **wipe/retire + factory reset**. Always pilot on a **few** devices before the fleet.

---

## Phase 1 — Prepare scope and enrollment restrictions

### Step 1 — Confirm/scope the enrollment restriction (allow corporate-owned dedicated Android)
1. Intune → **Devices → Enrollment → Enrollment restrictions → Device platform restrictions**.
2. Confirm **Android Enterprise (corporate-owned)** enrollment is **Allowed** for the operators/scope
   doing the pilot. If a default blocks it, **Create restriction** named
   `Android Dedicated - Enrollment Restriction - Pilot` allowing corporate-owned Android, and assign it
   to a scope for the pilot.
3. Run **`COSU-Discovery.ps1`** — it flags a blocking default before you waste a device.

### Step 2 — Create the dedicated enrollment profile
1. Intune → **Devices → Android → Enrollment → Corporate-owned dedicated devices → Create profile**.
2. **Name** `Android Dedicated - COSU - Pilot`; add a description. Choose **token type** =
   **Corporate-owned dedicated device** (the default dedicated token; if your tenant offers
   **dedicated with Microsoft Entra shared mode**, that is a distinct option — use plain dedicated for
   this pilot unless you specifically need shared-mode sign-in).
3. Set a sensible **token expiration** (e.g. 90 days) and **Create**.
4. Open the profile → **Token** to view the **enrollment token string**, the **QR code**, and the
   **expiry**. This one profile feeds **all** enrollment methods (QR / afw#setup / NFC / zero-touch).

> Prefer automation? **`COSU-Set-Configuration.ps1`** creates the enrollment profile (and the kiosk
> profile below) via Graph — default `-WhatIf`; add `-Apply`.

### Step 3 — Create the dedicated device group (dynamic, keyed on the profile)
1. Entra → **Groups → New group → Security**, **Membership type = Dynamic Device**; name it
   `Android Dedicated - Devices - Pilot`.
2. **Dynamic rule:** `(device.enrollmentProfileName -eq "Android Dedicated - COSU - Pilot")`. **Create.**
3. Every device enrolled with the profile is captured automatically — this is how user-less devices are
   targeted. (Automate with **`COSU-Set-ScopeTargeting.ps1`**, default `-WhatIf`.)

---

## Phase 2 — Apps and the kiosk

### Step 4 — Approve and assign the kiosk app(s) to the device group (Required)
1. Intune → **Apps → Android → Add → Managed Google Play app**; open the managed Google Play surface,
   **approve** each app the kiosk will run, then **Sync**.
2. For each app → **Assignments → Required → Add group** = `Android Dedicated - Devices - Pilot`.
   Because the device has no user, **Required-to-device** is what installs the app.
3. **Multi-app kiosk only:** also add and assign Microsoft's **Managed Home Screen** app
   (`com.microsoft.launcher.enterprise`) as **Required** to the same group — it is the locked launcher.
4. Run **`COSU-Discovery.ps1`** to confirm the apps are present, and note the exact **package names**
   (you will list them in the kiosk).

### Step 5 — Build the kiosk / device-restrictions profile
1. Intune → **Devices → Android → Configuration → Create → New policy** → Platform
   **Android Enterprise**, Profile type **Device restrictions** (under **Fully Managed, Dedicated, and
   Corporate-Owned Work Profile**). **Name** `Android Dedicated - Kiosk - Pilot`.
2. Expand **Device experience** (or **Kiosk**, depending on the current portal) and set **Enrollment
   profile type = Dedicated device**, then choose the kiosk mode:
   - **Single-app kiosk:** **Kiosk mode = Single app**, and select the **one** app (by package name)
     the device locks to. It launches on boot; the user cannot leave it.
   - **Multi-app kiosk:** **Kiosk mode = Multi-app**, **add** each allowed app (package names from Step 4)
     to the app list, and set the launcher options — grid size, whether to **lock the home button**, allow
     **Wi-Fi / Bluetooth / volume / flashlight** toggles, a **session PIN / exit**, and **screen saver**.
     Multi-app uses the **Managed Home Screen** launcher deployed in Step 4.
3. Set the **device restrictions** that harden the kiosk (as appropriate): block adding accounts, block
   factory reset by user, block safe boot, block USB file transfer, control system update behavior,
   set the allowed **input methods**, etc. Keep it minimal for the pilot and tighten later.
4. **Assignments** → **Add group** = `Android Dedicated - Devices - Pilot`. **Create.**

> The kiosk **allow-list must reference apps that are assigned to the device group** (Step 4). An app
> named here but not assigned will **not appear**. **`COSU-Validation.ps1`** cross-checks this.

### Step 6 — (Optional) OEM hardening at the pattern level
1. For **Zebra / Samsung** rugged devices, deliver OEM settings via an **OEMConfig** app (approved in
   managed Google Play) assigned to the device group — barcode-scanner profiles, key remaps, firmware
   update control, etc.
2. Add the OEMConfig app as **Required** to `Android Dedicated - Devices - Pilot` and configure its
   **App configuration policy**. The exact schema is the **OEM's** — deferred to the vendor's docs.

---

## Phase 3 — Enroll the pilot devices

### Step 7 — Enroll by your chosen method (factory-reset device required)
Pick the method that fits the fleet; all land on `Android Dedicated - COSU - Pilot`.
1. **QR code:** on the factory-reset **Welcome** screen, **tap the screen ~6 times** to start the QR
   reader (connect Wi-Fi if prompted), then **scan** the profile's QR code. Provisioning downloads the
   DPC and enrolls the device as dedicated.
2. **Token (afw#setup):** proceed to the Google sign-in prompt and enter **`afw#setup`**, then supply
   the **enrollment token string** when asked.
3. **NFC:** run an NFC-provisioning app on a "programmer" device carrying the token and **bump** the
   factory-reset device (the NFC payload/tooling is deferred to the OEM).
4. **Zero-touch:** a device purchased through a **zero-touch reseller** and assigned your configuration
   in the **zero-touch portal** enrolls automatically on first boot — no scanning. (Portal/reseller
   steps deferred to Google/reseller docs.)
5. Let the device finish provisioning; it should land on the **kiosk** (single app, or the Managed Home
   Screen with the allowed apps).

### Step 8 — Confirm the device landed in scope
1. Intune → **Devices → Android → Corporate-owned dedicated devices** (or **All devices**) shows the
   new device; it should be **no user / device owner**.
2. Confirm the device joined `Android Dedicated - Devices - Pilot` (dynamic membership can take a few
   minutes) so kiosk + apps deploy. Run **`COSU-Report.ps1`** to see it in inventory.

---

## Phase 4 — Validate and expand

### Step 9 — Validate the locked-down experience (pilot gate)
1. On the device, confirm: it **boots to the kiosk**; **only the allowed app(s)** are reachable;
   settings/other apps are blocked; and it is **remotely manageable** (try **Sync** and a benign device
   action from Intune).
2. Run **`COSU-Discovery.ps1`** (readiness), **`COSU-Validation.ps1`** (kiosk allow-list vs assigned
   apps; only-allowed-apps report), and **`COSU-Report.ps1`** (fleet health). Complete the **Testing
   Guide** pilot gate before expanding.

### Step 10 — Expand to production in waves
1. Create the production twins: enrollment profile `Android Dedicated - COSU - Prod`, kiosk
   `Android Dedicated - Kiosk - Prod`, and device group `Android Dedicated - Devices - Prod` (dynamic
   rule on the **prod** profile name) — or widen the pilot artifacts, per your change process.
2. Enroll production devices in **waves** by the chosen method; assign the same apps + kiosk to the prod
   device group.
3. Re-run **`COSU-Validation.ps1`** and **`COSU-Report.ps1`** after each wave; validate before widening.
4. **Zero-touch at scale:** have the reseller assign the prod configuration to purchased devices so new
   stock enrolls on first boot.

---
### Order of operations
`Enrollment restriction → dedicated enrollment profile → dynamic device group → approve + assign apps
(Required-to-device) → kiosk / device-restrictions profile (single or multi-app) → (OEM config) →
enroll pilot (QR/token/NFC/zero-touch) → confirm in scope → validate locked-down → expand in waves`
