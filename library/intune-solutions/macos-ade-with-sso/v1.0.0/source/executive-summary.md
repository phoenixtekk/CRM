# Executive Summary — macOS Automated Device Enrollment with SSO

Apple **Automated Device Enrollment (ADE)** turns every company-owned Mac into a zero-touch,
supervised, fully managed device the moment it is powered on — no manual setup, no local admin
hand-holding, no imaging. Paired with **Platform Single Sign-On (Platform SSO)** and the
**Microsoft Enterprise SSO** plug-in, your users sign in to their Mac with their **Microsoft Entra
ID** credentials and carry that identity, seamlessly and securely, into every app and browser.

This solution delivers the complete, field-tested method to stand this up in **Microsoft Intune** —
written so a single administrator can follow it end to end:

- **Zero-touch provisioning.** Macs bought through Apple Business Manager (or added with Apple
  Configurator) enroll automatically, supervised, with your branding and your apps, straight out of
  the box.
- **Entra-backed sign-in.** Platform SSO registers the Mac with Microsoft Entra ID and lets users
  unlock the device and authenticate to Microsoft 365 and SSO-enabled apps using their corporate
  identity — with a hardware-bound **Secure Enclave** key, not a synced password.
- **Conditional Access ready.** Enrolled, compliant, Entra-registered Macs become first-class
  citizens in your Zero Trust model.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click Intune steps, a requirements guide that tells you how to
verify *and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and
testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** company Macs that deploy themselves, authenticate with corporate identity, and meet
compliance — delivered by your own team, in a controlled pilot, without a consulting engagement.
