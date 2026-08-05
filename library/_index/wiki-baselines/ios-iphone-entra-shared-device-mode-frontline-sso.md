# iOS iPhone Entra ID Shared Device Mode — Frontline SSO with Global Sign-In & Single Sign-Out (Teams & MSAL Apps)

> **Version 1.0.0** · Category: Intune · Solution code: IOSSDMFL

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — iOS iPhone Entra ID Shared Device Mode (Frontline SSO)

Frontline teams share iPhones — a pool of shift phones any authorized worker can pick up — but a
shared phone with a single shared account, or a kiosk lockdown, gives **no one a private session**:
the previous worker's cached mail, chats, and tokens survive the next sign-in. This solution
configures **Microsoft Entra ID Shared Device Mode (SDM)** on those shared iPhones so each worker gets
a **real per-user identity session**: **sign in once** as yourself, and **sign out once** to **clear
your identity and app data from every supporting app** for the next person — **global sign-in and
single sign-out** across **Microsoft Teams** and MSAL-based line-of-business apps.

**The Microsoft-native answer for shared *iPhones*.** Apple's own multi-user technology, Shared iPad,
runs **only on iPad hardware** — it cannot help an iPhone fleet. Entra Shared Device Mode is the way to
give pooled iPhones a genuine per-user sign-in/sign-out experience within the Microsoft identity
stack.

**A distinct, honest scope.** This is per-user shared identity — not single-user SSO, not single-app
kiosk lockdown, not Apple Shared iPad. The package is explicit about what SDM isolates: it clears the
**Entra session and the data inside SDM-aware apps** on global sign-out; it does **not** partition the
whole OS, so app scope becomes the security boundary — only SDM-aware apps belong on a shared iPhone.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **No-affinity foundation, done right.** Shared iPhones enroll **without user affinity** via ABM/ADE
  into an **Assigned** device group whose owner is the **Intune Provisioning Client** — the specific
  detail that makes enrollment-time grouping actually populate (a common, silent failure when missed).
- **Shared-mode registration.** Each device is registered into Shared Device Mode through **Microsoft
  Authenticator** by a least-privilege **Cloud Device Administrator** account.
- **Proven hand-off.** The acceptance test is unambiguous: user A signs out, user B signs in **clean**,
  with no trace of A — validated on a real device with two real users.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click Intune/Entra steps, a requirements guide that tells you how to
verify *and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and
testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** pooled iPhones your frontline can share safely — each worker signed in as themselves,
each sign-out a clean hand-off — deployed and proven on a pilot before you scale, without a consulting
engagement.


---


# 1. Solution Overview — iOS iPhone Entra ID Shared Device Mode (Frontline SSO)

## What this solution is
This solution configures **Microsoft Entra ID Shared Device Mode (SDM)** on **pooled, shared
iPhones** managed by **Microsoft Intune**, so a frontline worker can walk up to any shift phone,
**sign in once**, use their Microsoft apps as themselves, and **sign out once** at end of shift —
which **clears their identity and app data from every supporting app on the device** for the next
person. It is the identity-session model for shared iPhones: **global sign-in** and **single (global)
sign-out** across apps that support SDM (notably **Microsoft Teams** and MSAL-based line-of-business
apps).

The devices are enrolled **without user affinity** (no single owner), registered into **shared
device mode** through the **Microsoft Authenticator** app, and handed between staff freely. Each
person gets their **own** Entra sign-in on the shared hardware — not a generic shared account.

> **This is not kiosk lockdown, and not a shared service account.** Restricting a phone to one app
> (kiosk/lockdown) or signing everyone in with one shared mailbox does **not** give each worker a
> private session — cached tokens and data from the previous user survive an app sign-out on a
> single-user device. Shared Device Mode exists precisely to solve that: it gives the device a
> **per-user identity session** that global sign-out tears down. (For single-purpose kiosk phones,
> see the separate *iOS iPhone Shared Device Mode (Lockdown) with WebEx* and *iOS Lock-Down Profile*
> solutions — those are a different job.)

