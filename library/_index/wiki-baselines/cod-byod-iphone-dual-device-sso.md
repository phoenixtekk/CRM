# Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On in Microsoft Intune

> **Version 1.0.0** · Category: Intune Solutions · Solution code: IOSDD

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

A huge share of your people carry **two iPhones** — a **corporate iPhone (COD)** the company buys and
controls, and their **own personal iPhone (BYOD)** they also use for work. They expect the **same work
account to just sign in on both**, seamlessly. Handled badly, that means duplicate policies,
inconsistent security, two logins, and frustrated users.

This solution is built for exactly that **one-person-two-iPhones** scenario, under **Microsoft
Intune** and **one Microsoft Entra identity**: the user signs in with the same corporate account on
**both** their company iPhone and their personal iPhone, gets **single sign-on** across them, and IT
applies the **right level of control to each** based on who owns it.

- **Corporate iPhone (COD)** → supervised enrollment via **Apple Business Manager + Automated Device
  Enrollment (ADE)**, full MDM, device compliance, and configuration. IT owns the iPhone end to end.
- **Personal iPhone (BYOD)** → lighter-touch management: **App Protection (MAM)** that secures
  corporate data inside apps without taking over the employee's phone — or optional **Account-Driven
  Apple User Enrollment**.
- **One identity, both iPhones, single sign-on** → the user's single Entra account works on both
  iPhones; on iOS the **Microsoft Authenticator** broker plus the **iOS Enterprise SSO extension** give
  **silent SSO** so they sign in once per iPhone. **Ownership-based targeting** routes the correct
  policy to each iPhone automatically, and **Conditional Access** grants access from their compliant
  company iPhone *or* a protected app on their personal one.

Built the standard Phoenixtekk way — **Assess → Configure → Pilot → Validate → Expand** — with exact,
click-by-click Intune steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing/troubleshooting
guides with clear pass/fail gates.

**Outcome:** one employee account that signs in seamlessly — with single sign-on — across both their
corporate and personal iPhone, corporate data protected on each, and access governed by compliance
and app protection — delivered by your own team without a consulting engagement.


---


# 1. Solution Overview — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

## What this solution is
This solution targets a specific, very common reality: **one person carries two iPhones** — a
**personal iPhone (BYOD)** they own and a **corporate iPhone (COD)** the company owns — and needs the
**same single work account to sign in seamlessly on both**, with the right level of management applied
to each. Think of the executive who carries a company iPhone for work and their own iPhone for life,
the clinician or field tech issued a corporate handset who still uses a personal one, or the hybrid
employee who answers Teams on either phone — all under one identity.

It delivers that in Microsoft Intune under **one Microsoft Entra identity**, across the two iOS
ownership models:

1. **Corporate iPhone (COD)** — the iPhone the organization buys and owns. Enrolled **supervised via
   Apple Business Manager + Automated Device Enrollment (ADE)**, fully managed in Intune (MDM); it
   receives configuration and compliance policies and the iOS Enterprise SSO extension.
2. **Personal iPhone (BYOD)** — the iPhone the employee owns. The corporate **identity and data** are
   protected without taking over the personal phone, primarily through **App Protection Policies
   (MAM)**, with optional lightweight **Account-Driven Apple User Enrollment**.

The defining design goal: **the user signs in with one Entra account on both iPhones and gets a single
sign-on experience** — Intune applies controls based on **device ownership**, not on a second account,
so the personal iPhone is protected (data-only) while the corporate iPhone is fully managed,
simultaneously, for the same person.

## How it works
1. **One identity, two iPhones.** The user has a single Microsoft Entra account. That one account
   enrolls their corporate iPhone **and** signs into the managed work apps on their personal iPhone —
   there is no separate "BYOD account," and both iPhones register to the same identity.
2. **Single sign-on across both.** On iOS the **Microsoft Authenticator** app is the identity broker;
   on the corporate iPhone the **iOS Enterprise SSO extension** (deployed by Intune) extends that SSO
   to Safari and other apps. The user signs in once per iPhone, then moves between Microsoft 365 and
   SSO-enabled apps without re-entering credentials.
3. **Ownership is tagged.** Each iPhone is marked **Corporate** (ADE-enrolled) or **Personal**
   (App Protection / User Enrollment defaults).
4. **Ownership-based targeting.** Policies are assigned to the **user**, then scoped with **iOS device
   filters** on `deviceOwnership` so the user's two iPhones each get the correct set:
   - the user's **Corporate** iPhone receives full **device compliance** + **configuration** policies
     and the **Enterprise SSO extension**;
   - the user's **Personal** iPhone receives **App Protection (MAM)** policies that encrypt corporate
     data, enforce a PIN, and block copy/paste or "Save As" to personal locations.
5. **Conditional Access ties it together.** A single Conditional Access policy for the user grants
   access when the request comes from their **compliant corporate iPhone** *or* from an **approved app
   with an app-protection policy** on their personal iPhone — so the one account works securely from
   **either** of the user's two iPhones.

## Single sign-on across the user's two iPhones
Because both iPhones register to the **same Entra identity**, the user gets a unified sign-in:
- **Corporate iPhone:** supervised and Entra-registered; the **iOS Enterprise SSO extension** (the
  Microsoft Entra ID plug-in, brokered by Authenticator) gives **silent SSO** to Microsoft 365, Entra
  apps, and Safari — no repeated passwords.
