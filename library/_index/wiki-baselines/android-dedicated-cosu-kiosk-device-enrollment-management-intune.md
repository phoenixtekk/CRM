# Android Dedicated (COSU) / Kiosk Device Enrollment & Management in Intune

> **Version 1.0.0** · Category: Android · Solution code: ANDROIDCOSU

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Android Dedicated (COSU) / Kiosk Device Enrollment & Management (Microsoft Intune)

Frontline, warehouse, retail, logistics, and clinical devices exist to do **one job** — scan, sign,
display, capture — and nothing else. Left as ordinary tablets they wander into personal use, get set up
inconsistently, and are hard to lock down and scale. The fix is Android Enterprise's **dedicated
(COSU)** model in **Microsoft Intune**: company-owned, user-less devices that **boot straight into a
kiosk** and stay locked to their allowed app(s).

This solution stands that up end to end: the **dedicated enrollment profile**, enrollment by **token /
QR / NFC / zero-touch**, the **kiosk** (single-app or multi-app), **device restrictions**, **managed
Google Play** app delivery to devices that have no signed-in user, and **remote management** — all
validated on a pilot before you scale. It is a complete, **deploy-it-today** package written for an
administrator with no prior dedicated-device experience.

## What you get
- A plain-language **Solution Overview** of the dedicated/COSU model, the four enrollment methods
  (token/QR/NFC/zero-touch), single- vs multi-app kiosk, and how apps reach a user-less device.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (the category
  Android requirements — Intune tenant, managed Google Play binding, roles, network, pilot — are
  referenced, not repeated).
- An **Implementation Guide** of precise, ordered **Intune admin center + Microsoft Graph** steps:
  enrollment profile, dynamic device group, app assignment, the kiosk profile, enrollment, and
  validation — pilot-first, each artifact named, with pass/fail gates and rollback.
- Five **PowerShell scripts** for readiness discovery, safe configuration (`-WhatIf`), the
  only-allowed-apps kiosk validation, fleet health/inventory reporting, and scope targeting.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
Purpose-built Android devices **enrolled at scale** by the method that fits the fleet, **locked to their
app(s)** by single- or multi-app kiosk, **fed managed Google Play apps** to the device with no user,
and **remotely managed** — consistent and tamper-resistant. OEM/rugged devices (Zebra, Samsung) are
supported at the pattern level via OEMConfig.

## The deployment model
**Assess → Design → Configure → Pilot → Validate → Expand** — build the profile and kiosk, prove them on
a handful of devices, then roll out in waves.

## An honest note
Dedicated is for **corporate-owned, single-purpose** devices only; reversing the enrollment model
requires a factory reset. The **AMAPI transition and whether a change forces re-enrollment are actively
evolving** — where behavior is version-dependent, this package flags **"verify against current Microsoft
guidance / your tenant"** rather than asserting it.

## Outcome
A fleet of Android dedicated (COSU) devices that boot straight to the job, enrolled consistently, locked
to their apps, and remotely managed — validated before you scale.


---


# 1. Solution Overview — Android Dedicated (COSU) / Kiosk Device Enrollment & Management in Intune

## What this solution is
This solution stands up **Android Enterprise dedicated devices** — Google's **COSU**
(Corporate-Owned, Single-Use) model — in **Microsoft Intune**. Dedicated devices are company-owned,
have **no user affinity**, and boot straight into a **kiosk**: either **one app** (single-app kiosk)
or a **curated set of apps** on a locked launcher (multi-app kiosk). This is the model for frontline,
warehouse, retail, logistics, and clinical devices that exist to do one job and nothing else.

It covers the whole path: choosing and building the **dedicated enrollment profile**, enrolling
devices by **token / QR code / NFC / zero-touch**, applying the **kiosk profile and device
restrictions**, delivering **managed Google Play** apps to devices that have no user signed in, and
**remotely managing** the fleet — validated on a pilot before you scale.

It is **vendor-neutral**. Samsung Knox and Zebra (and other rugged/kiosk OEMs) are covered at the
**pattern level** — where an OEM extension or OEMConfig app changes a step, this solution names the
action and defers the OEM console/agent specifics to the vendor's documentation.

## The dedicated (COSU) model in one paragraph
A dedicated device is enrolled as an Android Enterprise **device-owner** with **no user account**.
Because there is no user, everything is targeted at the **device**, not a person: enrollment is driven
by an **enrollment profile / token**, and policy and apps are assigned to a **device group** (typically
a **dynamic device group keyed on the enrollment profile name**). The device runs in **kiosk mode** —
Android's lock-task mode — so the user cannot leave the allowed app(s), reach settings, or use the
device personally.

## The four enrollment methods (pick per device fleet)
The dedicated enrollment profile produces a **token** (a string) plus a **QR code** that carry the
enrollment. From a factory-reset device you choose how that token is delivered:

- **QR code** — on the setup "Welcome" screen, tap the screen several times to launch the QR reader,
  then scan the profile's QR code. The most common method for dedicated devices; no Google account or
  typing needed.
