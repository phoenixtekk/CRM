# macOS Enterprise SSO App Extension (Extensible SSO for Apps & Browsers) via Intune

> **Version 1.0.0** · Category: Intune · Solution code: MACSSOEXT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — macOS Enterprise SSO App Extension (Apps & Browsers)

Users on managed Macs still hit repeated sign-in prompts in apps and Safari because the **Microsoft
Enterprise SSO plug-in** isn't deployed as an **app extension**. This solution deploys that plug-in as
an Apple **Extensible Single Sign-On (SSO) app extension** — a **redirect-type** extension — via
**Microsoft Intune**, so apps and browsers get **silent, shared single sign-on** to **Microsoft Entra
ID**: the user signs in once and the device broker satisfies subsequent Entra sign-ins across
cooperating apps and Safari — no repeated passwords.

**A deliberately scoped, distinct capability.** This is the **app/browser** SSO extension. It is
**not** macOS **Platform SSO device login** (that changes how users sign in to the Mac itself and is a
separate solution). This one deploys a single system-extension profile, silences prompts *inside apps
and browsers*, and is fully reversible by unassigning the profile — no re-imaging, no account
migration, no login-window change.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **One profile, one purpose.** A macOS **SSO app extension (Redirect)** configuration profile
  carrying the Microsoft Enterprise SSO identifiers, the Entra login URLs, and precise **app-bundle /
  URL scoping** — deployed pilot-first.
- **Silent SSO where it counts.** Safari and MSAL/broker-aware apps get silent Entra sign-in after a
  single priming sign-in; browser coverage is set honestly (Safari reliable; others best-effort).
- **Precise, reversible scoping.** `AppPrefixAllowList`, URL lists, and block lists target exactly the
  apps and browsers you intend — widen in waves after each gate.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click Intune steps, a requirements guide that tells you how to verify
*and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and
testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** silent, shared sign-in to Entra apps and browsers across every managed Mac — the
Enterprise SSO app extension deployed and proven on a pilot before you scale, without a consulting
engagement, and without touching how users log in to the Mac.


---


# 1. Solution Overview — macOS Enterprise SSO App Extension (Extensible SSO for Apps & Browsers)

## What this solution is
This solution deploys the **Microsoft Enterprise SSO plug-in** as an Apple **Extensible Single
Sign-On (SSO) app extension** on managed Macs, via a **Microsoft Intune** configuration profile. Once
in place, apps and browsers that authenticate against **Microsoft Entra ID** get **silent, shared
single sign-on** — the user signs in once and the device broker satisfies subsequent Entra sign-ins
across cooperating apps and Safari, without repeated password prompts.

Apple's **Extensible SSO** framework lets a third-party identity provider register a system-wide
authentication extension. Microsoft ships two kinds of extension through the same **Company Portal**
bundle:

- an **app SSO extension** (a **redirect**-type extension) that brokers Entra tokens for **apps and
  browsers** — **this is the subject of this solution**; and
- **Platform SSO** (a **credential**-type extension) that extends Entra sign-in to the **macOS login
  window / device account** — that is a **separate** capability, covered by a different product.

> **Scope, stated plainly.** This solution delivers the **app/browser SSO extension** only. It does
> **not** configure macOS **Platform SSO device login** (Secure Enclave / password-sync / smart-card
> login-window registration). If you want corporate identity **at the Mac login window**, use the
> companion solution *macOS Automated Device Enrollment with SSO* instead of, or in addition to, this
> one. The two are complementary but distinct: this one silences prompts *inside apps and browsers*;
> Platform SSO changes *how the user logs in to the Mac*.

## How Apple Extensible SSO works (the two types)
An Extensible SSO configuration profile carries a **type**:

- **Redirect** — for identity providers that use **OpenID Connect / OAuth 2 redirect** flows
  (Microsoft Entra ID is a redirect IdP). The extension intercepts authentication requests to a
  defined set of **URLs** and completes them silently using the broker. **This solution uses the
  redirect type.**
