# Windows Credential Theft Protection — Credential Guard, LSASS Protection & Windows LAPS (Intune)

**Category:** Intune Solutions · **Solution code:** CREDGUARD · **Version:** 1.0.0 · **Status:** generated

The endpoint-side **credential-theft / pass-the-hash defense** pack for **Windows 10/11** via **Microsoft
Intune** only — no GPO, no third-party agent. Deploys six coordinated controls (Credential Guard, LSASS
protection, WDigest off, Remote Credential Guard, WinRM RunAs off, Windows LAPS), readiness-gated and
pilot-first, and resolves ~3 common security-assessment findings directly.

## Products & pricing (3 tiers)
| SKU | Audience | Price |
|-----|----------|-------|
| PTK-CREDGUARD-COMM-001 | Commercial | $2,995.00 |
| PTK-CREDGUARD-NPO-001  | Non-Profit (−40%) | $1,797.00 |
| PTK-CREDGUARD-GOV-001  | Government (−15%) | $2,545.75 |

## What's included
- **Documentation** — Executive Summary, Solution Overview, Requirements (+ category Global
  Requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- **5 PowerShell scripts** — `CREDGUARD-Discovery.ps1`, `CREDGUARD-Validation.ps1`,
  `CREDGUARD-Report.ps1`, `CREDGUARD-Remediation.ps1`, `CREDGUARD-Set-ScopeTargeting.ps1`
  (read-only discovery/validation/reporting incl. on-device TPM/UEFI/Secure Boot/VBS readiness;
  remediation + targeting default to `-WhatIf`).
- **Deliverables** — `CREDGUARD-Solution.docx`, `CREDGUARD-Solution.pdf`, `CREDGUARD-Scripts.zip`,
  `CREDGUARD-hero.png`.

## Named objects (created once, reused throughout)
`Credential Protection - Pilot` (group), `Credential Guard - Pilot`, `LSASS Protection (RunAsPPL) -
Pilot`, `WDigest Disabled - Baseline`, `Remote Credential Guard - Pilot`, `WinRM No RunAs Credentials -
Baseline`, `Windows LAPS - Baseline`.

## Scope notes
- **Gap-only:** no existing Credential Guard / LAPS product in the catalog. WDigest overlaps the NTLM
  restriction solution but its primary home is here. The **RDP host-side** credential-delegation settings
  (`AllowProtectedCreds`, Restricted Admin, NLA) are cross-referenced to the separate **RDP hardening**
  solution, not duplicated.
- **Readiness-gated:** Credential Guard requires **TPM 2.0 / UEFI / Secure Boot / virtualization** — a
  readiness assessment and phased rollout are included; LSASS PPL is deployed **audit-first**.
- **Branding:** off (white-label). **Version directive:** New. **Gov:** price-only this run
  (Commercial-only deliverable).

## Files
```
source/            8 markdown docs + global-requirements-intune-solutions.md
scripts/           5 PowerShell scripts
listing/           bagisto-products.json, hero.json, sales-content.md
solution.meta.json
```

Next: `/publish-solution windows-credential-theft-protection-credential-guard-laps-intune`