- **Token / afw#setup (manual)** — enter `afw#setup` where the setup asks to sign in, then supply the
  enrollment token. Useful where a camera/QR is impractical.
- **NFC** — bump a factory-reset device against an NFC "programmer" device running an NFC-provisioning
  app that carries the token. A bulk method for identical hardware; the NFC bump payload is deferred to
  the OEM/tooling.
- **Zero-touch enrollment** — devices bought through a **zero-touch reseller** are pre-assigned an
  enrollment configuration, so they enroll automatically on first boot with no scanning. Requires the
  **Android zero-touch portal** (reseller-provisioned) linked to your EMM; the portal specifics are
  deferred to Google/reseller documentation.

All four land the device on the **same** dedicated enrollment profile and therefore the same kiosk and
restriction policy — the method only changes how the token reaches the device.

## Single-app vs multi-app kiosk
- **Single-app kiosk** — the device locks to **one** app (e.g. a scanning app, a survey app, a
  digital-signage player). The app launches on boot and the user cannot leave it. Configured on the
  Android Enterprise **device restrictions** profile by setting the kiosk to that one app.
- **Multi-app kiosk** — the device shows a **locked launcher** with a **curated set** of apps and
  nothing else. Intune delivers this using Microsoft's **Managed Home Screen** app
  (`com.microsoft.launcher.enterprise`) as the launcher, with the allowed apps listed in the kiosk
  configuration. You control the grid, whether the user can change Wi-Fi/Bluetooth/volume, a session
  PIN, screen-saver, and more.

Both are built on the **`androidDeviceOwnerGeneralDeviceConfiguration`** device-restrictions profile;
multi-app additionally requires the Managed Home Screen app deployed to the device group.

## Managed Google Play app delivery to devices with no user
Because a dedicated device has **no signed-in user**, apps are delivered to the **device**: managed
Google Play apps (`androidManagedStoreApp`) are assigned to the **dedicated device group** as
**Required**, so they install at/after enrollment without any user action. The kiosk allow-list must
reference apps that are actually **assigned and installed** — an app named in the kiosk but not
assigned to the group will not appear. Keeping the **app assignments and the kiosk allow-list in sync**
is a first-class validation in this solution.

## Remote management
Dedicated devices are managed remotely through Intune device actions — **restart, wipe, retire, sync,
remote-lock**, and (where supported) **remote assistance** — plus policy/app updates that flow to the
device group. The Reporting script surfaces fleet health (compliance, last check-in, OS version, OEM
model) so you can spot stale or drifted devices.

## What is authored exactly vs deferred
- **Exact navigation is given** for the **Intune admin center** (`intune.microsoft.com`) — the
  dedicated enrollment profile, the kiosk/device-restrictions profile, managed Google Play app
  assignment, enrollment restrictions, and device actions — and for **Microsoft Graph** automation.
- **The managed Google Play binding** (account enterprise vs Google Workspace) is a **category
  prerequisite** (global requirement G2) — confirm it is in place before enrolling.
- **OEM specifics** (Samsung Knox, Zebra) and the **zero-touch reseller portal** are integrated at the
  **pattern level**; their consoles/agents are deferred to the vendor's documentation.
- **The AMAPI transition and whether a policy change forces re-enrollment are actively evolving** —
  where behavior is version-dependent this solution flags **"verify against current Microsoft guidance
  / your tenant"** rather than asserting it.

## Benefits
- **Boots to the job** — devices power on straight into the allowed app(s); no personal use, no wandering.
- **Consistent at scale** — one enrollment profile + one kiosk policy applied to every device, the same way.
- **User-less by design** — no account to manage; policy and apps target the device group.
- **Choice of enrollment** — token, QR, NFC, or zero-touch, all landing on the same profile.
- **Managed + reversible** — remotely manageable, piloted first, with scripts to validate and report.

## Limitations (be honest with buyers)
- **Dedicated = corporate-owned, no user.** It is not for BYOD or personal-plus-work phones (those are
  other enrollment models). Choose dedicated only for purpose-built devices.
- **Re-enrollment sensitivity.** Changing the **enrollment model** of a device generally requires a
  **factory reset and re-enrollment**; some kiosk/restriction changes apply live while others may need a
  reboot. Whether a specific change forces re-enrollment is **version-dependent — verify against current
  Microsoft guidance / your tenant**, and treat enrollment-model changes as high-impact.
- **OEM/rugged features vary.** Barcode-scanner, OEMConfig, and firmware-update behavior differ by
  vendor (Zebra, Samsung) and are deferred to the OEM.
- **No managed Google Play binding = no dedicated devices.** The category binding (G2) is a hard
  prerequisite.

## The standard deployment model
> **Assess the fleet → design the profile + kiosk → configure the enrollment profile, kiosk, and app
> assignments → pilot-enroll a few devices → validate the locked-down experience → expand in waves.**
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates
> and a documented rollback for production changes.


---


