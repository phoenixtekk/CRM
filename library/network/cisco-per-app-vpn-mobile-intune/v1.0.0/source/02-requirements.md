# Requirements

Confirm every prerequisite below **before** you configure anything. Each entry follows the same
shape — **Description / Why / Verify / Implement if missing** — so you can walk the list top to
bottom and close gaps as you go. Category-wide items (Entra tenant, Intune, admin roles, change
control, rollback) are in `global-requirements-network.md`; the items here are specific to Cisco
per-app VPN on managed mobile devices.

> **Vendor boundary:** the Cisco Secure Client mobile app and the Cisco VPN **head-end** (gateway/
> firewall remote-access role, typically with Cisco ISE) are configured in **Cisco's consoles** and
> are **deferred to Cisco's official documentation**. Below you confirm *that* the head-end exists,
> is reachable, and authenticates your chosen method — not *how* to build it in Cisco.

---

## R1. Intune enrollment for the target mobile devices

**Description:** The iOS and Android devices that will run per-app VPN are enrolled in Microsoft
Intune and compliant.
**Why:** Per-app VPN profiles, the Cisco Secure Client app, and the app-to-VPN association are all
delivered by Intune MDM. An unenrolled device cannot receive them.
**Verify:** `https://intune.microsoft.com` → **Devices → All devices**; confirm the target iPhones/
iPads and Android devices appear as **enrolled** and **compliant**.
**Implement if missing:** Assign an Intune-bearing license, then enroll — iOS via Apple enrollment
(see R6), Android via Android Enterprise enrollment (see R7).

## R2. Managed apps (the apps that will tunnel) deployed by Intune

**Description:** The specific business apps you want to tunnel are deployed and **managed** by Intune
(not sideloaded / personally installed copies).
**Why:** The association only engages for **Intune-managed** app instances. On iOS an unmanaged copy
of the same app will bypass the tunnel; on Android the VPN allow-list references the **managed**
package.
**Verify:** Intune → **Apps → All apps**; confirm each target app exists as an assigned app (iOS
store/VPP or LOB app; Android **Managed Google Play** app) and shows install/assignment to your users.
**Implement if missing:** Intune → **Apps → All apps → Add** → choose the platform app type
(iOS store app / iOS VPP / iOS LOB, or Android **Managed Google Play**), select the app, and assign
it to `PILOT – Per-App VPN Users`. Record each app's **bundle ID (iOS)** / **package name (Android)** —
you will need them for the association.

## R3. Cisco Secure Client app delivered as a managed app

**Description:** The **Cisco Secure Client** app (iOS and Android) is deployed through Intune as a
managed app to the target devices.
**Why:** The VPN profile is configured for connection type Cisco Secure Client; the client app must
be present and managed for the profile to bind and connect.
**Verify:** Intune → **Apps → All apps**; confirm **Cisco Secure Client** exists for iOS (App Store /
VPP) and for Android (**Managed Google Play**) and is assigned to your pilot group.
**Implement if missing:** Add **Cisco Secure Client** from the App Store (iOS) and from Managed Google
Play (Android) as managed apps, assign to `PILOT – Per-App VPN Users`, and set it **required** so it
installs ahead of the VPN profile.

## R4. A reachable Cisco VPN head-end with a supported auth method (Cisco side — deferred)