- **Personal iPhone:** the **Microsoft Authenticator** broker (registered during app-protection
  onboarding) brokers Entra auth, so Outlook/Edge/Teams and other approved apps get silent SSO with
  the same account.
- **Consistent posture either way:** Conditional Access evaluates each iPhone on its own merits
  (compliant COD *or* MAM-protected BYOD), so the single account is honored from both without the user
  ever managing two logins.

## Management models (choose per ownership)
- **Corporate iPhone — full MDM (supervised ADE):** complete device management, configuration
  profiles, compliance, and zero-touch provisioning via Apple Business Manager + Automated Device
  Enrollment.
- **Personal iPhone — App Protection / MAM (recommended):** secures corporate data *inside* managed
  apps with no full device enrollment; least intrusive for employees, strong data-leak protection.
- **Personal iPhone — Account-Driven User Enrollment (optional):** when a personal iPhone must receive
  a few device settings while keeping personal data separate; still tagged Personal and scoped
  accordingly.

This solution standardizes on **supervised full MDM for the corporate iPhone** and **App Protection
for the personal iPhone**, with Account-Driven User Enrollment called out as an option.

## Benefits
- **One account on both of the user's iPhones** — no duplicate identities; the same login on the
  personal and the corporate iPhone.
- **Seamless single sign-on** — sign in once per iPhone, then move between Microsoft 365 apps (and
  between the two phones) without re-entering credentials.
- **Right-sized control** — full management on the corporate iPhone; data-only protection on the
  personal one — at the same time, for the same person.
- **Lower friction BYOD** — employees keep their personal iPhone private; corporate data stays
  contained in managed apps.
- **Consistent security** — compliance for the corporate iPhone, app protection for the personal one,
  unified by one Conditional Access policy that accepts either iPhone.
- **Scales cleanly** — ownership-based targeting means you assign once to the user and the right policy
  follows each of their iPhones.

## Limitations (be honest with buyers)
- **App Protection (MAM)** secures data **inside supported apps** (Microsoft 365 and SDK-enabled
  apps); it does not manage the whole personal iPhone or unmanaged apps.
- BYOD users must use the **managed/approved apps** (e.g. Outlook, Edge, Teams) to get corporate data;
  the built-in personal Mail/Safari apps are blocked from corporate data by design.
- Supervised corporate-iPhone enrollment requires the device to be in **Apple Business Manager** (ADE);
  iPhones not in ABM can still enroll, but not supervised/zero-touch.
- The iOS **Enterprise SSO extension** requires **Microsoft Authenticator** present on the device, and
  silent SSO applies to Entra-integrated apps.
- A user signing in on a brand-new iPhone enrolls/registers that device the first time.

## The standard Phoenixtekk deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **One Microsoft Entra identity per user, signed in across that user's two iPhones with single
> sign-on; the corporate iPhone under supervised full MDM (ABM + ADE) and the personal iPhone under
> App Protection (MAM); ownership-based targeting routes the right policy to each; a single Conditional
> Access policy governs access from both.**

Every step follows the Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, supported OS, network) are
covered once in the **Global Requirements — Intune Solutions** document; the items here are specific
to running a corporate iPhone (COD) and a personal iPhone (BYOD) under one identity.

## R1. A single Microsoft Entra identity per user
**Description:** Each user has exactly one Entra ID account used for both device types.
**Why:** The whole design depends on one account signing in on both the corporate and the personal
device; two accounts would split policy and defeat the goal.
**Verify:** Entra → **Users**; the pilot user exists once with a licensed account.
**Implement:** Consolidate duplicate accounts; ensure the user signs in with the same UPN everywhere.

## R2. Intune licensing that includes App Protection (MAM)
**Description:** A license plan that covers both device management (MDM) and app management (MAM).
**Why:** COD uses MDM; BYOD uses App Protection (MAM). Both must be licensed for the same user.
**Verify:** Entra → user → **Licenses**; an Intune-bearing plan (M365 E3/E5, Business Premium, or
Intune Plan 1) is assigned.
**Implement:** Assign the appropriate Microsoft 365/Intune license to all pilot users.

## R3. Microsoft Entra ID P1 (for Conditional Access)
**Description:** Entra ID P1 (or higher) for Conditional Access.
**Why:** A single Conditional Access policy is what lets one account access work from a compliant COD
*or* an app-protected BYOD device; CA requires P1.
**Verify:** Entra → **Conditional Access** opens and policies can be created (P1 present).
**Implement:** Assign Entra ID P1 (included in M365 E3/E5/Business Premium) to pilot users.

## R4. Enrollment restrictions configured for both ownership types
**Description:** Device platform/enrollment restrictions that **allow personal (BYOD)** enrollment for
the BYOD path and treat the correct platforms as **corporate** for COD.
**Why:** A restriction that blocks personal enrollment, or that auto-marks all devices corporate,
breaks the ownership distinction this solution relies on.
**Verify:** Intune → **Devices → Enrollment → Enrollment device platform restrictions**; the pilot
restriction shows the intended **Personal = Allow/Block** per platform.
**Implement:** Edit the default or a pilot-targeted restriction so BYOD platforms allow personal, and
keep COD platforms enrolling as corporate (see R5).