## Why iPhones specifically need this
Apple's own multi-user technology — **Shared iPad** with Managed Apple IDs — **only runs on iPad
hardware; it is not available on iPhone.** So for **shared iPhones**, there is no OS-level Apple
multi-user mode to fall back on. **Entra ID Shared Device Mode is the primary way to give shared
iPhones a real per-user sign-in/sign-out experience** within the Microsoft identity stack. (If your
fleet is iPads and you want Apple's OS-level partitioning, use the *Shared iPad for Frontline Teams*
solution instead; if it's iPhones, this is the one.)

## How Shared Device Mode works (the moving pieces)
1. **No-affinity enrollment.** The iPhone is enrolled via **Apple Business Manager + Automated Device
   Enrollment (ADE)** with an enrollment profile set to **enroll without user affinity** — the device
   belongs to the organization, not a person.
2. **Shared-mode registration (the Authenticator step).** The device is registered into **shared
   device mode** through **Microsoft Authenticator**. The account that performs this registration must
   hold the Entra **Cloud Device Administrator** role. Registration is a one-time provisioning action
   at device setup; afterward the device advertises itself as *shared* to apps that support SDM.
3. **SDM-aware apps.** Apps built on the **Microsoft Authentication Library (MSAL)** that opt into SDM
   — first and foremost **Microsoft Teams** for iOS — detect shared mode and switch to the
   global-sign-in / global-sign-out model. A worker signs into Teams; other SDM apps recognize the
   signed-in user; signing out of one signs out of all and clears their data.
4. **Intune delivers everything.** Intune enrolls the device (no affinity), deploys **Microsoft
   Authenticator** and the SDM apps (Teams, your MSAL LOB apps), applies device configuration and
   compliance, and (optionally) a light restriction profile — all targeted at an **assigned device
   group** the shared iPhones land in at enrollment.

## Global sign-in / single sign-out — what actually happens
- **Sign-in:** the worker opens Teams (or another SDM app), signs in with their Entra credentials and
  MFA. That identity becomes the device's **current shared-mode user**; other SDM apps pick it up
  without a second sign-in.
- **Sign-out:** the worker taps sign-out once. SDM performs a **global sign-out** — every SDM app
  drops the session and **clears that user's cached data and tokens** from the device, returning the
  phone to a clean state for the next person.

## What SDM isolates (stated honestly)
- **It isolates the Entra identity session and the data inside SDM-aware apps.** Global sign-out
  clears tokens and app data for SDM apps (Teams and MSAL apps that implement SDM).
- **It does not partition the entire iOS operating system** the way Apple Shared iPad does. Apps that
  are **not** SDM-aware do not participate in global sign-out; treat them accordingly (don't put
  personal-data-caching non-SDM apps on a shared iPhone, or restrict them). Combine SDM with a
  sensible restriction profile so only appropriate apps are present.
- **App support is narrower on iOS than on Android.** On Android, Managed Home Screen and a broad set
  of apps support SDM; on iOS the anchor is **Teams**, plus MSAL LOB apps that explicitly implement
  SDM. **Verify SDM support for each app you intend to deploy** rather than assuming — confirm against
  current Microsoft documentation for your tenant.

## Benefits
- **A real per-user session on shared iPhones** — each worker signs in as themselves; single sign-out
  wipes their session and app data for the next person.
- **The Microsoft-native answer for shared *iPhones*** — where Apple Shared iPad (iPad-only) cannot
  help.
- **Frontline-fit** — fast hand-off, no personal enrollment, no per-device user assignment.
- **Central management** — enrollment, apps, compliance, and restrictions all driven from Intune
  against one assigned device group.
- **Conditional Access aware** — the signed-in user's session supports Entra device/compliance
  policies for the SDM apps.

## Limitations (be honest with buyers)
- **iPhone / no-affinity only.** Targets shared iPhones enrolled without user affinity; it is not for
  single-user corporate phones (see the *Enterprise SSO app extension* solution for those).
- **App coverage is the gating factor.** Only SDM-aware apps (Teams + MSAL apps that implement SDM)
  get global sign-in/out; verify each app.
- **Requires Microsoft Authenticator** for shared-mode registration and the **Cloud Device
  Administrator** role for the registering account.
- **Not full OS multi-user.** SDM is an identity/app-data model, not an Apple OS partition; pair it
  with restrictions.
- Requires **Microsoft Entra ID**, supported iOS, and outbound access to Entra login endpoints.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Shared iPhones are enrolled without user affinity via ABM/ADE into an assigned device group,
> registered into Entra Shared Device Mode through Microsoft Authenticator, and given the SDM apps
> (Teams + MSAL LOB) so frontline workers get global sign-in and single sign-out — deployed
> pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — iOS iPhone Entra ID Shared Device Mode (Frontline SSO)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to Entra **Shared
Device Mode** on shared iPhones.

## R1. Apple Business Manager (ABM) with an ADE (MDM server) token in Intune
**Description:** ABM is set up and linked to Intune with an Automated Device Enrollment token, and the
shared iPhones are assigned to that MDM server in ABM.
**Why:** Shared iPhones must be **supervised** and enrolled **without user affinity** via ADE; that
requires an ABM↔Intune ADE token and the devices assigned to Intune in ABM.
**Verify:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens**; a token exists and
shows your shared iPhones as assigned devices.
**Implement:** Create/renew the ADE token (Intune → **Devices → Enrollment → Apple → Enrollment
program tokens → Add**), upload it to ABM, and assign the device serial numbers to the Intune MDM
server in ABM.

## R2. ADE enrollment profile set to "Enroll without User Affinity"
**Description:** An iOS/iPadOS ADE enrollment profile that enrolls the device **supervised** and
**without user affinity**.
**Why:** Shared devices must not bind to a single user; user affinity would defeat the shared model.
**Why it matters for SDM:** the shared, no-owner enrollment is what lets Shared Device Mode manage the
identity per-session rather than per-device.
**Verify:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens → (open your token) →
Profiles**; the profile shows **User Affinity = Enroll without User Affinity** and **Supervised = Yes**.
**Implement:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens → (open the token) →
Profiles → Create profile → iOS/iPadOS**, name it **iPhone SDM – ADE Profile**, set **User Affinity =
Enroll without User Affinity**, **Supervised**, and assign it to your shared devices.

## R3. Assigned device group for the shared iPhones (with the Intune Provisioning Client as OWNER)
**Description:** A Microsoft Entra **security group of type Assigned** (not Dynamic) that the shared
iPhones land in at enrollment, and on which the **Intune Provisioning Client** service principal is an
**Owner**.
**Why:** No-affinity ADE / shared devices have no user to drive dynamic membership, so enrollment-time
device grouping uses an **Assigned** group whose **owner** is the first-party **Intune Provisioning
Client** (AppId `f1346770-5b25-470b-88bd-d5744ab7952c`, often shown as *Intune Autopilot
ConfidentialClient* / *Intune Provisioning Client*). Without that owner, the group stays **empty at
enrollment** and nothing (apps, config, restrictions) deploys.
**Verify:** Entra → **Groups → (the group) → Owners**; the Intune Provisioning Client appears (search
by **AppId**, since the display name varies). Group **Membership type = Assigned**.
**Implement:** Entra → **Groups → New group → Security**, **Membership type = Assigned**, name it
**iPhone SDM – Devices**. Then **Owners → Add owners →** search the **AppId**
`f1346770-5b25-470b-88bd-d5744ab7952c` and add it. (If the SP is absent, open the Intune portal once
as Global Administrator to provision it.) The included `IOSSDMFL-Remediation.ps1` can set this owner
for you.

## R4. Microsoft Authenticator app (shared-mode registration host)
**Description:** The **Microsoft Authenticator** app deployed to the shared iPhones.
**Why:** On iOS, a device is registered into **Shared Device Mode** through **Microsoft
Authenticator**; it is also the identity broker for the SDM apps.
**Verify:** Intune → **Apps → iOS/iPadOS**; **Microsoft Authenticator** (publisher **Microsoft
Corporation**, bundle ID `com.microsoft.azureauthenticator`) is added and assigned **Required** to the
**iPhone SDM – Devices** group.
**Implement:** Intune → **Apps → iOS/iPadOS → Add → iOS store app**; add **Microsoft Authenticator**,
assign **Required** to **iPhone SDM – Devices**.

## R5. Cloud Device Administrator role for the registering account
**Description:** The account used to register each device into shared mode holds the Entra **Cloud
Device Administrator** role.
**Why:** Registering a device into Shared Device Mode requires this role; a standard user cannot
complete the shared-mode registration.
**Verify:** Entra → **Roles and administrators → Cloud Device Administrator**; the provisioning account
is a member.
**Implement:** Entra → **Roles and administrators → Cloud Device Administrator → Add assignments**; add
the provisioning account. Use a dedicated, least-privilege provisioning account.

## R6. Microsoft Teams and any SDM-aware LOB apps
**Description:** **Microsoft Teams** for iOS (the anchor SDM app) and any line-of-business apps that
explicitly support Shared Device Mode, deployed to the shared iPhones.
**Why:** Only SDM-aware apps deliver global sign-in / single sign-out. Teams is the primary iOS SDM
app; LOB apps must be built on MSAL and opt into SDM.
**Verify:** Intune → **Apps → iOS/iPadOS**; **Microsoft Teams** (publisher **Microsoft Corporation**,
bundle ID `com.microsoft.skype.teams`) is added/assigned; for each LOB app, confirm SDM support with
the app vendor.
**Implement:** Add **Microsoft Teams** (Required) to **iPhone SDM – Devices**. For LOB apps, confirm
SDM support (verify against current Microsoft docs and the app vendor) before relying on global
sign-out for them.

## R7. Supported iOS/iPadOS version
**Description:** A current, supported iOS/iPadOS release on the shared iPhones.
**Why:** Shared Device Mode and the SDM apps require a supported iOS; older releases may lack SDM
behavior.
**Verify:** On the device, **Settings → General → About**; or Intune → device → **Hardware**.
**Implement:** Update the devices, or stage a **minimum-OS compliance policy** so out-of-date phones
are flagged before they enter the pool.

## R8. Network access to Microsoft Entra login endpoints
**Description:** Outbound HTTPS to the Entra sign-in endpoints for your cloud.
**Why:** Registration, sign-in, and global sign-out complete against these endpoints.
**Verify:** From the device network, reach `https://login.microsoftonline.com` (commercial) or the
sovereign equivalent (`login.microsoftonline.us`, `login.partner.microsoftonline.cn`).
**Implement:** Allow Microsoft's published Entra/Office 365 URLs through proxy/firewall; do **not**
TLS-inspect the Microsoft login endpoints.

## R9. Restriction / configuration profile for the shared pool (recommended)
**Description:** A light **device restrictions** profile scoped to **iPhone SDM – Devices** that keeps
the shared phones limited to appropriate apps/functions.
**Why:** SDM isolates SDM-app data but does **not** partition the whole OS; restrictions keep non-SDM
apps and personal-data surfaces off the shared pool.
**Verify:** Intune → **Devices → Configuration**; a restrictions profile named **iPhone SDM –
Restrictions** is assigned to the group.
**Implement:** Intune → **Devices → Configuration → Create → iOS/iPadOS → Templates → Device
restrictions**, name it **iPhone SDM – Restrictions**, limit apps/functions to what the role needs,
assign to **iPhone SDM – Devices**.

## R10. Pilot user(s) and pilot iPhone
**Description:** At least two pilot frontline users with licensed Entra identities and one enrolled
shared pilot iPhone.
**Why:** The core value — one user signs in, signs out, a **second** user signs in clean — must be
validated with two identities on the same device.
**Verify:** Both pilot users can sign in to Teams; the pilot iPhone is in **iPhone SDM – Devices** and
registered into shared mode.
**Implement:** Add the pilot users to the **pilot security group** (Global Requirement G5) and the
pilot iPhone to **iPhone SDM – Devices**.


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


# 3. Implementation — iOS iPhone Entra ID Shared Device Mode (Frontline SSO)

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against
a small **pilot pool** first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and the
Entra admin center at `https://entra.microsoft.com` unless noted.

> **This configures shared-identity (Shared Device Mode) on no-affinity iPhones.** It is not
> single-user SSO and not single-app kiosk lockdown. Every device here is enrolled **without user
> affinity**.

---

## Phase 1 — Build the shared-device foundation

### Step 1. Create the assigned device group (and set the Provisioning Client as owner)
1. Go to **Entra → Groups → New group**.
2. **Group type = Security**; **Membership type = Assigned** (not Dynamic); **Name:**
   **iPhone SDM – Devices**. **Create**.
3. Open **iPhone SDM – Devices → Owners → Add owners**. Search by **Application ID**
   `f1346770-5b25-470b-88bd-d5744ab7952c` (the **Intune Provisioning Client**; the display name
   varies — search by the AppId, not the name) and **add it as an owner**.
   - *Why:* no-affinity/shared devices are placed into an **assigned** group at enrollment by this
     service principal; if it is not an owner, the group stays empty and nothing deploys.
   - *Shortcut:* `IOSSDMFL-Remediation.ps1` can create the group and set this owner for you.

### Step 2. Create the ADE enrollment profile (no user affinity)
1. Go to **Devices → Enrollment → Apple → Enrollment program tokens**, and **open your ADE token**.
2. Select the **Profiles** tab → **Create profile → iOS/iPadOS**.
3. **Name:** **iPhone SDM – ADE Profile**. Set **User Affinity = Enroll without User Affinity** and
   **Supervised = Yes**. Complete the wizard and **Create**.
4. Back on the token, assign **iPhone SDM – ADE Profile** to your shared iPhone serial numbers
   (**Devices** tab → select devices → **Assign profile**).

### Step 3. Deploy Microsoft Authenticator and Teams to the pool
1. Go to **Apps → iOS/iPadOS → Add → iOS store app**.
2. Add **Microsoft Authenticator** — publisher **Microsoft Corporation**, bundle ID
   `com.microsoft.azureauthenticator`. Assign **Required** to **iPhone SDM – Devices**.
3. Add **Microsoft Teams** — publisher **Microsoft Corporation**, bundle ID
   `com.microsoft.skype.teams` (*not* "Teams" by another publisher). Assign **Required** to
   **iPhone SDM – Devices**.
4. *(Optional)* Add any **SDM-aware LOB apps** (confirmed with the vendor) the same way.

### Step 4. Add a restriction profile for the shared pool
1. Go to **Devices → Configuration → Create → New policy**; **Platform = iOS/iPadOS**;
   **Profile type = Templates → Device restrictions → Create**.
2. **Name:** **iPhone SDM – Restrictions**. Limit apps/functions to what the frontline role needs
   (SDM isolates SDM-app data, not the whole OS — keep non-SDM, personal-data apps off the pool).
3. **Assignments:** **iPhone SDM – Devices**. **Review + create → Create**.

### Step 5. Grant the provisioning account the Cloud Device Administrator role
1. Go to **Entra → Roles and administrators → Cloud Device Administrator → Add assignments**.
2. Add the dedicated **provisioning account** you will use to register devices into shared mode.

---

## Phase 2 — Enroll and register a pilot iPhone into Shared Device Mode

### Step 6. Enroll the pilot iPhone (no affinity)
1. Wipe/prepare the pilot iPhone and start setup; because its serial is assigned the
   **iPhone SDM – ADE Profile**, it enrolls **supervised, without user affinity**.
2. Confirm the device appears in **Devices → iOS/iPadOS** as **corporate / no primary user**, and that
   it landed in **iPhone SDM – Devices** (Entra → Groups → members).

### Step 7. Register the device into Shared Device Mode (the Authenticator step)
1. On the pilot iPhone, open **Microsoft Authenticator** (deployed in Step 3).
2. Sign in with the **provisioning account** (the Cloud Device Administrator from Step 5) and complete
   the **shared device registration** prompt to mark this device as a **shared device**.
3. The device now advertises **shared mode** to SDM-aware apps. This is a one-time provisioning action
   per device.

---

## Phase 3 — Pilot the global sign-in / single sign-out experience

### Step 8. First user signs in
1. On the pilot iPhone, open **Microsoft Teams**. Confirm Teams shows the **shared-device** sign-in
   experience.
2. Sign in as **pilot user A** (Entra credentials + MFA). Confirm A is signed in to Teams and any
   other SDM apps recognize A without a second sign-in.

### Step 9. Single (global) sign-out
1. As pilot user A, perform **sign out** in Teams.
2. Confirm this triggers a **global sign-out** — A is signed out of all SDM apps and A's cached data
   is cleared from the device.

### Step 10. Second user signs in clean
1. Open Teams again and sign in as **pilot user B**.
2. Confirm **no trace of user A** — B sees only their own chats/data; A's session and data are gone.
   This is the core acceptance behavior.

---

## Phase 4 — Validate and expand

### Step 11. Validate with the scripts
1. Run **`IOSSDMFL-Discovery.ps1`** (tenant readiness: no-affinity ADE profile, Authenticator + Teams
   assigned, assigned group with the Provisioning Client owner, Cloud Device Administrator present).
2. Run **`IOSSDMFL-Validation.ps1`** to confirm the assigned group ownership, ADE profile affinity,
   and app assignments are correct.
3. Run **`IOSSDMFL-Report.ps1`** to list the shared-mode iPhones (no user affinity) and their app/group
   state.

### Step 12. Remediate gaps (safe by default)
1. If the group is missing the Provisioning Client owner, the ADE profile has the wrong affinity, or
   apps are unassigned, run **`IOSSDMFL-Remediation.ps1`** — it **defaults to `-WhatIf`** and prints
   exactly what it would change. Review, then re-run to apply.

### Step 13. Expand in waves
1. Once the pilot passes (Testing gate), assign the **iPhone SDM – ADE Profile** to the next batch of
   serials and register each device into shared mode (Step 7).
2. Roll out by location/shift in waves, validating each wave with `IOSSDMFL-Report.ps1` before
   widening. Register-into-shared-mode is per device, so script/track it as part of your provisioning
   runbook.


---


# 5. Testing & Validation — iOS iPhone Entra ID Shared Device Mode

Validate against a **pilot iPhone** with **two** pilot users before expanding. Each test has an
explicit **pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph) for tenant-side
checks and the on-device steps for the shared-session experience.

