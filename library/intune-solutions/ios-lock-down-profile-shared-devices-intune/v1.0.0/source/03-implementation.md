# 3. Implementation Guide — iOS Lock-Down Profile for Shared & Corporate iPhones

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**. You will stand up **two provisioning models** — a
**shared** no-user-affinity, locked-down phone and a **corporate** user-affinity, lighter phone — from
one Apple connection. Pilot first: **Assess → Configure → Pilot → Validate → Expand.**

Consoles used:
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com`
- **Apple Business Manager (ABM)** — `https://business.apple.com`

> **Naming convention used throughout:** `<Purpose> – <Scope> – <Stage>`. Create every object with the
> exact name shown; the scripts and the rest of these docs reference them verbatim.

---

## Phase 1 — Identity & Apple connection baseline

### Step 1. Create the Apple MDM Push (APNs) certificate
1. In Intune, go to **Devices → Enrollment → Apple → Apple MDM Push certificate**.
2. Check **I agree**, **Download** the CSR.
3. Click **Create your MDM push certificate** → `https://identity.apple.com`; sign in with a
   **company Apple ID** (record it — you must reuse it every year to renew).
4. **Create a Certificate**, upload the CSR, **Download** the `.pem`, then back in Intune enter the
   **Apple ID**, **Browse** to the `.pem`, **Upload**.
5. Confirm status **Active** with an expiration ~1 year out.

### Step 2. Connect Apple Business Manager (ADE token)
1. In Intune, go to **Devices → Enrollment → Apple → Enrollment program tokens → Add** → check
   **I agree** → **Download** the Intune **public key** (`.pem`).
2. In **ABM → Preferences → MDM Servers → Add**; name it `Intune – iOS MDM`; **Upload** the Intune
   public key; **Save**; **Download Token** (`.p7m`).
3. Back in Intune, enter the **Apple ID** used for ABM, **Browse** to the `.p7m`, **Upload**.
4. In **ABM → Devices**, set this MDM server as the **default** for iPhone (or assign serials to it
   per Step 8) so new phones flow to Intune.

### Step 3. Create the shared sign-in / managed account (for shared phones)
1. Entra → **Users → New user → Create new user**; **name it `svc-ios-shared`** (display name
   `iOS Shared – App Sign-in`). Set a strong password and store it in your password manager.
2. Assign whatever licenses the apps on the shared phones require for sign-in. *(This is the account
   staff use to sign into the apps on a shared phone — skip if every shared app is anonymous.)*

---

## Phase 2 — Enrollment profiles & device groups (both models)

### Step 4. Create the SHARED ADE enrollment profile (no user affinity)
1. In Intune, go to **Devices → Enrollment → Apple → Enrollment program tokens**, then **open the ADE
   token** you connected in Step 2.
2. Select the **Profiles** tab → **Create profile → iOS/iPadOS**; **name it `iOS Shared – ADE – Pilot`**
   and add a description.
3. **User affinity** = **Enroll without user affinity** *(this is what makes the device shared — no
   primary user)*.
4. **Management options:** enable **Supervised**; set **Locked enrollment = Yes** (users can't remove
   management — essential for a lock-down).
5. **Setup Assistant:** hide every non-essential pane (Apple ID, Restore, Siri, Privacy, Touch ID,
   Passcode as policy dictates) for a clean, hands-off first run.
6. **Review + Create.**

### Step 5. Create the CORPORATE ADE enrollment profile (user affinity)
1. On the **same** ADE token, select the **Profiles** tab → **Create profile → iOS/iPadOS**; **name it
   `iOS Corporate – ADE – Pilot`**.
2. **User affinity** = **Enroll with user affinity** *(the user signs in with their own Entra ID, so
   the phone is assigned to them)*. Choose **Setup Assistant with modern authentication** for the
   sign-in experience.
3. **Management options:** enable **Supervised**; set **Locked enrollment = Yes**.
4. **Setup Assistant:** keep the panes appropriate for a personal-use work phone (allow Apple ID for
   App Store use if your policy permits); hide what you don't need.
5. **Review + Create.**

