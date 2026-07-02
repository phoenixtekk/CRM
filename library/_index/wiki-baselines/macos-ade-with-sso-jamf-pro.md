# macOS Automated Device Enrollment with SSO (Jamf Pro + Intune)

> **Version 1.0.0** · Category: Intune · Solution code: JAMFADE

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Apple **Automated Device Enrollment (ADE)** turns every company-owned Mac into a zero-touch,
supervised, fully managed device the moment it is powered on — no imaging, no manual MDM steps, no
local-admin hand-holding. This solution manages those Macs with **Jamf Pro**, the dedicated
macOS management platform, and connects them to **Microsoft Entra ID** so sign-in is enforced with
corporate identity and Conditional Access.

Most organizations that already run Jamf for their Mac fleet still need their Macs to be
**first-class citizens in Microsoft Entra**: registered, compliant, and gated by the same
Conditional Access policies as their Windows estate. This solution delivers exactly that, as a
single, repeatable deployment a Mac admin can follow end to end:

- **Zero-touch provisioning with Jamf.** Macs in **Apple Business Manager** are assigned to a Jamf
  Pro **Automated Device Enrollment** instance and a **PreStage Enrollment**, so they enroll
  supervised, branded, and pre-loaded the first time they run Setup Assistant.
- **Platform SSO with the Microsoft Enterprise SSO plug-in.** Jamf deploys the Single Sign-On
  Extension configuration profile. Users sign in to macOS and to Microsoft 365 with their **Entra
  ID** identity, backed by a hardware-bound **Secure Enclave** key — phishing-resistant, not a synced
  password.
- **Compliance flows Jamf → Intune.** The **Jamf Pro ↔ Intune Device Compliance** integration
  registers each Mac in Entra and reports its Jamf compliance state to Intune, so Macs appear in
  **Intune → Devices** as partner-managed and compliant.
- **SSO enforced by Conditional Access.** Entra **Conditional Access** requires a compliant,
  registered Mac (and, optionally, a phishing-resistant authentication strength) before granting
  access to Microsoft 365 — turning Platform SSO from "available" into **mandatory**.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click steps across both consoles, a requirements guide that tells you
how to verify *and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph and
the Jamf Pro API), and testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** company Macs that Jamf provisions and manages, that authenticate with corporate identity
via a phishing-resistant Secure Enclave key, and that Entra Conditional Access treats as compliant,
registered, SSO-enforced devices — delivered by your own team, in a controlled pilot, without a
consulting engagement.


---


# 1. Solution Overview — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

## What this solution is
This solution stands up company-owned Macs that **Jamf Pro manages** and **Microsoft Entra enforces**.
It combines three capabilities into one repeatable deployment:

1. **Automated Device Enrollment (ADE)** — Apple's zero-touch enrollment program (formerly DEP).
   Company-owned Macs that belong to your **Apple Business Manager (ABM)** organization are assigned
   to **Jamf Pro** as their MDM and enroll automatically — **supervised** — the first time they run
   Setup Assistant. Management is mandatory and locked to the device.
2. **Platform Single Sign-On (Platform SSO)** — Apple's macOS framework that lets a third-party
   identity provider extend sign-in to the Mac itself. **Jamf deploys** the **Microsoft Enterprise
   SSO** extension via a configuration profile, so the Mac registers with **Microsoft Entra ID** and
   users authenticate with their corporate identity at the login window and across apps and
   Safari/Edge/Chrome.
3. **Jamf Pro ↔ Microsoft Intune Device Compliance** — the supported integration that registers each
   Jamf-managed Mac in **Entra ID** and reports its **compliance** state to **Intune**. Combined with
   Entra **Conditional Access**, this is what makes SSO **enforced**: only a compliant, registered Mac
   is allowed into Microsoft 365.

Together they give you a Mac that Jamf provisions and manages, that signs in with corporate identity,
and that Conditional Access treats as a trusted, compliant device.

## Why Jamf as the MDM (and Intune for identity & compliance)
A macOS device can have **only one MDM authority**. Organizations that have standardized on **Jamf
Pro** for deep, Mac-native management (PreStage, policies, patch, Self Service) keep Jamf as the MDM
— you do **not** move those Macs into Intune. Instead, you connect Jamf to the Microsoft cloud so the
Macs become **Entra-registered and Intune-compliant**, and you enforce access with the **same
Conditional Access** policies that protect the rest of your estate. Intune is the **identity and
compliance authority**; Jamf is the **device management authority**. This is the only architecture in
which "Jamf Pro device management" and "SSO enforced via Intune/Entra" coexist correctly.

## How it works
1. **ABM → Jamf Pro.** You connect ABM to Jamf Pro with an **Automated Device Enrollment** instance
   (an ADE/MDM-server token). Macs assigned to the Jamf MDM server in ABM enroll into Jamf.
2. **PreStage Enrollment.** A **PreStage Enrollment** in Jamf defines the out-of-box experience:
   supervised mode, account creation, which Setup Assistant panes to skip, and which apps/profiles
   pre-load.
3. **Power on → enroll.** When a user (or technician) powers on the Mac and connects to a network,
   Setup Assistant contacts Apple, discovers the Jamf MDM server, and enrolls automatically. The
   device becomes supervised and managed by Jamf; your apps and profiles flow down.
4. **Platform SSO registration.** Jamf deploys a **Single Sign-On Extension** configuration profile
   (Microsoft Enterprise SSO) and the **Company Portal** app. On first sign-in, Company Portal
   completes Platform SSO **registration**: the Mac generates a hardware-bound key in the **Secure
   Enclave** and registers with Entra ID.