# 2. Requirements Guide — Android Dedicated (COSU) / Kiosk Device Enrollment & Management

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide Android prerequisites (Intune tenant + Android
Enterprise, the **managed Google Play binding**, least-privilege roles, enrollment-method decision +
Graph toolchain, network reachability, pilot + change control) are in
`global-requirements-android.md` — confirm those **first**; this guide adds the dedicated/COSU
specifics and does not duplicate the six.

> **Object names used throughout (use verbatim):**
> dedicated enrollment profile `Android Dedicated - COSU - Pilot` (and `Android Dedicated - COSU - Prod`);
> kiosk / device-restrictions profile `Android Dedicated - Kiosk - Pilot`;
> dedicated device group `Android Dedicated - Devices - Pilot` (dynamic, keyed on the enrollment profile
> name) and `Android Dedicated - Devices - Prod`;
> enrollment-restriction `Android Dedicated - Enrollment Restriction - Pilot`;
> Managed Home Screen app assignment (multi-app only) target = the dedicated device group.

## 2.1 Managed Google Play connection in place (category G2)
**Description:** Intune connected to **managed Google Play** — either the **managed Google Play account
enterprise** (tenants without Google Workspace) or the **Google Workspace / Cloud Identity ↔ Intune
third-party EMM** binding. One and only one model per tenant.
**Why required:** Dedicated enrollment and all app delivery ride on the managed Google Play connection;
without it you cannot create Android Enterprise enrollment profiles or assign apps.
**Why verify:** Intune → **Devices → Android → Android enterprise** (or **Enrollment**) shows the
connection **bound/active**; run **`COSU-Discovery.ps1`** (reports the account-enterprise binding).
**How to implement if missing:** Establish the binding first (this is a separate category solution),
then return here.

## 2.2 Least-privilege administrative role
**Description:** **Intune Administrator** for enrollment-profile, kiosk-policy, and app work
(**Global Administrator** only for the initial managed Google Play binding, which is a prerequisite,
not part of this solution).
**Why required:** Creating enrollment profiles, device-restriction/kiosk profiles, and app assignments
requires the corresponding Intune role.
**How to verify:** M365 admin center / Entra **Roles** shows Intune Administrator on the operator.
**How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 2.3 Corporate-owned, user-less devices (dedicated is the right model)
**Description:** The target devices are **company-owned**, purpose-built, and intended to run with
**no user affinity** (not personal / not BYOD).
**Why required:** Dedicated (COSU) enrolls as an Android Enterprise **device owner with no user**;
choosing it for personal devices is the wrong model and cannot be undone without a factory reset.
**How to verify:** Confirm ownership and single-purpose use with the device owners; the devices are
supplied factory-reset (or will be reset before enrollment).
**How to implement if missing:** If devices need a user or personal use, choose a different enrollment
model (work profile / fully managed) — not this solution.

## 2.4 Devices support Android Enterprise device-owner enrollment
**Description:** The device hardware/OS supports Android Enterprise **device-owner** mode and the
chosen enrollment method (QR/NFC readers as needed; camera for QR; NFC for NFC bump).
**Why required:** Kiosk/lock-task mode and dedicated enrollment require device-owner mode on a supported
Android version; very old or non-GMS devices may not qualify.
**How to verify:** Confirm the device model on Android Enterprise's supported/recommended list and the
minimum Android version your kiosk features require; a factory-reset test device provisions to device
owner.
**How to implement if missing:** Use supported hardware; update Android to the required minimum before
enrolling.

