# iOS/iPadOS Enterprise SSO App Extension for Corporate-Owned iPhones

**Category:** Intune Solutions · **Solution code:** IOSSSOEXT · **Version:** 1.0.0 · **Status:** generated

Deploys the **Microsoft Enterprise SSO plug-in** as an Apple **Extensible SSO app extension** (hosted
in Microsoft Authenticator) on **corporate-owned, Intune-enrolled** iPhones/iPads, delivering silent,
shared single sign-on to Entra-secured apps and Safari. Pilot-first and reversible. The iOS counterpart
to the macOS Enterprise SSO App Extension (MACSSOEXT).

## Products & pricing (3 tiers)
| SKU | Audience | Price |
|-----|----------|-------|
| PTK-IOSSSOEXT-COMM-001 | Commercial | $2,495.00 |
| PTK-IOSSSOEXT-NPO-001  | Non-Profit (−40%) | $1,497.00 |
| PTK-IOSSSOEXT-GOV-001  | Government (−15%) | $2,120.75 |

## What's included
- **Documentation** — Executive Summary, Solution Overview, Requirements (+ category Global
  Requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- **5 PowerShell scripts** — `IOSSSOEXT-Discovery.ps1`, `IOSSSOEXT-Validation.ps1`,
  `IOSSSOEXT-Report.ps1`, `IOSSSOEXT-Remediation.ps1`, `IOSSSOEXT-Set-ScopeTargeting.ps1`
  (read-only discovery/validation/reporting; remediation + targeting default to `-WhatIf`).
- **Deliverables** — `IOSSSOEXT-Solution.docx`, `IOSSSOEXT-Solution.pdf`, `IOSSSOEXT-Scripts.zip`,
  `IOSSSOEXT-hero.png`.

## Scope notes
- **Gap-only:** distinct from MACSSOEXT (macOS), IOSDD (two-phone dual-device scenario), and the
  shared-device products. This is the standalone **iOS Enterprise SSO app extension** for single-user
  corporate iPhones.
- **iOS specifics:** extension hosted in **Microsoft Authenticator**; extension id
  `com.microsoft.azureauthenticator.ssoextension`; Device-features **Microsoft Entra ID** SSO extension
  type; **`Enable_SSO_On_All_ManagedApps`** managed-app coverage key.
- **Branding:** off (white-label). **Version directive:** New. **Gov:** price-only this run
  (Commercial-only deliverable).

## Files
```
source/            8 markdown docs + global-requirements-intune-solutions.md
scripts/           5 PowerShell scripts
listing/           bagisto-products.json, hero.json, sales-content.md
deliverables/      built DOCX/PDF/ZIP + hero PNG/SVG
solution.meta.json
```

Next: `/publish-solution ios-enterprise-sso-app-extension-corporate-owned-iphones`
