# 1. Solution Overview — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

## What this solution is
This solution stands up company-owned Macs that **Jamf Pro manages** and **Microsoft Entra enforces**.
It combines three capabilities into one repeatable deployment:

1. **Automated Device Enrollment (ADE)** — Apple's zero-touch enrollment program (formerly DEP).
   Company-owned Macs that belong to your **Apple Business Manager (ABM)** organization are assigned
   to **Jamf Pro** as their MDM and enroll automatically — **supervised** — the first time they run
   Setup Assistant. Management is mandatory and locked to the device.
2. **Platform Single Sign-On (Platform SSO)** — Apple's macOS framework that lets a third-party
   identity provider extend sign-in to the Mac itself. **Jamf deploys** the **Microsoft Enterprise
   SSO** extension via a configuration profile, so the Mac registers with **Microsoft Entra ID** and
   users authenticate with their corporate identity at the login window and across apps and
   Safari/Edge/Chrome.
3. **Jamf Pro ↔ Microsoft Intune Device Compliance** — the supported integration that registers each
   Jamf-managed Mac in **Entra ID** and reports its **compliance** state to **Intune**. Combined with
   Entra **Conditional Access**, this is what makes SSO **enforced**: only a compliant, registered Mac
   is allowed into Microsoft 365.

Together they give you a Mac that Jamf provisions and manages, that signs in with corporate identity,
and that Conditional Access treats as a trusted, compliant device.

## Why Jamf as the MDM (and Intune for identity & compliance)
A macOS device can have **only one MDM authority**. Organizations that have standardized on **Jamf
Pro** for deep, Mac-native management (PreStage, policies, patch, Self Service) keep Jamf as the MDM
— you do **not** move those Macs into Intune. Instead, you connect Jamf to the Microsoft cloud so the
Macs become **Entra-registered and Intune-compliant**, and you enforce access with the **same
Conditional Access** policies that protect the rest of your estate. Intune is the **identity and
compliance authority**; Jamf is the **device management authority**. This is the only architecture in
which "Jamf Pro device management" and "SSO enforced via Intune/Entra" coexist correctly.

## How it works
1. **ABM → Jamf Pro.** You connect ABM to Jamf Pro with an **Automated Device Enrollment** instance
   (an ADE/MDM-server token). Macs assigned to the Jamf MDM server in ABM enroll into Jamf.
2. **PreStage Enrollment.** A **PreStage Enrollment** in Jamf defines the out-of-box experience:
   supervised mode, account creation, which Setup Assistant panes to skip, and which apps/profiles
   pre-load.
3. **Power on → enroll.** When a user (or technician) powers on the Mac and connects to a network,
   Setup Assistant contacts Apple, discovers the Jamf MDM server, and enrolls automatically. The
   device becomes supervised and managed by Jamf; your apps and profiles flow down.
4. **Platform SSO registration.** Jamf deploys a **Single Sign-On Extension** configuration profile
   (Microsoft Enterprise SSO) and the **Company Portal** app. On first sign-in, Company Portal
   completes Platform SSO **registration**: the Mac generates a hardware-bound key in the **Secure
   Enclave** and registers with Entra ID.
5. **Compliance to Intune.** Through the **Jamf Pro ↔ Intune Device Compliance** connector, Jamf
   sends the Mac's inventory and compliance state to Intune; the Mac appears in **Intune → Devices**
   as a partner-managed, compliant device.
6. **SSO enforced.** Entra **Conditional Access** requires a **compliant** (and optionally
   phishing-resistant) Mac before granting Microsoft 365 access. Platform SSO supplies the credential;
   Conditional Access makes it mandatory.

## Platform SSO authentication methods (choose one)
- **Secure Enclave key (recommended)** — a hardware-bound key in the Mac's Secure Enclave signs
  authentication. Phishing-resistant; the local password is decoupled from Entra. Best security.
- **Password sync** — the user's local macOS password is kept in sync with their Entra password.
  Simplest for users; least hardened.
- **Smart card** — authentication via a smart card/certificate. For high-assurance environments.

This solution standardizes on the **Secure Enclave key** method, with notes for the alternatives.

## Benefits
- **Zero-touch deployment** — Macs enroll supervised into Jamf on first boot; no imaging, no manual MDM steps.
- **Keep your Jamf investment** — full Mac-native management (PreStage, policies, patch, Self Service) stays in Jamf.
- **Corporate identity on the Mac** — Entra sign-in at the login window and across apps/browsers.
- **Phishing-resistant** — Secure Enclave key, hardware-bound, never leaves the device.
- **Compliance in Intune** — Macs appear as partner-managed, compliant devices alongside Windows.
- **SSO enforced** — Conditional Access blocks non-compliant or non-registered Macs from Microsoft 365.

## Limitations (be honest with buyers)
- A Mac has **one MDM**. In this design **Jamf is the MDM**; the Macs are **not** Intune-MDM-managed.
  Conditional Access works via the **partner compliance** integration, not Intune-native MDM.
- ADE requires devices to be in **Apple Business Manager** (purchased via Apple/an authorized
  reseller, or added with **Apple Configurator** — the latter adds a provisional 30-day release period).
- Platform SSO requires **macOS 13 Ventura or later** (macOS 14 Sonoma+ strongly recommended).
- Requires Jamf's **APNs (MDM Push) certificate** and the **ADE/ABM token**, both renewed annually —
  hard expiry dates that block enrollment if missed.
- Platform SSO registration and compliance reporting depend on the **Company Portal** app and the
  **Microsoft Enterprise SSO** extension being present and current.
- Microsoft and Jamf have **evolved** the integration over time (the legacy "Conditional Access"
  connector was superseded by **Device Compliance**). Always confirm the **current** integration name
  and steps in the Jamf and Microsoft documentation before connecting.
- Personally-owned (BYO) Macs use a different (user-enrollment) path and are out of scope here.

## The standard Phoenixtekk deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Company-owned, Apple Business Manager–sourced Macs, automatically enrolled into Jamf Pro
> (supervised), registered with Microsoft Entra ID and reporting compliance to Intune via the Jamf ↔
> Intune Device Compliance integration, with Platform SSO via the Microsoft Enterprise SSO extension
> and a Secure Enclave key, and SSO enforced by Entra Conditional Access.**

Every step follows the Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**