## 2.5 The dedicated enrollment profile + enrollment method decision
**Description:** A decided delivery method — **QR / token (afw#setup) / NFC / zero-touch** — and the
Intune **dedicated enrollment profile** `Android Dedicated - COSU - Pilot` that produces the token/QR.
**Why required:** Every method lands the device on the same profile; the profile's **token has an
expiry** and the QR encodes it.
**How to verify:** Intune → **Devices → Android → Enrollment → Corporate-owned dedicated devices**
shows the profile with a **non-expired token**; run **`COSU-Discovery.ps1`** (lists profiles + token
expiry + enrolled count).
**How to implement if missing:** Create it (Implementation Step 2) or with **`COSU-Set-Configuration.ps1`**;
for **zero-touch** additionally link the reseller-provisioned **zero-touch portal** (deferred to
Google/reseller docs).

## 2.6 Kiosk decision: single-app or multi-app (and the app list)
**Description:** A decision on **single-app** (one locked app) vs **multi-app** (curated set), and the
**exact package name(s)** the kiosk will allow.
**Why required:** The kiosk profile is built differently for each, and multi-app additionally needs the
**Managed Home Screen** launcher; the allow-list must reference **real, assigned** apps.
**How to verify:** You have the app package name(s) (from managed Google Play) and, for multi-app, have
identified the **Managed Home Screen** app (`com.microsoft.launcher.enterprise`).
**How to implement if missing:** Approve/select the apps in managed Google Play (2.7) and record their
package names before building the kiosk.

## 2.7 Managed Google Play apps approved and available
**Description:** The kiosk app(s) are **approved in managed Google Play** and available in Intune as
**`androidManagedStoreApp`** entries, ready to assign to the device group.
**Why required:** Dedicated devices have no user, so apps must be assigned to the **device** as
**Required**; a kiosk app that is not assigned/installed will not appear on the device.
**How to verify:** Intune → **Apps → Android** lists the app(s); run **`COSU-Discovery.ps1`** (reports
managed store apps).
**How to implement if missing:** Approve the app(s) in the managed Google Play surface inside Intune,
then assign them in Implementation Step 4.

## 2.8 A dedicated device group (dynamic, keyed on the enrollment profile)
**Description:** An Entra **device group** that captures dedicated devices automatically —
`Android Dedicated - Devices - Pilot`, typically a **dynamic device group** with a membership rule on
the **enrollment profile name**.
**Why required:** Dedicated devices have no user, so kiosk policy and apps are assigned to a **device
group**; a dynamic rule on the profile name means every device enrolled with the profile is captured
with no manual step.
**How to verify:** Entra → **Groups** shows the group; run **`COSU-Report.ps1`** (membership count).
**How to implement if missing:** Create it with **`COSU-Set-ScopeTargeting.ps1`** (default `-WhatIf`;
add `-Apply`). Example dynamic rule: `(device.enrollmentProfileName -eq "Android Dedicated - COSU - Pilot")`.

## 2.9 Enrollment restriction allowing corporate-owned dedicated Android
**Description:** Device platform **enrollment restrictions** that **allow** Android Enterprise
corporate-owned (dedicated) enrollment for the operators/scope doing the pilot.
**Why required:** If a restriction blocks corporate-owned Android or the platform, enrollment fails even
with a valid token.
**How to verify:** Intune → **Devices → Enrollment → Enrollment restrictions → Device platform
restrictions**; confirm Android (corporate-owned) is allowed; **`COSU-Discovery.ps1`** flags a blocking
default.
**How to implement if missing:** Adjust/scoped-create the restriction (Implementation Step 1).

## 2.10 Network reachability for enrollment + managed Google Play (category G5)
**Description:** The device network can reach the **Google (managed Google Play, Android provisioning)**
and **Microsoft (Intune, Entra)** endpoints; QR/token/NFC/zero-touch provisioning all download the DPC
and register the device.
**Why required:** Blocked endpoints are the most common cause of "provisioning failed / can't complete
setup" on dedicated devices.
**How to verify:** Confirm the documented Google/Microsoft endpoints are allowed on the device VLAN/SSID.
**How to implement if missing:** Allow the endpoints before enrolling (see category G5).

## 2.11 Pilot scope + change control (category G6)
**Description:** A small **pilot set** of representative dedicated devices and a **change-control**
window; enrollment-model and connector changes are high-impact.
**Why required:** The pilot proves the profile + kiosk before fleet rollout and protects production
devices; some changes may force **re-enrollment** (verify against current guidance).
**How to verify:** A named pilot device set and an approval window exist.
**How to implement if missing:** Define the pilot and agree change control before production changes.

---
## Checklist
- [ ] Managed Google Play connection bound/active (2.1 / category G2)
- [ ] Intune Administrator role on the operator (2.2)
- [ ] Devices are corporate-owned, user-less, purpose-built (2.3)
- [ ] Hardware/OS supports Android Enterprise device-owner + chosen method (2.4)
- [ ] Dedicated enrollment profile `Android Dedicated - COSU - Pilot` with a non-expired token (2.5)
- [ ] Single-app vs multi-app decided; kiosk app package name(s) recorded (2.6)
- [ ] Kiosk app(s) approved in managed Google Play and present in Intune (2.7)
- [ ] Dynamic device group `Android Dedicated - Devices - Pilot` keyed on the profile name (2.8)
- [ ] Enrollment restriction allows corporate-owned dedicated Android (2.9)
- [ ] Device network reaches Google/Microsoft endpoints (2.10 / category G5)
- [ ] Pilot device set + change-control window agreed (2.11 / category G6)


---


# Global Requirements — Microsoft Intune Android (Android Enterprise) Solutions

These requirements apply to **every** solution in the **Android** category (Android Enterprise
connection & managed Google Play, Google Workspace ↔ Intune EMM integration, the Android Management API
(AMAPI) migration, dedicated/COSU & work-profile enrollment, app management, and enrollment
troubleshooting). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every Android solution).** The **Microsoft Intune admin center**
> (intune.microsoft.com), **Microsoft Graph**, the **managed Google Play** enrollment surface, and the
> **Google Admin console** (for Google Workspace / Cloud Identity integration) are authored at exact,
> current click-by-click / cmdlet detail from Microsoft's and Google's public documentation. The
> **Android Management API (AMAPI)** transition (Intune's move off the legacy Play EMM API) and
> **web-based / account-driven enrollment** are **actively evolving** — steps, defaults, and whether a
> change triggers **re-enrollment** are **cited or flagged "verify against current Microsoft guidance /
> your tenant"**, never asserted from memory or invented. **OEM specifics** (Samsung Knox, Zebra, and
> other rugged/kiosk vendors) and **third-party apps** are integrated at the pattern level; their
> consoles are deferred to the vendor's docs. Automation is **PowerShell** (Microsoft Graph) — never
> with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with Intune and Android Enterprise
- **Description:** A Microsoft 365 tenant with **Microsoft Intune** and Android Enterprise available,
  and the licensing the capability requires.
