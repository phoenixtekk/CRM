# Implement iOS Lock Down Profile for iOS iPhones in Microsoft Intune for Shared Devices

> **Version 1.0.0** · Category: Intune · Solution code: IOSLD

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — iOS Lock-Down Profile for Shared & Corporate iPhones (Microsoft Intune)

**White-label · Intune Solutions**

Most organizations hand out two kinds of iPhone: **shared devices** that anyone on shift picks up, and
**corporate devices** assigned to one person. The shared ones need a real **lock-down profile** so they
stay clean, consistent, and limited to the job; the corporate ones need a lighter, user-owned
experience — and staff need to know exactly how to **provision, sign in to, and use each**. Done ad hoc,
shared phones drift, get tied to whoever set them up, and users are confused about which device does
what.

This is a complete, **deploy-it-today** package for implementing an **iOS lock-down profile for shared
iPhones in Microsoft Intune**, alongside the full provisioning and login model for **both** shared and
corporate devices — written for an administrator with no prior Apple-management experience.

## What you get
- A plain-language **Solution Overview** of the shared-vs-corporate model, what a lock-down profile is
  (device restrictions, optional single/multi-app kiosk, supervised controls), and the two
  provisioning models.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (APNs, Apple
  Business Manager + ADE, supervision, groups, the shared sign-in account).
- An **Implementation Guide** of precise, click-by-click Intune steps: the shared **no-user-affinity**
  ADE enrollment, the corporate **user-affinity** ADE enrollment, the lock-down (restrictions + optional
  kiosk) for shared, a lighter baseline for corporate, plus compliance and access.
- A dedicated **Use & Login Guide** for end users: how staff pick up, sign in to, use, and hand back a
  shared phone, and how a user provisions and signs in to their own corporate phone.
- Five **PowerShell scripts** for readiness discovery, per-device model validation, fleet posture
  reporting, safe remediation, and the shared/corporate device-group builder.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
Two cleanly separated provisioning models from one Apple connection: **shared** iPhones with no primary
user, locked down with supervised restrictions (and an optional kiosk), where staff sign into the apps
with a **shared/managed account**; and **corporate** iPhones assigned to the user via their **own Entra
ID**, kept light and user-owned. (iPhones have no Apple "Shared iPad" mode — this solution implements
the accurate iPhone shared model: no user affinity + lock-down + app-level shared sign-in.)

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Shared iPhones locked to exactly what the job needs, corporate iPhones kept light and user-owned, and
staff who know how to provision, sign in to, and use both — managed at fleet scale in Intune and proven
on a pilot before you scale.


---


# 1. Solution Overview — iOS Lock-Down Profile for Shared iPhones (and Corporate iPhones)

## The two-device reality
Most organizations hand out iPhones in **two distinct ways**, and they need to be managed
differently:

- **Shared devices** — a phone that anyone on shift picks up, uses, and hands back. No single
  person owns it. It must stay **clean, consistent, and limited to what the job needs**, and it must
  not get tied to whoever happened to set it up.
- **Corporate devices** — a phone **assigned to one person**. It needs management and security, but a
  **lighter, user-owned** experience where the user signs in with their own identity and installs
  approved apps.

This solution delivers a repeatable **iOS lock-down profile for shared iPhones in Microsoft Intune**,
*and* the full provisioning and login model for **both** shared and corporate devices — so staff know
exactly how to pick up, sign in to, and use each kind of phone.

## What an iOS lock-down profile is
A "lock-down profile" is not a single Intune object — it is a small, named set of policies applied to
the shared phones:

1. A **Device restrictions** configuration profile (supervised restrictions) that **strips iOS down**
   to what the job needs: block the App Store, Safari, app install/remove, account modification, and
   "Erase all content and settings"; keep Wi-Fi, cellular/calling, and the apps the role requires.
2. An **optional Kiosk** profile — **single-app** (the phone runs exactly one app full-screen) or
   **multi-app** (a curated home screen of a few approved apps) — for the most locked-down use cases.
3. A **compliance** policy and (optionally) a **Conditional Access** policy so only a healthy, managed
   phone is trusted.

