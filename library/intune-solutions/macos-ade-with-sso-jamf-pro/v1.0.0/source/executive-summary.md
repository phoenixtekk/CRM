# Executive Summary — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Apple **Automated Device Enrollment (ADE)** turns every company-owned Mac into a zero-touch,
supervised, fully managed device the moment it is powered on — no imaging, no manual MDM steps, no
local-admin hand-holding. This solution manages those Macs with **Jamf Pro**, the dedicated
macOS management platform, and connects them to **Microsoft Entra ID** so sign-in is enforced with
corporate identity and Conditional Access.

Most organizations that already run Jamf for their Mac fleet still need their Macs to be
**first-class citizens in Microsoft Entra**: registered, compliant, and gated by the same
Conditional Access policies as their Windows estate. This solution delivers exactly that, as a
single, repeatable deployment a Mac admin can follow end to end:

- **Zero-touch provisioning with Jamf.** Macs in **Apple Business Manager** are assigned to a Jamf
  Pro **Automated Device Enrollment** instance and a **PreStage Enrollment**, so they enroll
  supervised, branded, and pre-loaded the first time they run Setup Assistant.
- **Platform SSO with the Microsoft Enterprise SSO plug-in.** Jamf deploys the Single Sign-On
  Extension configuration profile. Users sign in to macOS and to Microsoft 365 with their **Entra
  ID** identity, backed by a hardware-bound **Secure Enclave** key — phishing-resistant, not a synced
  password.
- **Compliance flows Jamf → Intune.** The **Jamf Pro ↔ Intune Device Compliance** integration
  registers each Mac in Entra and reports its Jamf compliance state to Intune, so Macs appear in
  **Intune → Devices** as partner-managed and compliant.
- **SSO enforced by Conditional Access.** Entra **Conditional Access** requires a compliant,
  registered Mac (and, optionally, a phishing-resistant authentication strength) before granting
  access to Microsoft 365 — turning Platform SSO from "available" into **mandatory**.

The package follows the standard Phoenixtekk shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click steps across both consoles, a requirements guide that tells you
how to verify *and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph and
the Jamf Pro API), and testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** company Macs that Jamf provisions and manages, that authenticate with corporate identity
via a phishing-resistant Secure Enclave key, and that Entra Conditional Access treats as compliant,
registered, SSO-enforced devices — delivered by your own team, in a controlled pilot, without a
consulting engagement.