## R5. A way to mark the corporate iPhone Corporate (ABM + ADE)
**Description:** The corporate iPhone enrolled through **Apple Business Manager + Automated Device
Enrollment (ADE)** so it is tagged **Corporate** and supervised.
**Why:** Ownership = Corporate is the signal that routes full MDM policy (vs. App Protection) to the
iPhone; ADE also makes the enrollment supervised and zero-touch.
**Verify:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens → (token) → Devices**
shows the iPhone serials; a device's **Ownership** field reads **Corporate**.
**Implement:** Add the iPhone serials to ABM and assign them to the Intune MDM server (Implementation
§§3, 7), or for non-ABM iPhones add **Corporate device identifiers** (serials/IMEIs).

## R6. Microsoft Authenticator and Company Portal apps
**Description:** **Microsoft Authenticator** (the iOS identity broker) and the Intune **Company
Portal** available on the iPhones.
**Why:** Authenticator brokers Entra auth and powers the iOS Enterprise SSO extension; Company Portal
surfaces app-protection-enabled apps and supports User Enrollment for BYOD.
**Verify:** Intune → **Apps → iOS/iPadOS**; Authenticator and Company Portal are added and assigned to
the pilot group.
**Implement:** Add both apps for iOS/iPadOS and assign them to the pilot group.

## R7. App Protection (MAM) capability and approved apps
**Description:** App Protection Policies plus the approved managed apps (Outlook, Edge, Teams, Office).
**Why:** BYOD data protection lives in App Protection Policies applied to managed apps; without the
apps, BYOD users can't safely reach corporate data.
**Verify:** Intune → **Apps → App protection policies** can be created; the approved apps are deployed
or available.
**Implement:** Create App Protection Policies (Implementation §4) and make the approved apps available
to BYOD users via Company Portal / store.

## R8. Device compliance policy for corporate devices
**Description:** A compliance policy targeting corporate-owned devices.
**Why:** Conditional Access for COD grants access only to **compliant** devices; the policy defines
compliant.
**Verify:** Intune → **Devices → Compliance**; a policy exists and is assigned (scoped to Corporate).
**Implement:** Create a compliance policy (OS minimums, encryption, etc.) and target it with the
Corporate device filter (Implementation §5).

## R9. Device-ownership filters
**Description:** Intune **device filters** on `deviceOwnership` (Corporate / Personal).
**Why:** Filters are how one assignment to a user group applies the *right* policy to the *right*
device type — the mechanism that makes "one account, both devices" work cleanly.
**Verify:** Intune → **Tenant administration → Filters**; the `iPhone – Corporate` and `iPhone –
Personal` filters exist.
**Implement:** Create them in Implementation §5, or run the included
`IOSDD-Set-OwnershipBasedTargeting.ps1`.

## R10. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, app protection check-ins, and authentication depend on these.
**Verify:** From an iPhone, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

## R11. Apple MDM Push (APNs) certificate
**Description:** A valid **Apple MDM Push certificate (APNs)** in Intune.
**Why:** Every iOS enrollment — supervised corporate ADE *and* personal User Enrollment — and ongoing
MDM communication requires APNs.
**Verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate** shows **Active**
with a future expiration.
**Implement:** Create/renew it (Implementation §2) using a **company Apple ID** you reuse each year.

## R12. Apple Business Manager + ADE token
**Description:** An **Apple Business Manager** account with the corporate iPhones added, and an
**Automated Device Enrollment token** connected to Intune.
**Why:** Supervised, zero-touch corporate-iPhone enrollment depends on ABM holding the device serials
and a valid ADE token mapping them to the Intune MDM server.
**Verify:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens** shows a token with a
future expiration and the iPhone serials under **Devices**.
**Implement:** Connect ABM and upload the ADE token (Implementation §3); add device serials in ABM and
assign them to the Intune MDM server.

## R13. iOS Enterprise SSO extension capability
**Description:** The ability to deploy the **iOS Enterprise SSO extension** (Microsoft Entra ID
plug-in) via a Device features configuration profile.
**Why:** It delivers silent SSO to Safari and Entra apps on the corporate iPhone, brokered by
Authenticator — the SSO half of "one account, both iPhones."
**Verify:** Intune → **Devices → Configuration → Create → iOS/iPadOS → Templates → Device features**
exposes **Single sign-on app extension**.
**Implement:** Create the profile in Implementation §12 and ensure Authenticator (R6) is deployed.


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


# 3. Implementation — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**. The whole design assumes **one Entra identity per user**
who carries **two iPhones** — a **corporate iPhone (COD)** and a **personal iPhone (BYOD)** — so you
assign policies to the **user (group)** and let **ownership-based filters** route the right policy to
each iPhone. Pilot first: **Assess → Configure → Pilot → Validate → Expand.**

Consoles used:
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com`
- **Apple Business Manager (ABM)** — `https://business.apple.com`

> **Scope note (iOS iPhones):** the **corporate iPhone** is enrolled supervised via **Apple Business
> Manager + Automated Device Enrollment (ADE)** for full MDM. The **personal iPhone** is protected by
> **App Protection Policies (MAM)** — with **Account-Driven Apple User Enrollment** called out as an
> optional lightweight MDM path. **Single sign-on** across both iPhones is delivered by the **Microsoft
> Authenticator** broker plus the **iOS Enterprise SSO extension**, all under one Entra identity.