> **What "pass" means here:** a worker signs in as themselves on a shared iPhone, signs out once, and
> the **next** worker signs in with **no trace** of the previous user in the SDM apps. This is a
> per-user identity session, not kiosk lockdown.

## Test 1 — Tenant readiness
**Procedure:** Run `IOSSDMFL-Discovery.ps1`.
**Pass:** A no-user-affinity ADE profile exists; Microsoft Authenticator and Teams are added/assigned;
the **iPhone SDM – Devices** assigned group exists with the Intune Provisioning Client as owner; the
Cloud Device Administrator role has a member.
**Fail:** Any missing → resolve before piloting (see Remediation).

## Test 2 — Assigned group ownership (enrollment-time grouping)
**Procedure:** Run `IOSSDMFL-Validation.ps1` (or Entra → Groups → **iPhone SDM – Devices** → Owners).
**Pass:** The group is **Assigned** and the **Intune Provisioning Client** (`f1346770-5b25-470b-88bd-
d5744ab7952c`) is an **owner**.
**Fail:** Group is Dynamic, or the SP is not an owner → devices won't populate at enrollment; fix with
`IOSSDMFL-Remediation.ps1`.

## Test 3 — No-affinity enrollment
**Procedure:** On the pilot iPhone (after ADE enrollment), Intune → **Devices → iOS/iPadOS → (device)**.
**Pass:** The device is **supervised**, shows **no primary user**, and is a member of
**iPhone SDM – Devices**.
**Fail:** Device has a primary user / user affinity → correct the **iPhone SDM – ADE Profile**
(Requirement R2) and re-enroll.