**Description:** A Cisco VPN **head-end** (gateway/firewall remote-access VPN role, policy typically
via Cisco ISE) that the Cisco Secure Client can reach, with a **connection name / server address**
and a **supported authentication method** (client certificate, or the method your head-end enforces).
**Why:** Intune's VPN profile only points the client at the head-end and carries per-app rules; the
head-end must accept the connection and authenticate it. Without a working head-end there is nothing
to tunnel to.
**Verify:** With Cisco Secure Client on a test device, confirm you can reach and authenticate to the
head-end connection entry (following Cisco's docs). Record the exact **server address / connection
name** and the **auth method** the head-end expects.
**Implement if missing:** Stand up / configure the head-end connection profile, address pool, and
split-tunnel/split-DNS **per Cisco's official documentation** (deferred here). This solution consumes
its server address and auth method; it does not build the Cisco side.

## R5. Authentication material — certificate profile or the chosen auth method

**Description:** The credential the client presents to the head-end. For certificate auth: a
**trusted root certificate** profile and a **user/device SCEP or PKCS certificate** profile in Intune
named `Cisco Per-App VPN – User Cert`. For other methods (e.g. federated / SAML at the head-end),
the corresponding identity path.
**Why:** The tunnel will not establish if the client cannot authenticate. Certificate auth is the
common, silent, per-app-friendly choice and is delivered by Intune to the managed device.
**Verify:** Intune → **Devices → Configuration** shows a **Trusted certificate** profile and a
**SCEP/PKCS certificate** profile assigned to the same pilot group; on a test device the cert is
present in the keychain/credential store.
**Implement if missing:** Intune → **Devices → Configuration → Create → New policy** → platform →
profile type **Trusted certificate** (deploy your issuing CA root), then a second policy of type
**SCEP certificate** (or **PKCS certificate**) named `Cisco Per-App VPN – User Cert` pointing at your
NDES/PKCS connector, and assign both to `PILOT – Per-App VPN Users`. Match the certificate's subject/
SAN and EKU to what the head-end expects (per Cisco docs).

## R6. iOS: supervised / ADE enrollment + working APNs

**Description:** Target iOS/iPadOS devices are **supervised** (enrolled through **Automated Device
Enrollment / ADE** via Apple Business Manager) and Intune has a valid **APNs** certificate.
**Why:** Reliable per-app VPN association is expected on supervised devices; APNs is required for
Intune to manage iOS at all. Without APNs, no iOS policy (including the VPN profile) is delivered.
**Verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate** shows a valid,
non-expired APNs certificate; target devices show **Supervised = Yes** under device details.
**Implement if missing:** Upload/renew the **Apple MDM Push (APNs)** certificate; connect **Apple
Business Manager** to Intune and (re)enroll target devices through **ADE** so they are supervised.

## R7. Android: Android Enterprise enrollment + Managed Google Play

**Description:** Target Android devices are enrolled in **Android Enterprise** (work profile for BYOD
or fully managed for corporate-owned) with **Managed Google Play** connected to Intune.
**Why:** Android per-app (app-based) VPN and managed apps require the Android Enterprise management
profile and package-name references from Managed Google Play.
**Verify:** Intune → **Devices → Enrollment → Android → Managed Google Play** shows **connected**;
target devices show an Android Enterprise ownership type (work profile / fully managed).
**Implement if missing:** Intune → **Devices → Enrollment → Android → Managed Google Play → Connect**
(bind your Managed Google Play account), then enroll devices into the appropriate Android Enterprise
mode.

## R8. Entra security groups for targeting

**Description:** Entra ID security groups used to scope assignment: a pilot group
`PILOT – Per-App VPN Users` and a broad group `BROAD – Per-App VPN Users`.
**Why:** Every profile, app, and certificate is assigned to a group. Piloting to a small group first
is how you validate "only the right apps tunnel" before fleet rollout.
**Verify:** Entra → **Groups**; both `PILOT – Per-App VPN Users` and `BROAD – Per-App VPN Users`
exist.
**Implement if missing:** Create them in Entra (**Groups → New group → Security**), or run
`CPAVPN-Set-ScopeTargeting.ps1` (in this solution) to create/populate the pilot group. Start with a
handful of known test users/devices in the pilot group.

## R9. A pilot group of real test users/devices

**Description:** A small set of **real** pilot users on **real** enrolled iOS and Android devices,
placed in `PILOT – Per-App VPN Users`.
**Why:** Per-app VPN behavior (does the app tunnel? does other traffic stay direct?) must be observed
on actual devices before expanding; simulators do not exercise the association reliably.
**Verify:** `PILOT – Per-App VPN Users` contains at least one enrolled iOS device and one enrolled
Android device belonging to cooperating testers.
**Implement if missing:** Add cooperating testers (and/or their devices) to `PILOT – Per-App VPN
Users`; confirm their devices are enrolled and compliant per R1.

## R10. Change control and rollback (from global requirements)

**Description:** A change window and a written rollback: **un-assign** the per-app VPN profiles from
the group (or remove the association) to revert to no-tunnel behavior; optionally remove the Cisco
Secure Client app.
**Why:** VPN/network changes affect how business apps reach internal resources and must be reversible.
**Verify:** The rollback steps are written and approved before the pilot goes live (see G7 in
`global-requirements-network.md`).
**Implement if missing:** Document the rollback (remove profile assignment from `PILOT – Per-App VPN
Users`) and a comms plan for testers.
