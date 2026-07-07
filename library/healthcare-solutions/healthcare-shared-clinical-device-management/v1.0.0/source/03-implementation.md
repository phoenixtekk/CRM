# 3. Implementation Guide — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

Follow these steps **in order**, primarily in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) with two steps in the **Microsoft Entra admin center**
(`https://entra.microsoft.com`). Every object is **named** and the name is reused **verbatim** in
later steps and in the testing/troubleshooting guides. Do not skip the prerequisite checks in
`02-requirements.md` and `global-requirements-healthcare-solutions.md`.

> **Model:** Register shared devices to Autopilot → provision unattended with a **self-deploying**
> profile → put them in **Shared PC mode** → **kiosk-lock** the single-purpose ones → push a
> **Required clinical app baseline** → keep WOWs **awake on battery** → pilot, validate, expand.
> Phase model: **Assess → Enroll/Provision → Standardize → Lock-down → Pilot → Validate → Expand.**

## Named objects (created in this guide)
- Entra dynamic group: **`Clinical – Shared Devices`** (whole shared fleet)
- Entra pilot group: **`Clinical – Shared Devices – Pilot`**
- Autopilot deployment profile: **`Clinical Shared – Self-Deploying – Provision`**
- Enrollment Status Page: **`Clinical Shared – ESP – Provision`**
- Shared PC config profile: **`Clinical Shared – Shared PC Mode – Standardize`**
- Power config profile: **`Clinical Shared – WOW Always-On – Standardize`**
- Kiosk config profile (single-purpose only): **`Clinical Shared – Kiosk Assigned Access – Lock-down`**
- App baseline assignment label: **`Clinical Shared – App Baseline – Standardize`**

---

## Phase 1 — Assess

## Step 1 — Inventory the current shared devices
1. Run **`CLINDEV-Discovery.ps1`** (read-only) to inventory candidate shared devices: enrollment type, current Shared PC state, group membership, and **primary user** (which on a true shared device should be **None**).
2. Record which devices are **single-purpose** (registration kiosk, wayfinding) — these get Assigned Access in Phase 4 — versus **multi-app WOWs / nurse-station PCs / tablets**, which get Shared PC mode only.
3. Confirm each device is registered to Autopilot: Intune → **Devices → Enrollment → Windows → Windows enrollment → Devices**. If a device is missing, import its hardware hash (see `02-requirements.md` R3).

---

## Phase 2 — Enroll / Provision

## Step 2 — Create the shared-fleet group (Entra)
1. In the **Microsoft Entra admin center**, go to **Identity → Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `Clinical – Shared Devices`. **Membership type:** **Dynamic Device**.
3. Click **Add dynamic query** and build a rule that matches the shared fleet — keyed on the Autopilot **group tag** / **order ID** set at registration, for example:
   `(device.devicePhysicalIds -any (_ -contains "[OrderID]:ClinicalShared"))`
   (or match enrollment profile name). Click **Save**.
4. Click **Create**. (You can also create this group, and optionally pre-stage profile/app assignments, with **`CLINDEV-Set-SharedDeviceGroup.ps1 -WhatIf`** then `-Apply`.)

> **Most reliable targeting — an Assigned group owned by the Intune Provisioning Client (enrollment-time
> device grouping).** The dynamic group tag above is convenient, but for **deterministic**
> shared-device enrollment (the **Windows Autopilot device preparation** model), make `Clinical – Shared
> Devices` an **Assigned** security group and add the **Intune Provisioning Client** first-party service
> principal — **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, in many tenants displayed as **`Intune
> Autopilot ConfidentialClient`** — as an **Owner** of the group. In Entra: **Groups → `Clinical –
> Shared Devices` → Owners → Add owners**, and search by that **AppId** (match by AppId, **not** the
> display name, which varies by tenant). Enrollment-time device grouping works by this principal
> *owning* the Assigned group — without the owner the group stays **empty at enrollment** and **none of
> the Shared PC / power / kiosk profiles or the clinical app baseline deploy**. The group must be
> **Assigned**, never Dynamic, for this mechanism. This is the same first-party principal and mechanism
> Windows Autopilot device preparation uses. **Verify the owner is present before each pilot.** *(If the
> principal isn't present in the tenant, open the Intune portal once as Global Administrator to
> provision it, then add it as owner.)*

## Step 3 — Create the pilot group (Entra)
1. In **Identity → Groups → All groups → New group**: Security, name `Clinical – Shared Devices – Pilot`, **Membership type:** Assigned.
2. **Members → Add members →** add the **test device(s)** (one of each type — WOW, kiosk, tablet, nurse-station PC). Click **Create**.

## Step 4 — Set the Autopilot group tag at registration
1. In the **Intune admin center**, go to **Devices → Enrollment → Windows → Windows enrollment → Devices** (Windows Autopilot devices).
2. Select the shared devices → **Edit** (or **Assign group tag**) and set the group tag used by the dynamic rule in Step 2 (e.g. `ClinicalShared`). Click **Save**.
3. Confirm each device's **Profile status** will resolve once the deployment profile (Step 5) is created.

