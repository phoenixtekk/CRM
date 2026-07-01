# 2. Requirements — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (Entra tenant, Intune licensing, admin roles, pilot group, network) are covered once in
the **Global Requirements — Intune Solutions** document; the items here are specific to Jamf-managed
Apple ADE, Platform SSO, and the Jamf ↔ Intune Device Compliance integration.

## R1. Apple Business Manager (or Apple School Manager) account
**Description:** A verified Apple Business Manager (ABM) organization.
**Why:** ADE only works for devices that belong to your ABM organization; ABM is also where you
assign devices to the **Jamf Pro** MDM server and accept device-management terms.
**Verify:** Sign in to `https://business.apple.com` with an ABM Administrator account; the
organization status is **active**.
**Implement:** Enroll at `https://business.apple.com/enroll` using your **D-U-N-S** number; complete
Apple's verification. Allow 1–5 business days.

## R2. Jamf Pro tenant with administrative access
**Description:** A licensed **Jamf Pro** instance (cloud or on-prem) and an admin account with rights
to manage enrollment, configuration profiles, and integrations.
**Why:** Jamf Pro is the **MDM authority** in this design — it enrolls, supervises, and manages the
Macs and deploys the SSO profile and Company Portal.
**Verify:** Sign in to your Jamf Pro console (e.g. `https://yourorg.jamfcloud.com`) as an
administrator; **Settings** is accessible.
**Implement:** Provision Jamf Pro (Jamf Cloud is fastest) and assign an administrator role with
**Settings**, **Enrollment**, and **Configuration Profiles** privileges.

## R3. Jamf Pro Apple Push Notification service (APNs) certificate
**Description:** A valid MDM Push certificate connecting **Jamf Pro** to Apple's push service.
**Why:** Every Apple device managed by Jamf requires APNs; without it, no Mac can enroll or receive
commands. (This certificate lives in **Jamf**, not Intune.)
**Verify:** Jamf Pro → **Settings → Global → Push certificates** (or **Global Management → Push
Certificates**) shows a valid Apple **MDM Push** certificate with a future expiration.
**Implement:** In Jamf Pro, create a Push Certificate request, sign in to
`https://identity.apple.com` with a **company Apple ID** (not personal), upload the signed
certificate. **Renew annually with the same Apple ID** — a new Apple ID re-issues the cert and
unenrolls all devices.

## R4. Automated Device Enrollment instance in Jamf Pro (ABM ↔ Jamf token)
**Description:** An ABM **MDM server** that points to Jamf, with its server token (`.p7m`) uploaded
into Jamf Pro as an **Automated Device Enrollment** instance.
**Why:** This is the trust link that lets ABM-assigned devices enroll into your Jamf tenant.
**Verify:** Jamf Pro → **Settings → Global → Automated Device Enrollment**; an instance is listed
with a future token expiration.
**Implement:** In Jamf Pro, download the **public key**; in ABM **Preferences → MDM Servers**, create
an MDM server named clearly (e.g. **Jamf – Production**), upload the public key, download the server
token; upload that token into Jamf's Automated Device Enrollment settings. **Renew annually.**

## R5. Devices present in Apple Business Manager and assigned to Jamf
**Description:** The target Macs appear in ABM and are assigned to the **Jamf** MDM server.
**Why:** Only ABM devices can use ADE, and assignment tells Apple which MDM a device should enroll
into during Setup Assistant.
**Verify:** ABM → **Devices** → select the device → **MDM Server** shows your **Jamf** server.
**Implement:** Purchase through Apple or an **Apple-authorized reseller** linked to your ABM (devices
appear automatically), or add existing Macs with **Apple Configurator** (note: Configurator-added
devices get a **30-day provisional period**). Then ABM → **Devices** → **Edit MDM Server** → choose
the **Jamf** server, and in Jamf **refresh** the ADE instance.

## R6. Jamf PreStage Enrollment for macOS
**Description:** A macOS **PreStage Enrollment** in Jamf that defines the zero-touch experience.
**Why:** The PreStage controls supervision, account creation, the Setup Assistant panes shown/hidden,
and which configuration profiles and apps deploy at enrollment.
**Verify:** Jamf Pro → **Computers → PreStage Enrollments**; a macOS PreStage exists and has devices
scoped to it.
**Implement:** Create a PreStage (Implementation Guide §Phase 2), enable **Supervision** and **Make
MDM Profile Mandatory**, set account creation, and scope the target serial numbers.