## Test 4 — Shared-mode registration
**Procedure:** Confirm the device was registered into shared mode via Microsoft Authenticator with the
Cloud Device Administrator account (Implementation Step 7).
**Pass:** Teams (and other SDM apps) present the **shared-device** sign-in experience, not the normal
single-user one.
**Fail:** Apps show a normal sign-in → re-run the Authenticator shared-device registration with an
account holding **Cloud Device Administrator** (R5).

## Test 5 — Global sign-in (user A)
**Procedure:** Sign in as **user A** in Teams; open another SDM app if present.
**Pass:** A is signed in; other SDM apps recognize A **without** a second sign-in.
**Fail:** Each app prompts separately with no shared identity → confirm shared-mode registration (Test
4) and that the apps are SDM-aware (R6).

## Test 6 — Single (global) sign-out
**Procedure:** As user A, sign out once in Teams.
**Pass:** A is signed out of **all** SDM apps and A's cached data is cleared from the device.
**Fail:** A still signed in elsewhere, or data remains → the app is not SDM-aware, or the device is not
truly in shared mode — re-verify Tests 4/6 and app support.

## Test 7 — Clean second sign-in (user B) — the core test
**Procedure:** Sign in as **user B** in Teams after A's sign-out.
**Pass:** B sees **only** their own data; there is **no trace** of user A (chats, files, tokens).
**Fail:** Any of A's data/session visible to B → do **not** proceed; the shared-session boundary is
not intact. Confirm SDM registration and that only SDM-aware apps hold user data on the device.