## Step 5 — Create the Autopilot self-deploying deployment profile
1. Go to **Devices → Enrollment → Windows → Windows enrollment → Deployment Profiles → Create profile → Windows PC**.
2. **Basics:** **Name:** `Clinical Shared – Self-Deploying – Provision`. **Description:** "Unattended provisioning for shared clinical devices (WOWs, kiosks, tablets, nurse-station PCs)." **Convert all targeted devices to Autopilot** = **No** (target by group). Click **Next**.
3. **Out-of-box experience (OOBE):**
   - **Deployment mode** = **Self-Deploying (preview/GA per tenant)**. *This is the key choice — there is no user at the cart to drive setup.*
   - **Join to Microsoft Entra ID as** = **Microsoft Entra joined**.
   - **Microsoft Software License Terms** = Hide. **Privacy settings** = Hide. **Hide change account options** = Hide.
   - **User account type** = Standard. **Allow pre-provisioned deployment** = as required.
   - **Apply device name template** = **Yes** → set a clear pattern, e.g. `WOW-%SERIAL%` / `KIOSK-%SERIAL%`. Click **Next**.
4. **Assignments → Add groups →** `Clinical – Shared Devices – Pilot` (add `Clinical – Shared Devices` later, at Expand). Click **Next → Create**.

## Step 6 — Create the Enrollment Status Page (ESP)
1. Go to **Devices → Enrollment → Windows → Windows enrollment → Enrollment Status Page → Create**.
2. **Name:** `Clinical Shared – ESP – Provision`. Click **Next**.
3. **Settings:** **Show app and profile configuration progress** = **Yes**; **Block device use until all apps and profiles are installed** = **Yes** (so a clinician never picks up a half-provisioned cart); set a sensible timeout; **Block device use until these required apps are installed** = select the clinical baseline apps from Step 10. Click **Next**.
4. **Assignments → Add groups →** `Clinical – Shared Devices – Pilot`. Click **Next → Create**.

## Step 7 — Self-provision the pilot devices
1. Factory-reset (or first-boot) a pilot device on the cart/kiosk stand with network reachable (see `02-requirements.md` R9).
2. The device runs **`Clinical Shared – Self-Deploying – Provision`** with **no user interaction**: it attests via TPM 2.0, joins Microsoft Entra ID, enrolls in Intune, and shows `Clinical Shared – ESP – Provision`.
3. When the ESP completes, confirm in Intune → **Devices → Windows → All devices** that the device is **Microsoft Entra joined**, **enrolled**, and shows **Primary user = None**.

---

## Phase 3 — Standardize

## Step 8 — Create the Shared PC mode configuration profile
1. Go to **Devices → Manage devices → Configuration → Create → New policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Templates → Shared multi-user device**. Click **Create**.
   *(Equivalently, the Settings-catalog **SharedPC** category exposes the same SharedPC CSP settings.)*
3. **Basics:** **Name:** `Clinical Shared – Shared PC Mode – Standardize`. **Description:** "Windows Shared PC mode for shared clinical devices: many-user account handling + cleanup, no personal owner." Click **Next**.
4. **Configuration settings — Shared PC mode:**
   - **Shared PC mode** = **Enabled**.
   - **Account management** = **Enabled** (so cycled accounts are cleaned up automatically).
   - **Delete accounts** = **At storage space threshold and inactive threshold** (keeps the device fast across shifts).
   - **Account deletion threshold (free disk space)** = e.g. start delete at **25%**, stop at **50%**.
   - **Inactive account threshold (days)** = e.g. **30** (tune to shift rotation).
   - **Local storage** = **Not configured** (or restrict per policy).
   - **Power policies** = leave to the dedicated power profile in Step 9 (do **not** let Shared PC mode sleep a WOW).
   - **Sleep timeout / Sign in on resume** = configure so the lock screen requires sign-in but the device is not put to sleep on battery (power handled in Step 9).
   - **Maintenance start time / education policies** = set maintenance to off-shift hours.
   Click **Next**.
5. **Assignments → Add groups →** `Clinical – Shared Devices – Pilot`. Click **Next → (Applicability/Review) → Create**.

## Step 9 — Create the WOW always-on power profile
1. Go to **Devices → Manage devices → Configuration → Create → New policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Settings catalog**. Click **Create**.
3. **Basics:** **Name:** `Clinical Shared – WOW Always-On – Standardize`. **Description:** "Keep WOWs/carts awake on battery so clinicians never return to an asleep, locked cart." Click **Next**.
4. **Configuration settings → Add settings →** from the **Power** category add and set, for **both On Battery and Plugged In**:
   - **Sleep / Sleep Timeout (Plugged In and On Battery)** = **0** (never sleep).
   - **Hibernate Timeout (Plugged In and On Battery)** = **0** (never hibernate).
   - **Turn Off Display / Display Timeout** = a short value (e.g. **10 min**) is fine — the screen may dim/turn off to save battery, but the **device must not sleep**.
   - **Allow Standby States When Sleeping** / **Lid Close Action** = set so closing a tablet/laptop lid does **not** sleep a cart device (e.g. **Do nothing** on AC, and on battery if cart runtime allows).
   - **Critical/Low battery action** = a graceful behavior near depletion (e.g. notify, then hibernate only at critical) so an ePHI session is not lost abruptly.
   Click **Next**.
