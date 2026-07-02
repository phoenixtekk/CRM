# macOS Automated Device Enrollment with SSO

> **Version 1.0.0** · Category: Intune · Solution code: ADEMAC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — macOS Automated Device Enrollment with SSO

Apple **Automated Device Enrollment (ADE)** turns every company-owned Mac into a zero-touch,
supervised, fully managed device the moment it is powered on — no manual setup, no local admin
hand-holding, no imaging. Paired with **Platform Single Sign-On (Platform SSO)** and the
**Microsoft Enterprise SSO** plug-in, your users sign in to their Mac with their **Microsoft Entra
ID** credentials and carry that identity, seamlessly and securely, into every app and browser.

This solution delivers the complete, field-tested method to stand this up in **Microsoft Intune** —
written so a single administrator can follow it end to end:

- **Zero-touch provisioning.** Macs bought through Apple Business Manager (or added with Apple
  Configurator) enroll automatically, supervised, with your branding and your apps, straight out of
  the box.
- **Entra-backed sign-in.** Platform SSO registers the Mac with Microsoft Entra ID and lets users
  unlock the device and authenticate to Microsoft 365 and SSO-enabled apps using their corporate
  identity — with a hardware-bound **Secure Enclave** key, not a synced password.
- **Conditional Access ready.** Enrolled, compliant, Entra-registered Macs become first-class
  citizens in your Zero Trust model.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click Intune steps, a requirements guide that tells you how to
verify *and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and
testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** company Macs that deploy themselves, authenticate with corporate identity, and meet
compliance — delivered by your own team, in a controlled pilot, without a consulting engagement.


---


# 1. Solution Overview — macOS Automated Device Enrollment with SSO

## What this solution is
This solution combines two Apple + Microsoft capabilities into one repeatable deployment:

1. **Automated Device Enrollment (ADE)** — Apple's zero-touch enrollment program (formerly DEP).
   Company-owned Macs that belong to your **Apple Business Manager (ABM)** organization are
   automatically enrolled into **Microsoft Intune**, **supervised**, the first time they run Setup
   Assistant. Management is mandatory and locked to the device.
2. **Platform Single Sign-On (Platform SSO)** — Apple's macOS framework that lets a third-party
   identity provider extend sign-in to the Mac itself. With the **Microsoft Enterprise SSO**
   extension, the Mac registers with **Microsoft Entra ID** and users authenticate with their
   corporate identity at the login window and across apps and Safari/Edge/Chrome.

Together they give you a Mac that provisions itself and signs in with corporate identity — managed,
supervised, and Conditional-Access ready.

## How it works
1. **Apple Business Manager → Intune.** You connect ABM to Intune with an **Automated Device
   Enrollment token** (a server token). Macs assigned to the Intune MDM server in ABM appear in
   Intune as ADE devices.
2. **Enrollment profile.** An **enrollment program profile** in Intune defines the out-of-box
   experience: supervised mode, user affinity, which Setup Assistant screens to skip, and whether
   management is locked.
3. **Power on → enroll.** When a user (or technician) powers on the Mac and connects to a network,
   Setup Assistant contacts Apple, discovers the Intune MDM server, and enrolls automatically. The
   device becomes supervised and managed; your apps and policies flow down.
4. **Platform SSO registration.** A configuration profile deploys the **Microsoft Enterprise SSO**
   extension. On first sign-in, the **Company Portal** app completes Platform SSO **registration**:
   the Mac generates a hardware-bound key in the **Secure Enclave** and registers it with Entra ID.
5. **Single sign-on.** From then on, the user's macOS sign-in is tied to their Entra identity, and
   apps/browsers that support the Microsoft identity broker get silent SSO — no repeated passwords.

## Platform SSO authentication methods (choose one)
- **Secure Enclave key (recommended)** — a hardware-bound key in the Mac's Secure Enclave signs
  authentication. Phishing-resistant; the local password is decoupled from Entra. Best security.
- **Password sync** — the user's local macOS password is kept in sync with their Entra password.
  Simplest for users; least hardened.
- **Smart card** — authentication via a smart card/certificate. For high-assurance environments.

This solution standardizes on the **Secure Enclave key** method, with notes for the alternatives.

