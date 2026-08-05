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
