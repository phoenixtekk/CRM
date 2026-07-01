# 8. Deliverables Summary — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — the two ownership models, the single-identity design, management models,
  benefits, and honest limitations.
- **Requirements Guide** — every prerequisite (one identity, MDM+MAM licensing, Entra ID P1,
  enrollment restrictions, corporate tagging, Company Portal, App Protection, compliance, ownership
  filters, network) with how to **verify** and how to **implement if missing**, plus the category-level
  Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across seven phases: identity, Apple
  connection & enrollment baseline, ownership-based targeting, corporate-iPhone supervised ADE full-MDM,
  personal-iPhone App Protection, single sign-on across both iPhones, unifying access with Conditional
  Access, then pilot/validate/expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates and an acceptance gate, proving
  one account works on both a corporate and a personal device.
- **Troubleshooting** — top-down diagnosis for identity, ownership, targeting, and access failures.
- **Best Practices** — the assign-to-user/scope-by-filter model, ownership hygiene, BYOD data
  protection, COD management, Conditional Access, and rollout discipline.

## PowerShell scripts (Microsoft Graph) — `IOSDD-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**.

1. **`IOSDD-Discovery.ps1`** — tenant readiness: enrollment restrictions (personal allowed?),
   compliance policies, App Protection policies, Corporate/Personal device filters, Company Portal,
   and Conditional Access presence.
2. **`IOSDD-Validation.ps1`** — for a given user, confirms a single identity owns both a **Corporate**
   device (compliant) and a **Personal** device (app protection applied), with a PASS/FAIL summary.
3. **`IOSDD-DeviceReport.ps1`** — tenant-wide CSV: devices by **ownership**, platform, enrollment
   type, compliance, and primary user — plus a list of users who have **both** a COD and a BYOD device.
4. **`IOSDD-Remediation.ps1`** — safe remediation: set device **ownership**, re-assign policies to the
   target group, and flag enrollment-restriction/filter misconfigurations. Read-only by default;
   changes require an explicit confirmation switch.
5. **`IOSDD-Set-OwnershipBasedTargeting.ps1`** — creates the **`iPhone – Corporate`** and **`iPhone –
   Personal`** `deviceOwnership` filters (and optionally assigns the compliance/app-protection policies
   with those filters) — the mechanism that makes one account work cleanly across both iPhones.

## Hero image
- **`IOSDD-hero.png`** — the branded product image (1200×1200) used on the marketplace listing.

## How it's delivered
A branded **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts
appendix), plus all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across
**unlimited devices**.