## Benefits
- **Zero-touch deployment** — Macs enroll supervised on first boot; no imaging, no manual MDM steps.
- **Corporate identity on the Mac** — Entra sign-in at the login window and across apps/browsers.
- **Phishing-resistant** — Secure Enclave key, hardware-bound, never leaves the device.
- **Supervised management** — stronger controls, app management, and wipe protection.
- **Conditional Access** — enrolled, compliant, Entra-registered Macs fit your Zero Trust model.
- **Better experience** — users sign in once with the identity they already know.

## Limitations (be honest with buyers)
- ADE requires devices to be in **Apple Business Manager** (purchased via Apple/authorized reseller,
  or added manually with **Apple Configurator** — the latter adds a provisional 30-day release period).
- Platform SSO requires **macOS 13 Ventura or later** (macOS 14 Sonoma+ strongly recommended for the
  best registration and Secure Enclave experience).
- Requires an **Apple Push Notification service (APNs) certificate**, renewed annually, and an
  **ADE/ABM token**, renewed annually — both are hard expiry dates that block enrollment if missed.
- Platform SSO registration depends on the **Company Portal** app and the **Microsoft Enterprise
  SSO** extension being present and current.
- Personally-owned (BYO) Macs use a different (user-enrollment) path and are out of scope here.

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Company-owned, Apple Business Manager–sourced Macs, automatically enrolled into Intune
> (supervised), with Platform SSO via the Microsoft Enterprise SSO extension and a Secure Enclave key.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — macOS Automated Device Enrollment with SSO

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to Apple ADE +
Platform SSO.

## R1. Apple Business Manager (or Apple School Manager) account
**Description:** A verified Apple Business Manager (ABM) organization.
**Why:** ADE only works for devices that belong to your ABM organization; ABM is also where you
assign devices to the Intune MDM server and accept device-management terms.
**Verify:** Sign in to `https://business.apple.com` with an ABM Administrator account; the
organization status is **active**.
**Implement:** Enroll at `https://business.apple.com/enroll` using your **D-U-N-S** number; complete
Apple's verification (a phone callback to a verifiable company contact). Allow 1–5 business days.

## R2. Apple Push Notification service (APNs) certificate
**Description:** A valid MDM Push certificate connecting Intune to Apple's push service.
**Why:** Every Apple device managed by Intune (iOS/iPadOS/macOS) requires APNs; without it, no Mac
can enroll or receive commands.
**Verify:** Intune admin center → **Devices → Enrollment → Apple → Apple MDM Push certificate** shows
**Active** with a future expiration date.
**Implement:** In Intune, download the CSR, sign in to `https://identity.apple.com` with a **company
Apple ID** (not a personal one), create/renew the certificate, and upload the resulting `.pem`.
**Renew annually with the same Apple ID** — a new Apple ID re-issues the cert and unenrolls all
devices.

## R3. Automated Device Enrollment token (ABM ↔ Intune connection)
**Description:** A downloaded ABM server token (`.p7m`) uploaded into Intune as an enrollment program
token.
**Why:** This is the trust link that lets ABM-assigned devices enroll into your Intune tenant.
**Verify:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens**; a token is listed
with a future expiration.
**Implement:** In Intune, download the public key; in ABM **Preferences → MDM Servers**, create an
MDM server, upload the public key, download the server token; upload that token back into Intune.
**Renew annually.**

## R4. Devices present in Apple Business Manager
**Description:** The target Macs appear in ABM and are assignable to the Intune MDM server.
**Why:** Only ABM devices can use ADE; a Mac not in ABM cannot be auto-enrolled.
**Verify:** ABM → **Devices**; the Mac's serial number is listed.
**Implement:** Purchase through Apple or an **Apple-authorized reseller** linked to your ABM (devices
appear automatically), or add existing Macs with **Apple Configurator** (note: Configurator-added
devices get a **30-day provisional period** during which the user can release them from management).

## R5. Devices assigned to the Intune MDM server
**Description:** Each target Mac is assigned to the Intune MDM server in ABM.
**Why:** Assignment tells Apple which MDM a device should enroll into during Setup Assistant.
**Verify:** ABM → **Devices** → select the device → **MDM Server** shows your Intune server.
**Implement:** ABM → **Devices** → select devices → **Edit MDM Server** → choose the Intune MDM
server. Then in Intune, **Sync** the enrollment token.

## R6. Supported macOS version
**Description:** macOS **13 Ventura or later** (macOS **14 Sonoma+ recommended**).
**Why:** Platform SSO and the Secure Enclave authentication method require macOS 13+; later releases
materially improve registration reliability.
**Verify:**  Apple menu → **About This Mac**, or Intune → device → **Hardware**.
**Implement:** Upgrade via **System Settings → General → Software Update**, or deploy a minimum-OS
**compliance policy** so non-compliant Macs are flagged and updated.