## Test 8 — Coverage / inventory report
**Procedure:** Run `IOSSDMFL-Report.ps1`.
**Pass:** The pilot iPhone appears as a no-affinity, shared-pool device with Authenticator + Teams
present; counts match **iPhone SDM – Devices**.
**Fail:** Device missing or apps absent → run `IOSSDMFL-Remediation.ps1` (`-WhatIf` first).

## Test 9 — Non-SDM app boundary (negative test)
**Procedure:** Confirm no non-SDM app that caches personal data is deployed to the shared pool (review
the **iPhone SDM – Restrictions** profile and app assignments).
**Pass:** Only SDM-aware apps (and safe utilities) are present; global sign-out therefore clears all
user data that exists on the device.
**Fail:** A non-SDM data-caching app is on the pool → remove it or restrict it; SDM will **not** clear
its data on sign-out.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass and **Test 7 (clean second sign-in) passes on a real
device with two real users**, and Test 9 confirms no non-SDM app leaks data across users.


---


# 6. Troubleshooting — iOS iPhone Entra ID Shared Device Mode

Work in enrollment order: confirm the device **enrolled without affinity and landed in the group**,
then that it was **registered into shared mode**, then that the **SDM apps behave**. Most failures are
a Dynamic (not Assigned) group, a missing group **owner**, a wrong enrollment affinity, or an app that
is not SDM-aware. Each symptom gives the **likely cause** and the **fix**.

