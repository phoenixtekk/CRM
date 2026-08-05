# Remote Desktop (RDP) Security Hardening for Windows Endpoints (Intune)

**Category:** Intune Solutions · **Solution code:** RDPHARD · **Version:** 1.0.0 · **Status:** generated

Deploys a single named **Intune Settings Catalog** configuration profile (**`RDP Hardening - Pilot`**)
that hardens **Remote Desktop (RDP)** on **Windows 10/11** endpoints — High/128-bit encryption, always
prompt for password, no drive redirection, no saved passwords, Remote Assistance disabled, and NLA
required. Resolves roughly five recurring Windows-client assessment findings. Pilot-first and
reversible; complements CIS and DISA STIG baselines.

## Products & pricing (3 tiers)
| SKU | Audience | Price |
|-----|----------|-------|
| PTK-RDPHARD-COMM-001 | Commercial | $2,495.00 |
| PTK-RDPHARD-NPO-001  | Non-Profit (−40%) | $1,497.00 |
| PTK-RDPHARD-GOV-001  | Government (−15%) | $2,120.75 |

## What's included
- **Documentation** — Executive Summary, Solution Overview, Requirements (+ category Global
  Requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- **5 PowerShell scripts** — `RDPHARD-Discovery.ps1`, `RDPHARD-Validation.ps1`, `RDPHARD-Report.ps1`,
  `RDPHARD-Remediation.ps1`, `RDPHARD-Set-ScopeTargeting.ps1` (read-only discovery/validation/reporting;
  remediation + targeting default to `-WhatIf`).
- **Deliverables** — `RDPHARD-Solution.docx`, `RDPHARD-Solution.pdf`, `RDPHARD-Scripts.zip`,
  `RDPHARD-hero.png`.

## Scope notes
- **Resolves ~5 assessment findings:** encryption High (`MinEncryptionLevel=3`), always prompt for
  password (`fPromptForPassword=1`), no drive redirection (`fDisableCdm=1`), no saved passwords
  (`DisablePasswordSaving=1`), Solicited Remote Assistance disabled (`fAllowToGetHelp=0`). Plus NLA
  (`UserAuthentication=1`) and guidance to limit who can log on via RDP.
- **Gap-only:** endpoint-side RDP hardening (host + client). The credential-delegation side (Restricted
  Admin / Remote Credential Guard) is **cross-referenced** to the credential-theft hardening solution,
  not duplicated. Network/gateway controls (RD Gateway, firewall, VPN) are out of scope.
- **Pilot-first:** High/128-bit encryption denies genuinely legacy sub-128-bit clients — a real breaking
  change, gated by an explicit legacy-client test before expansion. Exact Settings Catalog / CSP labels
  flagged **verify in your tenant**; registry anchors are the stable truth.
- **Branding:** off (white-label). **Version directive:** New. **Gov:** price-only this run
  (Commercial-only deliverable).

## Files
```
source/            8 markdown docs + global-requirements-intune-solutions.md
scripts/           5 PowerShell scripts
listing/           bagisto-products.json, hero.json, sales-content.md
solution.meta.json
```

Next: `/publish-solution remote-desktop-rdp-security-hardening-windows-intune`
