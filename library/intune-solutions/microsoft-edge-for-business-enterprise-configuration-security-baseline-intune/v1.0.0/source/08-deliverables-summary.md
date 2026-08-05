# 8. Deliverables Summary — Microsoft Edge for Business Enterprise Configuration & Security Baseline

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page: the two assessment findings resolved
  (password manager off; Edge enforced as default) plus the broader browser-hardening value.
- **Solution Overview** — the two Intune surfaces used (Settings Catalog Microsoft Edge ADMX-backed +
  Endpoint security Microsoft Edge security baseline), how default-browser enforcement and IE mode work,
  and the named objects you build and reuse.
- **Requirements Guide** — every Intune/Entra/Edge prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: assess and prepare
  (site list + associations XML), configure the named Settings Catalog baseline (password manager off,
  SmartScreen/PUA, extensions, sync/sign-in, typosquatting, startup, update channel, IE mode), enforce the
  default browser, apply the Microsoft Edge security baseline, pilot, then validate and expand.
- **Testing & Validation** — ten tests with explicit pass/fail gates (including confirming both findings
  are resolved and a negative test for unintended breakage) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis using `edge://policy`: profiles not applying, conflicts, the two
  findings, IE mode, extension control, and missing/renamed policies.
- **Best Practices** — resolving Settings-Catalog ↔ security-baseline conflicts, block-all-then-allow
  extensions, IE-mode site-list hygiene, sign-in/sync posture, update cadence, and reversible pilot-first
  rollout.

## PowerShell scripts (Microsoft Graph) — `EDGEBIZ-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK); each
has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and Report are
**read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first, then apply).

1. **`EDGEBIZ-Discovery.ps1`** — tenant readiness: the `Edge for Business - Baseline - Pilot` Settings
   Catalog profile exists with the core settings (`PasswordManagerEnabled = disabled`, SmartScreen), the
   `Edge for Business - Default Browser - Pilot` custom profile exists, and the Microsoft Edge security
   baseline is created.
2. **`EDGEBIZ-Validation.ps1`** — validates each object's **assignment** and per-device **applied** state,
   with a clear PASS/FAIL summary.
3. **`EDGEBIZ-Report.ps1`** — tenant-wide CSV report of Windows devices and whether the Edge configuration
   baseline is applied — the Edge coverage report.
4. **`EDGEBIZ-Remediation.ps1`** — safe remediation: creates the Settings Catalog Edge baseline with the
   core settings if missing and assigns it to a target group. **`-WhatIf` by default**; applies only when
   re-run with `-WhatIf:$false`.
5. **`EDGEBIZ-Set-ScopeTargeting.ps1`** — sets/adjusts the baseline profile's group assignment (target-group
   builder). **`-WhatIf` by default.**

## Hero image
- **`EDGEBIZ-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus all
five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.
