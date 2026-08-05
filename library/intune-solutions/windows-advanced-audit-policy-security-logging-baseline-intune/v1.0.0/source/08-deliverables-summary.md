# 8. Deliverables Summary — Windows Advanced Audit Policy & Security Logging Baseline

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: the audit
  *configuration* baseline for Windows 10/11 via Intune — not SIEM forwarding and not a broad CIS/STIG
  hardening baseline.
- **Solution Overview** — how Windows advanced (subcategory) auditing works, the all-important
  force-subcategory override (`SCENoApplyLegacyAuditPolicy`), what the baseline audits and why, the
  event-volume trade-offs, and how this relates to the Sentinel forwarding solution.
- **Requirements Guide** — every Intune/Windows prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps to build one Settings Catalog profile
  (`Win Audit Policy - Baseline - Pilot`): the override, all ~24 audit subcategories with recommended
  Success/Failure values (CIS / Microsoft-aligned), command-line process auditing, and the Security-log
  size — then pilot, validate, and expand (including a server variant).
- **Testing & Validation** — nine tests with explicit pass/fail gates, including the mandatory
  override check and an on-device `auditpol` / Event Viewer verification, plus an acceptance gate.
- **Troubleshooting** — top-down diagnosis for "settings applied but nothing audited," missing 4688
  command line, log rollover, conflicts, and per-device gaps.
- **Best Practices** — override-first discipline, detection-over-volume tuning, workstation vs server
  split, log sizing/forwarding, and reversible pilot-first rollout.

## PowerShell scripts (Microsoft Graph) — `WINAUDIT-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`WINAUDIT-Discovery.ps1`** — tenant readiness: the `Win Audit Policy - Baseline - Pilot` Settings
   Catalog profile is present with the force-subcategory override and the audit subcategory settings.
2. **`WINAUDIT-Validation.ps1`** — validates the profile's **assignment** and per-device **applied**
   state, with a clear PASS/FAIL summary.
3. **`WINAUDIT-Report.ps1`** — tenant-wide CSV report of Windows 10/11 devices and whether the audit
   baseline profile is applied — the audit-coverage report.
4. **`WINAUDIT-Remediation.ps1`** — scaffolds the full Settings Catalog audit profile if missing (the
   override, all subcategories at their recommended values, command-line auditing, log size) and assigns
   it to a target group. **`-WhatIf` by default**; applies only when re-run to commit.
5. **`WINAUDIT-Set-ScopeTargeting.ps1`** — sets/adjusts the profile's group assignment (target-group
   builder, with optional exclusion group). **`-WhatIf` by default.**

## Hero image
- **`WINAUDIT-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.

## Related solutions (not included here)
- **Entra ID & Intune Audit Telemetry to Microsoft Sentinel** — forwards the Windows Security events
  this baseline produces into your SIEM (Azure Monitor Agent + Data Collection Rules). This solution is
  the *source*; that one is the *transport*.
- **CIS / STIG Windows Security Baseline** — the broad hardening baseline; this audit baseline is the
  focused auditing slice and complements it without duplication.
