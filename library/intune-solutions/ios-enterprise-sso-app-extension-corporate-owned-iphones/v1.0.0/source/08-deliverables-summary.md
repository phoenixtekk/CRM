# 8. Deliverables Summary — iOS/iPadOS Enterprise SSO App Extension

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: the
  app/browser SSO extension for corporate-owned iPhones/iPads, not device enrollment and not
  shared-device identity.
- **Solution Overview** — how Apple's Extensible SSO (redirect vs credential types) and the Microsoft
  Enterprise SSO plug-in work on iOS (hosted in **Microsoft Authenticator**), how silent SSO is
  achieved, and how this differs from the Mac product and the shared-device / dual-device solutions.
- **Requirements Guide** — every Intune/Entra/iOS prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: prepare the
  device (Microsoft Authenticator), create the Device-features SSO app-extension profile with
  managed-app / URL scoping, pilot, then validate and expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates (including a negative test that
  enrollment/identity is unchanged) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for "still prompting," repeated MFA, scoping, browser, and
  conflict cases.
- **Best Practices** — managed-app-wide SSO vs allow-listing, getting the Authenticator broker host
  right, browser/MFA expectations, and reversible pilot-first rollout.

## PowerShell scripts (Microsoft Graph) — `IOSSSOEXT-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`IOSSSOEXT-Discovery.ps1`** — tenant readiness: the SSO app-extension profile is present with the
   correct Microsoft Enterprise SSO extension identifier, and Microsoft Authenticator (iOS) is
   added/assigned.
2. **`IOSSSOEXT-Validation.ps1`** — validates the profile's **assignment** and per-device **applied**
   state, with a clear PASS/FAIL summary.
3. **`IOSSSOEXT-Report.ps1`** — tenant-wide CSV report of iOS/iPadOS devices and whether the SSO
   app-extension profile is applied — the SSO coverage report.
4. **`IOSSSOEXT-Remediation.ps1`** — safe remediation of missing/mis-scoped profiles (re-assign to a
   target group, flag conflicts). **`-WhatIf` by default**; applies only when re-run to commit.
5. **`IOSSSOEXT-Set-ScopeTargeting.ps1`** — sets/adjusts the profile's group assignment (target-group
   builder). **`-WhatIf` by default.**

## Hero image
- **`IOSSSOEXT-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited
devices**.