- **Credential** — for **challenge/response (Kerberos-style)** providers, and the mechanism Apple's
  **Platform SSO** builds on to register the *device/login* identity. **Out of scope here.**

For the Microsoft Enterprise SSO **app** extension we therefore create a **redirect** profile that
names the Microsoft **Entra login URLs**, the extension's **bundle identifier**, and the Apple
**Team ID** — and, optionally, the **app bundle IDs** allowed to use it.

## How it works, step by step
1. **Company Portal delivers the extension binary.** The Microsoft Enterprise SSO extension ships
   inside the **Intune Company Portal** app for macOS. Company Portal must be installed on the device.
2. **Intune deploys the redirect profile.** A **configuration profile** (Settings catalog →
   *Single Sign-On Extension* / SSO app extension) activates the extension, sets its **Extension
   Identifier** `com.microsoft.CompanyPortalMac.ssoextension`, **Team Identifier** `UBF8T346G9`,
   **Type = Redirect**, and the **Entra URLs** the extension should intercept.
3. **First sign-in primes the broker.** The user signs in once to a Microsoft app or web property
   (for example Outlook on the web) with their Entra credentials, optionally completing MFA. The
   extension caches a **Primary Refresh Token (PRT)**–backed session on the device.
4. **Silent SSO afterward.** Subsequent Entra sign-ins from **cooperating apps and Safari** are
   satisfied **silently** by the extension — no password re-entry — until the session expires.
5. **Scoping (optional).** You can restrict which **app bundle IDs** participate, and add extra
   **URLs** or a `AppPrefixAllowList`, so the extension covers exactly the apps/browsers you intend.

## What silent SSO covers (and what it needs)
- **Safari and WebKit-based flows** and **native apps built on the Microsoft Authentication Library
  (MSAL)** or the macOS broker get silent SSO automatically once the extension is active.
- **Non-Microsoft browsers** (Chrome, Edge on macOS, Firefox) get broker SSO **only** when the
  browser supports the macOS SSO extension or ships the Microsoft **SSO browser support** hooks;
  otherwise they fall back to normal interactive sign-in. Best-effort by design — call this out to
  users.
- The device should have the **Microsoft Authenticator** or **Company Portal** identity present so
  the broker can register and issue the PRT.

## Benefits
- **Fewer prompts** — one sign-in, then silent Entra SSO across apps and Safari on the Mac.
- **No login-window change** — deploys a system extension only; it does **not** alter how users log
  in to macOS, so there is no re-imaging or account migration.
- **Fast to pilot** — a single configuration profile plus Company Portal; reversible by unassigning
  the profile.
- **Conditional Access friendly** — the broker session supports device-based Entra policies for the
  apps that use it.
- **Precise scoping** — target exactly the apps/URLs you want via bundle-ID and URL lists.

## Limitations (be honest with buyers)
- **Not device login.** This does not provide macOS login-window SSO — that is **Platform SSO**
  (separate product). Do not expect the Mac account password to sync with Entra here.
- Requires the **Company Portal** app (the extension lives inside it) and a supported macOS release
  (**macOS 10.15+** for the app SSO extension; a current macOS is recommended).
- **Browser coverage varies.** Only browsers with SSO-extension support get silent SSO; others sign
  in normally.
- Apps must use the **Microsoft broker/MSAL** or Safari/WebKit to benefit; legacy apps with embedded
  webviews may not.
- Requires **Microsoft Entra ID** as the IdP and outbound access to the Entra login endpoints.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Managed (Intune-enrolled) Macs receive the Microsoft Enterprise SSO plug-in as a redirect-type
> Extensible SSO app extension, scoped to Entra login URLs (and optionally specific app bundle IDs),
> deployed pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — macOS Enterprise SSO App Extension (Apps & Browsers)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to the Microsoft
Enterprise SSO **app extension** for apps and browsers.

