# Sales Content — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

## Hook
**Keep Jamf as your Mac MDM — and make every Mac Entra-registered, Intune-compliant, and SSO-enforced.**

A Mac can only have one MDM, and yours is Jamf Pro. But Jamf-only Macs are invisible to Microsoft
Entra: not registered, not compliant, not gated by Conditional Access. This solution closes that gap.
Apple Automated Device Enrollment enrolls a company Mac into Jamf the moment it powers on —
supervised, managed, branded — Platform SSO (deployed by Jamf) ties macOS sign-in to Microsoft Entra
ID with a hardware-bound Secure Enclave key, and the Jamf ↔ Intune Device Compliance integration makes
each Mac a compliant device that Conditional Access enforces.

## Run it yourself — simpler, cheaper, and proven
You do **not** need a consultant. This is the exact, field-tested method as self-guided,
click-by-click documentation a Mac admin can follow from Apple Business Manager through Jamf PreStage
and Platform SSO to a registered, compliant, SSO-enforced Mac — plus tested PowerShell for both
Microsoft Graph and the Jamf Pro API.

- **Simpler** — exact ABM + Jamf + Intune + Entra navigation in the right order; click to implement.
- **Cheaper** — one fixed price vs. an open meter; comparable consulting runs **$1,500–$3,000/day**.
- **Tested** — Assess → Configure → Pilot → Validate → Expand, with 10 validation tests and pass/fail gates.

## What's inside
- Solution Overview, Requirements (verify + implement-if-missing), Implementation (5 phases),
  Testing, Troubleshooting, Best Practices.
- 5 PowerShell scripts: Intune/Entra readiness (Graph), device validation, macOS fleet report,
  Jamf-side readiness (Jamf Pro API: ADE/token, PreStage, SSO profile), and a one-shot Jamf Platform
  SSO profile builder.

## The Phoenixtekk way
Buy once, deploy to unlimited devices, reuse the playbook. Every solution follows the same repeatable
shape so each rollout is familiar and low-risk.

## Bottom line
Macs that Jamf provisions and manages on first boot, authenticate with Entra identity via a
phishing-resistant Secure Enclave key, and report compliant to Intune so Conditional Access enforces
SSO — deployed by one administrator in a controlled pilot within a day.

## Pricing
- **Commercial:** $1,995
- **Non-Profit:** $1,197 (40% off; eligibility verification required)
