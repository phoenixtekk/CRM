# Windows Interactive Logon & Network-Access Security Options Hardening (Intune)

**Category:** Intune Solutions · **Solution code:** WINSECOPT · **Version:** 1.0.0 · **Status:** generated

Hardens the **four leftover interactive-logon and network-access Security Options** on **Windows 10/11**
via a single **Intune Settings Catalog** profile — the gap-only pack that closes the assessment findings
the NTLM/SMB, RDP, and credential-theft products leave behind. Pilot-first and reversible; complements a
CIS/STIG baseline.

## Products & pricing (3 tiers)
| SKU | Audience | Price |
|-----|----------|-------|
| PTK-WINSECOPT-COMM-001 | Commercial | $2,495.00 |
| PTK-WINSECOPT-NPO-001  | Non-Profit (−40%) | $1,497.00 |
| PTK-WINSECOPT-GOV-001  | Government (−15%) | $2,120.75 |

## What's included
- **Documentation** — Executive Summary, Solution Overview, Requirements (+ category Global
  Requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- **5 PowerShell scripts** — `WINSECOPT-Discovery.ps1`, `WINSECOPT-Validation.ps1`,
  `WINSECOPT-Report.ps1`, `WINSECOPT-Remediation.ps1`, `WINSECOPT-Set-ScopeTargeting.ps1`
  (read-only discovery/validation/reporting; remediation + targeting default to `-WhatIf`).
- **Deliverables** — `WINSECOPT-Solution.docx`, `WINSECOPT-Solution.pdf`, `WINSECOPT-Scripts.zip`,
  `WINSECOPT-hero.png` (built by the factory compiler).

## The four controls
1. **Prohibit connection to non-domain networks when connected to a domain-authenticated network** —
   Windows Connection Manager, `fBlockNonDomain = 1`.
2. **Interactive logon: Smart card removal behavior = Lock Workstation** — `scremoveoption = 1`.
3. **Disable "Sign-in and lock last interactive user automatically after a restart"** —
   `DisableAutomaticRestartSignOn = 1`.
4. **Do not display network selection UI = Enabled** — `DontDisplayNetworkSelectionUI = 1`.

## Scope notes
- **Gap-only:** the leftover Security Options not owned by the NTLM/SMB, RDP, or credential-theft
  products; complements a CIS/STIG baseline. Resolves ~4 Windows Client assessment findings.
- **User impact:** disabling automatic restart sign-on requires users to re-login after an update
  reboot — called out explicitly so the expectation can be set before rollout.
- **Verify-don't-invent:** exact Settings Catalog labels / `settingDefinitionId` values are flagged
  **verify in your tenant** where Microsoft may have renamed them.
- **Branding:** off (white-label). **Version directive:** New. **Gov:** price-only this run
  (Commercial-only deliverable).

## Files
```
source/            8 markdown docs + global-requirements-intune-solutions.md
scripts/           5 PowerShell scripts
listing/           bagisto-products.json, hero.json, sales-content.md
solution.meta.json
```

Next: build the deliverables, then `/publish-solution windows-interactive-logon-network-access-hardening-intune`