### Step 6. Create the device groups
1. Entra → **Groups → New group → Security**; **name it `iOS – Shared Devices`**. **Create**.
2. Create a second group **named `iOS – Corporate Devices`**. **Create**.
3. Add the appropriate phones to each (or use dynamic membership — see the tip below). *(The lock-down
   policies assign to the shared group; the lighter baseline assigns to the corporate group.)*

> Prefer automation? Run **`IOSLD-Set-DeviceGroupTargeting.ps1`** to create **both** groups as
> **dynamic device** groups whose rules match phones by their ADE **enrollment profile name** (Steps 4
> and 5), so each phone joins the correct group automatically the moment it enrolls.

### Step 7. Assign serials to each enrollment profile
1. In **ABM → Devices**, select the shared iPhone serials → **Edit MDM Server** → `Intune – iOS MDM`
   → **Confirm**. Do the same for the corporate serials.
2. In Intune, on the ADE token → **Devices**, click **Sync** (Apple rate-limits; allow a few minutes),
   then select the shared serials → **Assign profile → `iOS Shared – ADE – Pilot`**, and the corporate
   serials → **Assign profile → `iOS Corporate – ADE – Pilot`**.

---

## Phase 3 — Lock-down (shared) and baseline (corporate) profiles

### Step 8. Deploy the apps each model needs (do this before the kiosk)
1. **Apps → iOS/iPadOS → Add → iOS store app** (or **iOS volume purchase program app** if licensed via
   ABM). Search the app by its **exact publisher name and bundle ID** — store search returns
   near-identical results, so confirm the bundle ID before selecting.
2. **Assignments:** assign **Required** to **`iOS – Shared Devices`** for the shared role app(s), and to
   **`iOS – Corporate Devices`** for the corporate productivity apps.
3. Note each shared app's **bundle ID** — you'll select it by name/bundle ID in the kiosk profile.

### Step 9. Create the SHARED device-restrictions (lock-down) profile
1. **Devices → Configuration → Create → New policy → iOS/iPadOS → Templates → Device restrictions**;
   **name it `iOS Lock-Down – Shared – Restrictions`**.
2. Recommended **supervised** restrictions for a shared appliance phone:
   - **Block App Store**, **Block Safari** (or block Safari only if not needed for the role).
   - **Block installing apps** and **Block removing apps**.
   - **Block "Erase all content and settings"** and **Block account modification**.
   - **Block AirDrop**; restrict **iCloud** document/keychain sync; quiet **Control Center while
     locked** and **Notifications** you don't want.
3. **Keep enabled:** **Wi-Fi**, **Cellular/Calling**, **Microphone**, and any feature the role app
   needs.
4. **Assignments:** assign to **`iOS – Shared Devices`** → **Create**.

### Step 10. (Optional) Create the SHARED kiosk profile
*(Use this when the shared phone should run only one app, or a curated few.)*
1. **Devices → Configuration → Create → New policy → iOS/iPadOS → Templates → Device restrictions**;
   **name it `iOS Kiosk – Shared – Pilot`**.
2. Open the **Kiosk** settings:
   - **Single-app:** set **Kiosk mode = Single full-screen app**, choose **Store App**, and select the
     one role app (by name / bundle ID from Step 8). The phone runs only that app.
   - **Multi-app:** set **Kiosk mode = Multi-app**, add the handful of approved apps (e.g. the role app
     plus the native **Phone** app), and hide everything else.
3. **Assignments:** assign to **`iOS – Shared Devices`** → **Create**.

> Apply **either** the restrictions profile alone (a locked-but-usable home screen) **or** restrictions
> + kiosk (the most locked-down appliance). Both options are supported; pick per use case.

### Step 11. Create the CORPORATE baseline restrictions profile (lighter)
1. **Devices → Configuration → Create → New policy → iOS/iPadOS → Templates → Device restrictions**;
   **name it `iOS Corporate – Baseline – Restrictions`**.
2. Apply a **light** baseline suitable for a personal-use work phone: require/allow what your policy
   needs (e.g. block obviously risky features, keep the App Store and personal productivity usable).
   Do **not** apply the shared lock-down here — corporate phones are user-owned.
3. **Assignments:** assign to **`iOS – Corporate Devices`** → **Create**.