> **Scope reminder.** These requirements are for the **app/browser** SSO extension (redirect type).
> They deliberately do **not** include Platform SSO device-login prerequisites (Secure Enclave method,
> login-window registration). That is a separate solution.

## R1. macOS devices enrolled in Intune
**Description:** The target Macs are enrolled in Microsoft Intune and manageable.
**Why:** The SSO app-extension configuration profile is delivered by Intune MDM; it only reaches
enrolled devices.
**Verify:** Intune admin center (`https://intune.microsoft.com`) → **Devices → macOS → macOS devices**;
the device is listed and **managed**.
**Implement:** Enroll the Mac (Company Portal enrollment, Automated Device Enrollment, or user
enrollment as appropriate) so it appears under **Devices → macOS**.

## R2. Supported macOS version
**Description:** A macOS release that supports the Extensible SSO **app** extension (**macOS 10.15
Catalina or later**; a current, patched macOS recommended).
**Why:** Apple's Extensible SSO app-extension framework and the Microsoft Enterprise SSO plug-in
require macOS 10.15+; recent releases improve broker reliability.
**Verify:** On the Mac, **Apple menu → About This Mac**; or Intune → device → **Hardware**.
**Implement:** Update via **System Settings → General → Software Update**, or deploy a **minimum-OS
compliance policy** so older Macs are flagged.

## R3. Company Portal app for macOS (extension host)
**Description:** The Intune **Company Portal** application installed on the Mac.
**Why:** The **Microsoft Enterprise SSO extension binary ships inside Company Portal**; without it the
extension identifier the profile references does not exist on the device.
**Verify:** Intune → **Apps → macOS**; "Company Portal" is added and assigned to your pilot group, and
the app is installed on the device.
**Implement:** Intune → **Apps → macOS → Add** → add the macOS **Company Portal**, assign it
**Required** to the pilot group so it installs automatically.

## R4. Microsoft Authenticator or broker identity present (recommended)
**Description:** A Microsoft identity broker on the device — Company Portal is sufficient; Microsoft
**Authenticator** is not required on macOS but the broker session must be establishable.
**Why:** The extension brokers Entra tokens using a device-registered session (PRT); the first
interactive sign-in primes it.
**Verify:** After the profile applies, a first sign-in to a Microsoft app completes and later sign-ins
are silent (see Testing).
**Implement:** Ensure Company Portal is installed (R3) and the user completes one interactive Entra
sign-in to prime the broker.

## R5. Microsoft Entra ID as the identity provider
**Description:** Apps and browsers you want covered authenticate against **Microsoft Entra ID**.
**Why:** The redirect extension intercepts the **Entra login URLs**; only Entra-secured
authentication is brokered.
**Verify:** The target apps/sites sign in at `https://login.microsoftonline.com` (or your
sovereign-cloud equivalent).
**Implement:** Confirm the apps are registered in Entra and use Entra sign-in; non-Entra IdPs are out
of scope.

## R6. Extensible SSO app-extension configuration profile
**Description:** A macOS **SSO app extension** (redirect) configuration profile carrying the Microsoft
Enterprise SSO identifiers and Entra URLs.
**Why:** This profile is what activates and scopes the extension.
**Verify:** Intune → **Devices → Configuration**; a profile of type **SSO app extension** (redirect,
`com.microsoft.CompanyPortalMac.ssoextension`) exists and is assigned to your pilot group.
**Implement:** Create it during deployment (Implementation Guide, Phase 2), or run the included
`MACSSOEXT-Set-ScopeTargeting.ps1` / provisioning path via Microsoft Graph.

## R7. Target app bundle IDs and URLs identified
**Description:** A list of the **app bundle identifiers** and **Entra URLs** the extension should
cover.
**Why:** Correct scoping decides which apps/browsers get silent SSO; a missing URL means that flow
is not brokered.
**Verify:** You have the bundle IDs (for example `com.microsoft.Outlook`, `com.apple.Safari`) and the
Entra login URLs for your cloud.
**Implement:** Collect bundle IDs from the app vendors / `codesign`/`osascript id` output; use the
standard Entra URL set (see Implementation) plus any sovereign-cloud URLs.

