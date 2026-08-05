# 8. Deliverables Summary — Remote Desktop (RDP) Security Hardening

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: endpoint
  RDP hardening for Windows 10/11 via Intune, resolving ~5 assessment findings — not network/gateway
  controls, and not the full credential-theft program.
- **Solution Overview** — why RDP defaults are an assessment finding, the five findings plus NLA and
  the cross-referenced credential/logon extras, each mapped to its registry anchor, and the one
  breaking change (High encryption vs legacy clients).
- **Requirements Guide** — every Intune/Windows/Settings-Catalog prerequisite with how to **verify** and
  how to **implement if missing**, including the legacy-client impact assessment, plus the category-level
  Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: assess and prepare
  (including legacy-client identification), build the named `RDP Hardening - Pilot` Settings Catalog
  profile, pilot with a live RDP session, then validate and expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates, including the legacy-client
  breaking-change gate and a reversibility negative test, and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for "it didn't harden," conflicts with CIS/STIG baselines,
  the expected legacy-client refusal, and each per-setting symptom.
- **Best Practices** — pilot the breaking change first, one owner per setting, verify on the device,
  harden host vs client in the right place, and treat credential/network layers as adjacent projects.

## PowerShell scripts (Microsoft Graph) — `RDPHARD-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`RDPHARD-Discovery.ps1`** — tenant readiness: the `RDP Hardening - Pilot` Settings Catalog profile
   is present and carries the expected RDP settings (encryption, password prompt, drive redirection,
   saved passwords, Remote Assistance, NLA).
2. **`RDPHARD-Validation.ps1`** — validates the profile's **assignment** and per-device **applied**
   state, with a clear PASS/FAIL summary.
3. **`RDPHARD-Report.ps1`** — tenant-wide CSV report of Windows devices and whether the RDP hardening
   profile is applied — the coverage report.
4. **`RDPHARD-Remediation.ps1`** — safe remediation of a missing/mis-scoped profile (create the Settings
   Catalog profile if absent, assign it to a target group). **`-WhatIf` by default**; applies only when
   re-run with `-WhatIf:$false`.
5. **`RDPHARD-Set-ScopeTargeting.ps1`** — sets/adjusts the profile's group assignment (target-group
   builder, with optional exclusion group). **`-WhatIf` by default.**

## Hero image
- **`RDPHARD-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.