## R7. Company Portal app for macOS
**Description:** The Intune **Company Portal** application installed on the Mac.
**Why:** Company Portal performs the Platform SSO **registration** with Microsoft Entra ID and reports
device state; Platform SSO does not complete without it.
**Verify:** Intune → **Apps → macOS**; "Company Portal" is added and assigned to your pilot group.
**Implement:** Add Company Portal (Intune → Apps → macOS → Add → choose the macOS Company Portal) and
assign it **Required** to the pilot group so it installs automatically post-enrollment.

## R8. Microsoft Enterprise SSO extension capability
**Description:** The **Microsoft Enterprise SSO** plug-in delivered via a macOS **SSO app extension /
Platform SSO** configuration profile.
**Why:** This Apple-approved redirect extension is what brokers Entra authentication for Platform SSO
and app/browser single sign-on.
**Verify:** Intune → **Devices → Configuration**; a profile of type **SSO app extension** (Platform
SSO) exists targeting your pilot group.
**Implement:** Create it during deployment (Implementation Guide §6), or run the included
`Set-PlatformSSOProfile.ps1` to provision it via Microsoft Graph.

## R9. Network access to Apple management endpoints
**Description:** Outbound HTTPS to Apple's enrollment, push, and software endpoints.
**Why:** Setup Assistant, ADE discovery, APNs, and app delivery all depend on Apple endpoints.
**Verify:** From the device network, reach `https://mdmenrollment.apple.com`,
`https://gdmf.apple.com`, and the Apple push range `*.push.apple.com` (TCP 443 and 5223).
**Implement:** Allow Apple's published network ranges (Apple support article HT210060) plus the
Microsoft Intune/Entra endpoints through proxy/firewall. Do **not** TLS-inspect Apple push/enrollment.

## R10. macOS enrollment enabled in Intune
**Description:** macOS platform enrollment is permitted by enrollment restrictions.
**Why:** A restriction that blocks macOS will silently stop ADE devices from enrolling.
**Verify:** Intune → **Devices → Enrollment → Enrollment device platform restrictions → macOS**;
platform is **Allowed**.
**Implement:** Edit the default (or a targeted) restriction to **Allow** macOS for the pilot group.


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


# 3. Implementation — macOS Automated Device Enrollment with SSO

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything
against a **pilot group** first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and
Apple Business Manager at `https://business.apple.com` unless noted.

---

## Phase 1 — Connect Apple to Intune

### Step 1. Create the Apple MDM Push (APNs) certificate
1. In Intune, go to **Devices → Enrollment → Apple**.
2. Click **Apple MDM Push certificate**.
3. Check **I agree**, then **Download** the CSR file to your computer.
4. Click **Create your MDM push certificate** to open `https://identity.apple.com`.
5. Sign in with a **company Apple ID** (record which Apple ID you use — you must reuse it every year).
6. Click **Create a Certificate**, upload the CSR, then **Download** the `.pem` certificate.
7. Back in Intune, enter that **Apple ID** in the box, **Browse** to the `.pem`, and click **Upload**.
8. Confirm the status shows **Active** with an expiration ~1 year out.

### Step 2. Connect Apple Business Manager (download the Intune public key)
1. In Intune, go to **Devices → Enrollment → Apple → Enrollment program tokens**.
2. Click **Add**.
3. Check **I agree**, then **Download** the Intune **public key** (`.pem`).

### Step 3. Create the MDM server in Apple Business Manager
1. In ABM, go to **Preferences (your name, bottom-left) → MDM Servers**.
2. Click **Add** (or the **+**). Name it clearly, e.g. **Intune – Production**.
3. Under **MDM Server Settings**, **Upload** the Intune public key from Step 2.
4. Click **Save**, then **Download Token** — this downloads the server token (`.p7m`).

### Step 4. Upload the ABM token into Intune
1. Back on the Intune **Add enrollment program token** page, enter the **Apple ID** used for ABM.
2. **Browse** to the `.p7m` token file and **Upload**.
3. The token appears under **Enrollment program tokens** with a future expiration.

---

## Phase 2 — Assign devices and define the enrollment experience