## R8. Supported browsers for silent SSO (awareness)
**Description:** Awareness of which browsers honor the macOS SSO extension.
**Why:** **Safari/WebKit** flows are brokered natively; other browsers get silent SSO only if they
support the extension. Setting expectations prevents "it still prompts in Chrome" tickets.
**Verify:** Test each browser you support (Testing, Test 5).
**Implement:** Where a browser lacks support, document the fallback (normal interactive sign-in) or
standardize on Safari for brokered flows.

## R9. Network access to Microsoft Entra login endpoints
**Description:** Outbound HTTPS to the Entra sign-in endpoints for your cloud.
**Why:** The broker and the extension complete token requests against these endpoints.
**Verify:** From the device network, reach `https://login.microsoftonline.com` (commercial) or the
sovereign equivalent (`login.microsoftonline.us`, `login.partner.microsoftonline.cn`).
**Implement:** Allow Microsoft's published Entra/Office 365 URLs through proxy/firewall; do **not**
TLS-inspect the Microsoft login endpoints.

## R10. Pilot user and pilot Mac
**Description:** At least one pilot user with a licensed Entra identity and one enrolled pilot Mac.
**Why:** Every solution is validated on a pilot before fleet rollout.
**Verify:** The pilot user can sign in to a Microsoft 365 app; the pilot Mac is enrolled (R1) and has
Company Portal (R3).
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


---


# 5. Testing & Validation — macOS Enterprise SSO App Extension

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps
for the user experience.

> **What "pass" means here:** apps and browsers get **silent** Entra SSO. This solution does **not**
> change the macOS login window — do not test for login-window SSO; that is Platform SSO (separate
> product).

## Test 1 — Tenant readiness
**Procedure:** Run `MACSSOEXT-Discovery.ps1`.
**Pass:** An **SSO app extension** (redirect) configuration profile exists with Extension Identifier
`com.microsoft.CompanyPortalMac.ssoextension` and Team Identifier `UBF8T346G9`; Company Portal (macOS)
is added/assigned.
**Fail:** Missing profile, wrong type (Credential/Platform SSO instead of Redirect), or missing
Company Portal → resolve before piloting.

## Test 2 — Profile assignment
**Procedure:** Run `MACSSOEXT-Validation.ps1` (or check **Devices → Configuration → (profile) →
Assignments**).
**Pass:** The profile is assigned to the intended **pilot group** and to no unintended broad group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct the assignment (Implement
Step 7 / `MACSSOEXT-Set-ScopeTargeting.ps1`).

## Test 3 — Profile applied on the device
**Procedure:** On the pilot Mac, **System Settings → General → Device Management** (or Intune →
profile → **Device status**).
**Pass:** The **macOS SSO App Extension – Pilot** profile is installed and Intune shows **Succeeded**.
**Fail:** Not installed / error → force a sync (Company Portal → Check settings) and confirm Company
Portal is present (R3).

## Test 4 — Broker primed (first sign-in)
**Procedure:** In Safari, sign in once to `https://outlook.office.com` with the pilot user's Entra
credentials (complete MFA if prompted).
**Pass:** Interactive sign-in succeeds and completes cleanly.
**Fail:** Sign-in loops or errors → verify the Entra URLs in the profile (Step 5) and network access
to the login endpoints (R9).

## Test 5 — Silent SSO in apps and browsers
**Procedure:** Without re-entering credentials, open a **second** Entra-secured target: a native
Microsoft app (e.g. Outlook) and each supported browser (**Safari** first).
**Pass:** Sign-in is **silent** (no password prompt) using the same identity in Safari and in
MSAL/broker-aware apps.
**Fail (Safari/native):** Still prompting → verify Extension Identifier/Team ID and that the app's
bundle ID is not excluded by `AppPrefixAllowList`/`AppBlockList` (Step 6).
**Expected variance (other browsers):** Chrome/Firefox without SSO-extension support fall back to
interactive sign-in — record this as expected, not a failure (R8).

