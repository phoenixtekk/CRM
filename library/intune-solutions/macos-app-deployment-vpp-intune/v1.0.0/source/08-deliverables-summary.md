# 8. Deliverables Summary — macOS App Deployment & Apple VPP with Microsoft Intune

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — the macOS app-delivery model in Intune (VPP location tokens, device- vs.
  user-licensing, App Store vs. LOB/DMG/unmanaged PKG), how it works, benefits, and honest limits.
- **Requirements Guide** — every Apple/Intune prerequisite (ABM, a VPP location with acquired
  licenses, the VPP token, managed Macs, the pilot group, signed packages) with how to **verify** and
  how to **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: acquire licenses
  and connect VPP, add and assign the App Store (VPP) app, add and assign the enterprise (LOB) app,
  then pilot/validate/expand — with an ongoing token-renewal section.
- **Testing & Validation** — eight tests with explicit pass/fail gates and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for token/sync, install, and licensing failures.
- **Best Practices** — licensing model, the all-important token/license-sync lifecycle, app-type
  selection, targeting hygiene, updates, and operations.

## PowerShell scripts (Microsoft Graph) — `MACVPP-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**.

1. **`MACVPP-Discovery.ps1`** — tenant readiness: Apple VPP token status/expiry and last-sync time,
   synced App Store apps, and per-app VPP license totals. Flags a token expiring within 30 days.
   *Read-only.*
2. **`MACVPP-Validation.ps1`** — validates a specific Mac: managed macOS, the VPP app **installed and
   device-licensed**, and the enterprise (LOB) app **installed** — with a clear PASS/FAIL verdict.
   *Read-only.*
3. **`MACVPP-Report.ps1`** — tenant-wide CSV report: per-app VPP **total vs. consumed** licenses,
   install counts, licensing model, and any app **out of licenses**. *Read-only.*
4. **`MACVPP-Remediation.ps1`** — safe remediation: re-sync the VPP token, surface tokens nearing
   expiry, and (opt-in) re-assign the store/LOB apps to a target group. **Defaults to `-WhatIf`**;
   changes require explicit confirmation.
5. **`MACVPP-Set-ScopeTargeting.ps1`** — builds/populates the target Entra group and (opt-in)
   retargets app assignments from pilot to a wave/all-devices group. **Defaults to `-WhatIf`.**

## Hero image
- **`MACVPP-hero.png`** — the branded product image (1200×1200) used on the marketplace listing.

## How it's delivered
A branded **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts
appendix), plus all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across
**unlimited devices**.
