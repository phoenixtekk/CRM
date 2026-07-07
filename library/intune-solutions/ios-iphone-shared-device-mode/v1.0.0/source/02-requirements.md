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

## R11. Enrollment-time grouping owner (Intune Provisioning Client owns the Assigned shared group)
**Description:** When `iOS – Shared Devices` is an **Assigned** security group (the deterministic
targeting model), the **Intune Provisioning Client** first-party service principal — **AppId
`f1346770-5b25-470b-88bd-d5744ab7952c`**, often shown as **`Intune Autopilot ConfidentialClient`** —
must be an **Owner** of that group.
**Why:** Enrollment-time device grouping adds each newly enrolled shared iPhone to the Assigned group
by way of this principal *owning* the group. Without the owner the group stays **empty at enrollment**
and **none of the shared-device kiosk/restrictions/compliance profiles or the Cisco Webex app deploy**.
This is the same first-party principal and mechanism Windows Autopilot device preparation uses. Applies
when a **security group targets** the shared devices; a Dynamic group instead relies on its membership
rule and does not use this owner.
**Verify:** Entra → **Groups → `iOS – Shared Devices` → Owners** lists the service principal — confirm
by **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, not the display name (which varies by tenant).
Verify in your tenant before each pilot.
**Implement:** Entra → **Groups → `iOS – Shared Devices` → Owners → Add owners**, search by the AppId,
and add it. (If the principal isn't present, open the Intune portal once as Global Administrator to
provision it, then add it as owner.)