---

## Phase 1 — Identity, Apple connection & enrollment baseline

### Step 1. Confirm one identity and licensing per pilot user
1. Entra → **Users** → confirm each pilot user is a **single** account with an Intune + Entra ID P1
   license (Requirements R1–R3).
2. Entra → **Groups → New group** → **Security** → name it **`PILOT – iPhone COD-BYOD Users`** → add
   the pilot users. *(You assign every policy in this solution to this **user** group.)*

### Step 2. Create the Apple MDM Push (APNs) certificate
1. In Intune, go to **Devices → Enrollment → Apple → Apple MDM Push certificate**.
2. Check **I agree**, then **Download** the CSR file.
3. Click **Create your MDM push certificate** → `https://identity.apple.com`; sign in with a
   **company Apple ID** (record which Apple ID — you must reuse it every year).
4. **Create a Certificate**, upload the CSR, **Download** the `.pem`, then back in Intune enter that
   **Apple ID**, **Browse** to the `.pem`, and **Upload**.
5. Confirm the status shows **Active** with an expiration ~1 year out. *(Required for both
   corporate-iPhone MDM and personal-iPhone User Enrollment.)*

### Step 3. Connect Apple Business Manager for corporate iPhones (ADE token)
1. In Intune, go to **Devices → Enrollment → Apple → Enrollment program tokens → Add** → check
   **I agree** → **Download** the Intune **public key** (`.pem`).
2. In **ABM → Preferences → MDM Servers → Add**; name it **`Intune – iPhone COD`**; **Upload** the
   Intune public key; **Save**; **Download Token** (`.p7m`).
3. Back in Intune, enter the **Apple ID** used for ABM, **Browse** to the `.p7m`, **Upload**. The
   token appears under **Enrollment program tokens** with a future expiration.

### Step 4. Set enrollment restrictions for iPhone ownership types
1. **Devices → Enrollment → Enrollment device platform restrictions.**
2. Open the default (or create a pilot-scoped restriction **named `Enrollment Restriction – iPhone
   COD-BYOD – Pilot`**).
3. For **iOS/iPadOS**, set **Personal devices = Allow** *(so the user's personal iPhone may enroll for
   User Enrollment / register for App Protection)*.
4. Corporate iPhones are forced through ADE in the next phase, so they always tag **Corporate**.

---

## Phase 2 — Ownership-based targeting (the core of "one account, both iPhones")

### Step 5. Create device-ownership filters
1. **Tenant administration → Filters → Create.**
2. Filter 1: **name it `iPhone – Corporate`** — platform **iOS/iPadOS**; rule
   `(device.deviceOwnership -eq "Corporate")`.
3. Filter 2: **name it `iPhone – Personal`** — platform **iOS/iPadOS**; rule
   `(device.deviceOwnership -eq "Personal")`.
4. **Save** both.

> Prefer automation? Run **`IOSDD-Set-OwnershipBasedTargeting.ps1`** to create these filters (and
> optionally assign the policies below) via Microsoft Graph.

---

## Phase 3 — Corporate iPhone (COD): supervised ADE + full MDM

### Step 6. Create the iOS enrollment program profile (supervised)
1. In Intune, go to **Devices → Enrollment → Apple → Enrollment program tokens**, **open** your ADE
   token, then **Profiles → Create profile → iOS/iPadOS**; enter a name and description — **name it
   `iPhone ADE – COD – Pilot`**.
2. **User affinity** = **Enroll with user affinity** (required so the corporate iPhone ties to the
   user and can do SSO). Choose **Setup Assistant with modern authentication**.
3. **Management options:** enable **Supervised**; set **Locked enrollment = Yes** (prevents users
   removing management).
4. **Setup Assistant:** hide unnecessary panes (Restore, Apple ID, Siri, Privacy as policy dictates)
   for a clean first-run. **Review + Create.**

### Step 7. Assign devices and the profile (in ABM + Intune)
1. In **ABM → Devices**, select the corporate iPhone serial numbers → **Edit MDM Server** → choose
   **`Intune – iPhone COD`** → **Confirm**.
2. In Intune, on the token → **Devices**, click **Sync** (Apple rate-limits; allow a few minutes),
   then select the serials → **Assign profile** → **`iPhone ADE – COD – Pilot`**.

### Step 8. Create a compliance policy for corporate iPhones
1. **Devices → Compliance → Create policy → iOS/iPadOS**; **name it `iPhone – Compliance – COD –
   Pilot`**.
2. Set baseline rules (min iOS version, **require passcode**, jailbreak detection, etc.).
3. **Assignments:** assign to **`PILOT – iPhone COD-BYOD Users`**; under **Filter**, **Include** the
   **`iPhone – Corporate`** filter → **Create**.

### Step 9. Create a configuration profile for corporate iPhones
1. **Devices → Configuration → Create → New policy → iOS/iPadOS**; **name it `iPhone – Configuration
   – COD – Pilot`** (settings such as passcode, restrictions, Wi-Fi/VPN as needed).
2. **Assignments:** assign to **`PILOT – iPhone COD-BYOD Users`**, **Include** the **`iPhone –
   Corporate`** filter.

---

