# 3. Implementation — macOS Enterprise SSO App Extension (Apps & Browsers)

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against
a **pilot group** first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` unless
noted.

> **This deploys the app/browser SSO extension only.** It does **not** configure Platform SSO device
> login. Every setting below uses the **Redirect** extension type; do not select **Credential** /
> Platform SSO here (that is the separate device-login solution).

---

## Phase 1 — Prepare the device for the extension

### Step 1. Confirm macOS enrollment and version
1. Go to **Devices → macOS → macOS devices** and confirm the pilot Mac is **managed**.
2. Open the device → **Hardware** and confirm macOS **10.15+** (current release recommended).

### Step 2. Add and assign the Company Portal app (hosts the extension)
1. Go to **Apps → macOS → Add**.
2. Choose the macOS **Company Portal** app, **Select**.
3. Assign it **Required** to your **pilot group** so it installs automatically. Company Portal is what
   delivers the Microsoft Enterprise SSO extension binary — the profile in Phase 2 only *activates* it.

### Step 3. Gather scoping inputs
1. Record the **Entra login URLs** for your cloud (defaults below in Step 5).
2. Record the **app bundle IDs** you want covered, for example:
   - Safari — `com.apple.Safari`
   - Microsoft Outlook — `com.microsoft.Outlook`
   - Microsoft Teams — `com.microsoft.teams2`
   - Microsoft Word/Excel/PowerPoint — `com.microsoft.Word`, `com.microsoft.Excel`, `com.microsoft.Powerpoint`

---

## Phase 2 — Create the Extensible SSO app-extension profile

### Step 4. Create the configuration profile
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform** = **macOS**; **Profile type** = **Settings catalog** → **Create**.
3. **Basics → Name:** **macOS SSO App Extension – Pilot**. Add a description, e.g. *Microsoft
   Enterprise SSO app extension (redirect) for apps and browsers.* Click **Next**.

### Step 5. Add the Single Sign-On Extension settings (redirect)
1. On **Configuration settings**, click **Add settings**.
2. In the picker, search **Single Sign On Extension** and expand the
   **Authentication → Extensible Single Sign On (SSO)** category.
3. Add and set:
   - **Extension Identifier:** `com.microsoft.CompanyPortalMac.ssoextension`
   - **Team Identifier:** `UBF8T346G9`
   - **Type:** **Redirect**  ← (the app/browser extension type; **not** Credential/Platform SSO)
   - **URLs** (the Entra endpoints to intercept — commercial cloud):
     - `https://login.microsoftonline.com`
     - `https://login.microsoft.com`
     - `https://sts.windows.net`
     - `https://login.windows.net`
     - `https://login.microsoftonline.us` *(US Gov)*
     - `https://login.partner.microsoftonline.cn` *(21Vianet)*
   - Keep only the URLs for the cloud(s) you actually use.

### Step 6. Add the extension configuration (scoping) keys
Still under the SSO extension settings, add the optional **Extension-specific configuration** keys
that scope and tune the Microsoft extension:
- **`AppPrefixAllowList`** *(string)* — comma-separated bundle-ID prefixes allowed to use the
  extension, e.g. `com.microsoft.,com.apple.`  Limits which apps participate.
- **`browser_sso_interaction_enabled`** *(integer `1`)* — lets browsers (Safari and supporting
  browsers) do interactive broker sign-in through the extension.
- **`disable_explicit_app_prompt`** *(integer `1`)* — reduces redundant prompts from apps that would
  otherwise force interactive sign-in.
- *(Optional)* **`AppBlockList`** — bundle IDs to explicitly exclude.

> These keys are the Microsoft-documented extension parameters for the Enterprise SSO plug-in. Add
> only the ones you need; leave the rest at default.

### Step 7. Scope tags, assignment, review
1. **Next** through **Scope tags** (set if you use them).
2. **Assignments:** add the **pilot group**. Click **Next**.
3. **Review + create** → **Create**.

> Prefer automation? Run the included **`MACSSOEXT-Set-ScopeTargeting.ps1`** (Microsoft Graph) to set
> or adjust the assignment (defaults to **-WhatIf** — preview first, then re-run to apply), and
> **`MACSSOEXT-Discovery.ps1`** to confirm the profile is present and correctly typed.

---

## Phase 3 — Pilot

### Step 8. Push and confirm the profile
1. On the pilot Mac, force a sync: **Company Portal → (device) → Check settings**, or
   **System Settings → General → Device Management** and confirm the profile is installed.
2. In Intune → **Devices → Configuration → macOS SSO App Extension – Pilot → Device status**, confirm
   the pilot device shows **Succeeded**.

### Step 9. Prime the broker (first interactive sign-in)
1. On the pilot Mac, open **Safari** and sign in to a Microsoft 365 web app
   (`https://outlook.office.com`) with the pilot user's Entra credentials; complete MFA if prompted.
2. This first sign-in establishes the broker session the extension will reuse silently.

### Step 10. Confirm silent SSO
1. Open a **second** Entra-secured app or site (for example `https://portal.office.com`, or a native
   Microsoft app such as Outlook).
2. Confirm sign-in is **silent** — no password prompt — using the same identity.
3. Repeat in each supported browser to record which give silent SSO (see Testing, Test 5).

---

## Phase 4 — Validate and expand

### Step 11. Validate with the scripts
1. Run **`MACSSOEXT-Discovery.ps1`** (tenant readiness: extension profile present, correct
   identifier/type, Company Portal assigned).
2. Run **`MACSSOEXT-Validation.ps1`** to confirm the profile is **assigned** to the intended group and
   the pilot device shows the profile **applied**.
3. Run **`MACSSOEXT-Report.ps1`** to produce an SSO-coverage report (which macOS devices have the
   extension profile applied).

### Step 12. Remediate gaps (safe by default)
1. If devices are missing or mis-scoped, run **`MACSSOEXT-Remediation.ps1`** — it **defaults to
   `-WhatIf`** and prints exactly what it would change. Review, then re-run to apply.

### Step 13. Expand in waves
1. Once the pilot passes (Testing gate), broaden the profile assignment to the next group, or make it
   the standard macOS SSO extension profile.
2. Add any additional **app bundle IDs / URLs** discovered during the pilot to the scoping keys
   (Step 6) and re-validate.
3. Roll out in waves, validating each wave with `MACSSOEXT-Report.ps1` before widening.