Corporate phones get a **lighter** version: a baseline device-restrictions profile, compliance, and
(optionally) app-protection — security without turning a personal-use device into an appliance.

## The two provisioning models (this is the key decision)
Both kinds of phone are supervised and enrolled through **Apple Business Manager (ABM)** with
**Automated Device Enrollment (ADE)**. The difference is **user affinity**, set on the ADE enrollment
profile:

| | Shared device | Corporate device |
|---|---|---|
| ADE enrollment profile | `iOS Shared – ADE – Pilot` | `iOS Corporate – ADE – Pilot` |
| User affinity | **Enroll without user affinity** (no primary user) | **Enroll with user affinity** (user signs in) |
| Supervised | Yes | Yes |
| Locked enrollment | Yes (can't remove management) | Yes |
| Identity | A **shared/managed account** signed into the apps | The **user's own Entra ID** |
| Lock-down | Restrictions + optional Kiosk | Lighter baseline restrictions |

## A note on "shared" on iPhone (be accurate)
iPhones do **not** support Apple **Shared iPad** (the multi-user, per-user-partition feature is
iPad-only). On iPhone, "shared" means: the device has **no user affinity** (no primary user), it is
**locked down** with restrictions and optionally a kiosk, and staff **sign into the apps** with a
**shared/managed account** rather than logging into the device itself. This solution implements that
model correctly and does not pretend iPhones have Shared iPad.

## How an end user experiences each device
- **Shared phone:** pick it up, it is already on the locked-down home screen (or kiosk app), do the
  job, hand it back. Where an app needs identity, staff sign in with the **shared/managed account**.
  At hand-back the next person finds the phone in the same clean state.
- **Corporate phone:** the user runs Setup Assistant once, **signs in with their own Entra ID**, the
  phone enrolls assigned to them, the baseline profile and approved apps arrive, and they use it as
  their day-to-day work phone.

(The full step-by-step for both is in the **Use & Login Guide**, Section 4.)

## Benefits
- **Shared phones stay clean** — restrictions/kiosk keep them limited to the job and free of drift.
- **Not tied to one setter** — no-user-affinity enrollment means no phone is "owned" by whoever set it up.
- **Corporate stays light** — assigned phones get security without an appliance lock-down.
- **Clear for staff** — everyone knows how to provision, sign in to, and use each device type.
- **Fleet-scale and reportable** — one group + one policy set per model; per-device and fleet posture
  reporting.

## Limitations (be honest with buyers)
- True kiosk single/multi-app lock-down requires **supervised** devices (ABM + ADE, or Apple Configurator).
- iPhones have **no Shared iPad** multi-user mode — shared identity lives in the apps, not the OS.
- A shared sign-in account is a shared credential; protect it (Conditional Access, rotation) and prefer
  app-level SSO where the app supports it.
- ADE is **zero-touch only on devices added to ABM**; phones bought outside ABM need Apple Configurator
  to supervise.

## The standard deployment model
> **Connect Apple (APNs + ADE) → create the shared no-affinity and corporate user-affinity enrollment
> profiles → build the lock-down (restrictions + optional kiosk) for shared and the lighter baseline
> for corporate → add compliance and access → pilot one of each → validate → expand.**
> repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — iOS Lock-Down Profile for Shared & Corporate iPhones

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, supported OS, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to the dual
shared-vs-corporate iPhone lock-down model.

## R1. Apple MDM Push (APNs) certificate
**Description:** A valid **Apple MDM Push certificate (APNs)** in Intune.
**Why:** Every iOS enrollment and all ongoing MDM communication requires APNs — both shared and
corporate phones depend on it.
**Verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate** shows **Active**
with a future expiration; or run `IOSLD-Discovery.ps1`.
**Implement:** Create/renew it (Implementation §1, Step 1) using a **company Apple ID** reused each year.

## R2. Apple Business Manager + ADE token
**Description:** An **Apple Business Manager (ABM)** account with the iPhones added, and an
**Automated Device Enrollment (ADE) token** connected to Intune.
**Why:** Supervision (via ABM + ADE) is **required** for kiosk lock-down, and ADE enrolls both shared
(no-affinity) and corporate (user-affinity) phones zero-touch.
**Verify:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens** shows a token with a
future expiration and the iPhone serials under **Devices**; or run `IOSLD-Discovery.ps1`.
**Implement:** Connect ABM and upload the ADE token (Implementation §1, Step 2); add serials in ABM and
assign them to the Intune MDM server.

## R3. Supervised devices
**Description:** The iPhones must be **supervised**.
**Why:** iOS only allows true single-app/multi-app kiosk lock-down and the full supervised restriction
set on supervised devices. Corporate phones are supervised too (for the baseline restrictions).
**Verify:** Intune → **Devices → (device) → Properties** shows **Supervised = Yes** after enrollment;
or run `IOSLD-Validation.ps1`.
**Implement:** Enroll via ADE with **Supervised** enabled (Implementation §2), or supervise with Apple
Configurator for phones not in ABM.

## R4. A shared ADE enrollment profile (no user affinity)
**Description:** An iOS/iPadOS ADE enrollment profile, `iOS Shared – ADE – Pilot`, set to **Enroll
without user affinity**.
**Why:** No user affinity is what makes the phone **shared** — it has no primary user and is not tied
to whoever set it up.
**Verify:** On the ADE token → **Profiles**, the profile exists with **Enroll without user affinity**
and **Supervised**.
**Implement:** Create it (Implementation §2, Step 4).

## R5. A corporate ADE enrollment profile (user affinity)
**Description:** A second iOS/iPadOS ADE enrollment profile, `iOS Corporate – ADE – Pilot`, set to
**Enroll with user affinity**.
**Why:** User affinity makes the phone **corporate** — assigned to the user who signs in with their own
Entra ID at Setup Assistant.
**Verify:** On the ADE token → **Profiles**, the profile exists with **Enroll with user affinity** and
**Supervised**.
**Implement:** Create it (Implementation §2, Step 5).

## R6. A shared sign-in / managed account (for shared phones)
**Description:** A dedicated Entra account staff use to sign into the apps on the shared phones (where
an app needs identity).
**Why:** Shared phones have no per-user device identity; the working identity lives in this shared
account at the app layer.
**Verify:** Entra → **Users**; the account `iOS Shared – App Sign-in` (`svc-ios-shared`) exists and
holds the licenses the apps need.
**Implement:** Create the account and license it (Implementation §1, Step 3); store its credentials in
a password manager. Skip only if every shared app is fully anonymous.

## R7. Device groups for each model
**Description:** Two groups: `iOS – Shared Devices` and `iOS – Corporate Devices`.
**Why:** The lock-down policies assign once to the shared group; the lighter baseline assigns once to
the corporate group. Targeting by group keeps the two models cleanly separated.
**Verify:** Entra → **Groups**; both groups exist with the right members; or run `IOSLD-Discovery.ps1`.
**Implement:** Create them (Implementation §2, Step 3), or run `IOSLD-Set-DeviceGroupTargeting.ps1` to
build them as **dynamic** groups keyed on the ADE enrollment profile name.

## R8. Apps to deploy on the shared (and corporate) phones
**Description:** The iOS apps each device model needs (e.g. the role app(s) for shared; the productivity
apps for corporate).
**Why:** A kiosk must lock to an **installed** app, and a corporate baseline assigns approved apps.
**Verify:** Intune → **Apps → iOS/iPadOS**; the required apps are added and assigned to the correct
device group.
**Implement:** Add each app as an **iOS store app** (or **Volume Purchase Program** app from ABM) and
assign **Required** to the relevant group (Implementation §3). Identify each store app by its **exact
publisher name and bundle ID** to avoid picking a near-identical look-alike.

## R9. Supported / kiosk-capable iOS version
**Description:** A current, supported iOS version on each iPhone.
**Why:** Kiosk single/multi-app mode and the supervised restrictions require a supported iOS release.
**Verify:** **Settings → General → About** (or Intune device inventory) shows a supported iOS version.
**Implement:** Update iOS before/at enrollment; set the compliance minimum (Implementation §4).

## R10. Network access to Microsoft (and app) cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365/Entra/Intune service URLs **and** any endpoints the
deployed apps require.
**Why:** Enrollment, policy sync, app install, and sign-in all depend on these.
**Verify:** From a device, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune ranges (and the apps' published endpoints)
through proxy/firewall.

---
## Checklist
- [ ] Apple MDM Push (APNs) certificate Active — `IOSLD-Discovery.ps1`
- [ ] Apple Business Manager + ADE token connected — `IOSLD-Discovery.ps1`
- [ ] Devices supervised — `IOSLD-Validation.ps1`
- [ ] Shared ADE profile `iOS Shared – ADE – Pilot` (no user affinity)
- [ ] Corporate ADE profile `iOS Corporate – ADE – Pilot` (user affinity)
- [ ] Shared sign-in account `iOS Shared – App Sign-in` (where apps need identity)
- [ ] Groups `iOS – Shared Devices` and `iOS – Corporate Devices`
- [ ] Required apps added and assigned per model
- [ ] Supported iOS version on every iPhone
- [ ] Network allows Microsoft (and app) endpoints
- [ ] Pilot group(s) created (one shared + one corporate phone)


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing Guide — iOS Lock-Down Profile for Shared & Corporate iPhones

Run after the pilot phones enroll (Implementation Step 15) and after any profile change. Test **both**
models — a shared phone and a corporate phone.

## Test 1 — Tenant building blocks present
**Do:** Run `IOSLD-Discovery.ps1`.
**Expected:** PASS for APNs, ADE token, both enrollment profiles (`iOS Shared – ADE – Pilot`,
`iOS Corporate – ADE – Pilot`), both groups, the lock-down restrictions profile, the corporate baseline,
and compliance — overall **READY**.

## Test 2 — Shared phone is shared and supervised
**Do:** Run `IOSLD-Validation.ps1 -DeviceName "<shared phone>"` (or `-Serial`).
**Expected:** **No primary user**, **Supervised = Yes**, iOS platform, member of `iOS – Shared Devices`.

## Test 3 — Lock-down applied to the shared phone
**Do:** Intune → **Devices → Configuration →** `iOS Lock-Down – Shared – Restrictions` **→ Device
status** (and `iOS Kiosk – Shared – Pilot` if used). On the phone, try to open the App Store / Safari.
**Expected:** Profile shows **Succeeded**; App Store/Safari are blocked; only the role app(s) are
available. In single-app kiosk, the phone stays pinned to the one app.

## Test 4 — Corporate phone is user-assigned and supervised
**Do:** Run `IOSLD-Validation.ps1 -DeviceName "<corporate phone>"`.
**Expected:** **Has a primary user** (the assigned user), **Supervised = Yes**, member of
`iOS – Corporate Devices`, **compliant**.

## Test 5 — Corporate baseline applied (and lighter)
**Do:** Intune → **Devices → Configuration →** `iOS Corporate – Baseline – Restrictions` **→ Device
status**. On the corporate phone, confirm normal use (App Store usable per policy).
**Expected:** Profile **Succeeded**; the phone is **not** locked to one app and is usable as a normal
work phone within policy.

## Test 6 — Shared sign-in works at the app layer
**Do:** On the shared phone, open the role app and sign in with the `iOS Shared – App Sign-in` account.
**Expected:** The shared account signs in and the app works; the device itself has no user identity.

## Test 7 — Corporate sign-in works with the user's own identity
**Do:** On the corporate phone, open Company Portal / a work app and confirm sign-in with the user's
**own** Entra ID.
**Expected:** Sign-in (with SSO/MFA) succeeds; the phone reports the assigned user.

## Test 8 — Compliance and access
**Do:** Intune → **Devices → Compliance** for both `iOS Shared – Compliance – Pilot` and
`iOS Corporate – Compliance – Pilot`; check Conditional Access report-only results.
**Expected:** Pilot phones are **compliant**; CA report-only shows the policies would apply as intended.

## Test 9 — Fleet posture report
**Do:** Run `IOSLD-Report.ps1`.
**Expected:** A clear shared-vs-corporate breakdown — each phone classified, supervision and compliance
shown, and any model mismatch flagged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Shared pass** | Tests 1, 2, 3, 6, 8 pass for the shared phone |
| **Corporate pass** | Tests 1, 4, 5, 7, 8 pass for the corporate phone |
| **Expand** | Both gates pass and Test 9 shows correct fleet classification |


---


# 6. Troubleshooting Guide — iOS Lock-Down Profile for Shared & Corporate iPhones

Use `IOSLD-Discovery.ps1` for tenant readiness, `IOSLD-Validation.ps1` for a single device,
`IOSLD-Report.ps1` for the fleet, and `IOSLD-Remediation.ps1` (`-WhatIf` first) for safe fixes.

## A. Enrollment model is wrong
| Symptom | Cause | Remediation |
|---|---|---|
| A shared phone HAS a primary user | Enrolled with the corporate (user-affinity) profile, or a user signed in | Confirm the serial is assigned to `iOS Shared – ADE – Pilot` (no affinity); re-erase and re-enroll, or run `IOSLD-Remediation.ps1 -Apply -DeviceName <name>` to clear the primary user |
| A corporate phone has NO primary user | Enrolled with the shared (no-affinity) profile | Assign the serial to `iOS Corporate – ADE – Pilot`, erase, and re-enroll so the user signs in |
| Phone in the wrong group | Dynamic rule mismatch / static membership | Check membership against the ADE enrollment profile name; fix the group or re-run `IOSLD-Set-DeviceGroupTargeting.ps1` |

## B. Lock-down / kiosk not applying (shared)
| Symptom | Cause | Remediation |
|---|---|---|
| App Store/Safari still available | Restrictions profile not assigned or device not supervised | Confirm `iOS Lock-Down – Shared – Restrictions` is assigned to `iOS – Shared Devices`; confirm **Supervised = Yes** (`IOSLD-Validation.ps1`); **Sync** |
| Kiosk not pinning the app | App not installed before kiosk, or wrong bundle ID | Ensure the role app is **Required** and installed first; re-select it by exact bundle ID in `iOS Kiosk – Shared – Pilot`; **Sync** |
| Profile shows Error | Device not checked in / not supervised | Confirm enrollment, group membership, and supervision; **Sync** |

## C. Corporate baseline issues
| Symptom | Cause | Remediation |
|---|---|---|
| Corporate phone over-restricted | Shared lock-down profile assigned to corporate group | Unassign `iOS Lock-Down – Shared – Restrictions` from corporate; confirm only `iOS Corporate – Baseline – Restrictions` applies |
| Approved apps not installing | App not assigned to `iOS – Corporate Devices`, or not licensed | Assign the app **Required** to the corporate group; confirm VPP licenses; **Sync** |

## D. Sign-in problems
| Symptom | Cause | Remediation |
|---|---|---|
| Shared app sign-in fails | Wrong account (personal used), password rotated, or licensing | Use `iOS Shared – App Sign-in`; confirm its licenses; reset/rotate and update the password store |
| Corporate sign-in loops | User used a shared account, MFA not completing, or non-compliant | Have the user sign in with their **own** Entra ID; complete MFA; make the device compliant (Section E) |

## E. Compliance / Conditional Access blocking access
- Confirm the phone is **compliant** (`IOSLD-Validation.ps1` / Intune → device). Common fixes: update
  iOS to the minimum, set a passcode (corporate), resolve jailbreak detection.
- If `CA – iOS Shared` / `CA – iOS Corporate` block legitimately, keep them **report-only** while you
  remediate, then switch to **On**.

## F. ADE / sync issues
- New serials not appearing: in **ABM → Devices** assign them to the `Intune – iOS MDM` server, then in
  Intune on the ADE token → **Devices → Sync** (Apple rate-limits; allow a few minutes).
- APNs expired: renew with the **same company Apple ID** (Implementation Step 1) — a different Apple ID
  breaks all existing enrollments.

## G. Diagnostics quick reference
- `IOSLD-Discovery.ps1` — tenant building blocks (APNs, ADE, profiles, groups, compliance).
- `IOSLD-Validation.ps1 -DeviceName <name>` — per-device model + supervision + profile.
- `IOSLD-Report.ps1` — fleet shared-vs-corporate classification and mismatches.
- In Intune: **Devices → (device) → Device configuration** shows each profile's apply state; **Sync**
  forces a check-in.

## H. When to escalate
If a phone is correctly enrolled (right model, supervised), in the right group, synced, and the profile
still won't apply, capture the device's configuration status and serial and open a Microsoft Intune
support case (and, for ADE/supervision anomalies, confirm the serial's state in Apple Business Manager).


---


# 7. Best Practices — iOS Lock-Down Profile for Shared & Corporate iPhones

- **Decide the model per phone, up front.** A phone is either **shared** (no user affinity, locked
  down) or **corporate** (user affinity, lighter). Set it at the ADE enrollment profile — don't try to
  convert a phone's model after the fact.
- **Two enrollment profiles, two groups, two policy sets.** Keep `iOS Shared – ADE – Pilot` /
  `iOS – Shared Devices` and `iOS Corporate – ADE – Pilot` / `iOS – Corporate Devices` cleanly
  separated so a shared lock-down can never land on a corporate phone (or vice versa).
- **Always supervise.** Kiosk and the full supervised restriction set only hold on supervised devices;
  enroll via ABM + ADE (or Apple Configurator for non-ABM phones).
- **Lock enrollment.** Set **Locked enrollment = Yes** on both profiles so users can't remove
  management — essential for the shared lock-down and good hygiene for corporate.
- **Restrictions first, kiosk only when needed.** A device-restrictions profile gives a
  locked-but-usable shared phone; add a kiosk only when the role truly needs single/multi-app pinning.
- **Keep corporate light.** Resist the urge to over-restrict assigned phones — apply a baseline and
  app-protection, not the shared appliance lock-down.
- **Protect the shared account.** A shared sign-in is a shared credential: scope it tightly, gate it
  with `CA – iOS Shared` (require compliant device), rotate it, and prefer app SSO where supported.
- **Use dynamic groups keyed on the enrollment profile name.** New phones self-sort into the right
  group the moment they enroll (`IOSLD-Set-DeviceGroupTargeting.ps1`).
- **Pilot one of each, then expand in waves.** Validate a shared and a corporate phone with the scripts
  before widening, and re-validate each wave.
- **Name every object with the convention.** `<Purpose> – <Scope> – <Stage>` keeps docs, scripts, and
  the portal consistent and auditable.
- **Set a clean hand-back habit for shared phones.** Train staff to sign out of personal app sessions;
  the restrictions handle the rest.
- **Report regularly.** Run `IOSLD-Report.ps1` to confirm every phone is in the right model, supervised,
  and compliant, and to catch a corporate phone that drifted into the shared group (or vice versa).


---


# 8. Deliverables Summary — iOS Lock-Down Profile for Shared & Corporate iPhones

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The shared-vs-corporate model, what an iOS lock-down profile is, the two provisioning models, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps — APNs/ADE, both enrollment profiles, lock-down + baseline, compliance, access, pilot/expand |
| 4. Use & Login Guide | End-user guide: using/handing back a shared phone, and provisioning/signing in to a corporate phone |
| 5. Testing Guide | Validation procedures with pass/fail gates for both models |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IOSLD-Discovery.ps1` | Tenant/device readiness: APNs, ADE token, both enrollment profiles, supervised state, lock-down + baseline profiles, groups, compliance (read-only) |
| `IOSLD-Validation.ps1` | Per-device: confirms the enrollment model is correct (shared = no user / corporate = user), supervised, and the right profile applied (read-only) |
| `IOSLD-Report.ps1` | Fleet shared-vs-corporate posture report with supervision/compliance and model-mismatch flags (read-only, CSV) |
| `IOSLD-Remediation.ps1` | Safe drift fixes / re-assignment; defaults to `-WhatIf` |
| `IOSLD-Set-DeviceGroupTargeting.ps1` | Builds the shared and corporate device groups as dynamic groups keyed on ADE enrollment profile name (supports `-WhatIf`) |

## What the buyer receives
- These guides as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Shared iPhones locked down to exactly what the job needs, corporate iPhones kept light and user-owned,
both provisioned through Apple Business Manager + ADE, and staff who know how to provision, sign in to,
and use each — managed at fleet scale in Intune and proven on a pilot before you scale.
