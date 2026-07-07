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

## R11. Enrollment-time grouping owner for the shared group (Intune Provisioning Client as Owner)
**Description:** When `iOS – Shared Devices` is an **Assigned** security group (the deterministic
targeting model for the shared provisioning model), the **Intune Provisioning Client** first-party
service principal — **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, often shown as **`Intune
Autopilot ConfidentialClient`** — must be an **Owner** of that group.
**Why:** Enrollment-time device grouping adds each newly enrolled shared iPhone to the Assigned group
by way of this principal *owning* the group. Without the owner the group stays **empty at enrollment**
and **none of the shared-device lock-down (restrictions/kiosk/compliance) profiles or apps deploy**.
This is the same first-party principal and mechanism Windows Autopilot device preparation uses. Applies
when a **security group targets** the shared devices; a Dynamic group instead relies on its membership
rule and does not use this owner.
**Verify:** Entra → **Groups → `iOS – Shared Devices` → Owners** lists the service principal — confirm
by **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, not the display name (which varies by tenant).
Verify in your tenant before each pilot.
**Implement:** Entra → **Groups → `iOS – Shared Devices` → Owners → Add owners**, search by the AppId,
and add it. (If the principal isn't present, open the Intune portal once as Global Administrator to
provision it, then add it as owner.)

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
- [ ] Intune Provisioning Client (AppId `f1346770-5b25-470b-88bd-d5744ab7952c`) is an Owner of the Assigned `iOS – Shared Devices` group (R11)
