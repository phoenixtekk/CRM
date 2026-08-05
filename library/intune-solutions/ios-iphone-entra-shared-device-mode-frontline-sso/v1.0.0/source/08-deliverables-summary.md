# 8. Deliverables Summary — iOS iPhone Entra ID Shared Device Mode

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: per-user
  identity sessions on shared iPhones via Entra Shared Device Mode, not kiosk lockdown and not Apple
  Shared iPad.
- **Solution Overview** — how Entra Shared Device Mode works on iPhones (no-affinity enrollment,
  Authenticator shared-mode registration, SDM-aware apps), global sign-in / single sign-out, what it
  isolates (honestly), and why iPhones need it (Apple Shared iPad is iPad-only).
- **Requirements Guide** — every ABM/ADE, Entra, Intune, role, and app prerequisite with how to
  **verify** and how to **implement if missing** — including the Assigned-group + Intune Provisioning
  Client owner requirement — plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: build the
  foundation (assigned group + owner, no-affinity ADE profile, apps, restrictions, role), enroll and
  register a pilot device into shared mode, pilot the global sign-in / single sign-out, then validate
  and expand.
- **Testing & Validation** — nine tests with explicit pass/fail gates, centered on the two-user
  clean-hand-off test, plus a non-SDM-app boundary negative test.
- **Troubleshooting** — enrollment-order diagnosis for empty groups, affinity, shared-mode
  registration, sign-out data-clearing, and app-support cases.
- **Best Practices** — enrollment-time grouping, treating app scope as the security boundary,
  provisioning discipline, and proving the hand-off with two real users.

## PowerShell scripts (Microsoft Graph) — `IOSSDMFL-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`IOSSDMFL-Discovery.ps1`** — tenant readiness: no-affinity ADE profile, Microsoft Authenticator +
   Teams assigned, the Assigned device group with the Intune Provisioning Client as owner, and the
   Cloud Device Administrator role populated.
2. **`IOSSDMFL-Validation.ps1`** — validates the assigned-group ownership, ADE profile affinity, and
   app assignments, with a clear PASS/FAIL summary.
3. **`IOSSDMFL-Report.ps1`** — tenant-wide CSV report of shared (no-affinity) iOS devices and whether
   the SDM apps are present — the shared-pool inventory.
4. **`IOSSDMFL-Remediation.ps1`** — safe remediation: create/assign the Assigned device group, set the
   Intune Provisioning Client as owner, and flag missing app assignments. **`-WhatIf` by default.**
5. **`IOSSDMFL-Set-ScopeTargeting.ps1`** — sets/adjusts the target (Assigned) group used for the
   shared-device apps/config. **`-WhatIf` by default.**

## Hero image
- **`IOSSDMFL-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited
devices**.
