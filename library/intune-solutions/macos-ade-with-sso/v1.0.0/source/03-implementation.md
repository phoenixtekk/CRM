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