## R7. Supported macOS version
**Description:** macOS **13 Ventura or later** (macOS **14 Sonoma+ recommended**).
**Why:** Platform SSO and the Secure Enclave authentication method require macOS 13+; later releases
materially improve registration reliability.
**Verify:** Apple menu → **About This Mac**, or Jamf → device **Inventory → Operating System**.
**Implement:** Upgrade via **System Settings → General → Software Update**, or enforce a minimum OS
with a Jamf **Smart Group** + policy and a matching Intune **compliance** rule.

## R8. Company Portal app for macOS (deployed by Jamf)
**Description:** The Microsoft **Company Portal** application installed on the Mac by **Jamf**.
**Why:** Company Portal performs the Platform SSO **registration** with Entra ID **and** the device
registration that the Jamf ↔ Intune compliance integration depends on.
**Verify:** Jamf Pro → **Computers → Configuration Profiles / Apps**; Company Portal is scoped to your
pilot group and installs post-enrollment.
**Implement:** Add the macOS Company Portal as a Jamf **package/app** (or via the App Installers /
VPP) and scope it to the pilot Smart Group as **Required**.

## R9. Microsoft Enterprise SSO extension profile (deployed by Jamf)
**Description:** The **Microsoft Enterprise SSO** plug-in delivered via a Jamf macOS **Single Sign-On
Extensions** configuration profile (Platform SSO).
**Why:** This Apple-approved redirect extension brokers Entra authentication for Platform SSO and
app/browser single sign-on.
**Verify:** Jamf Pro → **Computers → Configuration Profiles**; a profile with a **Single Sign-On
Extensions** payload (Platform SSO) exists targeting your pilot group.
**Implement:** Create it during deployment (Implementation Guide §Phase 3), or run the included
`JAMFADE-Set-JamfSSOProfile.ps1` to upload it via the Jamf Pro Classic API.

## R10. Jamf Pro ↔ Microsoft Intune Device Compliance integration
**Description:** The supported connector that registers Jamf-managed Macs in **Entra ID** and reports
their **compliance** to **Intune**.
**Why:** This is what makes the Macs appear as compliant in Intune and lets **Conditional Access**
enforce SSO/compliance — without it, Jamf-managed Macs are invisible to Entra/Intune policy.
**Verify:** Intune admin center → **Tenant administration → Connectors and tokens → Partner device
management** (or **Partner compliance management**) shows **Jamf** as **Active**; in Jamf, **Settings
→ Global → Device Compliance** (macOS) is **connected**.
**Implement:** In Intune, enable the **Partner device management / compliance** connection for Jamf;
in Jamf, **Settings → Global → Device Compliance → macOS → Configure**, sign in with a Global
Administrator to grant the cloud-connector app consent, and complete the connection. Confirm the exact
current path in Jamf and Microsoft docs (the integration was renamed from the legacy "Conditional
Access").

## R11. Entra ID Conditional Access policy for macOS
**Description:** A Conditional Access policy that requires a **compliant** (and optionally
phishing-resistant) Mac for Microsoft 365.
**Why:** This converts Platform SSO from "available" to **enforced** — non-compliant or
non-registered Macs are blocked.
**Verify:** Entra → **Protection → Conditional Access**; a policy targets **macOS** and requires
**Require device to be marked as compliant** (start in **report-only**).
**Implement:** Create the policy in Implementation Guide §Phase 4; pilot in **report-only**, then
enable.

## R12. Network access to Apple, Jamf, and Microsoft endpoints
**Description:** Outbound HTTPS to Apple's enrollment/push/software endpoints, your Jamf Pro host, and
Microsoft Entra/Intune endpoints.
**Why:** Setup Assistant, ADE discovery, APNs, Jamf check-in, Entra registration, and compliance
reporting all depend on these endpoints.
**Verify:** From the device network, reach `https://mdmenrollment.apple.com`, `https://gdmf.apple.com`,
the Apple push range `*.push.apple.com` (TCP 443 and 5223), your `*.jamfcloud.com` host, and
`https://login.microsoftonline.com`.
**Implement:** Allow Apple's published ranges (Apple support article HT210060), your Jamf Cloud host,
and Microsoft's Entra/Intune ranges through proxy/firewall. Do **not** TLS-inspect Apple
push/enrollment.