## Test 6 — App/URL scoping behaves
**Procedure:** Confirm scoping keys take effect: an app **outside** the `AppPrefixAllowList` should
not be brokered; an app inside it should be.
**Pass:** Only the intended app bundle IDs get silent SSO; URLs outside the profile's list are not
brokered.
**Fail:** Unexpected apps brokered or intended apps skipped → adjust `AppPrefixAllowList` / URL list
(Step 6) and re-sync.

## Test 7 — Coverage report
**Procedure:** Run `MACSSOEXT-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **profile applied**; counts match the assigned
group.
**Fail:** Devices missing from the report → run `MACSSOEXT-Remediation.ps1` (`-WhatIf` first) to fix
assignment/scoping.

## Test 8 — No login-window change (negative test)
**Procedure:** Log the pilot user out and back in to macOS.
**Pass:** The **macOS login experience is unchanged** — the local account password still logs in; this
solution intentionally does not touch device login.
**Fail:** If login-window behavior changed, a Platform SSO (credential) profile is also present —
confirm this solution deployed **Redirect** only (Step 5).

## Acceptance gate
Proceed to **Expand** only when Tests 1–7 pass on at least one pilot Mac, Test 8 confirms device login
is unchanged, and a real pilot user confirms silent SSO across the intended apps and Safari.


---


# 6. Troubleshooting — macOS Enterprise SSO App Extension

Work top-down: confirm the **profile is applied**, then the **broker is primed**, then **scoping**.
Most "still prompting" cases are a missing Company Portal, a mis-typed identifier, or an app outside
the allow-list. Each symptom below gives the **likely cause** and the **fix**.

> **Before you start:** verify this is the app/browser extension problem you think it is. If the
> *macOS login window* changed or the account password is involved, you are looking at **Platform
> SSO** (separate solution), not this app extension.

## Symptom: The SSO profile never appears on the Mac
**Likely cause:** Device not synced, not assigned, or restriction blocking macOS.
**Fix:**
1. Confirm the device is in the **pilot group** and the profile is **assigned** (`MACSSOEXT-Validation.ps1`).
2. Force sync: **Company Portal → (device) → Check settings**.
3. Check **Devices → Configuration → (profile) → Device status** for an error.
4. Confirm **Company Portal** is installed (R3) — the extension identifier is invalid without it.

## Symptom: Profile shows "Error" / "Conflict" in Device status
**Likely cause:** A second SSO extension profile conflicts (e.g. a Platform SSO/Credential profile
targeting the same device), or duplicate SSO app-extension profiles.
**Fix:**
1. Run `MACSSOEXT-Discovery.ps1` to list SSO extension profiles.
2. Ensure only **one** SSO **app** extension (Redirect) profile targets the device.
3. A Platform SSO (Credential) profile can coexist but must be a **separate, intentional** policy — if
   unintended, unassign it.

## Symptom: Apps/browsers still prompt for a password (no silent SSO)
**Likely cause:** Broker not primed, wrong identifiers, or app not in the allow-list.
**Fix:**
1. Complete **one interactive sign-in** in Safari to prime the broker (Implementation Step 9).
2. Verify **Extension Identifier** `com.microsoft.CompanyPortalMac.ssoextension` and **Team Identifier**
   `UBF8T346G9` exactly (Step 5).
3. Confirm the app's **bundle ID** is covered by `AppPrefixAllowList` and not in `AppBlockList` (Step 6).
4. Confirm the app authenticates against a URL in the profile's **URL list**.

## Symptom: Silent SSO works in Safari but not in Chrome/Firefox
**Likely cause:** Expected — those browsers may not support the macOS SSO extension.
**Fix:**
1. Set `browser_sso_interaction_enabled = 1` (Step 6) to enable interactive broker sign-in where
   supported.
2. Where a browser has no extension support, document the fallback and steer web SSO to **Safari**.
3. This is a browser limitation, not a profile error — set expectations with users (R8).

## Symptom: One specific app is not brokered
**Likely cause:** Bundle ID excluded by scoping, uses an embedded webview, or a non-MSAL auth stack.
**Fix:**
1. Confirm the app's bundle ID matches your `AppPrefixAllowList` prefix.
2. Add the exact bundle ID if it falls outside the prefix.
3. If the app uses a legacy embedded webview (not the broker/MSAL or Safari), silent SSO may not be
   possible — note it as a known limitation.

## Symptom: Sign-in loops or fails after the profile applies
**Likely cause:** Missing Entra URL, blocked login endpoint, or TLS inspection.
**Fix:**
1. Confirm the correct **Entra URLs** for your cloud are present (Step 5) — commercial vs US Gov vs
   21Vianet differ.
2. From the device network, reach `https://login.microsoftonline.com` (or sovereign equivalent) (R9).
3. **Exempt Microsoft login endpoints from TLS inspection** — inspection breaks token exchange.