### Step 5. Assign Macs to the Intune MDM server (in ABM)
1. In ABM, go to **Devices**.
2. Select the target Mac(s) by serial number (or filter by purchase/order).
3. Click **Edit MDM Server** → choose your **Intune – Production** server → **Continue → Confirm**.

### Step 6. Sync and confirm devices in Intune
1. In Intune, open **Devices → Enrollment → Apple → Enrollment program tokens → (your token) → Devices**.
2. Click **Sync** (Apple rate-limits syncs; allow a few minutes).
3. Confirm the assigned serial numbers appear.

### Step 7. Create the macOS enrollment program profile
1. On the token, open **Profiles → Create profile → macOS**.
2. **Basics:** name it (e.g. **macOS ADE – Pilot**); set **User affinity** = **Enroll with user
   affinity** (required for Platform SSO so the device ties to a user).
3. **Management Settings:**
   - **Device management options** → enable **Supervised**.
   - **Locked enrollment** → **Yes** (prevents users from removing management).
   - **Sync with Company Portal** / **Install Company Portal** as prompted (so SSO registration can run).
4. **Setup Assistant:** hide unnecessary screens (Restore, Apple ID, Siri, Analytics, Touch ID setup
   as your policy dictates) for a clean first-run; keep **Location** and **Privacy** as required.
5. **Review + Create.**

### Step 8. Assign the enrollment profile to the token's devices
1. On the token → **Devices**, select the pilot serial numbers.
2. Click **Assign profile** → choose **macOS ADE – Pilot** → **Assign**.

### Step 9. Confirm macOS enrollment is allowed
1. Go to **Devices → Enrollment → Enrollment device platform restrictions**.
2. Open the default (or pilot-targeted) restriction → **macOS** → ensure **Allow**.

---

## Phase 3 — Deploy Company Portal and Platform SSO

### Step 10. Add and assign the Company Portal app
1. Go to **Apps → macOS → Add**.
2. Choose **macOS** app type for **Company Portal** (or add it as a managed app), **Select**.
3. Assign it **Required** to your **pilot group** so it installs automatically after enrollment.

### Step 11. Create the Platform SSO configuration profile
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform** = **macOS**; **Profile type** = **Settings catalog** → **Create**.
3. Name it **macOS Platform SSO – Pilot**.
4. Click **Add settings**; search **Single Sign On Extension** and add the **Extensible Single
   Sign-On (SSO)** settings.
5. Configure:
   - **Extension Identifier:** `com.microsoft.CompanyPortalMac.ssoextension`
   - **Team Identifier:** `UBF8T346G9`
   - **Type:** **Redirect**
   - **URLs:** `https://login.microsoftonline.com`, `https://login.microsoft.com`,
     `https://sts.windows.net`, `https://login.partner.microsoftonline.cn`,
     `https://login.chinacloudapi.cn`, `https://login.microsoftonline.us`,
     `https://login-us.microsoftonline.com`
   - **Platform SSO → Authentication Method:** **Secure Enclave Key** (recommended).
   - **Registration token:** `{{DEVICEREGISTRATION}}` (enables silent device registration).
6. **Review + Create**, then **Assign** to the pilot group.

> Prefer automation? Run the included **`Set-PlatformSSOProfile.ps1`** (Microsoft Graph) to create
> and assign this profile with the values above — then verify it in the console.

### Step 12. (Hybrid/optional) Conditional Access for managed Macs
1. Go to **Entra → Protection → Conditional Access**.
2. Create a policy (**name it `CA – macOS Compliant – Pilot`**) to require **device compliance**
   (and/or Entra registration) for macOS accessing Microsoft 365 — **start in report-only mode** for
   the pilot.

---

## Phase 4 — Pilot, validate, expand

### Step 13. Pilot-enroll a test Mac
1. **Erase** the pilot Mac (**System Settings → General → Transfer or Reset → Erase All Content and
   Settings**) so it returns to Setup Assistant. *(For a Configurator-added device, complete this
   before the 30-day provisional period ends.)*
2. Power on, choose language/region, connect to network.
3. Setup Assistant shows a **Remote Management** screen confirming your organization manages the Mac.
4. Sign in with the pilot user's **Entra ID** credentials when prompted; complete enrollment.
5. After desktop loads, **Company Portal** installs and prompts to **Register** — complete Platform
   SSO registration (a small key icon / login-window prompt confirms it).