5. **Compliance to Intune.** Through the **Jamf Pro ↔ Intune Device Compliance** connector, Jamf
   sends the Mac's inventory and compliance state to Intune; the Mac appears in **Intune → Devices**
   as a partner-managed, compliant device.
6. **SSO enforced.** Entra **Conditional Access** requires a **compliant** (and optionally
   phishing-resistant) Mac before granting Microsoft 365 access. Platform SSO supplies the credential;
   Conditional Access makes it mandatory.

## Platform SSO authentication methods (choose one)
- **Secure Enclave key (recommended)** — a hardware-bound key in the Mac's Secure Enclave signs
  authentication. Phishing-resistant; the local password is decoupled from Entra. Best security.
- **Password sync** — the user's local macOS password is kept in sync with their Entra password.
  Simplest for users; least hardened.
- **Smart card** — authentication via a smart card/certificate. For high-assurance environments.

This solution standardizes on the **Secure Enclave key** method, with notes for the alternatives.

## Benefits
- **Zero-touch deployment** — Macs enroll supervised into Jamf on first boot; no imaging, no manual MDM steps.
- **Keep your Jamf investment** — full Mac-native management (PreStage, policies, patch, Self Service) stays in Jamf.
- **Corporate identity on the Mac** — Entra sign-in at the login window and across apps/browsers.
- **Phishing-resistant** — Secure Enclave key, hardware-bound, never leaves the device.
- **Compliance in Intune** — Macs appear as partner-managed, compliant devices alongside Windows.
- **SSO enforced** — Conditional Access blocks non-compliant or non-registered Macs from Microsoft 365.

## Limitations (be honest with buyers)
- A Mac has **one MDM**. In this design **Jamf is the MDM**; the Macs are **not** Intune-MDM-managed.
  Conditional Access works via the **partner compliance** integration, not Intune-native MDM.
- ADE requires devices to be in **Apple Business Manager** (purchased via Apple/an authorized
  reseller, or added with **Apple Configurator** — the latter adds a provisional 30-day release period).
- Platform SSO requires **macOS 13 Ventura or later** (macOS 14 Sonoma+ strongly recommended).
- Requires Jamf's **APNs (MDM Push) certificate** and the **ADE/ABM token**, both renewed annually —
  hard expiry dates that block enrollment if missed.
- Platform SSO registration and compliance reporting depend on the **Company Portal** app and the
  **Microsoft Enterprise SSO** extension being present and current.
- Microsoft and Jamf have **evolved** the integration over time (the legacy "Conditional Access"
  connector was superseded by **Device Compliance**). Always confirm the **current** integration name
  and steps in the Jamf and Microsoft documentation before connecting.
- Personally-owned (BYO) Macs use a different (user-enrollment) path and are out of scope here.

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Company-owned, Apple Business Manager–sourced Macs, automatically enrolled into Jamf Pro
> (supervised), registered with Microsoft Entra ID and reporting compliance to Intune via the Jamf ↔
> Intune Device Compliance integration, with Platform SSO via the Microsoft Enterprise SSO extension
> and a Secure Enclave key, and SSO enforced by Entra Conditional Access.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (Entra tenant, Intune licensing, admin roles, pilot group, network) are covered once in
the **Global Requirements — Intune Solutions** document; the items here are specific to Jamf-managed
Apple ADE, Platform SSO, and the Jamf ↔ Intune Device Compliance integration.

## R1. Apple Business Manager (or Apple School Manager) account
**Description:** A verified Apple Business Manager (ABM) organization.
**Why:** ADE only works for devices that belong to your ABM organization; ABM is also where you
assign devices to the **Jamf Pro** MDM server and accept device-management terms.
**Verify:** Sign in to `https://business.apple.com` with an ABM Administrator account; the
organization status is **active**.
**Implement:** Enroll at `https://business.apple.com/enroll` using your **D-U-N-S** number; complete
Apple's verification. Allow 1–5 business days.

## R2. Jamf Pro tenant with administrative access
**Description:** A licensed **Jamf Pro** instance (cloud or on-prem) and an admin account with rights
to manage enrollment, configuration profiles, and integrations.
**Why:** Jamf Pro is the **MDM authority** in this design — it enrolls, supervises, and manages the
Macs and deploys the SSO profile and Company Portal.
**Verify:** Sign in to your Jamf Pro console (e.g. `https://yourorg.jamfcloud.com`) as an
administrator; **Settings** is accessible.
**Implement:** Provision Jamf Pro (Jamf Cloud is fastest) and assign an administrator role with
**Settings**, **Enrollment**, and **Configuration Profiles** privileges.

## R3. Jamf Pro Apple Push Notification service (APNs) certificate
**Description:** A valid MDM Push certificate connecting **Jamf Pro** to Apple's push service.
**Why:** Every Apple device managed by Jamf requires APNs; without it, no Mac can enroll or receive
commands. (This certificate lives in **Jamf**, not Intune.)
**Verify:** Jamf Pro → **Settings → Global → Push certificates** (or **Global Management → Push
Certificates**) shows a valid Apple **MDM Push** certificate with a future expiration.
**Implement:** In Jamf Pro, create a Push Certificate request, sign in to
`https://identity.apple.com` with a **company Apple ID** (not personal), upload the signed
certificate. **Renew annually with the same Apple ID** — a new Apple ID re-issues the cert and
unenrolls all devices.

