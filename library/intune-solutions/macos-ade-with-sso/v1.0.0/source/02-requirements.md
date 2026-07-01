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
