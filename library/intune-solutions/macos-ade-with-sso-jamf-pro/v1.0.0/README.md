# macOS Automated Device Enrollment with SSO (Jamf Pro + Intune) — v1.0.0

**Category:** Intune Solutions · **Solution code:** JAMFADE · **Version:** 1.0.0 · **Status:** generated

A standalone solution that documents the **Jamf Pro–managed** macOS architecture: ADE enrolls Macs
into **Jamf Pro** (the MDM), Jamf deploys **Platform SSO** (Microsoft Enterprise SSO, Secure Enclave),
and the **Jamf ↔ Intune Device Compliance** integration registers the Macs in **Entra ID** and reports
compliance so **Conditional Access enforces SSO**.

> **Relationship to `macos-ade-with-sso`:** this is a **separate product**, not a version of it. The
> two have similar titles but different architectures (Intune-as-MDM vs. Jamf-as-MDM), so per the
> solution-identity rule they are distinct solutions with distinct slugs and SKUs.

> **Shaping notes:** *"This solution much support with Jamf Pro Integration for MacOS device
> management."*

## Pricing
| Audience | SKU | Price |
|---|---|---|
| Commercial | PTK-JAMFADE-COMM-001 | $1,995.00 |
| Non-Profit | PTK-JAMFADE-NPO-001 | $1,197.00 (40% off) |

## What's included
- **Docs:** Executive Summary, Solution Overview, Requirements (+ category Global Requirements),
  Implementation (5 phases), Testing (10 tests), Troubleshooting, Best Practices, Deliverables Summary.
- **5 PowerShell scripts:**
  - `JAMFADE-Discovery.ps1` (Graph) — Intune/Entra readiness (Jamf partner active, compliance + CA policy, Company Portal).
  - `JAMFADE-Validation.ps1` (Graph) — one Mac: Entra-registered + partner-managed + compliant.
  - `JAMFADE-DeviceReport.ps1` (Graph) — tenant-wide macOS CSV (registration, compliance, partner).
  - `JAMFADE-JamfReadiness.ps1` (Jamf Pro API) — ADE instance/token, PreStage, SSO profile, APNs advisory.
  - `JAMFADE-Set-JamfSSOProfile.ps1` (Jamf Classic API) — build & scope the Platform SSO profile in Jamf.
- **Hero image:** `JAMFADE-hero.png` (1200×1200).

## Next
Review in `library/_index/INDEX.html`, then run `/publish-solution macos-ade-with-sso-jamf-pro`.
