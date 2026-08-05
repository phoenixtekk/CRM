# iOS/iPadOS Enterprise SSO App Extension for Corporate-Owned iPhones (Microsoft Enterprise SSO Plug-in via Intune)

> **Version 1.0.0** · Category: Intune · Solution code: IOSSSOEXT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — iOS/iPadOS Enterprise SSO App Extension (COD iPhones)

Users on corporate iPhones still hit repeated sign-in prompts — and repeated MFA — in apps and Safari
because the **Microsoft Enterprise SSO plug-in** isn't deployed as an **app extension**. This solution
deploys that plug-in as an Apple **Extensible Single Sign-On (SSO) app extension** — a
**redirect-type** extension hosted in **Microsoft Authenticator** — via **Microsoft Intune**, so apps
and browsers get **silent, shared single sign-on** to **Microsoft Entra ID**: the user signs in once
and the device broker satisfies subsequent Entra sign-ins across cooperating apps and Safari — no
repeated passwords, no repeat MFA.

**A deliberately scoped, distinct capability.** This is the **app/browser** SSO extension for
**corporate-owned, Intune-enrolled** iPhones/iPads. It is **not** device enrollment (ADE/ABM is a
prerequisite), **not** the two-phone personal+corporate model, and **not** shared-device identity —
each of those is a separate solution. It deploys a single configuration profile, silences prompts
*inside apps and Safari*, and is fully reversible by unassigning the profile — no re-enrollment, no
re-imaging.

The iOS story differs from the Mac in two ways this package makes explicit: the extension is hosted in
**Microsoft Authenticator** (not Company Portal), and iOS offers a one-key coverage lever —
**`Enable_SSO_On_All_ManagedApps`** — that extends SSO to every Intune-managed app at once.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **One profile, one purpose.** An iOS/iPadOS **SSO app extension (Microsoft Entra ID / Redirect)**
  configuration profile carrying the Microsoft Enterprise SSO identifiers, the Entra login URLs, and
  precise **managed-app / URL scoping** — deployed pilot-first.
- **Silent SSO where it counts.** Safari and MSAL/broker-aware apps get silent Entra sign-in after a
  single priming sign-in; browser coverage is set honestly (Safari reliable; others best-effort).
- **Precise, reversible scoping.** `Enable_SSO_On_All_ManagedApps`, `AppPrefixAllowList`, and URL
  lists target exactly the apps and browsers you intend — widen in waves after each gate.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click Intune steps, a requirements guide that tells you how to verify
*and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and
testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** silent, shared sign-in to Entra apps and browsers across every corporate iPhone — the
Enterprise SSO app extension deployed and proven on a pilot before you scale, without a consulting
engagement, and without touching how the device is enrolled.


---


# 1. Solution Overview — iOS/iPadOS Enterprise SSO App Extension for Corporate-Owned iPhones

## What this solution is
This solution deploys the **Microsoft Enterprise SSO plug-in** as an Apple **Extensible Single
Sign-On (SSO) app extension** on **corporate-owned (COD) iPhones and iPads** managed by **Microsoft
Intune**. Once in place, apps and browsers that authenticate against **Microsoft Entra ID** get
**silent, shared single sign-on** — the user signs in once and the on-device broker satisfies
subsequent Entra sign-ins across cooperating apps and Safari, without repeated password prompts or
per-app MFA.

Apple's **Extensible SSO** framework lets an identity provider register a system-wide authentication
extension. On iOS/iPadOS, Microsoft ships the Enterprise SSO plug-in **inside the Microsoft
Authenticator app** — this is the first important difference from the Mac, where the same extension
ships inside Company Portal:

- **iOS/iPadOS broker host = Microsoft Authenticator.** The extension binary lives in the
  **Microsoft Authenticator** app; without Authenticator installed, the extension identifier the
  profile references does not exist on the device.
- **macOS broker host = Company Portal.** (Covered by the separate *macOS Enterprise SSO App
  Extension* solution — do not confuse the two; the identifiers differ.)

