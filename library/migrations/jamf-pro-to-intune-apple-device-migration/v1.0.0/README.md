# Jamf Pro to Microsoft Intune Migration for Apple Devices — macOS, iPadOS & iOS/iPhone

- **Category:** Migrations · **Code:** JAMFMIG · **Version:** 1.0.0 · **Status:** generated · **Branding:** off

## Pricing (new model, T5 program tier)
| Audience | SKU | Price |
|---|---|---|
| Commercial | PTK-JAMFMIG-COMM-001 | $1,499.00 |
| Non-Profit | PTK-JAMFMIG-NPO-001 | $899.40 |
| Government | PTK-JAMFMIG-GOV-001 | $1,274.15 |

## What it solves
Migrates an Apple fleet (macOS, iPadOS, iOS/iPhone) off Jamf Pro onto Microsoft Intune in validated
waves. Handles the real mechanics: one-MDM-per-device, ABM re-assignment, supervised wipe-and-re-enroll
vs BYOD unenroll/re-enroll, VPP license hand-off, FileVault re-escrow, SSO + profile rebuild, cert
re-issue, decommission Jamf.

## Included
- Docs: 01 Overview · 02 Requirements (+ migrations global) · 03 Implementation (Phase 1–5, per platform)
  · 05 Testing · 06 Troubleshooting · 07 Best Practices · 08 Deliverables · Executive Summary.
- 5 scripts: Export-JamfInventory (Jamf API), Get-IntuneReadiness, Get-ABMAssignments,
  Validate-Migration, Track-Waves.

## Scope note
Mechanism identical in Commercial and GCC High/DoD (portal intune.microsoft.us) — no Government variant.

## Next
`/publish-solution jamf-pro-to-intune-apple-device-migration`