## Phase 4 — Personal iPhone (BYOD): App Protection (MAM)

### Step 10. Create the iOS App Protection Policy
1. **Apps → App protection policies → Create policy → iOS/iPadOS**; **name it `iPhone – App
   Protection – BYOD – Pilot`**.
2. **Apps:** select the approved managed apps (Outlook, Edge, Teams, Office, OneDrive, **Microsoft
   Authenticator**).
3. **Data protection:** block **backup**, restrict **cut/copy/paste** to managed apps, block **Save
   As** to personal locations, keep corporate data in managed apps.
4. **Access requirements:** require **PIN** / org credentials; set offline timeouts.
5. **Assignments:** assign to **`PILOT – iPhone COD-BYOD Users`**. *(App Protection is identity-based
   — it applies wherever the user signs into the managed app, so it targets the personal iPhone with
   no device enrollment.)*

### Step 11. Make the approved apps available to BYOD users
1. **Apps → iOS/iPadOS → Add** Outlook, Edge, Teams, Office, OneDrive, **Company Portal**, and
   **Microsoft Authenticator**.
2. Assign them **Available** to **`PILOT – iPhone COD-BYOD Users`** so users install them from the
   App Store / Company Portal.

> **Optional lightweight MDM for the personal iPhone:** if a personal iPhone must receive a few device
> settings, use **Account-Driven Apple User Enrollment** (Devices → Enrollment → Apple → enable
> **Account driven user enrollment**, **name the profile `iPhone – User Enrollment – BYOD – Pilot`**).
> It still tags **Personal** and is scoped by the **`iPhone – Personal`** filter, keeping personal data
> separate.

---

## Phase 5 — Single sign-on across the user's two iPhones

The goal: the user authenticates **once per iPhone**, then gets **silent SSO** to Microsoft 365 and
Entra apps on **both** iPhones with the same account. On iOS the **Microsoft Authenticator** app is
the identity broker, and the **iOS Enterprise SSO extension** extends that SSO to Safari and other
apps.

### Step 12. Deploy the iOS Enterprise SSO extension to the corporate iPhone
1. **Devices → Configuration → Create → New policy → iOS/iPadOS → Templates → Device features**;
   **name it `iPhone – Enterprise SSO – COD – Pilot`**.
