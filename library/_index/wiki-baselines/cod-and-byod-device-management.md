# Corporate-Owned (COD) & BYOD Device Management

> **Version 1.0.0** · Category: Intune · Solution code: CODBYOD

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Corporate-Owned (COD) & BYOD Device Management

Most organizations run **two** device realities at once: **corporate-owned devices (COD)** that IT
buys and fully controls, and **personal (BYOD)** devices employees already own and want to use for
work. Managed separately, they create duplicate policies, inconsistent security, and confused users.

This solution unifies both under **Microsoft Intune** and **one Microsoft Entra identity**: the same
user signs in with the same corporate account on **both** their company device and their personal
device, while IT applies the **right level of control to each** based on who owns it.

- **Corporate-owned (COD)** → full MDM enrollment, device compliance, and configuration. IT owns the
  device end to end.
- **Personal / BYOD** → lighter-touch management: **App Protection (MAM)** that secures corporate
  data inside apps without taking over the employee's device — or optional personal MDM enrollment.
- **One identity, both devices** → the user's single Entra account works everywhere; **ownership-based
  targeting** (device filters + assignments) routes the correct policy to each device automatically,
  and **Conditional Access** grants access from a compliant company device *or* a protected app on a
  personal one.

Built the standard repeatable way — **Assess → Configure → Pilot → Validate → Expand** — with exact,
click-by-click Intune steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing/troubleshooting
guides with clear pass/fail gates.

**Outcome:** a single, coherent device-management model where one employee account works on both a
corporate and a personal device, corporate data stays protected on each, and access is governed by
compliance and app protection — delivered by your own team without a consulting engagement.


---


# 1. Solution Overview — Corporate-Owned (COD) & BYOD Device Management

## What this solution is
A unified way to manage **two device-ownership models** in Microsoft Intune under **one Microsoft
Entra identity**:

1. **Corporate-Owned Devices (COD)** — devices the organization buys and owns. They are fully
   enrolled in Intune (MDM), receive configuration and compliance policies, and are managed end to
   end by IT.
2. **Bring Your Own Device (BYOD)** — personal devices the employee owns. The corporate **identity
   and data** are managed without taking over the personal device, primarily through **App
   Protection Policies (MAM)**, with optional lightweight personal MDM enrollment.

The defining design goal of this solution: **the same user account signs in on both device types.**
A user authenticates with their single Entra ID everywhere; Intune applies the correct controls to
each device based on **ownership**, not on a second account.

## How it works
1. **One identity.** Each user has a single Microsoft Entra account. That account is what enrolls the
   corporate device and what signs into work apps on the personal device — there is no separate
   "BYOD account."
2. **Ownership is tagged.** Every enrolled device is marked **Corporate** or **Personal** (by
   enrollment method, corporate device identifiers, or enrollment-restriction defaults).
3. **Ownership-based targeting.** Policies are assigned to the **user** (or a user group), then scoped
   with **device filters** on `deviceOwnership` so:
   - **Corporate** devices receive full **device compliance** + **configuration** policies.
   - **Personal** devices receive **App Protection (MAM)** policies that encrypt corporate data,
     enforce a PIN, and block copy/paste or "Save As" to personal locations.
4. **Conditional Access ties it together.** A single Conditional Access policy for the user grants
   access when the request comes from a **compliant corporate device** *or* from an **approved app
   with an app-protection policy** on a personal device — so the one account works securely from both.

## Management models (choose per ownership)
- **COD — full MDM:** complete device management, configuration profiles, compliance, and (optionally)
  Autopilot/ADE/Android Enterprise corporate enrollment for zero-touch provisioning.
- **BYOD — App Protection / MAM (recommended):** secures corporate data *inside* managed apps with no
  full device enrollment; least intrusive for employees, strong data-leak protection.
- **BYOD — personal MDM enrollment (optional):** when a personal device must receive a few device
  settings; still tagged Personal and scoped accordingly.

This solution standardizes on **full MDM for COD** and **App Protection for BYOD**, with personal MDM
called out as an option.

## Benefits
- **One account, both devices** — no duplicate identities; users sign in with what they already know.
- **Right-sized control** — full management where IT owns the device; data-only protection where the
  employee does.