### Step 12. (Optional) App protection for corporate phones
1. **Apps → App protection policies → Create policy → iOS/iPadOS**; **name it
   `iOS Corporate – App Protection`**.
2. Protect corporate data in managed apps (require PIN, block save-as to personal locations, etc.).
3. **Assignments:** assign to the corporate **users** (app-protection policies target users, not
   devices). **Create**.

---

## Phase 4 — Compliance & access (both models)

### Step 13. Create compliance policies
1. **Devices → Compliance → Create policy → iOS/iPadOS**; **name it `iOS Shared – Compliance – Pilot`**.
   Set baseline rules for a shared device (min iOS version, jailbreak detection; a passcode rule only
   if the shared-use model allows one — many shared phones run passcode-free for hand-off speed).
   **Assign** to **`iOS – Shared Devices`** → **Create**.
2. **Create policy** again; **name it `iOS Corporate – Compliance – Pilot`**. Set stricter rules for an
   assigned device (passcode required, min iOS version, jailbreak detection, encryption).
   **Assign** to **`iOS – Corporate Devices`** → **Create**.

### Step 14. (Optional) Conditional Access continuity
1. Entra → **Protection → Conditional Access → Create new policy**; **name it `CA – iOS Shared`**.
   **Users:** the `iOS Shared – App Sign-in` account. **Grant:** require **compliant device** so the
   shared account only works from a managed, locked-down phone. Start **Report-only** for the pilot.
2. **Create new policy** again; **name it `CA – iOS Corporate`**. **Users:** your corporate iPhone
   users. **Grant:** require **compliant device** (and MFA per policy). Start **Report-only**.

---

## Phase 5 — Pilot, validate, expand

### Step 15. Pilot-enroll one of each
1. **Erase** a pilot shared iPhone and a pilot corporate iPhone (**Settings → General → Transfer or
   Reset → Erase All Content and Settings**) so each returns to Setup Assistant.
2. **Shared phone:** power on, choose language/region, connect to network; Setup Assistant shows
   **Remote Management** naming your organization → continue. It enrolls **supervised, no user
   affinity**, joins **`iOS – Shared Devices`**, installs the role app(s), and applies the **lock-down
   (restrictions + optional kiosk)**. Sign into the app(s) with `iOS Shared – App Sign-in`.
3. **Corporate phone:** power on, connect, and at **Remote Management / sign-in** the user enters their
   **own Entra ID**. It enrolls **supervised, with user affinity**, joins **`iOS – Corporate
   Devices`**, and applies the **baseline** + corporate apps.

### Step 16. Validate
1. Run **`IOSLD-Discovery.ps1`** (tenant readiness: APNs, ADE token, both enrollment profiles, both
   groups, the lock-down + baseline profiles, compliance).
2. Run **`IOSLD-Validation.ps1`** for each pilot device:
   - **Shared pass:** enrolled with **no primary user**, **supervised**, member of **`iOS – Shared
     Devices`**, with the **lock-down restrictions** (and kiosk if used) **applied**.
   - **Corporate pass:** enrolled **with a primary user**, **supervised**, member of **`iOS – Corporate
     Devices`**, with the **baseline** applied and compliant.
3. Run **`IOSLD-Report.ps1`** for the fleet shared-vs-corporate posture.

### Step 17. Expand
1. When both pilots pass, add the rest of the serials to the ADE token and assign the correct
   enrollment profile to each (or make `iOS Shared – ADE – Pilot` / `iOS Corporate – ADE – Pilot` the
   default profile for the appropriate serials).
2. Group membership populates automatically if you used the dynamic groups.
3. Move `CA – iOS Shared` and `CA – iOS Corporate` from **report-only** to **On**, and roll out in
   waves, re-validating each wave with the scripts before widening.

> **Rollback note:** to back a change out, unassign the offending profile from its group (or remove the
> device from the group) and **Sync** — the phone reverts at the next check-in. To fully unenroll a
> pilot phone, retire/wipe it in Intune and erase it.

---
### Order of operations
`APNs → ADE token → shared account → SHARED ADE profile (no affinity) → CORPORATE ADE profile (affinity)
→ groups → assign serials → apps → SHARED restrictions (+ optional kiosk) → CORPORATE baseline →
compliance → Conditional Access → pilot one of each → validate → expand`