5. **Assignments → Add groups →** `Clinical – Shared Devices – Pilot`. Click **Next → Create**.

## Step 10 — Assign the clinical app baseline (Required)
1. For **each** clinical app in the standardized set (named exactly as published — e.g. the **Epic Hyperdrive** client packaged as a Win32 app per the dedicated Epic solution, a browser, a PDF reader, a secure-messaging client), go to **Apps → All apps →** select the app (or **Add** to package it first).
2. Open the app → **Properties → Assignments → Edit**.
3. Under **Required**, click **Add group →** `Clinical – Shared Devices – Pilot`. (Use this assignment consistently; label it `Clinical Shared – App Baseline – Standardize` in your runbook.) Click **Review + save**.
4. Repeat for every app in the baseline so the **same software installs on every device of that type**. Confirm these apps are also referenced in the ESP **required apps** list (Step 6) so provisioning blocks until they install.
5. Do **not** hand-install clinical apps on individual carts — the baseline must be Intune-delivered and reportable. For the Epic Hyperdrive client and Imprivata agent, follow the **Epic Hyperdrive Client Deployment** and **Imprivata SSO** solutions respectively; reference, do not duplicate, their packaging here.

---

## Phase 4 — Lock-down (single-purpose devices only)

## Step 11 — Create the Assigned Access kiosk profile (single-purpose devices)
> Apply this **only** to devices that are genuinely single-purpose (a check-in/registration kiosk, a wayfinding station). A multi-app WOW or nurse-station PC stays on Shared PC mode and is **not** single-app locked.
1. Go to **Devices → Manage devices → Configuration → Create → New policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Templates → Kiosk**. Click **Create**.
3. **Basics:** **Name:** `Clinical Shared – Kiosk Assigned Access – Lock-down`. **Description:** "Assigned Access lockdown for single-purpose clinical kiosks." Click **Next**.
4. **Configuration settings → Kiosk mode:**
   - For a **single-app** kiosk: **Kiosk mode** = **Single app, full-screen kiosk**. **User logon type** = **Auto logon** (a locally created, auto-signed-in kiosk account). **Application type** = the exact app — for a **store** app give its **exact store name/package family name**; for a **Win32/Edge** kiosk specify the app/URL. Disambiguate from similarly named apps using the exact published name and package ID.
   - For a **multi-app** kiosk (a few clinical apps, no full desktop): **Kiosk mode** = **Multi-app kiosk**; add each allowed app by **exact name + AUMID/package family name**; choose the **Start layout** and whether the taskbar is shown.
   - Set **Maintenance window** / **restart** behavior as needed.
   Click **Next**.
5. **Scope tags / Applicability** as required, then **Assignments → Add groups →** the **single-purpose kiosk** subset only (create a child group `Clinical – Shared Devices – Kiosks` if helpful, or target specific devices). Click **Next → Create**.

---

## Phase 5 — Pilot

## Step 12 — Validate the pilot devices
1. On each pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**) or reboot.
2. Run **`CLINDEV-Validation.ps1`** against the pilot devices → confirms each is **enrolled**, in **`Clinical – Shared Devices`** (or the pilot group), has the **Shared PC mode** profile applied (and kiosk profile where applicable), has the **clinical apps installed**, and has **no primary user**. Expect **PASS** on each check.
3. Walk the floor scenarios with a clinician: fast multi-user sign-in on a WOW, kiosk lock holds on a single-purpose device, the cart **stays awake** when left idle on battery, and all clinical apps launch. Complete the **Testing Guide** (`05-testing.md`) and meet its acceptance gate before expanding.

---

## Phase 6/7 — Validate & Expand

## Step 13 — Expand to the full fleet
1. Add **`Clinical – Shared Devices`** to the **Assignments** of: the Autopilot profile (`Clinical Shared – Self-Deploying – Provision`), the ESP (`Clinical Shared – ESP – Provision`), the Shared PC profile (`Clinical Shared – Shared PC Mode – Standardize`), the power profile (`Clinical Shared – WOW Always-On – Standardize`), and the clinical app baseline. Roll out in **waves** within approved maintenance windows.
2. Add single-purpose kiosks to the kiosk profile assignment as they come online.
3. After each wave, run **`CLINDEV-Report.ps1`** for a fleet view (counts by device type / profile / compliance) and **`CLINDEV-Validation.ps1`** for per-device PASS/FAIL. Use **`CLINDEV-Remediation.ps1`** (`-WhatIf` first, then `-Apply`) to clear any stray primary user or re-assign missing profiles.

---
### Order of operations
`Inventory → group (Clinical – Shared Devices) + pilot group → group tag → self-deploying Autopilot profile → ESP → self-provision → Shared PC mode → WOW always-on power → Required clinical app baseline → Assigned Access kiosk (single-purpose only) → validate pilot → expand in waves`
