# 1. Solution Overview — macOS Automated Device Enrollment with SSO

## What this solution is
This solution combines two Apple + Microsoft capabilities into one repeatable deployment:

1. **Automated Device Enrollment (ADE)** — Apple's zero-touch enrollment program (formerly DEP).
   Company-owned Macs that belong to your **Apple Business Manager (ABM)** organization are
   automatically enrolled into **Microsoft Intune**, **supervised**, the first time they run Setup
   Assistant. Management is mandatory and locked to the device.
2. **Platform Single Sign-On (Platform SSO)** — Apple's macOS framework that lets a third-party
   identity provider extend sign-in to the Mac itself. With the **Microsoft Enterprise SSO**
   extension, the Mac registers with **Microsoft Entra ID** and users authenticate with their
   corporate identity at the login window and across apps and Safari/Edge/Chrome.

Together they give you a Mac that provisions itself and signs in with corporate identity — managed,
supervised, and Conditional-Access ready.

## How it works
1. **Apple Business Manager → Intune.** You connect ABM to Intune with an **Automated Device
   Enrollment token** (a server token). Macs assigned to the Intune MDM server in ABM appear in
   Intune as ADE devices.
2. **Enrollment profile.** An **enrollment program profile** in Intune defines the out-of-box
   experience: supervised mode, user affinity, which Setup Assistant screens to skip, and whether
   management is locked.
3. **Power on → enroll.** When a user (or technician) powers on the Mac and connects to a network,
   Setup Assistant contacts Apple, discovers the Intune MDM server, and enrolls automatically. The
   device becomes supervised and managed; your apps and policies flow down.
4. **Platform SSO registration.** A configuration profile deploys the **Microsoft Enterprise SSO**
   extension. On first sign-in, the **Company Portal** app completes Platform SSO **registration**:
   the Mac generates a hardware-bound key in the **Secure Enclave** and registers it with Entra ID.
5. **Single sign-on.** From then on, the user's macOS sign-in is tied to their Entra identity, and
   apps/browsers that support the Microsoft identity broker get silent SSO — no repeated passwords.

## Platform SSO authentication methods (choose one)
- **Secure Enclave key (recommended)** — a hardware-bound key in the Mac's Secure Enclave signs
  authentication. Phishing-resistant; the local password is decoupled from Entra. Best security.
- **Password sync** — the user's local macOS password is kept in sync with their Entra password.
  Simplest for users; least hardened.
- **Smart card** — authentication via a smart card/certificate. For high-assurance environments.

This solution standardizes on the **Secure Enclave key** method, with notes for the alternatives.

## Benefits
- **Zero-touch deployment** — Macs enroll supervised on first boot; no imaging, no manual MDM steps.
- **Corporate identity on the Mac** — Entra sign-in at the login window and across apps/browsers.
- **Phishing-resistant** — Secure Enclave key, hardware-bound, never leaves the device.
- **Supervised management** — stronger controls, app management, and wipe protection.
- **Conditional Access** — enrolled, compliant, Entra-registered Macs fit your Zero Trust model.
- **Better experience** — users sign in once with the identity they already know.

## Limitations (be honest with buyers)
- ADE requires devices to be in **Apple Business Manager** (purchased via Apple/authorized reseller,
  or added manually with **Apple Configurator** — the latter adds a provisional 30-day release period).
- Platform SSO requires **macOS 13 Ventura or later** (macOS 14 Sonoma+ strongly recommended for the
  best registration and Secure Enclave experience).
- Requires an **Apple Push Notification service (APNs) certificate**, renewed annually, and an
  **ADE/ABM token**, renewed annually — both are hard expiry dates that block enrollment if missed.
- Platform SSO registration depends on the **Company Portal** app and the **Microsoft Enterprise
  SSO** extension being present and current.
- Personally-owned (BYO) Macs use a different (user-enrollment) path and are out of scope here.

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Company-owned, Apple Business Manager–sourced Macs, automatically enrolled into Intune
> (supervised), with Platform SSO via the Microsoft Enterprise SSO extension and a Secure Enclave key.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
