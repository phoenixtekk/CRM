# iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling in Microsoft Intune

> **Version 1.0.0** · Category: Intune Solutions · Solution code: IOSSDM

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Many teams need **shared phones, not personal ones** — pooled iPhones at a nurses' station, a
warehouse floor, a front desk, or a fleet of loaners that **anyone on shift can pick up and use for
one job: making calls**. Handed out as ordinary phones, they drift — apps get installed, settings get
changed, devices get tied to whoever set them up, and nobody can tell which handset is healthy.

This solution makes those iPhones **locked-down, shared appliances** under **Microsoft Intune**:

- **Shared, no owner** → enrolled with **no user affinity** via a **Device Enrollment Manager (DEM)**
  account, so no phone belongs to a person and any staff member can use any device.
- **Locked to one job** → **supervised** via Apple Business Manager + ADE and put into **kiosk
  lock-down** that exposes **only the Cisco Webex app**; the rest of iOS (App Store, Safari, Settings)
  is stripped away.
- **Corporate calling identity** → staff sign into Webex with a **shared organization account**, so the
  device stays generic while the calling identity stays managed.
- **Ready out of the box** → **Cisco Webex** is pushed as a required app and is the app the kiosk
  shows, so an enrolled iPhone comes up ready to call with zero per-device setup.

Built the standard Phoenixtekk way — **Assess → Configure → Pilot → Validate → Expand** — with exact,
click-by-click Intune steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing/troubleshooting
guides with clear pass/fail gates.

**Outcome:** a fleet of interchangeable, locked-down iPhones that do exactly one thing — Webex calling
under a managed organization account — enrolled hands-off and managed at fleet scale by your own team,
without a consulting engagement.


---


# 1. Solution Overview — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