- **Why required:** All Android policy, enrollment, and app configuration is performed in Intune.
- **How to verify:** Sign in to the Intune admin center; confirm Android platform availability.
- **How to implement if missing:** Provision/assign Intune licensing before starting.

## 2. The managed Google Play binding (account enterprise OR Google Workspace)
- **Description:** Intune connected to **managed Google Play** — either the **managed Google Play
  account enterprise** (for tenants WITHOUT Google Workspace) or the **Google Workspace / Cloud Identity
  ↔ Intune third-party EMM** integration (for tenants that use Google Workspace). One and only one model
  applies per tenant.
- **Why required:** Android Enterprise enrollment and app delivery depend on the managed Google Play
  connection; the two binding models are mutually exclusive and must be chosen deliberately.
- **How to verify:** Intune admin center → **Devices > Android > Android enterprise (or Enrollment)** —
  confirm the connection status and which model is in place.
- **How to implement if missing:** Establish the correct binding (this is often the first solution in the
  line) before enrolling devices.

## 3. Administrative access (least-privilege Intune roles)
- **Description:** Access with the least-privilege role the solution names — typically **Intune
  Administrator**, with **Global Administrator** only where genuinely required (e.g. the initial managed
  Google Play / Google Workspace binding).
- **Why required:** Enrollment, connector, and app changes require the corresponding role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 4. Enrollment method decision and Graph/PowerShell toolchain
- **Description:** A decided **enrollment method** — personally-owned **work profile** (BYOD), **fully
  managed**, **corporate-owned work profile**, or **dedicated / COSU (kiosk)** — plus a workstation with
  **Microsoft Graph PowerShell** for automation.
- **Why required:** Profiles, restrictions, and app assignment differ by enrollment method; the provided
  scripts run through Graph.
- **How to verify:** Confirm the target enrollment method(s) with the device owners; `Connect-MgGraph`
  succeeds.
- **How to implement if missing:** Choose the enrollment method and install Graph PowerShell before starting.

## 5. Network reachability to Google & Microsoft endpoints
- **Description:** Devices and the enrollment path can reach the required **Google (managed Google Play,
  Android)** and **Microsoft (Intune, Entra)** service endpoints (no proxy/filter blocks the enrollment
  or account sign-in).
- **Why required:** Enrollment, managed Google Play account provisioning, and adding a Google account all
  require reachability; blocked endpoints are a common cause of "can't add a Google account" failures.
- **How to verify:** Confirm the required endpoints are allowed on the device network.
- **How to implement if missing:** Allow the documented Google/Microsoft endpoints before enrolling.

## 6. A pilot scope and change control
- **Description:** A **pilot group / small device set** to validate on before fleet-wide rollout, and a
  **change-control** process for production changes (enrollment-model, connector, and AMAPI-migration
  changes are high-impact and may affect existing devices).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; the pilot proves the design and protects the production fleet.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

*The deployment model across every Android solution is the same: **Assess → Design → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.
Automation is delivered as **PowerShell** (Microsoft Graph) — never with hardcoded credentials or
secrets. Where the AMAPI transition or enrollment behavior is version-dependent, verify against current
Microsoft guidance rather than assuming.*


---


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


---


# 5. Testing Guide — Android Dedicated (COSU) / Kiosk Device Enrollment & Management

Run after the kiosk + apps are assigned and at least one device is enrolled (Implementation Steps 7–9),
and again after each expansion wave. Back each test with **`COSU-Discovery.ps1`** /
**`COSU-Validation.ps1`** / **`COSU-Report.ps1`**.

## Test 1 — Enrollment profile + token are valid
**Do:** Run **`COSU-Discovery.ps1`**; check Intune → **Devices → Android → Corporate-owned dedicated
devices**.
**Expected:** `Android Dedicated - COSU - Pilot` exists with a **non-expired token**; QR code available.

