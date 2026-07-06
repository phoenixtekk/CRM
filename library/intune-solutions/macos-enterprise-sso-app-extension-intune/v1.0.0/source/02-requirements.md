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