> **Scope, stated plainly.** This solution delivers the **app/browser SSO extension** for
> **corporate-owned, Intune-enrolled** iPhones/iPads. It is the identity-experience layer — it
> silences sign-in prompts *inside apps and Safari*. It is **not** device enrollment (ADE/ABM is a
> prerequisite, covered by the enrollment solutions), it is **not** the two-phone
> personal+corporate scenario (see *Dual-Device iPhone Management with SSO*), and it is **not**
> shared-device identity (see *iOS iPhone Shared Device Mode — Frontline SSO*). It assumes each COD
> iPhone is assigned to **one** user.

## How Apple Extensible SSO works (the two types)
An Extensible SSO configuration profile carries a **type**:

- **Redirect** — for identity providers that use **OpenID Connect / OAuth 2 redirect** flows.
  **Microsoft Entra ID is a redirect IdP**, so the Enterprise SSO plug-in is a **redirect-type**
  extension. It intercepts authentication requests to a defined set of **Entra URLs** and completes
  them silently using the broker. **This solution uses the redirect type.**
- **Credential** — for **challenge/response (Kerberos-style)** providers. **Out of scope here.**

On iOS/iPadOS, Intune's **Device features** template exposes a convenient **SSO app extension type =
Microsoft Entra ID** option that pre-populates the Microsoft extension identifiers for you; the
underlying type is still Redirect. This solution uses that path (with the raw Redirect values given
as well, so you can verify or script them).

## How it works, step by step
1. **Microsoft Authenticator delivers the extension binary.** The Enterprise SSO plug-in ships inside
   the **Microsoft Authenticator** app for iOS/iPadOS. Authenticator must be installed (deployed
   **Required** from Intune) on the COD device.
2. **Intune deploys the redirect profile.** A **configuration profile** (Device features → *Single
   sign-on app extension*, type **Microsoft Entra ID**) activates the extension, setting the
   **Extension Identifier** `com.microsoft.azureauthenticator.ssoextension`, **Team Identifier**
   `UBF8T346G9`, **Type = Redirect**, and the **Entra URLs** to intercept.
3. **First sign-in primes the broker.** The user signs in once to a Microsoft app or web property
   (for example Outlook, or `https://outlook.office.com` in Safari) with their Entra credentials,
   completing MFA. The extension registers a **Primary Refresh Token (PRT)**–backed session on the
   device.
4. **Silent SSO afterward.** Subsequent Entra sign-ins from **cooperating apps and Safari** are
   satisfied **silently** — no password re-entry, no repeat MFA — until the session expires.
5. **Scoping (optional but recommended).** Extension-configuration keys tune coverage: turn on SSO
   for **all managed apps**, allow-list app bundle-ID prefixes, and enable browser interaction.

## What silent SSO covers (and what it needs)
- **Safari and native apps built on the Microsoft Authentication Library (MSAL)** or the iOS broker
  get silent SSO automatically once the extension is active and the broker is primed.
- **Managed apps** (deployed and managed by Intune) can all be brought into SSO with the
  iOS-specific key **`Enable_SSO_On_All_ManagedApps = 1`** — a coverage lever the Mac does not have.
- **Non-Safari browsers** (Chrome, Edge, Firefox on iOS) get broker SSO **only** when they support
  the iOS SSO extension; otherwise they fall back to normal interactive sign-in. Best-effort by
  design — set that expectation with users.
- The device must have **Microsoft Authenticator** present so the broker can register and issue the
  PRT.

## Benefits
- **Fewer prompts, less MFA fatigue** — one sign-in, then silent Entra SSO across apps and Safari on
  the corporate iPhone.
- **Managed-app-wide SSO** — one key (`Enable_SSO_On_All_ManagedApps`) extends SSO to every
  Intune-managed app on the device.
- **No enrollment change** — deploys a configuration profile only; it does **not** re-enroll or
  re-image the device and is reversible by unassigning the profile.