## Test 2 — Device enrolls as dedicated (no user)
**Do:** Enroll a factory-reset pilot device by the chosen method (QR / afw#setup / NFC / zero-touch);
check Intune → **Devices**.
**Expected:** The device appears as **corporate-owned dedicated**, **no primary user / device owner**,
enrolled with the profile.

## Test 3 — Device lands in the dynamic device group
**Do:** Run **`COSU-Report.ps1`**; check Entra → **Groups → `Android Dedicated - Devices - Pilot`**.
**Expected:** The enrolled device is a member (dynamic rule on the enrollment profile name captured it).

## Test 4 — Kiosk apps installed (Required-to-device)
**Do:** Run **`COSU-Validation.ps1`**; on the device, look for the app(s).
**Expected:** Every managed Google Play app assigned **Required** to the group is **installed**; for
multi-app, the **Managed Home Screen** launcher is present.

## Test 5 — Device boots to the kiosk (single-app)
**Do:** Reboot a single-app device.
**Expected:** It launches **straight into the one allowed app**; the user cannot exit to a launcher,
settings, or any other app.

## Test 6 — Multi-app kiosk shows only the allowed set
**Do:** On a multi-app device, review the Managed Home Screen.
**Expected:** **Only** the curated apps appear; no other apps, no full settings; toggles limited to what
the kiosk policy allows (Wi-Fi/Bluetooth/volume as configured); session PIN/exit behaves as set.

## Test 7 — Only-allowed-apps report is clean
**Do:** Run **`COSU-Validation.ps1`**.
**Expected:** The kiosk **allow-list matches the apps assigned** to the device group — no app named in
the kiosk is missing an assignment, and no unexpected app is exposed. Any mismatch is listed to fix.

## Test 8 — Device restrictions hold
**Do:** On the device, attempt blocked actions (add a Google account, factory reset from settings, USB
file transfer, safe boot) per your policy.
**Expected:** Each blocked action is **prevented**; allowed actions still work.

## Test 9 — Device is remotely manageable
**Do:** From Intune, run **Sync** and a benign device action (e.g. **Restart**) on the pilot device.
**Expected:** The action reaches the device; **`COSU-Report.ps1`** shows a recent **last check-in** and
the device **compliant** (if a compliance policy is assigned).

## Test 10 — Fleet health + OEM/inventory breakdown
**Do:** Run **`COSU-Report.ps1`**.
**Expected:** A clear count of dedicated devices with compliance state, last check-in, OS version, and
manufacturer/model (OEM breakdown, e.g. Zebra/Samsung); no unexpected stale or non-dedicated devices in
the group.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Enrollment pass** | Tests 1–3 pass (profile/token valid; device enrolls dedicated; joins the group) |
| **Kiosk pass** | Tests 4–7 pass (apps installed; boots to kiosk; only allowed apps; report clean) |
| **Lockdown + management pass** | Tests 8–10 pass (restrictions hold; remotely manageable; fleet healthy) |

> Do not expand beyond the pilot until all three gates pass. Re-run Tests 4–10 after each wave.


---


# 6. Troubleshooting Guide — Android Dedicated (COSU) / Kiosk Device Enrollment & Management

Symptom → likely root cause → fix. Use **`COSU-Discovery.ps1`** (readiness),
**`COSU-Validation.ps1`** (only-allowed-apps), and **`COSU-Report.ps1`** (fleet health) to confirm
before and after each fix. Where enrollment/kiosk behavior is **version-dependent, verify against
current Microsoft guidance / your tenant** rather than assuming.

## A. Enrollment

### "Can't set up device / provisioning failed" when scanning the QR (or afw#setup)
- **Managed Google Play not bound.** Dedicated enrollment requires the managed Google Play connection
  (category G2). **Fix:** run **`COSU-Discovery.ps1`**; if the binding is not active, establish it first.
- **Device not factory-reset / already has an account.** Device-owner enrollment needs a **clean**
  device with no Google account added. **Fix:** factory-reset and enroll **before** any account is added.
- **Network blocks provisioning.** The setup path downloads the DPC and registers the device. **Fix:**
  allow the documented Google/Microsoft endpoints on the device VLAN/SSID (category G5).
- **Token expired.** The enrollment profile's token has a lifetime. **Fix:** `COSU-Discovery.ps1` reports
  the expiry; extend/rotate the token in the profile and regenerate the QR.

### QR reader won't start on the Welcome screen
- **Wrong gesture / device variant.** The QR reader is launched by **tapping the same spot ~6 times** on
  the first setup screen; some OEMs vary. **Fix:** follow the OEM's device-owner QR steps; on older
  devices use **`afw#setup`** + token instead.

### Enrollment is blocked even with a valid token
- **Enrollment restriction blocks corporate-owned Android.** **Fix:** Intune → **Devices → Enrollment →
  Enrollment restrictions → Device platform restrictions**; allow Android Enterprise (corporate-owned)
  for the scope. `COSU-Discovery.ps1` flags a blocking default.

### NFC or zero-touch device doesn't auto-enroll
- **NFC payload/tooling issue** — the NFC bump payload is OEM/tooling-specific. **Fix:** defer to the OEM
  NFC-provisioning steps and confirm the token in the payload is current.
- **Zero-touch not assigned** — the reseller must assign your **zero-touch configuration** to the device
  serials in the **zero-touch portal**. **Fix:** confirm with the reseller (portal deferred to
  Google/reseller docs); the device must be purchased through a zero-touch reseller.

## B. Device group / targeting

### Device enrolled but got no kiosk or apps
- **Not in the device group yet.** Kiosk + apps are assigned to `Android Dedicated - Devices - Pilot`;
  dynamic membership can take a few minutes. **Fix:** wait, then `COSU-Report.ps1` / check Entra group
  membership.
- **Dynamic rule doesn't match the profile.** The rule must be
  `(device.enrollmentProfileName -eq "Android Dedicated - COSU - Pilot")` — exact profile name. **Fix:**
  run **`COSU-Set-ScopeTargeting.ps1`**; it flags a rule that doesn't reference the profile.
- **Assigned to a user instead of the device group.** Dedicated devices have **no user**; user-targeted
  assignments never land. **Fix:** re-target apps/kiosk to the **device** group.

## C. Kiosk / apps

### A kiosk app is missing on the device
- **App named in the kiosk but not assigned.** The allow-list must reference apps that are **Required to
  the device group**. **Fix:** run **`COSU-Validation.ps1`** — it lists "in kiosk but not assigned";
  assign each as Required, then re-check.
- **App still installing.** Managed Google Play installs can lag enrollment. **Fix:** give it time / force
  a **Sync**; confirm in `COSU-Report.ps1`.

### Multi-app kiosk shows a blank/black home screen
- **Managed Home Screen not deployed.** Multi-app uses `com.microsoft.launcher.enterprise` as the
  launcher. **Fix:** assign **Managed Home Screen** Required to the device group; `COSU-Validation.ps1`
  FAILs when it's missing on a multi-app kiosk.

### Extra apps are visible / device isn't as locked as expected
- **Assigned-but-not-in-kiosk apps.** An app Required to the group but absent from the allow-list can be
  reachable. **Fix:** `COSU-Validation.ps1` lists these as WARN — add them to the kiosk or remove the
  assignment.
- **Restrictions too loose.** **Fix:** tighten the device-restrictions profile (block add-accounts,
  factory reset by user, USB transfer, safe boot) and re-test (Testing Test 8).

### Single-app kiosk doesn't launch the app on boot
- **Wrong package or app not installed.** **Fix:** confirm the exact **packageId** in the kiosk matches
  an installed app (`COSU-Validation.ps1`); correct the package and ensure it's assigned Required.

## D. Remote management / health

### Device won't take remote actions / looks offline
- **Stale check-in.** The device is likely powered off or off-network. **Fix:** `COSU-Report.ps1` flags
  stale devices (no check-in within `-StaleDays`); investigate connectivity/power before assuming failure.
- **Retired/wiped.** A device removed from management won't respond. **Fix:** confirm state in Intune;
  re-enroll (factory reset) if needed.

### A policy/kiosk change didn't apply
- **Waiting on check-in, reboot, or re-enrollment.** Some changes apply on next check-in, some need a
  reboot, and **enrollment-model changes require a factory reset + re-enrollment**. **Fix:** force
  **Sync**; reboot; and **verify against current Microsoft guidance / your tenant** whether the specific
  change requires re-enrollment before rolling it fleet-wide.

## E. OEM / rugged (pattern level)
- **Scanner / OEM setting not taking effect.** These are delivered by the **OEM's OEMConfig app + app
  configuration**, not native kiosk settings. **Fix:** confirm the OEMConfig app is assigned Required to
  the device group and its configuration is correct; the schema is the OEM's — defer to Zebra/Samsung
  docs.

---
## Escalation checklist
1. `COSU-Discovery.ps1` — binding active, profile + token valid, apps present, no blocking restriction?
2. `COSU-Set-ScopeTargeting.ps1` — device group exists, rule matches the profile, device is a member?
3. `COSU-Validation.ps1` — kiosk allow-list matches assigned apps (only allowed apps), MHS present for multi-app?
4. `COSU-Report.ps1` — device compliant, checked in recently, expected OEM/OS?
5. Still stuck → capture the enrollment/kiosk symptom and **verify the current Microsoft guidance** for
   dedicated (COSU) / AMAPI behavior in your tenant before a fleet-wide change.


---


# 7. Best Practices — Android Dedicated (COSU) / Kiosk Device Enrollment & Management

Field-proven recommendations for a scalable, tamper-resistant dedicated-device fleet.

## Design
- **Pick dedicated for the right reason.** Dedicated = corporate-owned, **no user**, single-purpose.
  If a device needs a user or personal use, it is a different enrollment model — don't force it.
- **One profile per purpose, not per device.** A single `Android Dedicated - COSU - *` profile plus one
  kiosk policy should serve a whole class of identical devices. Split profiles only when the kiosk app
  set or hardware genuinely differs.
- **Target the device, never the (absent) user.** Assign everything — apps and kiosk — to a **dynamic
  device group keyed on the enrollment profile name**. This is the whole trick to managing user-less
  devices at scale and needs no manual grouping.
- **Prefer multi-app only when you need it.** Single-app kiosk is simpler and harder to escape; use
  multi-app (Managed Home Screen) when the job genuinely needs a curated set.

## Enrollment method
- **QR is the default; zero-touch is the endgame.** For existing stock, QR is fastest to pilot. For
  ongoing purchasing at scale, get the **reseller to assign your zero-touch configuration** so new
  devices enroll on first boot with no touch.
- **Watch the token expiry.** The enrollment profile token expires; **`COSU-Discovery.ps1`** reports it.
  Rotate/extend before it lapses or new enrollments fail.
- **Standardize the reset step.** Enrollment requires a **factory-reset** device; bake "reset →
  enroll → verify kiosk" into your provisioning runbook so staging is consistent.

## Apps and kiosk
- **Keep the kiosk allow-list and app assignments in lockstep.** Every app named in the kiosk must be
  **Required-to-device** on the group; every Required app that should be user-visible should be in the
  kiosk. Run **`COSU-Validation.ps1`** on every change — a drifted allow-list is the #1 "app is
  missing" cause.
- **Assign apps to the group before (or with) the kiosk.** If the kiosk deploys before the app installs,
  the tile is empty until the app catches up.
- **Harden with intent, not reflexively.** Block what defeats the purpose (add-accounts, factory reset
  by user, USB transfer, safe boot). Leave what the job needs (a specific input method, a scanner
  toggle). Over-blocking creates support tickets.

## OEM / rugged
- **Deliver OEM settings via OEMConfig, at the pattern level.** Zebra/Samsung scanner profiles, key
  remaps, and firmware control belong in the **OEM's OEMConfig app + app configuration**, assigned to
  the device group — not hand-set on devices. The schema is the OEM's; defer to their docs.
- **Control firmware/OS updates deliberately.** Frontline fleets hate surprise updates mid-shift; set
  the system-update policy to your maintenance window where the OEM/Android supports it.

## Operations
- **Pilot on a few, then wave.** Prove the profile + kiosk on a handful, pass all three testing gates,
  then expand in waves — validating each wave. Never flip the whole fleet at once.
- **Treat enrollment-model changes as high-impact.** Reversing dedicated needs a **wipe + factory reset**;
  some kiosk/restriction changes may need a reboot or (rarely) re-enrollment — **verify against current
  Microsoft guidance / your tenant** before a fleet-wide change.
- **Monitor for stale devices.** Run **`COSU-Report.ps1`** on a schedule; a device with an old
  last-check-in is likely powered off, off-network, or drifted — investigate before it fails silently.
- **Document rollback.** For any production kiosk change, know the revert: unassign the kiosk to relax,
  delete the token to stop new enrollments, wipe/retire to fully reset a device.

## Automation & security
- **Run the scripts read-only first.** `COSU-Discovery` / `COSU-Validation` / `COSU-Report` are
  read-only; the config helpers default to **`-WhatIf`** — preview before `-Apply`.
- **Least privilege, no secrets.** Connect with the **least Graph scopes** each task needs; never place
  credentials, tokens, or the enrollment token string in scripts or source control.
- **Keep the enrollment token secret-ish.** The QR/token enrolls any factory-reset device onto your
  tenant — treat it as sensitive; rotate it if it leaks.


---


# 8. Deliverables Summary — Android Dedicated (COSU) / Kiosk Device Enrollment & Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The dedicated/COSU model, enrollment methods (QR/token/NFC/zero-touch), single- vs multi-app kiosk, app delivery to user-less devices, OEM at pattern level |
| 2. Requirements Guide | Every dedicated/COSU prerequisite with Verify / Implement-if-missing (category Android GRs referenced, not duplicated) |
| Global Requirements (Android) | Category-wide Android prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune + Graph steps: enrollment profile, dynamic device group, app assignment, kiosk (single/multi), enroll, validate; pilot-first with pass/fail + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Enrollment, kiosk, app-delivery, and remote-management issues by symptom → root cause |
| 7. Best Practices | Field-proven recommendations for a scalable dedicated fleet |

## PowerShell scripts (Microsoft Graph)
| Script | What it does | Safety |
|---|---|---|
| `COSU-Discovery.ps1` | Dedicated-device readiness: managed Google Play binding, enrollment profile(s) + token expiry + enrolled count, managed store apps, blocking enrollment restrictions | Read-only |
| `COSU-Set-Configuration.ps1` | Creates the dedicated enrollment profile and the kiosk / device-restrictions profile (single- or multi-app) | Default `-WhatIf`; `-Apply` to write |
| `COSU-Validation.ps1` | Kiosk / restriction validation: the kiosk **allow-list vs the apps assigned** to the device group — the "only allowed apps" report, mismatches listed | Read-only |
| `COSU-Report.ps1` | Enrolled-fleet health/inventory: dedicated device count, compliance, last check-in, OS version, OEM (manufacturer/model) breakdown | Read-only |
| `COSU-Set-ScopeTargeting.ps1` | Scope/config helper: builds the dynamic device group keyed on the enrollment profile name (and reports kiosk/app assignment targeting) | Default `-WhatIf`; `-Apply` to write |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
A fleet of purpose-built Android **dedicated (COSU)** devices that boot straight to the job — enrolled
at scale by token / QR / NFC / zero-touch, locked to their app(s) via single- or multi-app kiosk, fed
managed Google Play apps to the device, and remotely managed — consistent, tamper-resistant, and proven
on a pilot before you scale.
