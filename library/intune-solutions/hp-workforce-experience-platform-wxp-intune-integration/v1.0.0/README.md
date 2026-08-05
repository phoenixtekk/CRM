# HP Workforce Experience Platform (WXP) Integration with Microsoft Intune

**Category:** Intune Solutions · **Solution code:** HPWXP · **Version:** 1.0.0 · **Status:** generated

Integrates the **HP Workforce Experience Platform (WXP)** — the cloud DEX/analytics platform *formerly
HP TechPulse / Proactive Insights / Adaptive Endpoint Management* — with **Microsoft Intune**. Two
halves: (1) deploy the **WXP agent as a Required Intune Win32 app** (`HP WXP Agent - Pilot`) carrying the
tenant enrollment code, and (2) connect WXP to the **Entra/Intune tenant** via an admin-consented
enterprise application (`HP Workforce Experience`) so WXP correlates its hardware/experience/
sustainability telemetry with your Intune inventory. Pilot-first and reversible. Complements — does not
replace — Microsoft Endpoint Analytics.

## Products & pricing (3 tiers)
| SKU | Audience | Price |
|-----|----------|-------|
| PTK-HPWXP-COMM-001 | Commercial | $2,995.00 |
| PTK-HPWXP-NPO-001  | Non-Profit (−40%) | $1,797.00 |
| PTK-HPWXP-GOV-001  | Government (−15%) | $2,545.75 |

## What's included
- **Documentation** — Executive Summary, Solution Overview, Requirements (+ category Global
  Requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- **5 PowerShell scripts** — `HPWXP-Discovery.ps1`, `HPWXP-Validation.ps1`, `HPWXP-Report.ps1`,
  `HPWXP-Remediation.ps1`, `HPWXP-Set-ScopeTargeting.ps1` (read-only discovery/validation/reporting;
  remediation + targeting default to `-WhatIf`).
- **Deliverables** — `HPWXP-Solution.docx`, `HPWXP-Solution.pdf`, `HPWXP-Scripts.zip`, `HPWXP-hero.png`
  (built at compile time).

## Scope notes
- **Two-half integration:** agent-via-Intune (Win32 app + enrollment code + detection rule) **and** the
  Entra/Intune tenant connector (Global-Admin admin-consent flow initiated from the HP WXP console).
- **Gap-only:** no existing HP-specific product. Cross-references **ENDPTAN** (Microsoft Endpoint
  Analytics) and **EHEM** (generic DEX monitoring) without rebuilding them; positions WXP as an
  addition for hardware/sustainability/proactive-support telemetry.
- **Verify-don't-invent:** HP renamed this platform repeatedly. Console paths, agent installer filename,
  enrollment-code label, connector app display name, Graph scopes, and WXP network URLs are flagged
  **verify in the HP WXP admin console / your tenant** — not invented. Scripts parameterize the
  HP-renamed names (`-AppName`, `-ConnectorAppName`).
- **Prerequisite:** an **HP WXP subscription/licensing** is buyer-supplied (edition/entitlements —
  verify with HP).
- **Branding:** off (white-label). **Version directive:** New. **Gov:** price-only this run (Commercial
  deliverable).

## Files
```
source/            8 markdown docs + global-requirements-intune-solutions.md
scripts/           5 PowerShell scripts
listing/           bagisto-products.json, hero.json, sales-content.md
solution.meta.json
```

Next: `/publish-solution hp-workforce-experience-platform-wxp-intune-integration`