2. Under **Single sign-on app extension**, set **SSO app extension type = Microsoft Entra ID**
   (Microsoft's Enterprise SSO plug-in, brokered by Authenticator).
3. Leave the Microsoft-managed defaults; under **App bundle IDs**, add Safari and any line-of-business
   apps that should get silent SSO.
4. **Assignments:** assign to **`PILOT – iPhone COD-BYOD Users`**, **Include** the **`iPhone –
   Corporate`** filter → **Create**.

### Step 13. Establish the Authenticator broker on the personal iPhone
1. On the personal iPhone, the user installs **Microsoft Authenticator** (it is the **identity
   broker** that App Protection onboarding registers).
2. The first sign-in to a managed app (Outlook/Edge/Teams) registers the account through the broker;
   afterward, **other approved apps get silent SSO** with the same account.
3. Do **not** require enrollment for SSO — the broker provides SSO while the personal iPhone stays
   BYOD (App Protection only).

### Step 14. Confirm the same identity owns both iPhones
1. Entra → **Devices** → filter by the pilot user: confirm the **same UPN** has the **corporate
   iPhone** (Entra-registered, supervised) **and** a **registered personal iPhone** under one identity.
2. The user should move between their two iPhones and into M365 apps **without re-entering
   credentials** beyond one sign-in per iPhone.

---

## Phase 6 — Unify access with Conditional Access

### Step 15. One Conditional Access policy for both iPhones
1. Entra → **Protection → Conditional Access → Create new policy**; **name it `CA – iPhone COD-BYOD
   Access`**.
2. **Users:** **`PILOT – iPhone COD-BYOD Users`**.
3. **Target resources:** Office 365 (and other corporate apps).
4. **Conditions → Device platforms:** **iOS**.
5. **Grant:** require **one of the following** — **Require device to be marked as compliant**
   *(satisfied by the corporate iPhone)* **and/or** **Require app protection policy** *(satisfied by
   the personal iPhone's managed app)*; set to **Require one of the selected controls**.
6. **Enable policy:** **Report-only** for the pilot → **Create**.

This single policy lets the **same account** reach corporate data from a **compliant corporate
iPhone** or an **app-protected personal iPhone**.

---

## Phase 7 — Pilot, validate, expand

### Step 16. Pilot with one user on two iPhones
1. **Erase** the pilot **corporate** iPhone (**Settings → General → Transfer or Reset → Erase All
   Content and Settings**) so it returns to Setup Assistant; enroll via ADE — it tags **Corporate**
   and receives compliance/config + the Enterprise SSO extension.
2. On the **personal** iPhone, install **Microsoft Authenticator**, then sign into **Outlook/Edge**
   with the **same account** → the App Protection policy applies (PIN prompt, managed-app containment).
3. Confirm the **same UPN** now owns both a Corporate and a Personal iPhone in Intune.

### Step 17. Validate
1. Run **`IOSDD-Discovery.ps1`** (tenant readiness: APNs, ADE token, filters, App Protection, CA) and
   **`IOSDD-Validation.ps1 -User <upn>`**: confirm the user has **one Corporate iPhone** (compliant,
   supervised) and **one Personal iPhone** (app protection applied), under a single identity.
2. Confirm the **`iPhone – Corporate`** filter applied device policy and the **`iPhone – Personal`**
   filter did not (and vice-versa for app protection).
3. **Verify single sign-on:** on the corporate iPhone open a Microsoft 365 web app in **Safari** and
   confirm **silent SSO** (no password prompt — the Enterprise SSO extension at work); on the personal
   iPhone, after the first managed-app sign-in, a second approved app (e.g. Teams) opens **without** a
   fresh password — silent SSO on both iPhones for the one account.
4. Review Conditional Access **report-only** results for the pilot user.

### Step 18. Expand
1. When the pilot passes, widen the assignments from the pilot group to broader user groups (or make
   **`iPhone ADE – COD – Pilot`** the default profile for the ADE token).
2. Move **`CA – iPhone COD-BYOD Access`** from **report-only** to **On**.
3. Roll out in waves, validating each wave with the scripts before widening.


---


# 5. Testing & Validation — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

Validate against a **pilot user with two iPhones** (one corporate, one personal) before expanding.
Each test has an explicit **pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph)
for tenant-side checks and the on-device steps for the user experience.

## Test 1 — Tenant readiness
**Procedure:** Run `IOSDD-Discovery.ps1`.
**Pass:** The APNs certificate is **Active**, the ADE token is present, enrollment restrictions allow
the intended Personal/Corporate split, an App Protection policy exists, a compliance policy exists,
the `iPhone – Corporate`/`iPhone – Personal` **device filters** exist, Authenticator + Company Portal
are assigned, and a Conditional Access policy is present.
**Fail:** Any missing → resolve before piloting.

## Test 2 — Single identity, two iPhones
**Procedure:** Run `IOSDD-Validation.ps1 -User <upn>` for the pilot user.
**Pass:** The **same UPN** owns at least one **Corporate** iPhone and one **Personal** iPhone.
**Fail:** Devices split across different accounts → consolidate identity (Requirements R1).

## Test 3 — Corporate iPhone gets full MDM
**Procedure:** Inspect the pilot **corporate** iPhone in Intune.
**Pass:** Ownership = **Corporate**, **Supervised = Yes**; the **`iPhone – Compliance – COD – Pilot`**
and **`iPhone – Configuration – COD – Pilot`** policies (Corporate filter) are **applied**; device
reports **Compliant**.
**Fail:** Policies not applied → confirm the iPhone is tagged Corporate via ADE (R5) and the
`iPhone – Corporate` filter is set on the assignment (Implementation §§5, 8–9).

## Test 4 — Personal iPhone gets App Protection only
**Procedure:** On the pilot **personal** iPhone, sign into Outlook/Edge with the pilot account.
**Pass:** The `iPhone – App Protection – BYOD – Pilot` policy applies — **PIN prompt**, corporate data
confined to managed apps, **Save As**/paste to personal locations blocked. The iPhone is **not** fully
enrolled (or, if User-Enrolled, is tagged **Personal** and does **not** receive Corporate device
policies).
**Fail:** No PIN/containment → confirm the app is approved/managed and the App Protection policy is
assigned to the user (Implementation §10).

## Test 5 — Ownership filters route correctly
**Procedure:** Compare policy application across the two iPhones.
**Pass:** The **Corporate** iPhone receives device compliance/config and **not** the BYOD-only items;
the **Personal** iPhone receives app protection and **not** corporate device policies.
**Fail:** Cross-application → re-check the `deviceOwnership` filter rules and the Include/Exclude on
each assignment (Implementation §5).

## Test 6 — Single sign-on across both iPhones
**Procedure:** On the **corporate** iPhone, open a Microsoft 365 web app in **Safari**; on the
**personal** iPhone, after the first managed-app sign-in, open a second approved app (e.g. Teams).
**Pass:** The corporate iPhone gets **silent SSO** (no password prompt — the iOS Enterprise SSO
extension at work); the personal iPhone's second app opens **without** a fresh password (the
Authenticator broker at work) — one account, silent SSO on both.
**Fail:** Repeated prompts → confirm Microsoft Authenticator is installed on both iPhones and the
`iPhone – Enterprise SSO – COD – Pilot` profile is applied to the corporate iPhone (Implementation
§§12–13).

## Test 7 — One account reaches work from both iPhones
**Procedure:** With Conditional Access **report-only**, access a corporate web app from the corporate
iPhone and a managed app from the personal iPhone, signed in as the same user.
**Pass:** Both succeed — the corporate iPhone satisfies **compliant device**; the personal iPhone
satisfies **app protection policy** — under the **single** CA policy.
**Fail:** One path blocked → review CA grant controls ("require one of"), compliance state, and app
protection assignment (Implementation §15).

## Test 8 — Unmanaged path is blocked (data protection holds)
**Procedure:** On the personal iPhone, try to open corporate mail in the **built-in** (unmanaged) Mail
app or paste corporate data into a personal app.
**Pass:** Corporate data is **not** accessible in unmanaged apps; paste/Save-As to personal locations
is blocked.
**Fail:** Corporate data leaks to unmanaged apps → tighten App Protection data-relocation settings.