> **Before you start:** if the concern is "one worker can see another's data," first confirm the app
> in question is **SDM-aware**. SDM clears data only for apps that implement it — a non-SDM app on a
> shared phone is the classic false alarm (and a real leak). This is an app-scope decision, not an SDM
> bug.

## Symptom: Shared iPhones enroll but the group stays empty / nothing deploys
**Likely cause:** The device group is **Dynamic**, or the **Intune Provisioning Client** is not an
**owner** of the Assigned group.
**Fix:**
1. Confirm **iPhone SDM – Devices** is **Membership type = Assigned** (not Dynamic).
2. Add the **Intune Provisioning Client** (AppId `f1346770-5b25-470b-88bd-d5744ab7952c`) as an
   **owner** — search by **AppId**, since the display name varies (`IOSSDMFL-Remediation.ps1` can do
   this).
3. If the SP doesn't exist to search, open the Intune portal once as **Global Administrator** to
   provision it, then add it.

## Symptom: The device enrolled with a primary user (user affinity)
**Likely cause:** The ADE profile is not set to **Enroll without User Affinity**.
**Fix:**
1. Intune → **Devices → Enrollment → Apple → Enrollment program tokens → (token) → Profiles →
   iPhone SDM – ADE Profile** and set **User Affinity = Enroll without User Affinity**, **Supervised**.