- **Conditional Access friendly** — the broker PRT session supports device-based Entra policies for
  the apps that use it.
- **Precise scoping** — target exactly the apps/URLs you want via bundle-ID prefixes and URL lists.

## Limitations (be honest with buyers)
- **Corporate-owned, enrolled devices.** This targets Intune-enrolled COD iPhones/iPads. It is not a
  BYOD/MAM-only capability (personal-device SSO for unenrolled phones is a different model).
- Requires the **Microsoft Authenticator** app (the extension lives inside it) and a supported
  iOS/iPadOS release (**iOS/iPadOS 13+**; a current release recommended).
- **Browser coverage varies.** Only browsers with iOS SSO-extension support get silent SSO; others
  sign in normally.
- Apps must use the **Microsoft broker/MSAL** or Safari to benefit; legacy apps with embedded
  webviews may not.
- Requires **Microsoft Entra ID** as the IdP and outbound access to the Entra login endpoints.
- **Identifiers can change.** The extension identifier and template options above reflect current
  Microsoft documentation — **verify them in your tenant** before fleet rollout rather than assuming.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Corporate-owned, Intune-enrolled iPhones/iPads receive the Microsoft Enterprise SSO plug-in
> (hosted in Microsoft Authenticator) as a redirect-type Extensible SSO app extension, scoped to
> Entra login URLs and managed apps, deployed pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — iOS/iPadOS Enterprise SSO App Extension (COD iPhones)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to the Microsoft
Enterprise SSO **app extension** for corporate-owned iPhones/iPads.

> **Scope reminder.** These requirements are for the **app/browser** SSO extension (redirect type) on
> **enrolled, corporate-owned** iPhones/iPads. They deliberately do **not** include shared-device
> identity (Shared Device Mode) or the personal+corporate dual-device model — those are separate
> solutions.

## R1. Corporate-owned iPhones/iPads enrolled in Intune
**Description:** The target devices are Intune-enrolled corporate-owned iOS/iPadOS devices
(supervised via Apple Business Manager + Automated Device Enrollment is the recommended COD path).
**Why:** The SSO app-extension configuration profile is delivered by Intune MDM; it only reaches
enrolled devices.
**Verify:** Intune admin center (`https://intune.microsoft.com`) → **Devices → iOS/iPadOS → iOS/iPadOS
devices**; the device is listed and **managed** (and, for COD, **supervised**).
**Implement:** Enroll the device via **Automated Device Enrollment (ADE)** with an ABM/ADE token and
enrollment profile so it appears under **Devices → iOS/iPadOS** as supervised/corporate. (Device
enrollment itself is covered by the ADE enrollment solutions.)

## R2. Supported iOS/iPadOS version
**Description:** An iOS/iPadOS release that supports the Extensible SSO **app** extension
(**iOS/iPadOS 13 or later**; a current, patched release recommended).
**Why:** Apple's Extensible SSO app-extension framework and the Microsoft Enterprise SSO plug-in
require iOS/iPadOS 13+; recent releases improve broker reliability.
**Verify:** On the device, **Settings → General → About → Software Version**; or Intune → device →
**Hardware**.
**Implement:** Update via **Settings → General → Software Update**, or deploy a **minimum-OS
compliance policy** so older devices are flagged.

## R3. Microsoft Authenticator app (extension host)
**Description:** The **Microsoft Authenticator** app installed on the device.
**Why:** On iOS/iPadOS the **Microsoft Enterprise SSO extension binary ships inside Microsoft
Authenticator** (unlike macOS, where it ships in Company Portal). Without Authenticator the extension
identifier the profile references does not exist on the device.
**Verify:** Intune → **Apps → iOS/iPadOS**; **Microsoft Authenticator** is added and assigned to your
pilot group, and the app is installed on the device.
**Implement:** Intune → **Apps → iOS/iPadOS → Add → iOS store app**; add **Microsoft Authenticator**
(publisher **Microsoft Corporation**, bundle ID `com.microsoft.azureauthenticator`), assign it
**Required** to the pilot group so it installs automatically.