## Test 9 — Compliance & enforcement
**Procedure:** Review compliance for the corporate iPhone and the report-only CA results for the user.
**Pass:** Corporate iPhone **Compliant**; CA evaluates the user correctly from both iPhones.
**Fail:** Non-compliant or CA misfires → review the compliance policy and CA conditions.

## Acceptance gate
Proceed to **Expand** only when Tests 1–9 pass for a pilot user who has **both** a corporate and a
personal iPhone signed in with the **same account**, single sign-on works on both (Test 6), and the
data-protection checks (Test 8) hold.


---


# 6. Troubleshooting — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

Work top-down: confirm the **identity** (one account), then **ownership** (Corporate vs Personal),
then **targeting** (filters/assignments), then **SSO**, then **access** (Conditional Access). Most
issues are an iPhone tagged with the wrong ownership, a missing filter on an assignment, a BYOD user
not using a managed app, or Microsoft Authenticator not installed.

## A user's two iPhones show under different accounts
- **Duplicate identities.** Consolidate to one Entra account; the user must sign in with the same UPN
  on both iPhones (Requirements R1). Re-enroll/re-register the stray iPhone under the correct account.

## A corporate iPhone is tagged Personal (or vice-versa)
- **Wrong ownership.** Intune → **Devices → (device) → Properties → Device ownership** → set
  **Corporate**/**Personal**. For the corporate iPhone, enroll it via **ABM + ADE** so it tags
  Corporate (and supervised) automatically (R5/R12).
- After fixing, the iPhone picks up the correct filtered policies on next sync.

## Corporate policies are not applying to the corporate iPhone
- **Filter mismatch.** The compliance/config assignment must **Include** the **`iPhone – Corporate`**
  filter and target the **user** group (Implementation §§8–9). Verify the filter rule is
  `(device.deviceOwnership -eq "Corporate")`.
- **Device not compliant/enrolled.** Confirm the iPhone is enrolled (supervised, ADE) and checking in.

## App Protection isn't applying to the personal iPhone
- **User not in scope.** App Protection assigns to the **user** group — confirm the pilot user is a
  member (Implementation §10).
- **App not managed/approved.** The user must use an **approved managed app** (Outlook, Edge, Teams).
  The built-in Mail/Safari apps are intentionally excluded.
- **No Intune/MAM license** on the user (R2).
- App Protection applies on **next app launch / token refresh** — close and reopen the managed app.

## Personal iPhone user can't access corporate mail/data
- **By design in an unmanaged app.** They must use the managed app (e.g. Outlook), not the built-in
  one. Deploy and direct them to the approved apps (Implementation §11).
- **Conditional Access blocking.** If CA requires app protection, accessing from a non-managed app is
  blocked — expected. Check Entra → **Sign-in logs** for the CA result.

## Single sign-on keeps prompting for a password
- **Authenticator missing.** Microsoft Authenticator is the iOS identity broker — it must be installed
  on **both** iPhones (R6). On the personal iPhone, sign into one managed app first to register it.
- **Enterprise SSO extension not applied.** On the corporate iPhone, confirm the
  `iPhone – Enterprise SSO – COD – Pilot` profile shows **Succeeded** (Intune → Devices → (device) →
  Device configuration) and that Safari/the target app's bundle ID is listed (Implementation §12).
- **App not Entra-integrated.** Silent SSO applies to Entra-integrated apps; a non-Entra app will
  still prompt.

## One account works on the corporate iPhone but not the personal one (or vice-versa)
- **CA grant too strict.** The Conditional Access policy must **require *one of*** compliant device
  **or** app protection — not **both** (Implementation §15). "Require all" blocks one of the two paths.
- **App protection not yet registered** on the personal iPhone — open a managed app and complete the
  PIN setup.

## Personal iPhone received corporate **device** policies (over-management)
- The personal iPhone was **fully enrolled** and/or tagged **Corporate**. Confirm enrollment
  restrictions and ownership (R4–R5); for BYOD, prefer **App Protection without enrollment**. If
  Account-Driven User Enrollment is intended, ensure it's tagged **Personal** so the `iPhone – Personal`
  filter excludes corporate policies.

## Corporate iPhone won't enroll via ADE
- **APNs/ADE token lapsed.** Renew the **Apple MDM Push certificate** (R11) and the **ADE token** (R12)
  — an expired token blocks all iOS enrollment.
- **Serial not assigned.** Confirm the iPhone serial is in ABM and assigned to the `Intune – iPhone COD`
  MDM server, and the `iPhone ADE – COD – Pilot` profile is assigned (Implementation §§3, 7).

## Conditional Access has unexpected effects
- Keep the pilot policy in **report-only** and read Entra → **Sign-in logs → Conditional Access** to
  see exactly which control was/wasn't satisfied before turning it **On**.

## Useful checkpoints
- **Intune:** Devices → (device) → **Properties** (ownership), **Compliance**, **Configuration**;
  Apps → **App protection policies → (policy) → Monitor** for per-user status; Tenant administration →
  **Filters**; Devices → Enrollment → Apple for APNs/ADE token status.
- **Entra:** **Sign-in logs → Conditional Access** tab for grant evaluation.
- **Scripts:** re-run `IOSDD-Validation.ps1 -User <upn>` after each change to confirm the gate.


---


# 7. Best Practices — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

Field-proven guidance to keep one identity working cleanly across both device types.

## Identity & assignment model
- **Assign policies to user groups, scope with device filters.** This is the heart of the design:
  one assignment to the user, the right policy follows the device's ownership. Avoid mixing
  per-device group assignments that fight the filters.
- **Keep one Entra identity per user.** Never create a separate "BYOD account" — it splits policy and
  breaks Conditional Access logic.
- **Name groups and filters by intent** (e.g. *PILOT – iPhone COD-BYOD Users*, *iPhone – Corporate*,
  *iPhone – Personal*) so assignments are self-documenting.

## Ownership hygiene
- **Make ownership deterministic.** Enroll the corporate iPhone through **ABM + ADE** so it tags
  **Corporate** automatically; let the personal iPhone default to **Personal**.
- **Audit ownership regularly** with `IOSDD-DeviceReport.ps1` — a device tagged the wrong way gets
  the wrong policy set.

## BYOD data protection
- **Prefer App Protection (MAM) without enrollment for BYOD.** It protects corporate data without
  managing the employee's personal device — better adoption, less privacy friction, strong
  data-leak controls.
- **Lock the data boundary:** block backup, restrict cut/copy/paste and "Save As" to managed apps,
  require a PIN, and enforce encryption within managed apps.
- **Only enroll the personal iPhone (Account-Driven User Enrollment) when you truly need device
  settings** — and keep it tagged **Personal** so it never receives corporate device policies.

## Corporate iPhone management
- **Apply a real compliance baseline** (min iOS version, passcode, jailbreak detection) and gate
  access on it via Conditional Access.
- **Use Apple Business Manager + ADE** for hands-off, supervised corporate-iPhone provisioning, and
  **renew the APNs and ADE tokens** before they expire (a lapse blocks all iOS enrollment).

## Conditional Access
- **One policy, "require one of."** Grant access when the request is from a **compliant** device
  **or** an **app-protection-protected** app — never require both, or you lock out one device type.
- **Always start report-only.** Read the sign-in logs for the pilot user before enforcing.
- **Add MFA** as part of the same access story for a complete Zero Trust posture.

## Rollout discipline
- **Pilot one user with two real devices** (a corporate and a personal one) — it's the only way to
  prove the single-identity experience end to end.
- **Expand in waves**, validating each with `IOSDD-Validation.ps1` before widening.
- **Communicate the BYOD deal to employees:** what IT can and cannot see/do on a personal device
  under App Protection (data containment, *not* device surveillance) — clarity drives adoption.

## Operations & documentation
- **Keep a runbook** of the pilot/production groups, the two ownership filters, the compliance and
  app-protection policies, and the Conditional Access policy — the moving parts that define the model.
- **Report monthly** with `IOSDD-DeviceReport.ps1`: device counts by ownership, users who have both
  a COD and a BYOD device, compliance, and app-protection coverage.


---


# 8. Deliverables Summary — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — the two ownership models, the single-identity design, management models,
  benefits, and honest limitations.
- **Requirements Guide** — every prerequisite (one identity, MDM+MAM licensing, Entra ID P1,
  enrollment restrictions, corporate tagging, Company Portal, App Protection, compliance, ownership
  filters, network) with how to **verify** and how to **implement if missing**, plus the category-level
  Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across seven phases: identity, Apple
  connection & enrollment baseline, ownership-based targeting, corporate-iPhone supervised ADE full-MDM,
  personal-iPhone App Protection, single sign-on across both iPhones, unifying access with Conditional
  Access, then pilot/validate/expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates and an acceptance gate, proving
  one account works on both a corporate and a personal device.
- **Troubleshooting** — top-down diagnosis for identity, ownership, targeting, and access failures.
- **Best Practices** — the assign-to-user/scope-by-filter model, ownership hygiene, BYOD data
  protection, COD management, Conditional Access, and rollout discipline.

## PowerShell scripts (Microsoft Graph) — `IOSDD-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**.

1. **`IOSDD-Discovery.ps1`** — tenant readiness: enrollment restrictions (personal allowed?),
   compliance policies, App Protection policies, Corporate/Personal device filters, Company Portal,
   and Conditional Access presence.
2. **`IOSDD-Validation.ps1`** — for a given user, confirms a single identity owns both a **Corporate**
   device (compliant) and a **Personal** device (app protection applied), with a PASS/FAIL summary.
3. **`IOSDD-DeviceReport.ps1`** — tenant-wide CSV: devices by **ownership**, platform, enrollment
   type, compliance, and primary user — plus a list of users who have **both** a COD and a BYOD device.
4. **`IOSDD-Remediation.ps1`** — safe remediation: set device **ownership**, re-assign policies to the
   target group, and flag enrollment-restriction/filter misconfigurations. Read-only by default;
   changes require an explicit confirmation switch.
5. **`IOSDD-Set-OwnershipBasedTargeting.ps1`** — creates the **`iPhone – Corporate`** and **`iPhone –
   Personal`** `deviceOwnership` filters (and optionally assigns the compliance/app-protection policies
   with those filters) — the mechanism that makes one account work cleanly across both iPhones.

## Hero image
- **`IOSDD-hero.png`** — the branded product image (1200×1200) used on the marketplace listing.

## How it's delivered
A branded **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts
appendix), plus all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across
**unlimited devices**.
