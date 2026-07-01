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