## R4. Automated Device Enrollment instance in Jamf Pro (ABM ↔ Jamf token)
**Description:** An ABM **MDM server** that points to Jamf, with its server token (`.p7m`) uploaded
into Jamf Pro as an **Automated Device Enrollment** instance.
**Why:** This is the trust link that lets ABM-assigned devices enroll into your Jamf tenant.
**Verify:** Jamf Pro → **Settings → Global → Automated Device Enrollment**; an instance is listed
with a future token expiration.
**Implement:** In Jamf Pro, download the **public key**; in ABM **Preferences → MDM Servers**, create
an MDM server named clearly (e.g. **Jamf – Production**), upload the public key, download the server
token; upload that token into Jamf's Automated Device Enrollment settings. **Renew annually.**

## R5. Devices present in Apple Business Manager and assigned to Jamf
**Description:** The target Macs appear in ABM and are assigned to the **Jamf** MDM server.
**Why:** Only ABM devices can use ADE, and assignment tells Apple which MDM a device should enroll
into during Setup Assistant.
**Verify:** ABM → **Devices** → select the device → **MDM Server** shows your **Jamf** server.
**Implement:** Purchase through Apple or an **Apple-authorized reseller** linked to your ABM (devices
appear automatically), or add existing Macs with **Apple Configurator** (note: Configurator-added
devices get a **30-day provisional period**). Then ABM → **Devices** → **Edit MDM Server** → choose
the **Jamf** server, and in Jamf **refresh** the ADE instance.

## R6. Jamf PreStage Enrollment for macOS
**Description:** A macOS **PreStage Enrollment** in Jamf that defines the zero-touch experience.
**Why:** The PreStage controls supervision, account creation, the Setup Assistant panes shown/hidden,
and which configuration profiles and apps deploy at enrollment.
**Verify:** Jamf Pro → **Computers → PreStage Enrollments**; a macOS PreStage exists and has devices
scoped to it.
**Implement:** Create a PreStage (Implementation Guide §Phase 2), enable **Supervision** and **Make
MDM Profile Mandatory**, set account creation, and scope the target serial numbers.

## R7. Supported macOS version
**Description:** macOS **13 Ventura or later** (macOS **14 Sonoma+ recommended**).
**Why:** Platform SSO and the Secure Enclave authentication method require macOS 13+; later releases
materially improve registration reliability.
**Verify:** Apple menu → **About This Mac**, or Jamf → device **Inventory → Operating System**.
**Implement:** Upgrade via **System Settings → General → Software Update**, or enforce a minimum OS
with a Jamf **Smart Group** + policy and a matching Intune **compliance** rule.

## R8. Company Portal app for macOS (deployed by Jamf)
**Description:** The Microsoft **Company Portal** application installed on the Mac by **Jamf**.
**Why:** Company Portal performs the Platform SSO **registration** with Entra ID **and** the device
registration that the Jamf ↔ Intune compliance integration depends on.
**Verify:** Jamf Pro → **Computers → Configuration Profiles / Apps**; Company Portal is scoped to your
pilot group and installs post-enrollment.
**Implement:** Add the macOS Company Portal as a Jamf **package/app** (or via the App Installers /
VPP) and scope it to the pilot Smart Group as **Required**.

## R9. Microsoft Enterprise SSO extension profile (deployed by Jamf)
**Description:** The **Microsoft Enterprise SSO** plug-in delivered via a Jamf macOS **Single Sign-On
Extensions** configuration profile (Platform SSO).
**Why:** This Apple-approved redirect extension brokers Entra authentication for Platform SSO and
app/browser single sign-on.
**Verify:** Jamf Pro → **Computers → Configuration Profiles**; a profile with a **Single Sign-On
Extensions** payload (Platform SSO) exists targeting your pilot group.
**Implement:** Create it during deployment (Implementation Guide §Phase 3), or run the included
`JAMFADE-Set-JamfSSOProfile.ps1` to upload it via the Jamf Pro Classic API.

