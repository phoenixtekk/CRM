# 3. Implementation — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**. The design is **shared, no-user-affinity iPhones**: enroll
under a **Device Enrollment Manager (DEM)** account, supervise via **Apple Business Manager + ADE**,
lock to **Cisco Webex** with a kiosk profile, and sign into Webex with a **shared organization
account**. Pilot first: **Assess → Configure → Pilot → Validate → Expand.**

Consoles used:
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com`
- **Apple Business Manager (ABM)** — `https://business.apple.com`

> **Scope note:** these are **shared appliance phones**, not personal devices. They have **no primary
> user** (DEM enrollment), are **supervised** (so the kiosk lock-down applies), and expose **only Cisco
> Webex**. Staff identity lives in the Webex sign-in (a **shared organization account**), not on the
> device.

---

## Phase 1 — Identity & Apple connection baseline

### Step 1. Create the shared organization account (Webex login)
1. Entra → **Users → New user → Create new user**; **name it `svc-webex-shared`** (display name
   **`Shared Webex – iOS Phones`**). Set a strong password and store it in your password manager.
2. Assign the licenses your Cisco Webex sign-in requires (and any Microsoft 365 license your tenant
   needs for the sign-in). *(This is the account staff use to sign into Webex on the shared phones.)*

### Step 2. Create the Device Enrollment Manager (DEM) account
1. Entra → **Users → New user**; **name it `dem-ios-shared`** (display name **`DEM – iOS Shared
   Devices`**). Set a strong password.
2. In Intune, go to **Devices → Enrollment → Device enrollment managers → Add**.
3. Enter `dem-ios-shared@<your-domain>` and **Add**. *(This grants the account the DEM role so it can
   enroll many devices **without user affinity**.)*
4. Confirm the account now appears in the **Device enrollment managers** list.

### Step 3. Create the Apple MDM Push (APNs) certificate
1. In Intune, go to **Devices → Enrollment → Apple → Apple MDM Push certificate**.
2. Check **I agree**, **Download** the CSR.
3. Click **Create your MDM push certificate** → `https://identity.apple.com`; sign in with a
   **company Apple ID** (record it — you must reuse it every year).
4. **Create a Certificate**, upload the CSR, **Download** the `.pem`, then back in Intune enter the
   **Apple ID**, **Browse** to the `.pem`, **Upload**.
5. Confirm status **Active** with an expiration ~1 year out.

### Step 4. Connect Apple Business Manager (ADE token)
1. In Intune, go to **Devices → Enrollment → Apple → Enrollment program tokens → Add** → check
   **I agree** → **Download** the Intune **public key** (`.pem`).
2. In **ABM → Preferences → MDM Servers → Add**; name it **`Intune – iOS Shared`**; **Upload** the
   Intune public key; **Save**; **Download Token** (`.p7m`).
3. Back in Intune, enter the **Apple ID** used for ABM, **Browse** to the `.p7m`, **Upload**.

### Step 5. Create the shared-device group
1. Entra → **Groups → New group → Security**; **name it `iOS – Shared Devices`**.
2. Membership: add the shared iPhones to this group (see the dynamic-group tip below). *(Every policy
   in this solution is assigned to this **device** group.)*

> Prefer automation? Run **`IOSSDM-Set-SharedDeviceTargeting.ps1`** to create a **dynamic device**
> group whose rule matches the shared iPhones by their ADE **enrollment profile name** (Step 7), so a
> phone joins `iOS – Shared Devices` automatically the moment it enrolls.

---

## Phase 2 — Enrollment (DEM + supervised, no user affinity)

### Step 6. Set enrollment restrictions for the shared iPhones
1. **Devices → Enrollment → Enrollment device platform restrictions.**
2. Create a restriction **named `Enrollment Restriction – iOS Shared – Pilot`** (or edit the default)
   and ensure **iOS/iPadOS** is **Allowed**.

### Step 7. Create the iOS ADE enrollment profile (supervised, no user affinity)
1. On the ADE token, open **Profiles → Create profile → iOS/iPadOS**; **name it `iOS Shared – ADE –
   Pilot`**.
2. **User affinity** = **Enroll without user affinity** *(this is what makes the device shared — no
   primary user)*.
3. **Management options:** enable **Supervised**; set **Locked enrollment = Yes** (users can't remove
   management — essential for a kiosk).
4. **Setup Assistant:** hide every non-essential pane (Apple ID, Restore, Siri, Privacy, Touch ID,
   Passcode as policy dictates) for a clean, hands-off first-run.
5. **Review + Create.**

### Step 8. Assign devices and the profile
1. In **ABM → Devices**, select the shared iPhone serial numbers → **Edit MDM Server** → choose
   **`Intune – iOS Shared`** → **Confirm**.
2. In Intune, on the token → **Devices**, click **Sync** (Apple rate-limits; allow a few minutes),
   then select the serials → **Assign profile** → **`iOS Shared – ADE – Pilot`**.

> **DEM note:** if you enroll a device manually (Apple Configurator or Setup Assistant) rather than
> ADE, sign in with the **`dem-ios-shared`** account so it enrolls without user affinity. ADE with
> **Enroll without user affinity** (Step 7) achieves the same shared result zero-touch and is preferred.

---

## Phase 3 — Lock-down (kiosk) configuration