- **Lower friction BYOD** — employees keep their device private; corporate data stays contained.
- **Consistent security** — compliance for COD, app protection for BYOD, unified by Conditional Access.
- **Scales cleanly** — ownership-based targeting means you assign once to the user and the right policy
  follows the device.

## Limitations (be honest with buyers)
- **App Protection (MAM)** secures data **inside supported apps** (Microsoft 365 and SDK-enabled
  apps); it does not manage the whole personal device or unmanaged apps.
- BYOD users must use the **managed/approved apps** (e.g. Outlook, Edge, Teams) to get corporate data;
  built-in personal mail/browser apps are blocked from corporate data by design.
- COD zero-touch provisioning (Autopilot/ADE/Android Enterprise) is referenced but each platform's
  full enrollment is covered by its own solution; this solution unifies the **model**.
- A user signing in on a brand-new device enrolls/registers that device the first time.

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **One Microsoft Entra identity per user; corporate-owned devices under full MDM and personal
> devices under App Protection (MAM); ownership-based targeting routes the right policy to each; a
> single Conditional Access policy governs access from both.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — Corporate-Owned (COD) & BYOD Device Management

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, supported OS, network) are
covered once in the **Global Requirements — Intune Solutions** document; the items here are specific
to running COD and BYOD under one identity.

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

## R5. A way to mark devices Corporate
**Description:** Corporate device identifiers and/or corporate enrollment methods so COD devices are
tagged **Corporate**.
**Why:** Ownership = Corporate is the signal that routes full MDM policy (vs. App Protection) to a
device.
**Verify:** Intune → **Devices → Enrollment → Corporate device identifiers** (serials/IMEIs), or a
device's **Ownership** field reads **Corporate**.
**Implement:** Add corporate identifiers, use corporate enrollment programs (Autopilot/ADE/Android
Enterprise corporate), or set **Ownership = Corporate** on the device record.

## R6. Company Portal app
**Description:** The Intune **Company Portal** available on managed devices.
**Why:** Company Portal performs MDM enrollment for COD and is the broker that registers a personal
device and surfaces app-protection-enabled apps for BYOD.
**Verify:** Intune → **Apps**; Company Portal is added for the relevant platforms and assigned to the
pilot group.
**Implement:** Add Company Portal per platform and assign it to the pilot group.

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
**Verify:** Intune → **Tenant administration → Filters**; filters for Corporate and Personal exist.
**Implement:** Create them in Implementation §5, or run the included `Set-OwnershipBasedTargeting.ps1`.

## R10. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, app protection check-ins, and authentication depend on these.
**Verify:** From a device, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
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
**Why:** Every solution is piloted to a small group before fleet rollout.
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
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation — Corporate-Owned (COD) & BYOD Device Management

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**. The whole design assumes **one Entra identity per user**
that works on both device types — so you assign policies to the **user (group)** and let
**ownership-based filters** route the right policy to each device. Pilot first:
**Assess → Configure → Pilot → Validate → Expand.**

All steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and Microsoft Entra
at `https://entra.microsoft.com` unless noted.

---

## Phase 1 — Identity & enrollment baseline

### Step 1. Confirm one identity and licensing per pilot user
1. Entra → **Users** → confirm each pilot user is a **single** account with an Intune + Entra ID P1
   license (Requirements R1–R3).
2. Entra → **Groups → New group** → **Security** → name it **`PILOT – COD-BYOD Users`** → add the pilot users.
   *(You assign every policy in this solution to this **user** group.)*

### Step 2. Set enrollment restrictions for both ownership types
1. **Devices → Enrollment → Enrollment device platform restrictions.**
2. Open the default (or create a pilot-scoped restriction **named `Enrollment Restriction – COD-BYOD – Pilot`**).
3. For **BYOD** platforms (e.g. iOS/Android personal), set **Personal devices = Allow**.
4. For platforms you only allow as corporate, set **Personal devices = Block** (those must enroll via
   a corporate method).

### Step 3. Establish how COD devices are marked Corporate
1. **Devices → Enrollment → Corporate device identifiers → Add** serial numbers/IMEIs of company
   devices **(or)** rely on a corporate enrollment program (Autopilot/ADE/Android Enterprise).
