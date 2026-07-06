# 8. Deliverables Summary — macOS Enterprise SSO App Extension

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: the
  app/browser SSO extension, not Platform SSO device login.
- **Solution Overview** — how Apple's Extensible SSO (redirect vs credential types) and the Microsoft
  Enterprise SSO plug-in work for **apps and browsers**, how silent SSO is achieved, and how this
  differs from Platform SSO device login.
- **Requirements Guide** — every Intune/Entra/macOS prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: prepare the
  device (Company Portal), create the redirect SSO app-extension profile with app/URL scoping, pilot,
  then validate and expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates (including a negative test that
  device login is unchanged) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for "still prompting," scoping, browser, and conflict
  cases.
- **Best Practices** — app/URL scoping discipline, keeping the app extension distinct from Platform
  SSO, browser expectations, and reversible pilot-first rollout.

## PowerShell scripts (Microsoft Graph) — `MACSSOEXT-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`MACSSOEXT-Discovery.ps1`** — tenant readiness: the SSO **app** extension (Redirect) profile is
   present with the correct Microsoft Enterprise SSO Extension/Team identifiers, and Company Portal
   (macOS) is added/assigned.
2. **`MACSSOEXT-Validation.ps1`** — validates the profile's **assignment** and per-device **applied**
   state, with a clear PASS/FAIL summary.
3. **`MACSSOEXT-Report.ps1`** — tenant-wide CSV report of macOS devices and whether the SSO
   app-extension profile is applied — the SSO coverage report.
4. **`MACSSOEXT-Remediation.ps1`** — safe remediation of missing/mis-scoped profiles (re-assign to a
   target group, flag conflicts). **`-WhatIf` by default**; applies only when re-run to commit.
5. **`MACSSOEXT-Set-ScopeTargeting.ps1`** — sets/adjusts the profile's group assignment (target-group
   builder). **`-WhatIf` by default.**

## Hero image
- **`MACSSOEXT-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited
devices**.