## Symptom: Works for some users, not others
**Likely cause:** Group membership, licensing, or Company Portal not installed on those devices.
**Fix:**
1. Confirm affected users/devices are in the assigned group (`MACSSOEXT-Report.ps1`).
2. Confirm each user has a licensed Entra identity (R10) and each device has Company Portal (R3).
3. Have the affected user complete the one-time interactive sign-in to prime the broker.

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or missing Company Portal.
**Fix:**
1. Run `MACSSOEXT-Report.ps1` to list which devices lack the applied profile.
2. Run `MACSSOEXT-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (R1) and Company Portal (R3).

## Escalation checklist
Before opening a Microsoft support case, collect: the `MACSSOEXT-Discovery.ps1` output, the profile's
Device status export, the exact Extension/Team identifiers and URL list, the affected app bundle IDs,
macOS version, and whether Safari brokers silently (isolates the extension from browser-specific
issues).


---


# 7. Best Practices — macOS Enterprise SSO App Extension (App/URL Scoping)

These practices keep the app/browser SSO extension precise, predictable, and reversible. They assume
the deployment model in the Solution Overview: a **redirect-type** Extensible SSO app extension for
apps and browsers, deployed via Intune, pilot-first.

## Keep it distinct from Platform SSO
- **One profile, one purpose.** Use a **Redirect** SSO app-extension profile for apps/browsers, and —
  if you also want device login — a **separate** Platform SSO (Credential) profile from the companion
  solution. Do not merge the two intents into one policy; mixing them makes troubleshooting and
  rollback harder.
- **Name for clarity.** Name the profile so its scope is obvious, e.g. **macOS SSO App Extension –
  <ring>**, never a generic "SSO" that could be confused with device login.

## Scope apps deliberately (bundle IDs)
- **Start allow-listed, not open.** Set `AppPrefixAllowList` to the prefixes you actually support
  (for example `com.microsoft.,com.apple.`) rather than leaving it empty/broad. Widen only after the
  pilot proves stable.
- **Prefer prefixes over long ID lists.** A prefix like `com.microsoft.` covers the Office suite and
  Teams without enumerating every bundle ID; add specific IDs only for outliers.
- **Record every bundle ID you add.** Keep a short table (app → bundle ID → why included) so the next
  admin understands the scope. Verify IDs from the vendor or `osascript -e 'id of app "AppName"'`.
- **Use `AppBlockList` for exceptions,** not as the primary control — block only apps that
  misbehave with the broker.

## Scope URLs to the right cloud
- **Only your cloud's Entra URLs.** Commercial uses `login.microsoftonline.com` /
  `login.microsoft.com` / `sts.windows.net` / `login.windows.net`. US Gov uses
  `login.microsoftonline.us`; 21Vianet uses `login.partner.microsoftonline.cn`. Do **not** add clouds
  you don't use — extra URLs widen the interception surface for no benefit.
- **Add app-specific auth URLs as discovered.** If a legitimate app authenticates against an Entra URL
  not in the list, add it during the pilot and re-validate — don't wildcard.

## Set browser expectations
- **Safari is the reliable path.** WebKit/Safari flows broker natively. Standardize on Safari for
  brokered web SSO where you can.
- **Enable `browser_sso_interaction_enabled = 1`** so supporting browsers can complete interactive
  broker sign-in; document that non-supporting browsers (some Chrome/Firefox builds) fall back to
  normal sign-in — set that expectation with users up front to avoid tickets.

## Deploy pilot-first and reversibly
- **Assign to a pilot group, never "All devices" first.** Expand in waves after each gate passes.
- **Rollback is unassignment.** Because this only adds a system extension profile, removing the
  assignment cleanly reverts behavior to pre-SSO — no account or login-window cleanup needed. Keep the
  profile so you can re-target quickly.
- **Prime once, then measure.** Expect one interactive sign-in per user to seed the broker; measure
  silent SSO from the *second* sign-in onward.

## Operate and monitor
- **Report before you widen.** Run `MACSSOEXT-Report.ps1` each wave; only broaden when coverage
  matches the assigned group.
- **Remediate with `-WhatIf` first.** `MACSSOEXT-Remediation.ps1` and `MACSSOEXT-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply.
- **Keep Company Portal current.** The extension binary ships in Company Portal; keep it assigned
  **Required** and updated so the extension identifier stays valid.