## What this solution is
This solution turns ordinary **iOS iPhones into locked-down, shared "appliance" phones** managed by
Microsoft Intune. The devices are **not assigned to one person** — they are pooled, shared handsets
(think a nurses' station, a warehouse floor, a hotel front desk, a fleet of loaner phones) that any
authorized staff member can pick up and use for a **single, controlled purpose: making and taking
calls in the Cisco Webex app**.

It delivers exactly the four constraints this deployment requires:

1. **Shared, no-user-affinity enrollment** via a **Device Enrollment Manager (DEM)** account — devices
   enroll under one management identity with **no primary user**, so they are owned by the
   organization, not a person, and can be handed between staff freely.
2. **Lock-down (kiosk) mode** — a supervised kiosk configuration restricts each iPhone to **only the
   Cisco Webex app** (plus the system essentials needed to place calls), hiding the rest of iOS so the
   device can't be repurposed, wandered off into Settings, or used for anything but its job.
3. **Organization accounts for login** — staff sign into Webex with a **shared organization account**
   (or their own org account at the app layer), so the *device* stays generic while the *app session*
   carries the corporate identity.
4. **Cisco Webex provisioned automatically** — the Webex app is pushed as a **required** app and is the
   single app the kiosk exposes, so a freshly enrolled iPhone comes up ready to call with nothing else
   to configure.

## How it works
1. **One DEM account enrolls the fleet.** An Intune **Device Enrollment Manager** account (a normal
   Entra user granted the DEM role) is allowed to enroll a large number of devices **without user
   affinity**. Every shared iPhone enrolls under this account, so none of them gets tied to an
   individual user.
2. **Supervised via Apple Business Manager.** The iPhones are added to **Apple Business Manager (ABM)**
   and enrolled through **Automated Device Enrollment (ADE)** as **supervised** devices — supervision
   is what unlocks true kiosk lock-down and the deeper restrictions.
3. **A device group gathers the shared phones.** All shared iPhones land in one Intune group, so every
   policy below is assigned once to that group and applies to the whole fleet.
4. **The kiosk profile locks the device to Webex.** A supervised **kiosk** configuration profile puts
   each iPhone into single-app (or multi-app) mode showing **only Cisco Webex**, and a device
   restrictions profile strips out everything the appliance shouldn't expose.
5. **Webex is deployed and ready.** The **Cisco Webex** app is assigned **Required** to the shared
   group so it installs automatically; staff sign in with the **shared organization account** to place
   calls.
6. **Compliance keeps the fleet healthy.** A compliance policy (OS minimum, passcode/lock behavior as
   appropriate for a shared device) reports the health of every shared iPhone.

## Authentication & login model
Because the devices are **shared and have no primary user**, identity lives at the **app layer**, not
the device layer:
- The **device** authenticates to Intune via the **DEM account** at enrollment — that is the only
  device-level identity.
- **Staff** authenticate to **Cisco Webex** with a **shared organization account** (an Entra account
  provisioned for the shared-phone role). This keeps the corporate calling identity consistent across
  the whole fleet while the hardware stays interchangeable.
- Optionally, the shared account's sign-in to Webex / Office 365 can be governed by Conditional Access.

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Shared iOS iPhones enrolled with no user affinity via a Device Enrollment Manager account,
> supervised through Apple Business Manager + ADE, locked to the Cisco Webex app with a kiosk profile,
> and signed into Webex with a shared organization account — assigned once to a single shared-device
> group and rolled out pilot-first.**

Every step follows the Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**

## Benefits
- **Interchangeable handsets** — no device belongs to anyone; any staff member can grab any phone and
  start calling.
- **Single-purpose lock-down** — the iPhone does one job (Webex calling) and nothing else; no
  wandering into Settings, the App Store, Safari, or unrelated apps.
- **Zero per-device setup** — DEM enrollment + required Webex + kiosk profile means a phone comes out
  of the box ready to call.
- **Consistent corporate calling identity** — a shared organization account keeps Webex calling under
  one managed identity across the fleet.
- **Fleet-scale management** — assign every policy once to the shared-device group; add a phone to the
  group and it inherits the whole configuration.
- **Auditable & healthy** — compliance and reporting scripts show enrollment, supervision, kiosk, and
  Webex install state across all shared phones.

## Limitations (be honest with buyers)
- **Kiosk lock-down requires supervised devices** — supervision (ABM + ADE, or Apple Configurator) is
  required; unsupervised iPhones cannot be fully locked to a single app.
- **DEM-enrolled devices have no primary user**, so user-affinity features (per-user app licensing
  tied to the device user, Company Portal self-service for that user) don't apply — by design for
  shared devices.
- **A DEM account has an enrollment cap** (a single DEM account can enroll a large but finite number
  of devices); very large fleets use additional DEM accounts.
- **Shared-account hygiene matters** — a shared Webex login means staff don't get individual identity
  on the device; treat the shared account's credentials and Conditional Access carefully.
- **Webex feature availability** depends on your Cisco Webex licensing/calling plan — this solution
  deploys and locks the app; the calling service is provided by Cisco.


---


# 2. Requirements — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, supported OS, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to shared, locked-down
iOS iPhones enrolled via a DEM account and provisioned with Cisco Webex.

## R1. A Device Enrollment Manager (DEM) account
**Description:** An Entra user granted the Intune **Device Enrollment Manager** role.
**Why:** A DEM account enrolls many devices **without user affinity**, which is what makes the iPhones
shared (no primary user) rather than personal.
**Verify:** Intune → **Devices → Enrollment → Device enrollment managers**; the account is listed.
**Implement:** Create the account and add it under **Device enrollment managers** (Implementation §2).

## R2. A shared organization account for Webex sign-in
**Description:** A dedicated Entra account staff use to sign into Cisco Webex on the shared phones.
**Why:** Devices are shared and have no per-user identity; the corporate calling identity lives in this
shared account at the app layer.
**Verify:** Entra → **Users**; the shared account exists and holds the licenses Webex needs.
**Implement:** Create the account and license it (Implementation §1); store its credentials securely.

## R3. Apple MDM Push (APNs) certificate
**Description:** A valid **Apple MDM Push certificate (APNs)** in Intune.
**Why:** Every iOS enrollment and all ongoing MDM communication requires APNs.
**Verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate** shows **Active**.
**Implement:** Create/renew it (Implementation §3) using a **company Apple ID** reused each year.

## R4. Apple Business Manager + ADE token (supervised enrollment)
**Description:** An **Apple Business Manager** account with the shared iPhones added, and an
**Automated Device Enrollment token** connected to Intune.
**Why:** Supervision (via ABM + ADE) is **required** for kiosk lock-down; ADE also enrolls the fleet
zero-touch with no user affinity.
**Verify:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens** shows a token with a
future expiration and the iPhone serials under **Devices**.
**Implement:** Connect ABM and upload the ADE token (Implementation §4); add serials in ABM and assign
them to the Intune MDM server.

## R5. Supervised devices
**Description:** The iPhones must be **supervised**.
**Why:** iOS only allows true single-app/multi-app kiosk lock-down on supervised devices.
**Verify:** Intune → **Devices → (device) → Properties** shows **Supervised = Yes** after enrollment.
**Implement:** Enroll via ADE with **Supervised** enabled (Implementation §7), or supervise with Apple
Configurator.

## R6. A shared-device group
**Description:** An Intune group containing all shared iPhones.
**Why:** Every policy (kiosk, restrictions, compliance, app) is assigned once to this group.
**Verify:** Entra → **Groups**; `iOS – Shared Devices` exists with the shared phones as members.
**Implement:** Create it (Implementation §5), or run `IOSSDM-Set-SharedDeviceTargeting.ps1` for a
dynamic group keyed on the ADE enrollment profile name.

## R7. Cisco Webex app available to deploy
**Description:** The **Cisco Webex** iOS app (store app, or a VPP/ABM-licensed app).
**Why:** Webex is the single app the kiosk exposes and the calling app staff use.
**Verify:** Intune → **Apps → iOS/iPadOS**; **Cisco Webex** is added and assigned **Required** to the
shared group.
**Implement:** Add Webex as an iOS store app (or VPP app) and assign Required (Implementation §9).

## R8. Webex / Cisco calling licensing
**Description:** The Cisco Webex licensing/calling plan that lets the shared account place calls.
**Why:** Intune deploys and locks the app; the calling **service** is provided by Cisco and requires
appropriate Webex licensing.
**Verify:** In Webex Control Hub, the shared account (or its calling identity) has a calling license.
**Implement:** Provision Webex calling licensing in Cisco Webex Control Hub (outside Intune).

## R9. Kiosk-capable iOS version
**Description:** A current, supported iOS version on each iPhone.
**Why:** Kiosk single/multi-app mode and the supervised restrictions require a supported iOS release.
**Verify:** **Settings → General → About** (or Intune device inventory) shows a supported iOS version.
**Implement:** Update iOS before/at enrollment; set the compliance minimum (Implementation §13).

## R10. Network access to Microsoft & Cisco cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365/Entra/Intune service URLs **and** the Cisco Webex
calling/media endpoints.
**Why:** Enrollment, policy sync, app install, sign-in, and Webex calling/media all depend on these.
**Verify:** From a device, reach `https://login.microsoftonline.com`,
`https://enrollment.manage.microsoft.com`, and the Webex sign-in/calling endpoints.
**Implement:** Allow Microsoft's published Office 365/Intune ranges and Cisco Webex's published
network requirements through proxy/firewall.


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** Phoenixtekk solution in the **Intune Solutions**
category. They are published once at the category level on the marketplace so individual
solution listings stay small. Confirm these are in place before deploying *any* Intune solution.

Each entry: **Description · Why required · How to verify · How to implement if missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, enrollment, and security policies.
**Verify:** `https://intune.microsoft.com` loads and **Tenant administration → Tenant status** shows an active subscription.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies, enrollment connectors, and configuration profiles requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator** (or Global Administrator for connector setup).
**Implement:** Assign **Intune Administrator** to the operator; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted devices are enrolled and manageable in Intune.
**Why:** Policies only reach enrolled (or app-managed) devices, regardless of platform.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Configure the appropriate enrollment method for the platform and ownership model, then enroll the device.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every Phoenixtekk solution is piloted to a small group before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists with intended members.
**Implement:** Entra → **Groups → New group** → type **Security** → add pilot members.

## G6. Supported, current operating system
**Description:** A supported OS baseline with current updates for the targeted platform.
**Why:** Modern Intune features and security settings assume a patched, vendor-supported OS.
**Verify:** Check the device's OS version or Intune → device → **Hardware**.
**Implement:** Deploy update policies or upgrade to a supported release.

## G7. Network access to required cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The Phoenixtekk deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing & Validation — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Validate against a **pilot shared iPhone** before expanding. Each test has an explicit **pass/fail
gate**. Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device
steps for the user experience.

## Test 1 — Tenant readiness
**Procedure:** Run `IOSSDM-Discovery.ps1`.
**Pass:** The **DEM account** is registered, the APNs certificate is **Active**, the ADE token is
present, the `iOS – Shared Devices` group exists, the `iOS Shared – Kiosk Lockdown – Pilot` and
`iOS Shared – Restrictions – Pilot` profiles exist, **Cisco Webex** is added (Required), and a
compliance policy exists.
**Fail:** Any missing → resolve before piloting.

## Test 2 — Enrolled by DEM, no user affinity
**Procedure:** Inspect the pilot iPhone in Intune → **Devices → (device) → Properties**; run
`IOSSDM-Validation.ps1`.
**Pass:** **Enrolled by** = the `dem-ios-shared` account; **Primary user** is **none/empty**;
**Supervised = Yes**.
**Fail:** A primary user is set → re-enroll without user affinity via ADE (Implementation §7) or via
the DEM account.

## Test 3 — Device is in the shared group and gets policy
**Procedure:** Confirm group membership and policy application.
**Pass:** The iPhone is a member of **`iOS – Shared Devices`** and the kiosk, restrictions, and
compliance policies show **applied/succeeded**.
**Fail:** Not a member → add it (or fix the dynamic rule), then re-sync.

## Test 4 — Cisco Webex installed
**Procedure:** Inspect the device's managed apps (Intune) and the Home screen.
**Pass:** **Cisco Webex** shows **Installed** and is present on the device.
**Fail:** Not installed → confirm the Required assignment to `iOS – Shared Devices` and force a sync.

## Test 5 — Kiosk lock-down holds
**Procedure:** On the pilot iPhone, attempt to leave Webex / reach Settings, App Store, or Safari.
**Pass:** In **single-app** mode the device stays in **Cisco Webex** and cannot be exited; in
**multi-app** mode only the allowed apps appear and everything else is hidden. App Store/Safari are
unavailable.
**Fail:** Other apps/Settings reachable → confirm the device is **Supervised** (Test 2) and the
`iOS Shared – Kiosk Lockdown – Pilot` profile applied.

## Test 6 — Shared org account signs in and calls
**Procedure:** In Webex, sign in with the **`Shared Webex – iOS Phones`** account and place a test call.
**Pass:** Sign-in succeeds with the shared account and a call connects (audio both ways).
**Fail:** Sign-in fails → check the account's Webex licensing (R8) and any Conditional Access (Test 8);
call fails → check network/calling endpoints (R10) and Webex calling licensing.

## Test 7 — Restrictions enforced
**Procedure:** Verify the `iOS Shared – Restrictions – Pilot` controls (e.g. App Store blocked, account
modification blocked, erase blocked).
**Pass:** The blocked actions are unavailable; calling-related functions (cellular/Wi-Fi, microphone)
still work.
**Fail:** A restriction not applied → re-check the profile assignment and device sync.

## Test 8 — (If used) Conditional Access for the shared account
**Procedure:** With `CA – iOS Shared Webex` in report-only, sign into Webex from the kiosk phone and
review Entra → **Sign-in logs → Conditional Access**.
**Pass:** The shared account satisfies **compliant device** from the kiosk iPhone.
**Fail:** Blocked → confirm the device is compliant (Test 3) and the CA grant is correct.

## Acceptance gate
Proceed to **Expand** only when Tests 1–7 pass (and Test 8 if CA is used): the pilot iPhone is
**DEM-enrolled with no primary user**, **supervised**, **locked to Cisco Webex**, signed in with the
**shared organization account**, and a **call connects**.


---


# 6. Troubleshooting — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Work top-down: confirm **enrollment** (DEM, no user affinity), then **supervision**, then **grouping**,
then **kiosk lock-down**, then the **Webex app**, then **calling**. Most issues are a device that
enrolled with a primary user, a device that isn't supervised, or the kiosk applied before Webex
installed.

## The iPhone enrolled with a primary user (not shared)
- **Wrong enrollment path.** It was enrolled with user affinity. Re-enroll via ADE with **Enroll
  without user affinity** (Implementation §7), or enroll signed in as the **`dem-ios-shared`** account.
- Confirm in **Devices → (device) → Properties**: **Primary user** must be empty, **Enrolled by** =
  the DEM account.

## Kiosk lock-down isn't holding (other apps reachable)
- **Device not supervised.** Single/multi-app kiosk requires **Supervised = Yes** (Properties). If it's
  unsupervised, re-enroll via ADE with Supervised enabled (Implementation §7).
- **Kiosk profile not applied.** Check `iOS Shared – Kiosk Lockdown – Pilot` shows **Succeeded** on the
  device and is assigned to **`iOS – Shared Devices`**.
- **App not installed yet.** The kiosk needs Webex installed to lock to — confirm Test 4 first.

## Cisco Webex didn't install
- **Assignment.** Webex must be **Required** to **`iOS – Shared Devices`** (Implementation §9); confirm
  the device is a group member.
- **VPP licensing.** If you deployed Webex via VPP, confirm device-based licenses are available and
  assigned. Force a device sync and re-check.

## The device isn't in the shared group
- **Static group:** add the device manually. **Dynamic group:** confirm the membership rule matches the
  ADE **enrollment profile name** used in Step 7, and allow time for dynamic evaluation.
- Re-run `IOSSDM-Validation.ps1` after the device appears in the group.

## Shared account can't sign into Webex
- **Webex licensing.** The shared account needs a Webex calling license in Cisco Webex Control Hub (R8).
- **Conditional Access.** If `CA – iOS Shared Webex` requires a compliant device, confirm the iPhone is
  **Compliant** (Test 3) — otherwise the shared account is correctly blocked. Read Entra → **Sign-in
  logs → Conditional Access**.
- **Wrong credentials.** Confirm the `Shared Webex – iOS Phones` account password (rotate if unsure).

## Calls won't connect (sign-in works)
- **Network/endpoints.** The Webex media/calling endpoints must be reachable (R10) — verify proxy/
  firewall allows Cisco Webex's published ranges.
- **Restrictions too tight.** Confirm `iOS Shared – Restrictions – Pilot` did not disable cellular/Wi-Fi
  or the microphone.
- **Webex calling service.** Confirm the calling plan/licensing is active in Webex Control Hub.

## Enrollment fails at Setup Assistant
- **APNs/ADE token lapsed.** Renew the **Apple MDM Push certificate** (R3) and the **ADE token** (R4) —
  an expired token blocks all iOS enrollment.
- **Serial not assigned.** Confirm the serial is in ABM and assigned to the `Intune – iOS Shared` MDM
  server, and the `iOS Shared – ADE – Pilot` profile is assigned (Implementation §8).

## Useful checkpoints
- **Intune:** Devices → (device) → **Properties** (primary user, supervised), **Device configuration**
  (kiosk/restrictions status), **Managed apps** (Webex install); Devices → Enrollment → Apple for
  APNs/ADE token status; Devices → Enrollment → **Device enrollment managers** for the DEM account.
- **Entra:** **Sign-in logs → Conditional Access** for the shared account.
- **Scripts:** re-run `IOSSDM-Validation.ps1` after each change to confirm the gate.


---


# 7. Best Practices — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Field-proven guidance for running a fleet of locked-down, shared iPhones.

## Enrollment & ownership model
- **Always enroll without user affinity.** Shared devices must have **no primary user** — use the ADE
  profile's **Enroll without user affinity** option, or enroll via the DEM account. A primary user on
  a shared phone breaks the model.
- **Prefer ADE over manual DEM enrollment.** ABM + ADE gives zero-touch, supervised, locked enrollment;
  keep the DEM account as the path for any device you must enroll by hand (Apple Configurator).
- **Watch the DEM cap.** A single DEM account enrolls a large but finite number of devices; for big
  fleets, split across multiple DEM accounts and document which account owns which batch.
- **Name everything by intent** — `DEM – iOS Shared Devices`, `iOS – Shared Devices`,
  `iOS Shared – Kiosk Lockdown – Pilot` — so the configuration is self-documenting and auditable.

## Lock-down (kiosk)
- **Supervise first, then lock.** Kiosk single/multi-app mode only works on supervised devices — confirm
  **Supervised = Yes** before expecting the lock-down to hold.
- **Single-app for pure calling; multi-app if you need the native Phone app.** Single full-screen app
  is the tightest lock; switch to multi-app only when staff genuinely need a second app, and hide
  everything else.
- **Don't over-restrict the call path.** Keep cellular/Wi-Fi, microphone, and Webex's networking
  enabled — a restriction that blocks the call defeats the purpose.
- **Stage restrictions in report/pilot first.** Apply the restrictions profile to one device and
  confirm calling still works before fleet-wide rollout.

## Shared account hygiene
- **Treat the shared Webex account as privileged.** Rotate its password on a schedule, store it in a
  password manager, and gate it with **Conditional Access** (compliant device) so it only works from a
  managed kiosk phone.
- **Decide your sign-out policy.** For truly shared use, decide whether Webex stays signed in between
  shifts or staff sign in/out — document it and configure accordingly.
- **Avoid per-user data on a shared device** — the device is a pool resource; keep personal data off it.

## App deployment
- **Deploy Webex Required before applying the kiosk.** The kiosk needs an installed app to lock to;
  push Webex first, confirm it installs, then enforce the kiosk.
- **Use VPP/ABM licensing for Webex where possible** — device-based VPP licensing fits shared,
  no-user-affinity devices better than per-user store installs.
- **Pin the bundle ID.** Lock to Cisco Webex by bundle ID (`com.cisco.squared`) so the kiosk targets
  the right app unambiguously.

## Rollout & operations
- **Pilot one phone end to end** — enroll, lock, sign in, place a call — before expanding.
- **Expand in waves**, validating each with `IOSSDM-Validation.ps1` before widening.
- **Report regularly** with `IOSSDM-DeviceReport.ps1`: enrollment account, supervision, kiosk state,
  Webex install, and compliance across the whole shared fleet.
- **Keep a runbook** of the DEM account(s), the shared group, the kiosk/restrictions/compliance
  profiles, the Webex app, and the shared Webex account — the moving parts that define the fleet.


---


# 8. Deliverables Summary — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — the shared-device model, the DEM/no-affinity design, kiosk lock-down, the
  shared-account login model, benefits, and honest limitations.
- **Requirements Guide** — every prerequisite (DEM account, shared Webex account, APNs, ABM + ADE
  token, supervision, shared-device group, Cisco Webex app, Webex calling licensing, iOS version,
  network) with how to **verify** and how to **implement if missing**, plus the category-level Global
  Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across five phases: identity & Apple
  connection baseline, DEM/supervised no-affinity enrollment, kiosk lock-down to Cisco Webex, compliance
  & access, then pilot/validate/expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates and an acceptance gate, proving a
  shared iPhone is DEM-enrolled, supervised, locked to Webex, and calling under the shared account.
- **Troubleshooting** — top-down diagnosis for enrollment, ownership, kiosk, app, and calling failures.
- **Best Practices** — enrollment/ownership model, kiosk discipline, shared-account hygiene, app
  deployment, and rollout.

## PowerShell scripts (Microsoft Graph) — `IOSSDM-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**.

1. **`IOSSDM-Discovery.ps1`** — tenant readiness: DEM account registered, APNs, ADE token, the shared
   group, kiosk/restrictions profiles, the Cisco Webex app, and a compliance policy.
2. **`IOSSDM-Validation.ps1`** — for a given shared iPhone, confirms it is **DEM-enrolled, no primary
   user, supervised**, in the shared group, kiosk applied, and **Cisco Webex installed**, with a
   PASS/FAIL summary.
3. **`IOSSDM-DeviceReport.ps1`** — tenant-wide CSV of shared iPhones: enrollment account, supervision,
   kiosk state, Webex install, compliance, and last check-in.
4. **`IOSSDM-Remediation.ps1`** — safe remediation: re-assign the shared-device policies/app to the
   group and flag devices with a stray primary user or missing kiosk/app. Read-only by default; changes
   require an explicit confirmation switch.
5. **`IOSSDM-Set-SharedDeviceTargeting.ps1`** — creates the **`iOS – Shared Devices`** group (dynamic,
   keyed on the ADE enrollment profile name) and optionally assigns the kiosk/restrictions/compliance
   policies and the Webex app to it — the mechanism that makes the fleet self-configure on enrollment.

## Hero image
- **`IOSSDM-hero.png`** — the branded product image (1200×1200) used on the marketplace listing.

## How it's delivered
A branded **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts
appendix), plus all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across
**unlimited devices**.