### Step 14. Validate
1. Run **`ADEMAC-Discovery.ps1`** (tenant readiness) and **`ADEMAC-Validation.ps1`** (this device):
   confirm the Mac is **enrolled, supervised, ADE**, has the **SSO profile applied**, and is
   **registered** with Entra.
2. On the Mac, open a Microsoft 365 web app and confirm **silent SSO** (no password prompt).
3. Confirm compliance in **Intune → Devices → macOS → (device) → Compliance**.

### Step 15. Expand
1. Once the pilot passes, assign the enrollment profile and the Company Portal/SSO/compliance
   policies to broader groups (or make the enrollment profile the **default** for the token).
2. Move any Conditional Access policy from **report-only** to **on** for macOS.
3. Roll out in waves, validating each wave with the scripts before widening.


---


# 5. Testing & Validation — macOS Automated Device Enrollment with SSO

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps
for the user experience.

## Test 1 — Tenant readiness
**Procedure:** Run `ADEMAC-Discovery.ps1`.
**Pass:** APNs certificate **Active** (expiry > 30 days), an **ADE/enrollment token** present
(expiry > 30 days), at least one **macOS enrollment profile**, Company Portal app assigned, and a
**Platform SSO** configuration profile present.
**Fail:** Any of the above missing or expiring within 30 days → resolve before enrolling devices.

## Test 2 — Device appears as ADE
**Procedure:** In Intune → Enrollment program tokens → (token) → **Devices**, locate the pilot serial;
or run `ADEMAC-DeviceReport.ps1`.
**Pass:** The serial is listed, **profile assigned**, status ready for enrollment.
**Fail:** Serial missing → re-check ABM MDM-server assignment (R5) and **Sync**.

## Test 3 — Zero-touch enrollment
**Procedure:** Erase the pilot Mac and run Setup Assistant on a managed network.
**Pass:** A **Remote Management** screen names your organization; enrollment completes without manual
MDM profile installation; the device shows in **Intune → Devices → macOS** within minutes.
**Fail:** No Remote Management screen → device not assigned/synced, or network blocks
`mdmenrollment.apple.com` (R9).

## Test 4 — Supervision and lock
**Procedure:** Inspect the enrolled device in Intune (or run `ADEMAC-Validation.ps1`).
**Pass:** Device is **Supervised = Yes** and **Corporate-owned**; management is **locked**
(user cannot remove the MDM profile).
**Fail:** Supervised = No → the enrollment profile did not enable Supervised (Step 7); re-erase and
re-enroll after correcting.

## Test 5 — Company Portal + Platform SSO registration
**Procedure:** After desktop loads, confirm Company Portal installed and complete the **Register**
prompt; then check the SSO state.
**Pass:** Company Portal reports the device **registered**; macOS shows the Platform SSO login-window
prompt / key indicator; `ADEMAC-Validation.ps1` reports the SSO profile **applied**.
**Fail:** No registration prompt → confirm Company Portal is **Required** (R7) and the SSO profile is
assigned to the user/device (Step 11), then retry.

## Test 6 — Single sign-on works
**Procedure:** On the Mac, open a Microsoft 365 web app (e.g. `https://outlook.office.com`) in Safari
and Edge/Chrome; open a native app that supports the broker.
**Pass:** Sign-in is **silent** (no password prompt) using the registered Entra identity.
**Fail:** Repeated password prompts → verify the SSO extension URLs and identifiers (Step 11), and
that the Microsoft Enterprise SSO extension is present.

## Test 7 — Secure Enclave authentication method
**Procedure:** Confirm the Platform SSO method in effect.
**Pass:** Authentication uses the **Secure Enclave key** (hardware-bound); the user's local password
is decoupled from Entra.
**Fail:** Method shows password sync when Secure Enclave was intended → correct the SSO profile
setting (Step 11) and re-register.

## Test 8 — Compliance & Conditional Access
**Procedure:** Review the device's **Compliance** in Intune; if Conditional Access is configured,
test access from the Mac.
**Pass:** Device is **Compliant**; Conditional Access (report-only or on) evaluates the Mac as a
managed, registered device.
**Fail:** Non-compliant → review the assigned compliance policy and OS minimum (R6).

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass on at least one pilot Mac and the user-experience
checks (silent SSO, clean first-run) are confirmed by a real pilot user.


---


# 6. Troubleshooting — macOS Automated Device Enrollment with SSO

Work top-down: confirm the **connection** (APNs/token), then **assignment** (ABM → Intune), then the
**device** (enrollment), then **Platform SSO**. Most failures are an expired token, an unassigned
device, or a blocked network endpoint.