## R4. Microsoft Entra ID as the identity provider
**Description:** Apps and browsers you want covered authenticate against **Microsoft Entra ID**.
**Why:** The redirect extension intercepts the **Entra login URLs**; only Entra-secured
authentication is brokered.
**Verify:** The target apps/sites sign in at `https://login.microsoftonline.com` (or your
sovereign-cloud equivalent).
**Implement:** Confirm the apps are registered in Entra and use Entra sign-in; non-Entra IdPs are out
of scope.

## R5. Extensible SSO app-extension configuration profile
**Description:** An iOS/iPadOS **SSO app extension** (redirect / **Microsoft Entra ID** type)
configuration profile carrying the Microsoft Enterprise SSO identifiers and Entra URLs.
**Why:** This profile is what activates and scopes the extension.
**Verify:** Intune → **Devices → Configuration**; a profile with an **SSO app extension** section
(extension identifier `com.microsoft.azureauthenticator.ssoextension`) exists and is assigned to your
pilot group.
**Implement:** Create it during deployment (Implementation Guide, Phase 2), or set/adjust its
assignment with the included `IOSSSOEXT-Set-ScopeTargeting.ps1`.

## R6. Target app bundle IDs and Entra URLs identified
**Description:** The **app bundle identifiers** and **Entra URLs** the extension should cover.
**Why:** Correct scoping decides which apps/browsers get silent SSO; a missing URL means that flow is
not brokered. On iOS you can also enable SSO for **all managed apps** at once.
**Verify:** You have the bundle IDs (for example `com.microsoft.Office.Outlook`,
`com.apple.mobilesafari`) and the Entra login URLs for your cloud.
**Implement:** Collect bundle IDs from the app vendors / the app's store listing; use the standard
Entra URL set (see Implementation) plus any sovereign-cloud URLs. Prefer
`Enable_SSO_On_All_ManagedApps = 1` for managed apps.

## R7. Supported browsers for silent SSO (awareness)
**Description:** Awareness of which iOS browsers honor the SSO extension.
**Why:** **Safari** flows are brokered natively; other browsers get silent SSO only if they support
the extension. Setting expectations prevents "it still prompts in Chrome" tickets.
**Verify:** Test each browser you support (Testing, Test 5).
**Implement:** Where a browser lacks support, document the fallback (normal interactive sign-in) or
standardize on Safari for brokered flows.

## R8. Network access to Microsoft Entra login endpoints
**Description:** Outbound HTTPS to the Entra sign-in endpoints for your cloud.
**Why:** The broker and the extension complete token requests against these endpoints.
**Verify:** From the device network, reach `https://login.microsoftonline.com` (commercial) or the
sovereign equivalent (`login.microsoftonline.us`, `login.partner.microsoftonline.cn`).
**Implement:** Allow Microsoft's published Entra/Office 365 URLs through proxy/firewall; do **not**
TLS-inspect the Microsoft login endpoints.

## R9. Company Portal for Conditional Access compliance (recommended)
**Description:** The Intune **Company Portal** app present for compliance/registration where
Conditional Access requires a compliant device.
**Why:** Silent SSO and device-based Conditional Access work best when the device is registered and
reporting compliance; Authenticator provides the SSO broker, Company Portal the MDM compliance
channel.
**Verify:** Intune → **Apps → iOS/iPadOS**; Company Portal is assigned; the device shows **compliant**.
**Implement:** Assign **Company Portal** (bundle ID `com.microsoft.CompanyPortal`) **Required** to the
pilot group if your CA policies gate the target apps on compliance.

