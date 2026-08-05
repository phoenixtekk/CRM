# 3. Implementation — iOS/iPadOS Enterprise SSO App Extension (COD iPhones)

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against
a **pilot group** first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` unless
noted.

> **This deploys the app/browser SSO extension only** on **enrolled, corporate-owned** iPhones/iPads.
> It does not enroll devices and does not configure shared-device identity. Every setting below uses
> the **Redirect / Microsoft Entra ID** extension type.

---

## Phase 1 — Prepare the device for the extension

### Step 1. Confirm iOS/iPadOS enrollment and version
1. Go to **Devices → iOS/iPadOS → iOS/iPadOS devices** and confirm the pilot device is **managed**
   (and, for COD, **supervised**).
2. Open the device → **Hardware** and confirm iOS/iPadOS **13+** (current release recommended).

### Step 2. Add and assign Microsoft Authenticator (hosts the extension)
1. Go to **Apps → iOS/iPadOS → Add**.
2. **App type = iOS store app**, **Select**. Search **Microsoft Authenticator** — publisher
   **Microsoft Corporation**, bundle ID `com.microsoft.azureauthenticator` (*not* "Authenticator"
   by another publisher). **Select**.
3. Assign it **Required** to your **pilot group** so it installs automatically. Microsoft
   Authenticator is what delivers the Enterprise SSO extension binary on iOS — the profile in Phase 2
   only *activates* it.
4. *(Recommended, if Conditional Access gates the target apps on compliance — R9)* Repeat for
   **Company Portal** (bundle ID `com.microsoft.CompanyPortal`), assigned **Required**.

### Step 3. Gather scoping inputs
1. Record the **Entra login URLs** for your cloud (defaults below in Step 5).
2. Decide the app coverage. The simplest, most complete option on iOS is to enable SSO for **all
   managed apps** (Step 6). If you prefer an allow-list, record the **app bundle IDs**, for example:
   - Safari — `com.apple.mobilesafari`
   - Microsoft Outlook — `com.microsoft.Office.Outlook`
   - Microsoft Teams — `com.microsoft.skype.teams`
   - Microsoft Edge — `com.microsoft.msedge`

---

## Phase 2 — Create the Extensible SSO app-extension profile

### Step 4. Create the configuration profile
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform** = **iOS/iPadOS**; **Profile type** = **Templates** → **Device features** → **Create**.
3. **Basics → Name:** **iOS SSO App Extension – Pilot**. Add a description, e.g. *Microsoft Enterprise
   SSO app extension (redirect) for apps and browsers on COD iPhones.* Click **Next**.

### Step 5. Configure the Single sign-on app extension (Microsoft Entra ID)
1. On **Configuration settings**, expand **Single sign-on app extension**.
2. **SSO app extension type:** select **Microsoft Entra ID**. This pre-populates the Microsoft
   extension for you. *(If you choose **Redirect** instead, set these values by hand:)*
   - **Extension identifier:** `com.microsoft.azureauthenticator.ssoextension`
   - **Team identifier:** `UBF8T346G9`
   - **URLs** (the Entra endpoints to intercept — commercial cloud):
     - `https://login.microsoftonline.com`
     - `https://login.microsoft.com`
     - `https://sts.windows.net`
     - `https://login.windows.net`
     - `https://login.microsoftonline.us` *(US Gov)*
     - `https://login.partner.microsoftonline.cn` *(21Vianet)*
   - Keep only the URLs for the cloud(s) you actually use.

### Step 6. Add the extension configuration (scoping) keys
Still in the **Single sign-on app extension** section, under **Additional configuration**, add the
key/value pairs that scope and tune the Microsoft extension (each row: Key · Type · Value):
- **`Enable_SSO_On_All_ManagedApps`** · Integer · `1` — extends SSO to **all Intune-managed apps**
  (the recommended iOS coverage lever). 
- **`browser_sso_interaction_enabled`** · Integer · `1` — lets Safari (and supporting browsers) do
  interactive broker sign-in through the extension.
- **`disable_explicit_app_prompt`** · Integer · `1` — reduces redundant prompts from apps that would
  otherwise force interactive sign-in.
- *(Optional, if you did **not** enable all managed apps)* **`AppPrefixAllowList`** · String ·
  `com.microsoft.,com.apple.` — comma-separated bundle-ID prefixes allowed to use the extension.

> These keys are the Microsoft-documented extension parameters for the iOS Enterprise SSO plug-in.
> Add only the ones you need; leave the rest at default. **Verify current key names in your tenant** —
> Microsoft occasionally revises them.

### Step 7. Scope tags, assignment, review
1. **Next** through **Scope tags** (set if you use them).
2. **Assignments:** add the **pilot group**. Click **Next**.
3. **Review + create** → **Create**.

> Prefer automation? Run the included **`IOSSSOEXT-Set-ScopeTargeting.ps1`** (Microsoft Graph) to set
> or adjust the assignment (defaults to **-WhatIf** — preview first, then re-run to apply), and
> **`IOSSSOEXT-Discovery.ps1`** to confirm the profile is present and correctly configured.

---

## Phase 3 — Pilot

### Step 8. Push and confirm the profile
1. On the pilot device, open the **Company Portal** or **Settings** app and force a sync
   (**Settings → General → VPN & Device Management → (MDM profile)**, or Company Portal → **Check
   status**), and confirm **Microsoft Authenticator** is installed.
2. In Intune → **Devices → Configuration → iOS SSO App Extension – Pilot → Device status**, confirm
   the pilot device shows **Succeeded**.

### Step 9. Prime the broker (first interactive sign-in)
1. On the pilot device, open **Microsoft Authenticator** once so the extension is active, then open
   **Safari** and sign in to a Microsoft 365 web app (`https://outlook.office.com`) with the pilot
   user's Entra credentials; complete MFA if prompted.
2. This first sign-in establishes the broker session (PRT) the extension will reuse silently.

### Step 10. Confirm silent SSO
1. Open a **second** Entra-secured app or site (for example the **Outlook** app, or
   `https://portal.office.com` in Safari).
2. Confirm sign-in is **silent** — no password prompt and no repeat MFA — using the same identity.
3. Repeat in each supported browser to record which give silent SSO (see Testing, Test 5).

---

## Phase 4 — Validate and expand

### Step 11. Validate with the scripts
1. Run **`IOSSSOEXT-Discovery.ps1`** (tenant readiness: SSO app-extension profile present with the
   correct identifier, Microsoft Authenticator assigned).
2. Run **`IOSSSOEXT-Validation.ps1`** to confirm the profile is **assigned** to the intended group and
   the pilot device shows the profile **applied**.
3. Run **`IOSSSOEXT-Report.ps1`** to produce an SSO-coverage report (which iOS/iPadOS devices have the
   extension profile applied).

### Step 12. Remediate gaps (safe by default)
1. If devices are missing or mis-scoped, run **`IOSSSOEXT-Remediation.ps1`** — it **defaults to
   `-WhatIf`** and prints exactly what it would change. Review, then re-run to apply.

### Step 13. Expand in waves
1. Once the pilot passes (Testing gate), broaden the profile assignment to the next group, or make it
   the standard iOS SSO extension profile for corporate devices.
2. Add any additional **app bundle IDs / URLs** discovered during the pilot to the scoping keys
   (Step 6) and re-validate — or confirm `Enable_SSO_On_All_ManagedApps` already covers them.
3. Roll out in waves, validating each wave with `IOSSSOEXT-Report.ps1` before widening.