## The Mac never shows a "Remote Management" screen
- **Device not assigned to the Intune MDM server.** ABM → **Devices** → confirm **MDM Server** = your
  Intune server (R5). After fixing, Intune → token → **Sync**.
- **Profile not assigned.** Intune → token → **Devices** → select serial → **Assign profile**.
- **Already past Setup Assistant.** ADE only triggers during Setup Assistant — **Erase All Content
  and Settings** and try again.
- **Network blocks Apple.** Ensure `mdmenrollment.apple.com` and `gdmf.apple.com` are reachable and
  **not** TLS-inspected (R9).
- **Configurator device past 30-day window** or released by the user — re-add and re-assign.

## Enrollment fails partway / device not in Intune
- **APNs certificate invalid/expired.** Intune → Apple MDM Push certificate must be **Active** (R2).
  If it was renewed with a *different* Apple ID, devices unenroll — restore the original Apple ID.
- **Enrollment token expired.** Renew the ABM server token (R3); re-upload to Intune.
- **macOS blocked by enrollment restriction.** Allow macOS for the target group (R10).

## Device enrolled but **not Supervised**
- The enrollment profile didn't enable **Supervised** (Step 7). Correct the profile, then **erase and
  re-enroll** — supervision is set at enrollment and cannot be toggled on an enrolled device.

## Company Portal doesn't install
- Confirm the app is **Required** and assigned to the **user/group** that owns the device (R7).
- Force a check-in: on the Mac, open **Company Portal** (if present) or **System Settings → Privacy &
  Security → Profiles**, and confirm management; in Intune, use **Sync** on the device.

## Platform SSO never prompts to register
- **Company Portal missing or outdated** — it performs registration (R7); update it.
- **SSO profile not assigned** to the signed-in user (Step 11). Confirm assignment and that the
  enrollment used **user affinity** (Step 7).
- **Extension identifiers wrong** — must be `com.microsoft.CompanyPortalMac.ssoextension` / team
  `UBF8T346G9` (Step 11).
- **macOS too old** — Platform SSO requires macOS 13+ (14+ recommended) (R6).
- After fixing, sign out/in or reboot to re-trigger the registration prompt.

## Registered, but apps still prompt for a password
- **Missing SSO URLs** — ensure all Microsoft login URLs are listed in the SSO extension (Step 11).
- **Browser without broker support** — Safari/Edge/Chrome with the Microsoft SSO extension get silent
  SSO; some third-party browsers won't.
- **Conditional Access interruption** — a policy may require interaction; review CA sign-in logs in
  Entra.

## Secure Enclave method not taking effect
- The profile may be set to **password sync**. Set **Authentication Method = Secure Enclave Key**
  (Step 11), re-assign, and **re-register** (sign out/in). Existing registrations keep their original
  method until re-registered.

## "Awaiting configuration" / device stuck at Setup Assistant
- Usually a transient Apple/Intune sync delay or a network hiccup. Confirm endpoints (R9), **Sync**
  the token, and allow several minutes; if persistent, erase and retry.

## Token / certificate expiry (preventive)
- Both the **APNs certificate** and the **ADE token** expire **annually** and **block enrollment** if
  lapsed. Run `ADEMAC-Discovery.ps1` (or `ADEMAC-Remediation.ps1`) regularly; it flags anything
  expiring within 30 days. Renew with the **same Apple ID** each time.

## Useful checkpoints
- **Intune:** Devices → macOS → (device) → **Hardware / Compliance / Configuration**; Enrollment →
  Apple → token → **Devices**.
- **On the Mac:** **System Settings → Privacy & Security → Profiles** (MDM profile present);
  **Console.app** filtered for `AppSSO` / `DeviceManagement` for SSO and enrollment logs.
- **Scripts:** re-run `ADEMAC-Validation.ps1` after each change to confirm the gate.


---


# 7. Best Practices — macOS Automated Device Enrollment with SSO

Field-proven guidance to keep the deployment reliable, secure, and low-maintenance.

## Identity & authentication
- **Standardize on the Secure Enclave key method.** It is phishing-resistant and decouples the local
  password from Entra. Reserve password sync for edge cases that genuinely need it.
- **Require user affinity** on the enrollment profile so each Mac is tied to a user and Platform SSO
  can register. Device-affinity (shared) Macs need a different design.