## R10. Pilot user and pilot device
**Description:** At least one pilot user with a licensed Entra identity and one enrolled pilot COD
iPhone/iPad.
**Why:** Every solution is validated on a pilot before fleet rollout.
**Verify:** The pilot user can sign in to a Microsoft 365 app; the pilot device is enrolled (R1) and
has Microsoft Authenticator (R3).
**Implement:** Add the pilot user/device to the **pilot security group** (Global Requirement G5) used
for the profile assignment.


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing & Validation — iOS/iPadOS Enterprise SSO App Extension

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps
for the user experience.

> **What "pass" means here:** apps and browsers on the corporate iPhone get **silent** Entra SSO after
> one priming sign-in. This solution does **not** enroll the device or change shared-device identity.

## Test 1 — Tenant readiness
**Procedure:** Run `IOSSSOEXT-Discovery.ps1`.
**Pass:** An **SSO app extension** configuration profile exists with Extension Identifier
`com.microsoft.azureauthenticator.ssoextension` (redirect / Microsoft Entra ID type); Microsoft
Authenticator (iOS) is added/assigned.
**Fail:** Missing profile, wrong identifier, or missing Authenticator → resolve before piloting.

## Test 2 — Profile assignment
**Procedure:** Run `IOSSSOEXT-Validation.ps1` (or check **Devices → Configuration → (profile) →
Assignments**).
**Pass:** The profile is assigned to the intended **pilot group** and to no unintended broad group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct the assignment (Implement
Step 7 / `IOSSSOEXT-Set-ScopeTargeting.ps1`).

## Test 3 — Profile applied on the device
**Procedure:** On the pilot device, **Settings → General → VPN & Device Management → (MDM profile)**
(or Intune → profile → **Device status**).
**Pass:** The **iOS SSO App Extension – Pilot** profile is installed and Intune shows **Succeeded**;
Microsoft Authenticator is present.
**Fail:** Not installed / error → force a sync and confirm Microsoft Authenticator is installed (R3).

## Test 4 — Broker primed (first sign-in)
**Procedure:** Open Microsoft Authenticator once, then in Safari sign in to
`https://outlook.office.com` with the pilot user's Entra credentials (complete MFA if prompted).
**Pass:** Interactive sign-in succeeds and completes cleanly.
**Fail:** Sign-in loops or errors → verify the Entra URLs in the profile (Step 5) and network access
to the login endpoints (R8).

## Test 5 — Silent SSO in apps and browsers
**Procedure:** Without re-entering credentials, open a **second** Entra-secured target: a native
Microsoft app (e.g. the **Outlook** app) and each supported browser (**Safari** first).
**Pass:** Sign-in is **silent** (no password prompt, no repeat MFA) using the same identity in Safari
and in MSAL/broker-aware apps.
**Fail (Safari/native):** Still prompting → verify Extension Identifier/Team ID and that the app is
covered by `Enable_SSO_On_All_ManagedApps` or the `AppPrefixAllowList` (Step 6).
**Expected variance (other browsers):** Chrome/Firefox without SSO-extension support fall back to
interactive sign-in — record this as expected, not a failure (R7).

## Test 6 — Managed-app coverage behaves
**Procedure:** Confirm the coverage lever: with `Enable_SSO_On_All_ManagedApps = 1`, open two
different Intune-managed Microsoft apps and confirm both are silent; if you used `AppPrefixAllowList`
instead, confirm an app outside the prefix is not brokered while one inside it is.
**Pass:** The intended apps get silent SSO; apps you did not scope do not.
**Fail:** Unexpected apps brokered or intended apps skipped → adjust the scoping keys (Step 6) and
re-sync.

