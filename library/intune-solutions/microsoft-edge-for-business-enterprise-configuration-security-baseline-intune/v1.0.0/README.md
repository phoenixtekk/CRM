# Microsoft Edge for Business — Enterprise Configuration & Security Baseline (Intune)

**Category:** Intune Solutions · **Solution code:** EDGEBIZ · **Version:** 1.0.0 · **Status:** generated

Turns **Microsoft Edge for Business** into a **managed, hardened, standardized** browser across the
Windows fleet using **Microsoft Intune** — the **Settings Catalog (Microsoft Edge ADMX-backed)** for
configuration and the **Microsoft Edge security baseline** (Endpoint security) for the hardening floor,
plus default-browser enforcement and IE mode for legacy line-of-business apps. Pilot-first and reversible.
Resolves two common assessment findings (password manager off; Edge enforced as default) plus broad
browser hardening.

## Products & pricing (3 tiers)
| SKU | Audience | Price |
|-----|----------|-------|
| PTK-EDGEBIZ-COMM-001 | Commercial | $1,995.00 |
| PTK-EDGEBIZ-NPO-001  | Non-Profit (−40%) | $1,197.00 |
| PTK-EDGEBIZ-GOV-001  | Government (−15%) | $1,695.75 |

## What's included
- **Documentation** — Executive Summary, Solution Overview, Requirements (+ category Global
  Requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- **5 PowerShell scripts** — `EDGEBIZ-Discovery.ps1`, `EDGEBIZ-Validation.ps1`, `EDGEBIZ-Report.ps1`,
  `EDGEBIZ-Remediation.ps1`, `EDGEBIZ-Set-ScopeTargeting.ps1` (read-only discovery/validation/reporting;
  remediation + targeting default to `-WhatIf`).
- **Deliverables** — `EDGEBIZ-Solution.docx`, `EDGEBIZ-Solution.pdf`, `EDGEBIZ-Scripts.zip`,
  `EDGEBIZ-hero.png` (built by the factory compiler at publish time).

## Named objects (reused across all docs)
- Pilot group: **`Edge for Business - Pilot Devices`**
- Settings Catalog baseline: **`Edge for Business - Baseline - Pilot`**
- Default-browser custom profile: **`Edge for Business - Default Browser - Pilot`**
- Microsoft Edge security baseline: **`Edge for Business - Security Baseline - Pilot`**
- Enterprise Mode Site List file: **`EdgeForBusiness-EMSiteList.xml`**

## Scope notes
- **Covers:** Edge as default browser org-wide (Intune default-associations); IE mode + Enterprise Mode
  Site List for legacy apps; password manager off (`PasswordManagerEnabled = Disabled`); SmartScreen +
  PUA; extension block/allow-list (sideloading control); sync/work-profile sign-in; typosquatting
  protection; update channel & cadence; startup/home pages; and applying the Microsoft Edge security
  baseline. **Windows only.**
- **Gap-only:** no existing Edge enterprise-config product in the catalog.
- **Verify-don't-invent:** exact Edge policy names are given with CSP keys where confident; version-
  sensitive items are flagged **verify in your tenant**.
- **Branding:** off (white-label). **Version directive:** New. **Gov:** price-only this run
  (Commercial-only deliverable).

## Files
```
source/            8 markdown docs + global-requirements-intune-solutions.md
scripts/           5 PowerShell scripts
listing/           bagisto-products.json, hero.json, sales-content.md
solution.meta.json
```

Next: `/publish-solution microsoft-edge-for-business-enterprise-configuration-security-baseline-intune`
