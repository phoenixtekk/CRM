# 8. Deliverables Summary — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — what ADE, Platform SSO, and the Jamf ↔ Intune Device Compliance integration
  are, how they work together, why Jamf is the MDM and Intune the identity/compliance authority, the
  authentication methods, benefits, and honest limitations.
- **Requirements Guide** — every Apple/Jamf/Intune prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across five phases: connect Apple to
  Jamf, assign devices & define the PreStage, deploy Company Portal + Platform SSO via Jamf, connect
  Jamf to Intune and create the Conditional Access policy, then pilot/validate/expand.
- **Testing & Validation** — ten tests with explicit pass/fail gates and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for enrollment, Platform SSO, compliance, and Conditional
  Access failures.
- **Best Practices** — architecture/ownership, identity, enrollment hygiene, the all-important
  token/certificate lifecycle, OS/updates, rollout discipline, and security posture.

## PowerShell scripts — `JAMFADE-Scripts.zip`
Each script has a header explaining **Purpose · How to run · Expected results**. Three use the
**Microsoft Graph** PowerShell SDK (Intune/Entra side); two call the **Jamf Pro API** (MDM side).

1. **`JAMFADE-Discovery.ps1`** (Graph) — Intune/Entra readiness: the **Jamf device-compliance partner**
   is **Active** for macOS, a macOS **compliance policy** exists, a **Conditional Access** policy
   targets macOS, and the macOS **Company Portal** is available. Flags gaps.
2. **`JAMFADE-Validation.ps1`** (Graph) — validates a specific Mac: **Entra-registered**, reported by
   the Jamf partner, and **compliant** in Intune — with a clear PASS/FAIL summary.
3. **`JAMFADE-DeviceReport.ps1`** (Graph) — tenant-wide CSV report of macOS devices: registration,
   ownership, compliance state, and partner-managed (Jamf) status.
4. **`JAMFADE-JamfReadiness.ps1`** (Jamf Pro API) — Jamf-side readiness: APNs status/expiry, the
   **Automated Device Enrollment** instance/token expiry, macOS **PreStage** presence, and the
   **Single Sign-On Extensions** (Platform SSO) profile presence. Flags anything within 30 days of
   expiry.
5. **`JAMFADE-Set-JamfSSOProfile.ps1`** (Jamf Pro Classic API) — uploads and scopes the macOS Platform
   SSO (Single Sign-On Extensions) configuration profile with the correct Microsoft Enterprise SSO
   identifiers, URLs, and Secure Enclave method.

## Hero image
- **`JAMFADE-hero.png`** — the branded product image (1200×1200) used on the marketplace listing.

## How it's delivered
A branded **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts
appendix), plus all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across
**unlimited devices**.