## Test 7 — Coverage report
**Procedure:** Run `IOSSSOEXT-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **profile applied**; counts match the assigned
group.
**Fail:** Devices missing from the report → run `IOSSSOEXT-Remediation.ps1` (`-WhatIf` first) to fix
assignment/scoping.

## Test 8 — No enrollment/identity change (negative test)
**Procedure:** Confirm the device is still enrolled and assigned to the same single user; sign out of
one app.
**Pass:** The device enrollment and its single-user assignment are **unchanged**; this solution only
adds the SSO extension profile and does not alter enrollment or introduce a shared session.
**Fail:** If device ownership/affinity changed, an unintended enrollment or shared-device policy is
also present — confirm this solution deployed the **SSO extension profile** only.

## Acceptance gate
Proceed to **Expand** only when Tests 1–7 pass on at least one pilot device, Test 8 confirms
enrollment/identity is unchanged, and a real pilot user confirms silent SSO across the intended apps
and Safari.


---


# 6. Troubleshooting — iOS/iPadOS Enterprise SSO App Extension

Work top-down: confirm the **profile is applied**, then **Microsoft Authenticator is present and the
broker is primed**, then **scoping**. Most "still prompting" cases are a missing Authenticator app, a
mis-typed identifier, or an app outside the coverage keys. Each symptom below gives the **likely
cause** and the **fix**.

> **Before you start:** verify this is the app/browser extension problem you think it is. If the
> device is *shared between people* and users see each other's sessions, that is a shared-device
> identity problem (**Shared Device Mode**, separate solution), not this per-user app extension.

## Symptom: The SSO profile never appears on the device
**Likely cause:** Device not synced, not assigned, or not enrolled.
**Fix:**
1. Confirm the device is in the **pilot group** and the profile is **assigned**
   (`IOSSSOEXT-Validation.ps1`).
2. Force sync from Company Portal (**Check status**) or **Settings → General → VPN & Device
   Management**.
3. Check **Devices → Configuration → (profile) → Device status** for an error.
4. Confirm **Microsoft Authenticator** is installed (R3) — the extension identifier is invalid
   without it.

## Symptom: Profile shows "Error" / "Conflict" in Device status
**Likely cause:** A second SSO app-extension profile conflicts, or a duplicate profile targets the
same device.
**Fix:**
1. Run `IOSSSOEXT-Discovery.ps1` to list SSO extension profiles.
2. Ensure only **one** SSO app-extension (redirect / Microsoft Entra ID) profile targets the device.
3. Remove or re-scope the duplicate.

## Symptom: Apps/browsers still prompt for a password (no silent SSO)
**Likely cause:** Authenticator missing, broker not primed, wrong identifiers, or app not covered.
**Fix:**
1. Confirm **Microsoft Authenticator** is installed, then open it once to activate the extension.
2. Complete **one interactive sign-in** in Safari to prime the broker (Implementation Step 9).
3. Verify **Extension Identifier** `com.microsoft.azureauthenticator.ssoextension` and **Team
   Identifier** `UBF8T346G9` exactly (Step 5).
4. Confirm the app is covered by `Enable_SSO_On_All_ManagedApps = 1` or by your `AppPrefixAllowList`
   (Step 6), and that the app authenticates against a URL in the profile's list.

## Symptom: Silent SSO works in Safari but not in Chrome/Edge/Firefox
**Likely cause:** Expected — those browsers may not support the iOS SSO extension.
**Fix:**
1. Set `browser_sso_interaction_enabled = 1` (Step 6) to enable interactive broker sign-in where
   supported.
2. Where a browser has no extension support, document the fallback and steer web SSO to **Safari**.
3. This is a browser limitation, not a profile error — set expectations with users (R7).

## Symptom: One specific app is not brokered
**Likely cause:** App not managed (so `Enable_SSO_On_All_ManagedApps` doesn't cover it), bundle ID
outside the allow-list, or the app uses a non-MSAL/embedded webview auth stack.
**Fix:**
1. If you rely on `Enable_SSO_On_All_ManagedApps`, confirm the app is actually deployed as a
   **managed** app.
2. Otherwise add the exact bundle ID (or its prefix) to `AppPrefixAllowList` (Step 6).
3. If the app uses a legacy embedded webview (not the broker/MSAL or Safari), silent SSO may not be
   possible — note it as a known limitation.

## Symptom: Repeated MFA prompts even after priming
**Likely cause:** Broker session not established, or Conditional Access re-challenging.
**Fix:**
1. Confirm Authenticator registered the device (open Authenticator; the work account is present).
2. Set `disable_explicit_app_prompt = 1` (Step 6).
3. Review Conditional Access sign-in frequency / device-compliance policies gating the app; confirm
   the device reports **compliant** (R9) so CA is satisfied by the device rather than re-prompting.

## Symptom: Sign-in loops or fails after the profile applies
**Likely cause:** Missing Entra URL, blocked login endpoint, or TLS inspection.
**Fix:**
1. Confirm the correct **Entra URLs** for your cloud are present (Step 5) — commercial vs US Gov vs
   21Vianet differ.
2. From the device network, reach `https://login.microsoftonline.com` (or sovereign equivalent) (R8).
3. **Exempt Microsoft login endpoints from TLS inspection** — inspection breaks token exchange.

