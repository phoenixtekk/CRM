# 8. Deliverables Summary — Windows Interactive Logon & Network-Access Security Options Hardening

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: the four
  leftover interactive-logon and network-access Security Options findings, not NTLM/SMB, RDP,
  credential-theft, or full-baseline hardening.
- **Solution Overview** — what each of the four controls does (Windows Connection Manager non-domain
  block, smart-card removal = Lock Workstation, disable automatic restart sign-on, hide the network
  selection UI), the exact values, the honest user-impact, and how this pack is gap-only and
  complements a CIS/STIG baseline.
- **Requirements Guide** — every Intune/Windows prerequisite with how to **verify** and how to
  **implement if missing**, including checking for existing owners of these settings, plus the
  category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: assess and
  prepare, build the single named Settings Catalog profile with the four settings, pilot, then
  validate and expand.
- **Testing & Validation** — ten tests with explicit pass/fail gates (including registry spot-checks
  and a negative test that nothing else changed) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for missing/not-applying settings, baseline conflicts, the
  "Disabled-means-on" inversion, and the user-visible behaviors.
- **Best Practices** — owning each setting once, communicating the user-visible changes, precise values
  with verify-in-tenant discipline, and reversible pilot-first rollout.

## PowerShell scripts (Microsoft Graph) — `WINSECOPT-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`WINSECOPT-Discovery.ps1`** — tenant readiness: a Windows Settings Catalog profile is present that
   carries all four target settings.
2. **`WINSECOPT-Validation.ps1`** — validates the profile's **assignment** and per-device **applied**
   state, with a clear PASS/FAIL summary.
3. **`WINSECOPT-Report.ps1`** — tenant-wide CSV report of Windows devices and whether the hardening
   profile is applied — the coverage report.
4. **`WINSECOPT-Remediation.ps1`** — safe remediation: creates the Settings Catalog profile with the
   four settings if missing and assigns it to a target group. **`-WhatIf` by default**; applies only
   when re-run with `-WhatIf:$false`.
5. **`WINSECOPT-Set-ScopeTargeting.ps1`** — sets/adjusts the profile's group assignment (target-group
   builder, with optional exclusion group). **`-WhatIf` by default.**

## Hero image
- **`WINSECOPT-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.
