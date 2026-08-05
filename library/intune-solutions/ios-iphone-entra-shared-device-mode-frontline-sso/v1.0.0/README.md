# iOS iPhone Entra ID Shared Device Mode — Frontline SSO

**Category:** Intune Solutions · **Solution code:** IOSSDMFL · **Version:** 1.0.0 · **Status:** generated

Configures **Microsoft Entra ID Shared Device Mode (SDM)** on **shared/pooled iPhones** managed by
Intune, so frontline workers get **global sign-in** and **single sign-out** (Teams + MSAL apps): sign
in once as yourself, sign out once to clear your identity and app data for the next person. The
Microsoft-native shared-**iPhone** answer (Apple Shared iPad is iPad-only).

## Products & pricing (3 tiers)
| SKU | Audience | Price |
|-----|----------|-------|
| PTK-IOSSDMFL-COMM-001 | Commercial | $2,795.00 |
| PTK-IOSSDMFL-NPO-001  | Non-Profit (−40%) | $1,677.00 |
| PTK-IOSSDMFL-GOV-001  | Government (−15%) | $2,375.75 |

## What's included
- **Documentation** — Executive Summary, Solution Overview, Requirements (+ category Global
  Requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- **5 PowerShell scripts** — `IOSSDMFL-Discovery.ps1`, `IOSSDMFL-Validation.ps1`, `IOSSDMFL-Report.ps1`,
  `IOSSDMFL-Remediation.ps1`, `IOSSDMFL-Set-ScopeTargeting.ps1` (read-only discovery/validation/report;
  remediation + targeting default to `-WhatIf`).
- **Deliverables** — `IOSSDMFL-Solution.docx`, `IOSSDMFL-Solution.pdf`, `IOSSDMFL-Scripts.zip`,
  `IOSSDMFL-hero.png`.

## Scope notes
- **Gap-only:** distinct from IOSSDM (WebEx single-app kiosk, shared service account), IOSLD (lockdown
  profile), and SHAREDIPAD (Apple Managed Apple IDs, iPad-only). This is **Entra ID Shared Device
  Mode** = per-user global sign-in / single sign-out on shared iPhones.
- **Lessons applied:** 2026-07-16 lockdown≠session-isolation; Assigned-group + **Intune Provisioning
  Client owner** (`f1346770-5b25-470b-88bd-d5744ab7952c`) for no-affinity enrollment-time grouping; ADE
  full nav drill-down; store-app publisher + bundle IDs (Authenticator `com.microsoft.azureauthenticator`,
  Teams `com.microsoft.skype.teams`).
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

Next: `/publish-solution ios-iphone-entra-shared-device-mode-frontline-sso`