2. Confirm a known company device shows **Ownership = Corporate** on its device record.

---

## Phase 2 — Ownership-based targeting (the core of "one account, both devices")

### Step 4. Create device-ownership filters
1. **Tenant administration → Filters → Create.**
2. Filter 1: **Corporate Devices** — platform as needed; rule `(device.deviceOwnership -eq "Corporate")`.
3. Filter 2: **Personal Devices** — rule `(device.deviceOwnership -eq "Personal")`.
3. **Save** both.

> Prefer automation? Run **`Set-OwnershipBasedTargeting.ps1`** to create these filters (and optionally
> assign the policies below) via Microsoft Graph.

---

## Phase 3 — Corporate-owned (COD): full MDM

### Step 5. Create a compliance policy for corporate devices
1. **Devices → Compliance → Create policy** → pick the platform; **name it `COD – Compliance – Pilot`**.
2. Set baseline rules (OS minimum, disk encryption, firewall, etc.).
3. **Assignments:** assign to **PILOT – COD-BYOD Users**, and under **Filter**, **Include** the
   **Corporate Devices** filter → **Create**.

### Step 6. Create configuration profile(s) for corporate devices
1. **Devices → Configuration → Create → New policy** → platform → your settings; **name it `COD – Configuration – Pilot`**.
2. **Assignments:** assign to **PILOT – COD-BYOD Users**, **Include** the **Corporate Devices** filter.

*(Zero-touch corporate enrollment — Windows Autopilot, Apple ADE, Android Enterprise corporate — is
each covered by its own solution; plug those in for fully automated COD provisioning.)*

---

## Phase 4 — BYOD: App Protection (MAM)

### Step 7. Create App Protection Policies
1. **Apps → App protection policies → Create policy** → **iOS/iPadOS**, **name it `BYOD – App Protection – iOS – Pilot`** (repeat for **Android** as **`BYOD – App Protection – Android – Pilot`**).
2. **Apps:** select the approved managed apps (Outlook, Edge, Teams, Office, OneDrive).
3. **Data protection:** block **backup**, restrict **cut/copy/paste** to managed apps, block **Save
   As** to personal locations, require corporate data to stay in managed apps.
4. **Access requirements:** require **PIN** / org credentials to access; set offline timeouts.
5. **Assignments:** assign to **PILOT – COD-BYOD Users**. *(App Protection is identity-based — it
   applies to the user wherever they sign into the managed app, so it naturally targets the personal
   device without device enrollment.)*

### Step 8. Make the approved apps available to BYOD users
1. **Apps → (platform) → Add** Outlook, Edge, Teams, Office, Company Portal as needed.
2. Assign them **Available** to **PILOT – COD-BYOD Users** so users install them from Company
   Portal / store.

---

## Phase 5 — Unify access with Conditional Access

### Step 9. One Conditional Access policy for both device types
1. Entra → **Protection → Conditional Access → Create new policy** → name it **`CA – COD-BYOD Access`**.
2. **Users:** **PILOT – COD-BYOD Users**.
3. **Target resources:** Office 365 (and other corporate apps).
4. **Grant:** require **one of the following** — **Require device to be marked as compliant** *(this
   is satisfied by the corporate device)* **and/or** **Require app protection policy** *(satisfied by
   the personal device's managed app)*; set the control to **Require one of the selected controls**.
5. **Enable policy:** **Report-only** for the pilot → **Create**.

This single policy is what lets the **same account** reach corporate data from a **compliant COD** or
an **app-protected BYOD** device.

---

## Phase 6 — Pilot, validate, expand

### Step 10. Pilot with one user on two devices
1. As a pilot user, enroll a **corporate** device (it tags Corporate → gets compliance/config).
2. On a **personal** device, sign into **Outlook/Edge** with the **same account** → the App
   Protection policy applies (PIN prompt, managed-app data containment).
3. Confirm the **same UPN** now owns both a Corporate and a Personal device in Intune.

### Step 11. Validate
1. Run **`CODBYOD-Discovery.ps1`** (tenant readiness) and **`CODBYOD-Validation.ps1 -User <upn>`**:
   confirm the user has **one Corporate** device (compliant) and **one Personal** device (app
   protection applied), under a single identity.
2. Confirm the **Corporate** filter applied device policy and the **Personal** filter did not (and
   vice-versa for app protection).
3. Review Conditional Access **report-only** results for the pilot user.

### Step 12. Expand
1. When the pilot passes, widen the assignments from the pilot group to broader user groups.
2. Move **CA – COD-BYOD Access** from **report-only** to **On**.
3. Roll out in waves, validating each wave with the scripts before widening.


---


# 5. Testing & Validation — Corporate-Owned (COD) & BYOD Device Management

Validate against a **pilot user with two devices** (one corporate, one personal) before expanding.
Each test has an explicit **pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph)
for tenant-side checks and the on-device steps for the user experience.

