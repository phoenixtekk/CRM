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
