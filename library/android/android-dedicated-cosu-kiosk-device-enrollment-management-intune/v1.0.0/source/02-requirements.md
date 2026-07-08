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