- **Layer Conditional Access** to require compliant, registered Macs for Microsoft 365 — start in
  **report-only**, then enforce once the pilot is clean.

## Enrollment hygiene
- **Always supervise** company Macs (Step 7) and **lock enrollment** so management can't be removed.
- **Buy through channels linked to ABM** so devices appear automatically; use Apple Configurator only
  for legacy stock, and complete enrollment before the **30-day provisional period** lapses.
- **Keep one well-named MDM server** per environment in ABM (e.g. *Intune – Production*) to avoid
  assigning devices to the wrong tenant.

## Token & certificate lifecycle (the #1 cause of outages)
- **Track both annual expiries** — the **APNs certificate** and the **ADE token**. A lapse blocks all
  new enrollments and can unenroll devices.
- **Always renew APNs with the same company Apple ID.** Document which Apple ID owns it; never use a
  personal Apple ID or one tied to an individual who may leave.
- **Schedule `ADEMAC-Discovery.ps1`** to run regularly and alert on anything within 30 days of expiry.

## Operating system & updates
- **Set a minimum-OS compliance policy** (macOS 14+ recommended) so Platform SSO works reliably and
  out-of-support Macs are flagged.
- **Manage updates with Intune** (declarative software updates) so the fleet stays patched without
  user intervention.

## Rollout discipline
- **Pilot first, expand in waves.** Validate each wave with `ADEMAC-Validation.ps1` before widening.
- **Hide noisy Setup Assistant screens** for a clean, fast first-run, but keep privacy/location
  prompts that your policy requires.
- **Pre-stage apps as Required** (starting with Company Portal) so a freshly enrolled Mac is useful
  within minutes.

## Operations & documentation
- **Keep a runbook** of the Apple ID, ABM org, MDM server name, token/cert expiry dates, and the SSO
  profile identifiers — the values that, if lost, are painful to recover.
- **Report monthly** with `ADEMAC-DeviceReport.ps1`: enrolled macOS count, ADE vs. other, OS spread,
  Platform SSO registration coverage, and compliance.
- **Test OS upgrades** against the SSO extension before broad deployment; Apple occasionally changes
  Platform SSO behavior between major releases.

## Security posture
- **Combine with disk encryption** (FileVault) and a **macOS security baseline/compliance policy** for
  a complete managed posture (separate solutions cover these).
- **Limit local admin** and use Intune to manage privileged access; supervised + locked enrollment
  prevents users from quietly removing management.


---


# 8. Deliverables Summary — macOS Automated Device Enrollment with SSO

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — what ADE and Platform SSO are, how they work together, the authentication
  methods, benefits, and honest limitations.
- **Requirements Guide** — every Apple/Intune prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: connect Apple
  to Intune, assign devices and define the enrollment experience, deploy Company Portal + Platform
  SSO, then pilot/validate/expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for enrollment and Platform SSO failures.
- **Best Practices** — identity, enrollment hygiene, the all-important token/certificate lifecycle,
  OS/updates, rollout discipline, and security posture.

## PowerShell scripts (Microsoft Graph) — `ADEMAC-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**.

1. **`ADEMAC-Discovery.ps1`** — tenant readiness: APNs certificate status/expiry, ADE/enrollment
   token status/expiry, macOS enrollment profiles, Company Portal assignment, and Platform SSO
   profile presence. Flags anything expiring within 30 days.
2. **`ADEMAC-Validation.ps1`** — validates a specific Mac: enrolled, supervised, ADE, SSO profile
   applied, Entra-registered, and compliant — with a clear PASS/FAIL summary.
3. **`ADEMAC-DeviceReport.ps1`** — tenant-wide CSV report of macOS devices: enrollment type, OS
   version, ownership/supervision, Platform SSO registration state, and compliance.
4. **`ADEMAC-Remediation.ps1`** — safe remediation: re-sync the ADE token, re-assign the
   enrollment/SSO profiles to a target group, and surface tokens/certs nearing expiry. Read-only by
   default; changes require an explicit confirmation switch.
5. **`Set-PlatformSSOProfile.ps1`** — creates and assigns the Platform SSO (SSO app extension)
   configuration profile with the correct Microsoft Enterprise SSO identifiers, URLs, and Secure
   Enclave method.

## Hero image
- **`ADEMAC-hero.png`** — the branded product image (1200×1200) used on the marketplace listing.

## How it's delivered
A branded **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts
appendix), plus all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across
**unlimited devices**.