## Test 1 — Tenant readiness
**Procedure:** Run `CODBYOD-Discovery.ps1`.
**Pass:** Enrollment restrictions allow the intended Personal/Corporate split, an App Protection
policy exists, a compliance policy exists, Corporate/Personal **device filters** exist, Company Portal
is assigned, and a Conditional Access policy is present.
**Fail:** Any missing → resolve before piloting.

## Test 2 — Single identity, two devices
**Procedure:** Run `CODBYOD-Validation.ps1 -User <upn>` for the pilot user.
**Pass:** The **same UPN** owns at least one **Corporate** device and one **Personal** device.
**Fail:** Devices split across different accounts → consolidate identity (Requirements R1).

## Test 3 — Corporate device gets full MDM
**Procedure:** Inspect the pilot **corporate** device in Intune.
**Pass:** Ownership = **Corporate**; the **compliance** and **configuration** policies (Corporate
filter) are **applied**; device reports **Compliant**.
**Fail:** Policies not applied → confirm the device is tagged Corporate (R5) and the Corporate filter
is set on the assignment (Implementation §5–6).

## Test 4 — Personal device gets App Protection only
**Procedure:** On the pilot **personal** device, sign into Outlook/Edge with the pilot account.
**Pass:** The App Protection policy applies — **PIN prompt**, corporate data confined to managed apps,
**Save As**/paste to personal locations blocked. The device is **not** fully enrolled (or, if
personally enrolled, is tagged **Personal** and does **not** receive Corporate device policies).
**Fail:** No PIN/containment → confirm the app is approved/managed and the App Protection policy is
assigned to the user (Implementation §7).

## Test 5 — Ownership filters route correctly
**Procedure:** Compare policy application across the two devices.
**Pass:** The **Corporate** device receives device compliance/config and **not** the BYOD-only items;
the **Personal** device receives app protection and **not** corporate device policies.
**Fail:** Cross-application → re-check the `deviceOwnership` filter rules and the Include/Exclude on
each assignment (Implementation §4).

## Test 6 — One account reaches work from both devices
**Procedure:** With Conditional Access **report-only**, access a corporate web app from the corporate
device and a managed app from the personal device, signed in as the same user.
**Pass:** Both succeed — the corporate device satisfies **compliant device**; the personal device
satisfies **app protection policy** — under the **single** CA policy.
**Fail:** One path blocked → review CA grant controls ("require one of"), compliance state, and app
protection assignment (Implementation §9).

## Test 7 — Unmanaged path is blocked (data protection holds)
**Procedure:** On the personal device, try to open corporate mail in the **built-in** (unmanaged) mail
app or paste corporate data into a personal app.
**Pass:** Corporate data is **not** accessible in unmanaged apps; paste/Save-As to personal locations
is blocked.
**Fail:** Corporate data leaks to unmanaged apps → tighten App Protection data-relocation settings.

## Test 8 — Compliance & enforcement
**Procedure:** Review compliance for the corporate device and the report-only CA results for the user.
**Pass:** Corporate device **Compliant**; CA evaluates the user correctly from both devices.
**Fail:** Non-compliant or CA misfires → review the compliance policy and CA conditions.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass for a pilot user who has **both** a corporate and a
personal device signed in with the **same account**, and the data-protection checks (Test 7) hold.


---


# 6. Troubleshooting — Corporate-Owned (COD) & BYOD Device Management

Work top-down: confirm the **identity** (one account), then **ownership** (Corporate vs Personal),
then **targeting** (filters/assignments), then **access** (Conditional Access). Most issues are a
device tagged with the wrong ownership, a missing filter on an assignment, or a BYOD user not using a
managed app.