2. Re-assign the profile to the serials and **re-enroll** the affected devices (affinity is set at
   enrollment).

## Symptom: Teams shows a normal single-user sign-in, not shared mode
**Likely cause:** The device was never registered into Shared Device Mode, or the registering account
lacked the role.
**Fix:**
1. On the device, open **Microsoft Authenticator** and complete the **shared device registration**
   using an account that holds **Cloud Device Administrator** (R5).
2. Confirm the registration succeeded, then reopen Teams — it should present the shared-device
   experience.

## Symptom: Shared-device registration fails / is greyed out
**Likely cause:** The registering account lacks **Cloud Device Administrator**, or Authenticator isn't
installed.
**Fix:**
1. Entra → **Roles and administrators → Cloud Device Administrator** — add the provisioning account.
2. Confirm **Microsoft Authenticator** is installed on the device (R4) and the device has network
   access to the Entra endpoints (R8).

## Symptom: Sign-out doesn't clear the previous user (user B sees user A's data)
**Likely cause:** The offending app is **not SDM-aware**, or the device is not truly in shared mode.
**Fix:**
1. Identify which app retained data. If it is not Teams/an SDM-aware MSAL app, **remove or restrict**
   it — SDM cannot clear non-SDM apps.
2. Re-confirm shared-mode registration (Test 4) and that Teams itself performs global sign-out.
3. Tighten the **iPhone SDM – Restrictions** profile so only SDM-aware apps are present (R9).

## Symptom: Repeated MFA / sign-in loops on the shared device
**Likely cause:** Conditional Access re-challenging, blocked endpoint, or TLS inspection.
**Fix:**
1. Review Conditional Access sign-in-frequency policies applied to the frontline users; shared devices
   naturally re-authenticate per user per shift — tune frequency to the shift model.
2. Confirm the device reaches `https://login.microsoftonline.com` (or sovereign equivalent) (R8).
3. **Exempt Microsoft login endpoints from TLS inspection.**

## Symptom: Some LOB apps don't participate in global sign-in/out
**Likely cause:** The app is not built on MSAL or does not implement Shared Device Mode.
**Fix:**
1. Confirm SDM support with the app vendor / current Microsoft documentation.
2. If unsupported, do **not** rely on it for shared use — restrict it off the pool or accept it is
   outside the global-sign-out boundary and holds no user data.

## Symptom: Report shows fewer shared iPhones than expected
**Likely cause:** Devices not yet ADE-enrolled, not registered into shared mode, or missing from the
group.
**Fix:**
1. Run `IOSSDMFL-Report.ps1` to list which devices lack no-affinity enrollment or the SDM apps.
2. Run `IOSSDMFL-Remediation.ps1` (`-WhatIf` first) to fix group ownership/app assignment.
3. Complete the per-device shared-mode registration for stragglers (Implementation Step 7).

## Escalation checklist
Before opening a Microsoft support case, collect: the `IOSSDMFL-Discovery.ps1` output, the ADE
profile's affinity setting, the **iPhone SDM – Devices** group type + owners, the exact app bundle IDs
and their SDM support status, the registering account's role, iOS version, and a description of the
two-user sign-in/sign-out test result (isolates SDM from app-specific behavior).


---


# 7. Best Practices — iOS iPhone Entra ID Shared Device Mode (Frontline)

These practices keep the shared-iPhone identity model correct, predictable, and safe across users.
They assume the deployment model in the Solution Overview: no-affinity ABM/ADE enrollment into an
assigned device group, shared-mode registration via Microsoft Authenticator, and SDM-aware apps
(Teams + MSAL LOB), deployed pilot-first.

## Get the enrollment-time grouping right (the #1 pitfall)
- **Assigned group, not Dynamic.** Shared/no-affinity devices have no user to drive dynamic rules —
  use an **Assigned** security group (**iPhone SDM – Devices**).
- **Make the Intune Provisioning Client an owner.** Add AppId
  `f1346770-5b25-470b-88bd-d5744ab7952c` as an **owner** of that group (search by AppId, not the
  display name). Without it, devices never populate the group at enrollment and nothing deploys.
- **One group, everything targeted to it.** Point the ADE profile assignment, the apps, the
  restriction profile, and compliance at the same **iPhone SDM – Devices** group so a device is fully
  configured the moment it lands.

## Treat app scope as the security boundary
- **Only SDM-aware apps belong on a shared iPhone.** Global sign-out clears data **only** for apps
  that implement SDM. Anchor on **Microsoft Teams**; add LOB apps **only** after confirming SDM
  support with the vendor / current Microsoft docs.