## Symptom: Works for some users, not others
**Likely cause:** Group membership, licensing, or Authenticator not installed on those devices.
**Fix:**
1. Confirm affected users/devices are in the assigned group (`IOSSSOEXT-Report.ps1`).
2. Confirm each user has a licensed Entra identity (R10) and each device has Microsoft Authenticator
   (R3).
3. Have the affected user open Authenticator and complete the one-time interactive sign-in to prime
   the broker.

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or missing Authenticator.
**Fix:**
1. Run `IOSSSOEXT-Report.ps1` to list which devices lack the applied profile.
2. Run `IOSSSOEXT-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (R1) and Authenticator (R3).

## Escalation checklist
Before opening a Microsoft support case, collect: the `IOSSSOEXT-Discovery.ps1` output, the profile's
Device status export, the exact Extension/Team identifiers and URL list, the affected app bundle IDs,
iOS/iPadOS version, whether Authenticator is installed and registered, and whether Safari brokers
silently (isolates the extension from browser-specific issues).


---


# 7. Best Practices — iOS/iPadOS Enterprise SSO App Extension (App/URL Scoping)

These practices keep the app/browser SSO extension precise, predictable, and reversible on
corporate-owned iPhones/iPads. They assume the deployment model in the Solution Overview: a
**redirect-type** Extensible SSO app extension hosted in **Microsoft Authenticator**, deployed via
Intune, pilot-first.

## Get the broker host right
- **Deploy Microsoft Authenticator first, Required.** On iOS the extension lives in Authenticator (not
  Company Portal). Make it a **Required** app assigned to the same group as the SSO profile so the
  extension binary is always present before the profile lands.
- **Add Company Portal where Conditional Access needs compliance.** Authenticator brokers the token;
  Company Portal carries MDM compliance. If CA gates the target apps on a compliant device, deploy
  both.

## Prefer managed-app-wide SSO, scope only when you must
- **Start with `Enable_SSO_On_All_ManagedApps = 1`.** On iOS this is the cleanest coverage: every
  Intune-managed app gets SSO without enumerating bundle IDs. Use an `AppPrefixAllowList` only if you
  deliberately want a narrower set.
- **If you allow-list, prefer prefixes over long ID lists.** A prefix like `com.microsoft.` covers the
  Office suite and Teams without listing every bundle ID; add specific IDs only for outliers.
- **Record every bundle ID you add.** Keep a short table (app → bundle ID → why included) so the next
  admin understands the scope.

## Scope URLs to the right cloud
- **Only your cloud's Entra URLs.** Commercial uses `login.microsoftonline.com` /
  `login.microsoft.com` / `sts.windows.net` / `login.windows.net`. US Gov uses
  `login.microsoftonline.us`; 21Vianet uses `login.partner.microsoftonline.cn`. Do **not** add clouds
  you don't use — extra URLs widen the interception surface for no benefit.
- **Use the "Microsoft Entra ID" template type** to auto-populate identifiers, then **verify** them
  against current Microsoft docs before you widen the rollout.

## Set browser and MFA expectations
- **Safari is the reliable path.** Safari flows broker natively. Standardize on Safari for brokered
  web SSO where you can.
- **Enable `browser_sso_interaction_enabled = 1`** so supporting browsers can complete interactive
  broker sign-in; document that non-supporting browsers fall back to normal sign-in.
- **Prime once, then measure.** Expect one interactive sign-in (with MFA) per user to seed the broker;
  measure silent SSO from the *second* sign-in onward. Use `disable_explicit_app_prompt = 1` to cut
  redundant app prompts.

## Deploy pilot-first and reversibly
- **Assign to a pilot group, never "All devices" first.** Expand in waves after each gate passes.
- **Rollback is unassignment.** Because this only adds a configuration profile, removing the
  assignment cleanly reverts behavior to pre-SSO — no enrollment or account cleanup needed. Keep the
  profile so you can re-target quickly.

## Operate and monitor
- **Report before you widen.** Run `IOSSSOEXT-Report.ps1` each wave; only broaden when coverage
  matches the assigned group.
- **Remediate with `-WhatIf` first.** `IOSSSOEXT-Remediation.ps1` and `IOSSSOEXT-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply.
- **Keep Microsoft Authenticator current.** The extension binary ships in Authenticator; keep it
  assigned **Required** and updated so the extension identifier stays valid.