## A user's two devices show under different accounts
- **Duplicate identities.** Consolidate to one Entra account; the user must sign in with the same UPN
  on both devices (Requirements R1). Re-enroll/re-register the stray device under the correct account.

## A corporate device is tagged Personal (or vice-versa)
- **Wrong ownership.** Intune → **Devices → (device) → Properties → Device ownership** → set
  **Corporate**/**Personal**. For COD, add **corporate device identifiers** or use a corporate
  enrollment program so it tags Corporate automatically (R5).
- After fixing, the device picks up the correct filtered policies on next sync.

## Corporate policies are not applying to the corporate device
- **Filter mismatch.** The compliance/config assignment must **Include** the **Corporate Devices**
  filter and target the **user** group (Implementation §5–6). Verify the filter rule is
  `(device.deviceOwnership -eq "Corporate")`.
- **Device not compliant/enrolled.** Confirm the device is enrolled and checking in.

## App Protection isn't applying to the BYOD device
- **User not in scope.** App Protection assigns to the **user** group — confirm the pilot user is a
  member (Implementation §7).
- **App not managed/approved.** The user must use an **approved managed app** (Outlook, Edge, Teams).
  Built-in mail/browser apps are intentionally excluded.
- **No Intune/MAM license** on the user (R2).
- App Protection applies on **next app launch / token refresh** — close and reopen the managed app.

## BYOD user can't access corporate mail/data
- **By design in an unmanaged app.** They must use the managed app (e.g. Outlook), not the built-in
  one. Deploy and direct them to the approved apps (Implementation §8).
- **Conditional Access blocking.** If CA requires app protection, accessing from a non-managed app is
  blocked — expected. Check Entra → **Sign-in logs** for the CA result.

## One account works on the corporate device but not the personal one (or vice-versa)
- **CA grant too strict.** The Conditional Access policy must **require *one of*** compliant device
  **or** app protection — not **both** (Implementation §9). "Require all" blocks one of the two paths.
- **App protection not yet registered** on the personal device — open a managed app and complete the
  PIN setup.

## Personal device received corporate **device** policies (over-management)
- The personal device was **fully enrolled** and/or tagged **Corporate**. Confirm enrollment
  restrictions and ownership (R4–R5); for BYOD, prefer **App Protection without enrollment**. If
  personal MDM enrollment is intended, ensure it's tagged **Personal** so the Personal filter excludes
  corporate policies.

## Conditional Access has unexpected effects
- Keep the pilot policy in **report-only** and read Entra → **Sign-in logs → Conditional Access** to
  see exactly which control was/wasn't satisfied before turning it **On**.

## Useful checkpoints
- **Intune:** Devices → (device) → **Properties** (ownership), **Compliance**, **Configuration**;
  Apps → **App protection policies → (policy) → Monitor** for per-user status; Tenant administration →
  **Filters**.
- **Entra:** **Sign-in logs → Conditional Access** tab for grant evaluation.
- **Scripts:** re-run `CODBYOD-Validation.ps1 -User <upn>` after each change to confirm the gate.


---


# 7. Best Practices — Corporate-Owned (COD) & BYOD Device Management

Field-proven guidance to keep one identity working cleanly across both device types.

## Identity & assignment model
- **Assign policies to user groups, scope with device filters.** This is the heart of the design:
  one assignment to the user, the right policy follows the device's ownership. Avoid mixing
  per-device group assignments that fight the filters.
- **Keep one Entra identity per user.** Never create a separate "BYOD account" — it splits policy and
  breaks Conditional Access logic.
- **Name groups and filters by intent** (e.g. *PILOT – COD-BYOD Users*, *Corporate Devices*,
  *Personal Devices*) so assignments are self-documenting.

## Ownership hygiene
- **Make ownership deterministic.** Use corporate enrollment programs and corporate device
  identifiers so COD tags **Corporate** automatically; let BYOD default to **Personal**.
- **Audit ownership regularly** with `CODBYOD-DeviceReport.ps1` — a device tagged the wrong way gets
  the wrong policy set.

## BYOD data protection
- **Prefer App Protection (MAM) without enrollment for BYOD.** It protects corporate data without
  managing the employee's personal device — better adoption, less privacy friction, strong
  data-leak controls.
- **Lock the data boundary:** block backup, restrict cut/copy/paste and "Save As" to managed apps,
  require a PIN, and enforce encryption within managed apps.
- **Only enroll a personal device (MDM) when you truly need device settings** — and keep it tagged
  **Personal** so it never receives corporate device policies.

## Corporate device management
- **Apply a real compliance baseline** (OS minimum, encryption, firewall) and gate access on it via
  Conditional Access.
- **Layer the zero-touch enrollment solutions** (Autopilot / Apple ADE / Android Enterprise) for
  hands-off COD provisioning; this solution unifies the model they all feed into.

## Conditional Access
- **One policy, "require one of."** Grant access when the request is from a **compliant** device
  **or** an **app-protection-protected** app — never require both, or you lock out one device type.
- **Always start report-only.** Read the sign-in logs for the pilot user before enforcing.
- **Add MFA** as part of the same access story for a complete Zero Trust posture.

## Rollout discipline
- **Pilot one user with two real devices** (a corporate and a personal one) — it's the only way to
  prove the single-identity experience end to end.
- **Expand in waves**, validating each with `CODBYOD-Validation.ps1` before widening.
- **Communicate the BYOD deal to employees:** what IT can and cannot see/do on a personal device
  under App Protection (data containment, *not* device surveillance) — clarity drives adoption.

## Operations & documentation
- **Keep a runbook** of the pilot/production groups, the two ownership filters, the compliance and
  app-protection policies, and the Conditional Access policy — the moving parts that define the model.
- **Report monthly** with `CODBYOD-DeviceReport.ps1`: device counts by ownership, users who have both
  a COD and a BYOD device, compliance, and app-protection coverage.


---


# 8. Deliverables Summary — Corporate-Owned (COD) & BYOD Device Management

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — the two ownership models, the single-identity design, management models,
  benefits, and honest limitations.
- **Requirements Guide** — every prerequisite (one identity, MDM+MAM licensing, Entra ID P1,
  enrollment restrictions, corporate tagging, Company Portal, App Protection, compliance, ownership
  filters, network) with how to **verify** and how to **implement if missing**, plus the category-level
  Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across six phases: identity &
  enrollment baseline, ownership-based targeting, COD full-MDM, BYOD App Protection, unifying access
  with Conditional Access, then pilot/validate/expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates and an acceptance gate, proving
  one account works on both a corporate and a personal device.
- **Troubleshooting** — top-down diagnosis for identity, ownership, targeting, and access failures.
- **Best Practices** — the assign-to-user/scope-by-filter model, ownership hygiene, BYOD data
  protection, COD management, Conditional Access, and rollout discipline.

## PowerShell scripts (Microsoft Graph) — `CODBYOD-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**.

1. **`CODBYOD-Discovery.ps1`** — tenant readiness: enrollment restrictions (personal allowed?),
   compliance policies, App Protection policies, Corporate/Personal device filters, Company Portal,
   and Conditional Access presence.
2. **`CODBYOD-Validation.ps1`** — for a given user, confirms a single identity owns both a **Corporate**
   device (compliant) and a **Personal** device (app protection applied), with a PASS/FAIL summary.
3. **`CODBYOD-DeviceReport.ps1`** — tenant-wide CSV: devices by **ownership**, platform, enrollment
   type, compliance, and primary user — plus a list of users who have **both** a COD and a BYOD device.
4. **`CODBYOD-Remediation.ps1`** — safe remediation: set device **ownership**, re-assign policies to the
   target group, and flag enrollment-restriction/filter misconfigurations. Read-only by default;
   changes require an explicit confirmation switch.
5. **`Set-OwnershipBasedTargeting.ps1`** — creates the **Corporate** and **Personal** `deviceOwnership`
   filters (and optionally assigns the compliance/app-protection policies with those filters) — the
   mechanism that makes one account work cleanly across both device types.

## Hero image
- **`CODBYOD-hero.png`** — the branded product image (1200×1200) used on the marketplace listing.

## How it's delivered
A branded **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts
appendix), plus all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across
**unlimited devices**.