### Step 9. Deploy the Cisco Webex app (required) first
*(Deploy the app before the kiosk so the kiosk has an installed app to lock to.)*
1. **Apps → iOS/iPadOS → Add → iOS store app**; search **Webex** (publisher **Cisco Systems, Inc.** — bundle ID `com.cisco.squared`, *not* 'Webex Meetings'), **Select**.
   *(If you license Webex through ABM/VPP, add it as a **Volume Purchase Program** app and assign
   licenses by device.)*
2. **Assignments:** assign **Required** to **`iOS – Shared Devices`** so it installs automatically.
3. Note the Webex **bundle ID** (`com.cisco.squared`) — you'll select Webex by name/bundle ID in the
   kiosk profile.

### Step 10. Create the kiosk lock-down profile (single-app → Webex)
1. **Devices → Configuration → Create → New policy → iOS/iPadOS → Templates → Device restrictions**;
   **name it `iOS Shared – Kiosk Lockdown – Pilot`**.
2. Open the **Kiosk** settings → **Kiosk mode = Single full-screen app**; for **App to run in kiosk
   mode**, choose **Store App** and select **Cisco Webex** (bundle ID `com.cisco.squared`).
   *(Use **Multi-app** instead if staff also need the native **Phone** app — add Webex and Phone, and
   hide all other apps.)*
3. **Assignments:** assign to **`iOS – Shared Devices`** → **Create**.

### Step 11. Create the device restrictions profile (strip the rest of iOS)
1. **Devices → Configuration → Create → New policy → iOS/iPadOS → Templates → Device restrictions**;
   **name it `iOS Shared – Restrictions – Pilot`**.
2. Recommended supervised restrictions for an appliance phone: **Block App Store**, **Block Safari**,
   **Block installing/removing apps**, **Block Erase all content and settings**, **Block account
   modification**, **Block AirDrop**, **Block adding/removing eSIM/lines** as appropriate, and disable
   the **Control Center while locked** / **Notifications** noise you don't want.
3. Keep **Wi-Fi**, **Cellular/Calling**, and **Microphone** enabled (the phone must place calls).
4. **Assignments:** assign to **`iOS – Shared Devices`** → **Create**.

### Step 12. (Optional) Webex app configuration profile
1. If your Webex tenant supports managed app configuration, **Apps → App configuration policies →
   Add → Managed devices**; **name it `iOS Shared – Webex Config – Pilot`**, platform **iOS/iPadOS**,
   target app **Cisco Webex**.
2. Add the configuration keys Cisco documents for org/email pre-fill (e.g. default email domain) so the
   shared org account is easier to sign in. **Assign** to **`iOS – Shared Devices`**.

---

## Phase 4 — Compliance & access

### Step 13. Create a compliance policy for the shared phones
1. **Devices → Compliance → Create policy → iOS/iPadOS**; **name it `iOS Shared – Compliance –
   Pilot`**.
2. Set baseline rules suitable for a shared device (min iOS version, jailbreak detection; a passcode
   rule only if the shared-use model allows one — many kiosks run passcode-free for hand-off speed).
3. **Assignments:** assign to **`iOS – Shared Devices`** → **Create**.

### Step 14. (Optional) Conditional Access for the shared Webex account
1. Entra → **Protection → Conditional Access → Create new policy**; **name it `CA – iOS Shared
   Webex`**.
2. **Users:** **`Shared Webex – iOS Phones`** (the Step 1 account). **Target resources:** the Webex /
   Office 365 apps. **Grant:** require **compliant device** (the shared iPhone) so the shared account
   only works from a managed kiosk phone.
3. **Enable policy:** **Report-only** for the pilot → **Create**.

---

## Phase 5 — Pilot, validate, expand

### Step 15. Pilot-enroll a shared iPhone
1. **Erase** the pilot iPhone (**Settings → General → Transfer or Reset → Erase All Content and
   Settings**) so it returns to Setup Assistant.
2. Power on, choose language/region, connect to network.
3. Setup Assistant shows **Remote Management** naming your organization → continue. The phone enrolls
   **supervised, no user affinity**, joins **`iOS – Shared Devices`**, installs **Cisco Webex**, and
   drops into **kiosk mode** showing only Webex.
4. Sign into Webex with the **`Shared Webex – iOS Phones`** account and place a test call.

### Step 16. Validate
1. Run **`IOSSDM-Discovery.ps1`** (tenant readiness: DEM account, APNs, ADE token, shared group, kiosk
   profile, restrictions, Webex app, compliance) and **`IOSSDM-Validation.ps1`** for the pilot device.
2. **Pass:** the iPhone is **enrolled by the DEM account**, **supervised**, **no primary user**, a
   member of **`iOS – Shared Devices`**, has the **kiosk** + **restrictions** profiles **applied**, and
   **Cisco Webex installed**.
3. On the device, confirm it is **locked to Webex** (Home button / app switcher do not leave Webex in
   single-app mode) and that a **call connects**.

### Step 17. Expand
1. When the pilot passes, add the rest of the shared iPhone serials to the ADE token and assign the
   **`iOS Shared – ADE – Pilot`** profile (or make it the **default** profile for the token).
2. Add the devices to **`iOS – Shared Devices`** (automatic if you used the dynamic group).
3. Move **`CA – iOS Shared Webex`** from **report-only** to **On** (if used), and roll out in waves,
   validating each wave with the scripts before widening.