- **Don't TLS-inspect Microsoft login endpoints** — it breaks the broker token exchange.

## Change control
- **Version scope changes.** When you add bundle IDs/URLs or flip a coverage key, note the date and
  reason; re-run Discovery and Report to confirm no regressions.
- **Review after iOS major upgrades.** Confirm the extension still applies and silent SSO holds after
  significant iOS/iPadOS releases before expanding further.


---


# 8. Deliverables Summary — iOS/iPadOS Enterprise SSO App Extension

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: the
  app/browser SSO extension for corporate-owned iPhones/iPads, not device enrollment and not
  shared-device identity.
- **Solution Overview** — how Apple's Extensible SSO (redirect vs credential types) and the Microsoft
  Enterprise SSO plug-in work on iOS (hosted in **Microsoft Authenticator**), how silent SSO is
  achieved, and how this differs from the Mac product and the shared-device / dual-device solutions.
- **Requirements Guide** — every Intune/Entra/iOS prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: prepare the
  device (Microsoft Authenticator), create the Device-features SSO app-extension profile with
  managed-app / URL scoping, pilot, then validate and expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates (including a negative test that
  enrollment/identity is unchanged) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for "still prompting," repeated MFA, scoping, browser, and
  conflict cases.
- **Best Practices** — managed-app-wide SSO vs allow-listing, getting the Authenticator broker host
  right, browser/MFA expectations, and reversible pilot-first rollout.

## PowerShell scripts (Microsoft Graph) — `IOSSSOEXT-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`IOSSSOEXT-Discovery.ps1`** — tenant readiness: the SSO app-extension profile is present with the
   correct Microsoft Enterprise SSO extension identifier, and Microsoft Authenticator (iOS) is
   added/assigned.
2. **`IOSSSOEXT-Validation.ps1`** — validates the profile's **assignment** and per-device **applied**
   state, with a clear PASS/FAIL summary.
3. **`IOSSSOEXT-Report.ps1`** — tenant-wide CSV report of iOS/iPadOS devices and whether the SSO
   app-extension profile is applied — the SSO coverage report.
4. **`IOSSSOEXT-Remediation.ps1`** — safe remediation of missing/mis-scoped profiles (re-assign to a
   target group, flag conflicts). **`-WhatIf` by default**; applies only when re-run to commit.
5. **`IOSSSOEXT-Set-ScopeTargeting.ps1`** — sets/adjusts the profile's group assignment (target-group
   builder). **`-WhatIf` by default.**

## Hero image
- **`IOSSSOEXT-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited
devices**.