## R10. Jamf Pro ↔ Microsoft Intune Device Compliance integration
**Description:** The supported connector that registers Jamf-managed Macs in **Entra ID** and reports
their **compliance** to **Intune**.
**Why:** This is what makes the Macs appear as compliant in Intune and lets **Conditional Access**
enforce SSO/compliance — without it, Jamf-managed Macs are invisible to Entra/Intune policy.
**Verify:** Intune admin center → **Tenant administration → Connectors and tokens → Partner device
management** (or **Partner compliance management**) shows **Jamf** as **Active**; in Jamf, **Settings
→ Global → Device Compliance** (macOS) is **connected**.
**Implement:** In Intune, enable the **Partner device management / compliance** connection for Jamf;
in Jamf, **Settings → Global → Device Compliance → macOS → Configure**, sign in with a Global
Administrator to grant the cloud-connector app consent, and complete the connection. Confirm the exact
current path in Jamf and Microsoft docs (the integration was renamed from the legacy "Conditional
Access").

## R11. Entra ID Conditional Access policy for macOS
**Description:** A Conditional Access policy that requires a **compliant** (and optionally
phishing-resistant) Mac for Microsoft 365.
**Why:** This converts Platform SSO from "available" to **enforced** — non-compliant or
non-registered Macs are blocked.
**Verify:** Entra → **Protection → Conditional Access**; a policy targets **macOS** and requires
**Require device to be marked as compliant** (start in **report-only**).
**Implement:** Create the policy in Implementation Guide §Phase 4; pilot in **report-only**, then
enable.

## R12. Network access to Apple, Jamf, and Microsoft endpoints
**Description:** Outbound HTTPS to Apple's enrollment/push/software endpoints, your Jamf Pro host, and
Microsoft Entra/Intune endpoints.
**Why:** Setup Assistant, ADE discovery, APNs, Jamf check-in, Entra registration, and compliance
reporting all depend on these endpoints.
**Verify:** From the device network, reach `https://mdmenrollment.apple.com`, `https://gdmf.apple.com`,
the Apple push range `*.push.apple.com` (TCP 443 and 5223), your `*.jamfcloud.com` host, and
`https://login.microsoftonline.com`.
**Implement:** Allow Apple's published ranges (Apple support article HT210060), your Jamf Cloud host,
and Microsoft's Entra/Intune ranges through proxy/firewall. Do **not** TLS-inspect Apple
push/enrollment.


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
**Why:** Policies only reach enrolled devices, regardless of platform (Windows, macOS, iOS/iPadOS, Android).
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Configure the appropriate enrollment method for the platform (e.g. automatic enrollment for Windows, Automated Device Enrollment for Apple) and enroll the device.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted to a small group before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists with intended members.
**Implement:** Entra → **Groups → New group** → type **Security** → add pilot members.

## G6. Supported, current operating system
**Description:** A supported OS baseline with current updates for the targeted platform.
**Why:** Modern Intune features and security settings assume a patched, vendor-supported OS.
**Verify:** Check the device's OS version (e.g. `winver` on Windows, **About This Mac** on macOS) or Intune → device → **Hardware**.
**Implement:** Deploy update policies (Windows Update rings, macOS update/compliance policies) or upgrade to a supported release.

## G7. Network access to required cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs (plus Apple endpoints for Apple-platform solutions).
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges (and Apple's published ranges where applicable) through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything
against a **pilot group / pilot Smart Group** first.

Consoles used:
- **Apple Business Manager** — `https://business.apple.com`
- **Jamf Pro** — your instance, e.g. `https://yourorg.jamfcloud.com`
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com`

> **Integration naming note:** Microsoft and Jamf renamed the macOS integration from the legacy
> "Conditional Access" to **Device Compliance / Partner device management**. The steps below use the
> current model; confirm the exact menu labels in your tenant's Jamf and Microsoft docs.

---

## Phase 1 — Connect Apple to Jamf Pro

### Step 1. Create the Jamf APNs (MDM Push) certificate
1. In Jamf Pro, go to **Settings → Global → Push certificates** (or **Global Management → Push
   Certificates**).
2. Click **New**, choose to create an **MDM Push Certificate**, and **download the CSR**.
3. Click through to **Apple Push Certificates Portal** (`https://identity.apple.com`) and sign in with
   a **company Apple ID** (record which Apple ID — you must reuse it every year).
4. **Create a Certificate**, upload the CSR, then **download** the signed `.pem`.
5. Back in Jamf, **upload** the `.pem` and enter the Apple ID used.
6. Confirm the certificate shows **valid** with an expiration ~1 year out.

### Step 2. Create the Automated Device Enrollment instance (download Jamf public key)
1. In Jamf Pro, go to **Settings → Global → Automated Device Enrollment**.
2. Click **New** and **download the public key** (`.pem`).

### Step 3. Create the MDM server in Apple Business Manager
1. In ABM, go to **Preferences (your name, bottom-left) → MDM Servers**.
2. Click **Add** (or **+**). Name it clearly, e.g. **Jamf – Production**.
3. Under **MDM Server Settings**, **Upload** the Jamf public key from Step 2.
4. Click **Save**, then **Download Token** — this downloads the server token (`.p7m`).

### Step 4. Upload the ABM token into Jamf
1. Back in Jamf's **Automated Device Enrollment** instance, **upload** the `.p7m` server token and
   enter the **Apple ID** used for ABM.
2. **Save.** The instance shows a future token expiration. Use **Refresh** to pull assigned devices.

---

## Phase 2 — Assign devices and define the enrollment experience

### Step 5. Assign Macs to the Jamf MDM server (in ABM)
1. In ABM, go to **Devices**.
2. Select the target Mac(s) by serial number (or filter by order).
3. Click **Edit MDM Server** → choose your **Jamf – Production** server → **Continue → Confirm**.

### Step 6. Refresh and confirm devices in Jamf
1. In Jamf Pro → **Settings → Global → Automated Device Enrollment → (your instance)**, click
   **Refresh** (Apple rate-limits syncs; allow a few minutes).
2. Confirm the assigned serial numbers appear under the instance.

### Step 7. Create the macOS PreStage Enrollment
1. In Jamf Pro, go to **Computers → PreStage Enrollments → New**.
2. **General:** name it (e.g. **macOS ADE – Pilot**); select the **Automated Device Enrollment
   instance** from Step 4.
3. Enable **Supervision** and **Make MDM Profile Mandatory** (prevents users from removing
   management).
4. **Account Settings:** configure the local account creation model (e.g. create a managed admin and
   a standard user, or defer user creation to Platform SSO per your design).
5. **Configuration Profiles / Enrollment Packages:** attach the **Single Sign-On Extensions** profile
   (Step 10) and the **Company Portal** app (Step 9) so they deploy at enrollment.
6. **Setup Assistant panes:** hide unnecessary panes (Restore, Apple ID, Siri, Analytics, Touch ID as
   policy dictates) for a clean first-run; keep **Location** and **Privacy** as required.
7. **Scope:** assign the pilot serial numbers. **Save.**

---

## Phase 3 — Deploy Company Portal and Platform SSO (via Jamf)

### Step 8. Create the pilot Smart Group
1. In Jamf Pro, go to **Computers → Smart Computer Groups → New**.
2. Name it **macOS SSO – Pilot**; add a criterion that matches your pilot devices (e.g. by PreStage,
   building, or serial list). **Save.**

### Step 9. Add and scope the Company Portal app
1. In Jamf Pro, add **Company Portal** for macOS — via **Computers → Mac Apps** (App Installers/VPP)
   or as a signed **package** under **Computers → Packages** + a policy.
2. Scope it to the **macOS SSO – Pilot** Smart Group, set to install automatically (Required).

### Step 10. Create the Platform SSO configuration profile
1. In Jamf Pro, go to **Computers → Configuration Profiles → New**.
2. **General:** name it **macOS Platform SSO – Pilot**; **Level = Computer Level**.
3. Add the **Single Sign-On Extensions** payload and configure:
   - **Payload Type:** **SSO** (Redirect)
   - **Extension Identifier:** `com.microsoft.CompanyPortalMac.ssoextension`
   - **Team Identifier:** `UBF8T346G9`
   - **Sign-On Type:** **Redirect**
   - **URLs:** `https://login.microsoftonline.com`, `https://login.microsoft.com`,
     `https://sts.windows.net`, `https://login.partner.microsoftonline.cn`,
     `https://login.chinacloudapi.cn`, `https://login.microsoftonline.us`,
     `https://login-us.microsoftonline.com`
   - **Platform SSO → Authentication Method:** **Secure Enclave Key** (recommended)
   - Enable **Use Platform SSO** and (optional) **Token to user identifier** / new-user creation per
     your account model.
4. **Scope** to the **macOS SSO – Pilot** Smart Group. **Save.**

> Prefer automation? Run the included **`JAMFADE-Set-JamfSSOProfile.ps1`** (Jamf Pro Classic API) to
> upload and scope this profile with the values above — then verify it in the Jamf console.

---

## Phase 4 — Connect Jamf to Intune and enforce SSO

### Step 11. Enable the Jamf ↔ Intune Device Compliance integration
1. In **Intune** → **Tenant administration → Connectors and tokens → Partner device management** (or
   **Partner compliance management**), enable the connection for **Jamf** (this consents the Jamf
   cloud-connector app in Entra).
2. In **Jamf Pro** → **Settings → Global → Device Compliance → macOS → Configure**.
3. Click **Connect**, sign in with a **Global Administrator** to grant consent, and complete the
   connection. Confirm Jamf reports the connection as **active**.
4. In Intune, **Tenant administration → Partner device management** now shows **Jamf** as **Active**.

### Step 12. Confirm device registration & compliance flow
1. In Jamf, ensure the pilot Smart Group is **scoped for compliance** (the macOS Device Compliance
   settings define which computers register and report).
2. After a pilot Mac registers (via Company Portal), confirm it appears in **Intune → Devices →
   macOS** as **partner-managed** with a **compliance** state.

### Step 13. Create the macOS Conditional Access policy (enforce SSO)
1. In **Entra → Protection → Conditional Access → Create new policy**; **name it `CA – macOS (Jamf) Compliant – Pilot`**.
2. **Users:** your pilot group. **Target resources:** Office 365 (and other apps as needed).
3. **Conditions → Device platforms:** **macOS**.
4. **Grant:** **Require device to be marked as compliant** (optionally add **Require authentication
   strength → Phishing-resistant** to require the Secure Enclave credential).
5. **Enable policy:** **Report-only** for the pilot. **Create.**

---

## Phase 5 — Pilot, validate, expand

### Step 14. Pilot-enroll a test Mac
1. **Erase** the pilot Mac (**System Settings → General → Transfer or Reset → Erase All Content and
   Settings**) so it returns to Setup Assistant. *(For a Configurator-added device, complete this
   before the 30-day provisional period ends.)*
2. Power on, choose language/region, connect to network.
3. Setup Assistant shows a **Remote Management** screen naming your organization (Jamf).
4. Complete enrollment; the PreStage applies, **Company Portal** installs, and the **SSO** profile
   deploys.
5. Open **Company Portal** and complete the **Register** prompt to finish Platform SSO registration
   and Entra device registration (a key icon / login-window prompt confirms it).

### Step 15. Validate
1. Run **`JAMFADE-JamfReadiness.ps1`** (Jamf side: ADE instance, PreStage, SSO profile) and
   **`JAMFADE-Discovery.ps1`** (Intune/Entra side: Jamf partner active, compliance policy, CA policy,
   Company Portal).
2. Run **`JAMFADE-Validation.ps1`** for the pilot Mac: confirm it is **registered** in Entra,
   **compliant** in Intune (partner-managed), and the **SSO profile** is applied.
3. On the Mac, open a Microsoft 365 web app and confirm **silent SSO** (no password prompt).
4. Confirm the Conditional Access **report-only** result in Entra **sign-in logs** shows the policy
   would apply and the device evaluates as **compliant**.

### Step 16. Expand
1. Once the pilot passes, widen the PreStage scope and the SSO/Company Portal/compliance Smart Group
   to broader populations (or make the PreStage the default for the ADE instance).
2. Move the Conditional Access policy from **report-only** to **On** for macOS.
3. Roll out in waves, validating each wave with the scripts before widening.


---


# 5. Testing & Validation — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts for tenant-side checks (Microsoft Graph and the Jamf Pro API) and
the on-device steps for the user experience.

## Test 1 — Jamf side readiness
**Procedure:** Run `JAMFADE-JamfReadiness.ps1` (Jamf Pro API).
**Pass:** Jamf **APNs** valid (>30 days), an **Automated Device Enrollment** instance present with a
token >30 days, at least one macOS **PreStage Enrollment**, and a **Single Sign-On Extensions**
(Platform SSO) configuration profile present.
**Fail:** Any missing or expiring within 30 days → resolve before enrolling devices.

## Test 2 — Intune/Entra side readiness
**Procedure:** Run `JAMFADE-Discovery.ps1` (Microsoft Graph).
**Pass:** **Jamf** shows as an **Active** device-compliance partner for macOS, a macOS **compliance
policy** exists, a **Conditional Access** policy targets macOS requiring compliance, and the macOS
**Company Portal** is available.
**Fail:** Partner not active, or compliance/CA policy missing → fix per Implementation §Phase 4.

## Test 3 — Device appears as ADE in Jamf
**Procedure:** In Jamf → Automated Device Enrollment → (instance), or run `JAMFADE-JamfReadiness.ps1`.
**Pass:** The pilot serial is listed and **scoped to the PreStage**, ready for enrollment.
**Fail:** Serial missing → re-check ABM MDM-server assignment (R5) and **Refresh** the instance.

## Test 4 — Zero-touch enrollment into Jamf
**Procedure:** Erase the pilot Mac and run Setup Assistant on a managed network.
**Pass:** A **Remote Management** screen names your organization (Jamf); enrollment completes without
manual MDM-profile installation; the device appears in **Jamf → Computers** within minutes.
**Fail:** No Remote Management screen → device not assigned/refreshed, or network blocks
`mdmenrollment.apple.com` (R12).

## Test 5 — Supervision and lock
**Procedure:** Inspect the enrolled device in Jamf (or run `JAMFADE-JamfReadiness.ps1`).
**Pass:** Device is **Supervised = Yes** and the MDM profile is **mandatory** (user cannot remove it).
**Fail:** Supervised = No → the PreStage did not enable **Supervision** (Step 7); re-erase and
re-enroll after correcting.

## Test 6 — Company Portal + Platform SSO registration
**Procedure:** After desktop loads, confirm Company Portal installed and complete the **Register**
prompt; then check the SSO state.
**Pass:** Company Portal reports the device **registered**; macOS shows the Platform SSO login-window
prompt / key indicator; `JAMFADE-Validation.ps1` reports the device **registered** in Entra and the SSO
profile **applied**.
**Fail:** No registration prompt → confirm Company Portal is scoped/installed (R8) and the SSO profile
is scoped (Step 10), then retry.

## Test 7 — Single sign-on works
**Procedure:** On the Mac, open a Microsoft 365 web app (e.g. `https://outlook.office.com`) in Safari
and Edge/Chrome; open a native app that supports the broker.
**Pass:** Sign-in is **silent** (no password prompt) using the registered Entra identity.
**Fail:** Repeated password prompts → verify the SSO extension URLs and identifiers (Step 10), and
that the Microsoft Enterprise SSO extension is present.

## Test 8 — Secure Enclave authentication method
**Procedure:** Confirm the Platform SSO method in effect.
**Pass:** Authentication uses the **Secure Enclave key** (hardware-bound); the local password is
decoupled from Entra.
**Fail:** Method shows password sync when Secure Enclave was intended → correct the SSO profile (Step
10) and **re-register**.

## Test 9 — Compliance flows Jamf → Intune
**Procedure:** Review the pilot Mac in **Intune → Devices → macOS** (or run `JAMFADE-Validation.ps1` /
`JAMFADE-DeviceReport.ps1`).
**Pass:** The Mac appears as **partner-managed (Jamf)** with a **Compliant** state reported to Intune.
**Fail:** Device absent or non-compliant → confirm the Device Compliance integration is **Active**
(R10) and the Jamf compliance scope includes the device (Step 12).

## Test 10 — Conditional Access enforces SSO
**Procedure:** With the CA policy in **report-only**, sign in to Microsoft 365 from the Mac and review
Entra **sign-in logs**.
**Pass:** The CA policy evaluates the Mac as **compliant** and (if configured) satisfies the
phishing-resistant strength; in **report-only** it shows "would have applied / granted."
**Fail:** Policy reports non-compliant or not-registered → resolve Tests 6/9 first, then re-test
before switching CA to **On**.

## Acceptance gate
Proceed to **Expand** only when Tests 1–10 pass on at least one pilot Mac and the user-experience
checks (silent SSO, clean first-run) are confirmed by a real pilot user. Switch Conditional Access
from **report-only** to **On** only after Test 10 passes.


---


# 6. Troubleshooting — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Work top-down: confirm the **Apple ↔ Jamf connection** (APNs/ADE token), then **assignment** (ABM →
Jamf), then the **device** (enrollment/supervision), then **Platform SSO**, then the **Jamf ↔ Intune
compliance** flow and **Conditional Access**. Most failures are an expired token, an unassigned
device, a missing integration, or a blocked network endpoint.

## The Mac never shows a "Remote Management" screen
- **Device not assigned to the Jamf MDM server.** ABM → **Devices** → confirm **MDM Server** = your
  Jamf server (R5). After fixing, Jamf → Automated Device Enrollment → **Refresh**.
- **Not scoped to a PreStage.** Jamf → **PreStage Enrollments** → confirm the serial is scoped (R6).
- **Already past Setup Assistant.** ADE only triggers during Setup Assistant — **Erase All Content
  and Settings** and try again.
- **Network blocks Apple.** Ensure `mdmenrollment.apple.com` and `gdmf.apple.com` are reachable and
  **not** TLS-inspected (R12).
- **Configurator device past 30-day window** or released by the user — re-add and re-assign.

## Enrollment fails partway / device not in Jamf
- **Jamf APNs certificate invalid/expired.** Jamf → **Push certificates** must be valid (R3). If it
  was renewed with a *different* Apple ID, devices unenroll — restore the original Apple ID.
- **ADE token expired.** Renew the ABM server token (R4); re-upload to the Jamf ADE instance.

## Device enrolled but **not Supervised**
- The **PreStage** didn't enable **Supervision** (Step 7). Correct the PreStage, then **erase and
  re-enroll** — supervision is set at enrollment and cannot be toggled on an enrolled device.

## Company Portal doesn't install
- Confirm the app is scoped to the pilot Smart Group and set to install automatically (R8/Step 9).
- Force a check-in: on the Mac, run **Self Service** or `sudo jamf recon` / `sudo jamf policy`; in
  Jamf, confirm the computer's **inventory** updates.

## Platform SSO never prompts to register
- **Company Portal missing or outdated** — it performs registration (R8); update it.
- **SSO profile not scoped** to the device (Step 10). Confirm scope and that the profile installed
  (System Settings → Privacy & Security → Profiles).
- **Extension identifiers wrong** — must be `com.microsoft.CompanyPortalMac.ssoextension` / team
  `UBF8T346G9` (Step 10).
- **macOS too old** — Platform SSO requires macOS 13+ (14+ recommended) (R7).
- After fixing, sign out/in or reboot to re-trigger the registration prompt.

## Registered, but apps still prompt for a password
- **Missing SSO URLs** — ensure all Microsoft login URLs are listed in the SSO extension (Step 10).
- **Browser without broker support** — Safari/Edge/Chrome with the Microsoft SSO extension get silent
  SSO; some third-party browsers won't.
- **Conditional Access interruption** — a policy may require interaction; review CA sign-in logs in
  Entra.

## Secure Enclave method not taking effect
- The profile may be set to **password sync**. Set **Authentication Method = Secure Enclave Key**
  (Step 10), re-scope, and **re-register** (sign out/in). Existing registrations keep their original
  method until re-registered.

## Mac doesn't appear in Intune / shows non-compliant
- **Device Compliance integration not active.** Intune → **Tenant administration → Partner device
  management** must show **Jamf = Active** (R10). Re-run consent in Jamf → **Device Compliance** if
  needed.
- **Device not in the Jamf compliance scope.** Confirm the Smart Group used for compliance includes
  the Mac (Step 12).
- **Not registered in Entra.** Registration happens via **Company Portal** — complete Test 6 first.
- **Inventory stale.** Run `sudo jamf recon` to push fresh inventory; compliance reflects on the next
  sync.

## Conditional Access blocks a Mac it shouldn't
- **Compliance not yet reported.** New devices may take a sync cycle — confirm Intune shows
  **Compliant** before enforcing.
- **Policy too broad.** Keep CA in **report-only** for the pilot; review Entra **sign-in logs** to see
  exactly which control failed before switching to **On** (Step 13).
- **Authentication strength mismatch.** If you required phishing-resistant strength, the Mac must be
  using the **Secure Enclave** method (Test 8).

## Integration renamed / steps don't match the console
- Microsoft and Jamf **superseded the legacy "Conditional Access"** integration with **Device
  Compliance / Partner device management**. If a menu label differs, follow the **current** Jamf and
  Microsoft documentation for the macOS Device Compliance integration.

## Token / certificate expiry (preventive)
- The Jamf **APNs certificate** and the **ADE token** expire **annually** and **block enrollment** if
  lapsed. Run `JAMFADE-JamfReadiness.ps1` regularly; it flags anything expiring within 30 days. Renew
  APNs with the **same Apple ID** each time.

## Useful checkpoints
- **Jamf:** Computers → (device) → **Inventory / Management / Configuration Profiles**; Settings →
  Global → **Automated Device Enrollment / Push certificates / Device Compliance**.
- **Intune/Entra:** Devices → macOS → (device) → **Compliance**; Tenant administration → **Partner
  device management**; Entra → **Conditional Access** + **Sign-in logs**.
- **On the Mac:** **System Settings → Privacy & Security → Profiles**; **Console.app** filtered for
  `AppSSO` / `DeviceManagement`; `sudo jamf recon` to refresh inventory.
- **Scripts:** re-run `JAMFADE-Validation.ps1` after each change to confirm the gate.


---


# 7. Best Practices — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Field-proven guidance to keep the Jamf-managed, Entra-enforced deployment reliable, secure, and
low-maintenance.

## Architecture & ownership
- **Keep one MDM authority.** Jamf is the **MDM**; Intune/Entra are the **identity & compliance**
  authority. Never try to dual-enroll a Mac into both Jamf and Intune MDM.
- **Document the split.** Record which controls live in Jamf (enrollment, profiles, patch, Self
  Service) versus Entra/Intune (registration, compliance, Conditional Access) so the team knows where
  to look.

## Identity & authentication
- **Standardize on the Secure Enclave key method.** It is phishing-resistant and decouples the local
  password from Entra. Reserve password sync for edge cases that genuinely need it.
- **Pair Platform SSO with a phishing-resistant Conditional Access strength** once the pilot is clean,
  so the Secure Enclave credential is actually required, not just available.
- **Enforce with Conditional Access in waves** — start **report-only**, confirm compliance is
  flowing, then turn the macOS policy **On**.

## Enrollment hygiene
- **Always supervise** company Macs (Step 7) and make the **MDM profile mandatory** so management
  can't be removed.
- **Buy through channels linked to ABM** so devices appear automatically; use Apple Configurator only
  for legacy stock, and complete enrollment before the **30-day provisional period** lapses.
- **Keep one well-named MDM server** per environment in ABM (e.g. *Jamf – Production*) to avoid
  assigning devices to the wrong tenant.
- **Use Smart Groups** to drive scope (PreStage, SSO profile, Company Portal, compliance) so a device
  picks up everything automatically as it enrolls.

## Token & certificate lifecycle (the #1 cause of outages)
- **Track both annual expiries** — the Jamf **APNs certificate** and the **ADE token**. A lapse blocks
  all new enrollments and can unenroll devices.
- **Always renew APNs with the same company Apple ID.** Document which Apple ID owns it; never use a
  personal Apple ID or one tied to an individual who may leave.
- **Schedule `JAMFADE-JamfReadiness.ps1`** to run regularly and alert on anything within 30 days of
  expiry.

## Operating system & updates
- **Set a minimum-OS rule in both places** — a Jamf Smart Group/policy and a matching Intune
  **compliance** rule (macOS 14+ recommended) so Platform SSO works reliably and out-of-support Macs
  are flagged and blocked by Conditional Access.
- **Manage updates in Jamf** (Software Updates / DDM) so the fleet stays patched without user
  intervention.

## Rollout discipline
- **Pilot first, expand in waves.** Validate each wave with `JAMFADE-Validation.ps1` before widening.
- **Hide noisy Setup Assistant panes** for a clean, fast first-run, but keep privacy/location prompts
  that your policy requires.
- **Pre-stage apps and profiles** (Company Portal + SSO) in the PreStage so a freshly enrolled Mac is
  useful — and registerable — within minutes.

## Operations & documentation
- **Keep a runbook** of the Apple ID, ABM org, Jamf MDM server name, APNs/ADE expiry dates, the SSO
  profile identifiers, and the Device Compliance connector status — the values that, if lost, are
  painful to recover.
- **Report monthly** with `JAMFADE-DeviceReport.ps1`: macOS count, Platform SSO registration coverage,
  Entra registration, and Intune compliance (partner-managed) — so drift is visible early.
- **Re-validate the Jamf ↔ Intune integration after major updates** to either platform; Microsoft and
  Jamf occasionally change the connector and the SSO/Platform-SSO behavior between releases.

## Security posture
- **Combine with disk encryption** (FileVault, escrowed to Jamf) and a **macOS security baseline** for
  a complete managed posture.
- **Make compliance meaningful** — define Intune compliance to reflect real Jamf signals (encryption,
  OS version, etc.) so Conditional Access enforces a genuine security bar, not just registration.
- **Limit local admin** and use Jamf to manage privileged access; supervised + mandatory enrollment
  prevents users from quietly removing management.


---


# 8. Deliverables Summary — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — what ADE, Platform SSO, and the Jamf ↔ Intune Device Compliance integration
  are, how they work together, why Jamf is the MDM and Intune the identity/compliance authority, the
  authentication methods, benefits, and honest limitations.
- **Requirements Guide** — every Apple/Jamf/Intune prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across five phases: connect Apple to
  Jamf, assign devices & define the PreStage, deploy Company Portal + Platform SSO via Jamf, connect
  Jamf to Intune and create the Conditional Access policy, then pilot/validate/expand.
- **Testing & Validation** — ten tests with explicit pass/fail gates and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for enrollment, Platform SSO, compliance, and Conditional
  Access failures.
- **Best Practices** — architecture/ownership, identity, enrollment hygiene, the all-important
  token/certificate lifecycle, OS/updates, rollout discipline, and security posture.

## PowerShell scripts — `JAMFADE-Scripts.zip`
Each script has a header explaining **Purpose · How to run · Expected results**. Three use the
**Microsoft Graph** PowerShell SDK (Intune/Entra side); two call the **Jamf Pro API** (MDM side).

1. **`JAMFADE-Discovery.ps1`** (Graph) — Intune/Entra readiness: the **Jamf device-compliance partner**
   is **Active** for macOS, a macOS **compliance policy** exists, a **Conditional Access** policy
   targets macOS, and the macOS **Company Portal** is available. Flags gaps.
2. **`JAMFADE-Validation.ps1`** (Graph) — validates a specific Mac: **Entra-registered**, reported by
   the Jamf partner, and **compliant** in Intune — with a clear PASS/FAIL summary.
3. **`JAMFADE-DeviceReport.ps1`** (Graph) — tenant-wide CSV report of macOS devices: registration,
   ownership, compliance state, and partner-managed (Jamf) status.
4. **`JAMFADE-JamfReadiness.ps1`** (Jamf Pro API) — Jamf-side readiness: APNs status/expiry, the
   **Automated Device Enrollment** instance/token expiry, macOS **PreStage** presence, and the
   **Single Sign-On Extensions** (Platform SSO) profile presence. Flags anything within 30 days of
   expiry.
5. **`JAMFADE-Set-JamfSSOProfile.ps1`** (Jamf Pro Classic API) — uploads and scopes the macOS Platform
   SSO (Single Sign-On Extensions) configuration profile with the correct Microsoft Enterprise SSO
   identifiers, URLs, and Secure Enclave method.

## Hero image
- **`JAMFADE-hero.png`** — the branded product image (1200×1200) used on the marketplace listing.

## How it's delivered
A branded **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts
appendix), plus all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across
**unlimited devices**.