- **Keep non-SDM, personal-data apps off the pool.** Use the **iPhone SDM – Restrictions** profile to
  ensure no app that caches personal data — but doesn't participate in global sign-out — is present.
  This is the difference between "clean hand-off" and "the next worker sees the last one's data."
- **Don't confuse this with kiosk lockdown.** Lockdown limits *which* app runs; SDM manages *whose
  identity* is active. If the requirement is a single-purpose appliance phone, use the lockdown
  solution instead; if it's per-user frontline sign-in, use SDM.

## Provisioning discipline
- **Dedicated, least-privilege provisioning account.** Grant **Cloud Device Administrator** to a
  dedicated account used only to register devices into shared mode — not a personal admin identity.
- **Make shared-mode registration part of the runbook.** Registration is **per device** via
  Authenticator; script/track it so no device silently skips it and falls back to single-user
  behavior.
- **Verify iOS app support before each wave.** SDM app coverage on iOS is narrower than Android and
  evolves — re-confirm Teams and any LOB apps before widening.

## Pilot-first and prove the hand-off
- **Always test with two real users.** The acceptance test is user A signs out → user B signs in
  **clean**. Never expand on a single-user test.
- **Pilot by location/shift.** Roll out to one site or shift, validate with `IOSSDMFL-Report.ps1`,
  then widen.

## Operate and monitor
- **Report before you widen.** Run `IOSSDMFL-Report.ps1` each wave; confirm no-affinity enrollment and
  SDM apps across the pool.
- **Remediate with `-WhatIf` first.** `IOSSDMFL-Remediation.ps1` and `IOSSDMFL-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply.
- **Tune Conditional Access to the shift model.** Shared devices re-authenticate per user per shift;
  set sign-in frequency accordingly rather than fighting it.
- **Don't TLS-inspect Microsoft login endpoints** — it breaks registration and sign-out.

## Change control
- **Re-verify after iOS major upgrades** and after adding any app to the pool — confirm the two-user
  clean-hand-off test still passes before expanding.
- **Record app SDM-support decisions.** Keep a short table (app → bundle ID → SDM supported? → source)
  so the next admin knows the boundary.


---


# 8. Deliverables Summary — iOS iPhone Entra ID Shared Device Mode

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: per-user
  identity sessions on shared iPhones via Entra Shared Device Mode, not kiosk lockdown and not Apple
  Shared iPad.
- **Solution Overview** — how Entra Shared Device Mode works on iPhones (no-affinity enrollment,
  Authenticator shared-mode registration, SDM-aware apps), global sign-in / single sign-out, what it
  isolates (honestly), and why iPhones need it (Apple Shared iPad is iPad-only).
- **Requirements Guide** — every ABM/ADE, Entra, Intune, role, and app prerequisite with how to
  **verify** and how to **implement if missing** — including the Assigned-group + Intune Provisioning
  Client owner requirement — plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: build the
  foundation (assigned group + owner, no-affinity ADE profile, apps, restrictions, role), enroll and
  register a pilot device into shared mode, pilot the global sign-in / single sign-out, then validate
  and expand.
- **Testing & Validation** — nine tests with explicit pass/fail gates, centered on the two-user
  clean-hand-off test, plus a non-SDM-app boundary negative test.
- **Troubleshooting** — enrollment-order diagnosis for empty groups, affinity, shared-mode
  registration, sign-out data-clearing, and app-support cases.
- **Best Practices** — enrollment-time grouping, treating app scope as the security boundary,
  provisioning discipline, and proving the hand-off with two real users.

## PowerShell scripts (Microsoft Graph) — `IOSSDMFL-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`IOSSDMFL-Discovery.ps1`** — tenant readiness: no-affinity ADE profile, Microsoft Authenticator +
   Teams assigned, the Assigned device group with the Intune Provisioning Client as owner, and the
   Cloud Device Administrator role populated.
2. **`IOSSDMFL-Validation.ps1`** — validates the assigned-group ownership, ADE profile affinity, and
   app assignments, with a clear PASS/FAIL summary.
3. **`IOSSDMFL-Report.ps1`** — tenant-wide CSV report of shared (no-affinity) iOS devices and whether
   the SDM apps are present — the shared-pool inventory.
4. **`IOSSDMFL-Remediation.ps1`** — safe remediation: create/assign the Assigned device group, set the
   Intune Provisioning Client as owner, and flag missing app assignments. **`-WhatIf` by default.**
5. **`IOSSDMFL-Set-ScopeTargeting.ps1`** — sets/adjusts the target (Assigned) group used for the
   shared-device apps/config. **`-WhatIf` by default.**

## Hero image
- **`IOSSDMFL-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited
devices**.
