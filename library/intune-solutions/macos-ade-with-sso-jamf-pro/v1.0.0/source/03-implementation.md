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