- **Don't TLS-inspect Microsoft login endpoints** — it breaks the broker token exchange.

## Change control
- **Version scope changes.** When you add bundle IDs/URLs, note the date and reason; re-run Discovery
  and Report to confirm no regressions.
- **Review after macOS major upgrades.** Confirm the extension still applies and silent SSO holds
  after significant macOS releases before expanding further.


---


# 8. Deliverables Summary — macOS Enterprise SSO App Extension

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: the
  app/browser SSO extension, not Platform SSO device login.
- **Solution Overview** — how Apple's Extensible SSO (redirect vs credential types) and the Microsoft
  Enterprise SSO plug-in work for **apps and browsers**, how silent SSO is achieved, and how this
  differs from Platform SSO device login.
- **Requirements Guide** — every Intune/Entra/macOS prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: prepare the
  device (Company Portal), create the redirect SSO app-extension profile with app/URL scoping, pilot,
  then validate and expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates (including a negative test that
  device login is unchanged) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for "still prompting," scoping, browser, and conflict
  cases.
- **Best Practices** — app/URL scoping discipline, keeping the app extension distinct from Platform
  SSO, browser expectations, and reversible pilot-first rollout.

## PowerShell scripts (Microsoft Graph) — `MACSSOEXT-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`MACSSOEXT-Discovery.ps1`** — tenant readiness: the SSO **app** extension (Redirect) profile is
   present with the correct Microsoft Enterprise SSO Extension/Team identifiers, and Company Portal
   (macOS) is added/assigned.
2. **`MACSSOEXT-Validation.ps1`** — validates the profile's **assignment** and per-device **applied**
   state, with a clear PASS/FAIL summary.
3. **`MACSSOEXT-Report.ps1`** — tenant-wide CSV report of macOS devices and whether the SSO
   app-extension profile is applied — the SSO coverage report.
4. **`MACSSOEXT-Remediation.ps1`** — safe remediation of missing/mis-scoped profiles (re-assign to a
   target group, flag conflicts). **`-WhatIf` by default**; applies only when re-run to commit.
5. **`MACSSOEXT-Set-ScopeTargeting.ps1`** — sets/adjusts the profile's group assignment (target-group
   builder). **`-WhatIf` by default.**

## Hero image
- **`MACSSOEXT-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited
devices**.
