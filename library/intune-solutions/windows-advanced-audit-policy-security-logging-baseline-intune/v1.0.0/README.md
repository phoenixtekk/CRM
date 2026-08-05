# Windows Advanced Audit Policy & Security Event Logging Baseline (Intune)

**Category:** Intune Solutions · **Solution code:** WINAUDIT · **Version:** 1.0.0 · **Status:** generated

Configures the full **Windows Advanced Audit Policy Configuration** on **Windows 10/11** endpoints via a
single **Intune Settings Catalog** profile — ~24 CIS / Microsoft-aligned audit subcategories, the
force-subcategory override (`SCENoApplyLegacyAuditPolicy`), command-line process auditing (4688), and a
right-sized Security event log. Pilot-first and reversible. Resolves the cluster of "Configure Auditing
for …" / "Audit Logon" findings a Windows client security assessment raises.

## Products & pricing (3 tiers)
| SKU | Audience | Price |
|-----|----------|-------|
| PTK-WINAUDIT-COMM-001 | Commercial | $2,795.00 |
| PTK-WINAUDIT-NPO-001  | Non-Profit (−40%) | $1,677.00 |
| PTK-WINAUDIT-GOV-001  | Government (−15%) | $2,375.75 |

## What's included
- **Documentation** — Executive Summary, Solution Overview, Requirements (+ category Global
  Requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- **5 PowerShell scripts** — `WINAUDIT-Discovery.ps1`, `WINAUDIT-Validation.ps1`, `WINAUDIT-Report.ps1`,
  `WINAUDIT-Remediation.ps1`, `WINAUDIT-Set-ScopeTargeting.ps1` (read-only discovery/validation/reporting;
  remediation + targeting default to `-WhatIf`).
- **Deliverables** — `WINAUDIT-Solution.docx`, `WINAUDIT-Solution.pdf`, `WINAUDIT-Scripts.zip`,
  `WINAUDIT-hero.png`.

## Scope notes
- **Gap-only:** the focused audit-policy **configuration** baseline. Distinct from a broad CIS/STIG
  hardening baseline (much wider) and from the **Entra ID & Intune Audit Telemetry to Microsoft Sentinel**
  solution (log forwarding). This solution is the *source* of events; the Sentinel solution is the
  *transport*.
- **Key object:** one Settings Catalog profile named **`Win Audit Policy - Baseline - Pilot`**, assigned
  to the **`Win Audit Policy - Pilot Devices`** Entra group.
- **The override matters:** the baseline sets *"Force audit policy subcategory settings …"* explicitly so
  advanced subcategories are actually honored; the scripts verify `SCENoApplyLegacyAuditPolicy = 1`.
- **Volume honesty:** Process Creation (4688) and File Share are high-volume; the guide tunes for
  workstations and calls out a server variant.
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

Next: `/publish-solution windows-advanced-audit-policy-security-logging-baseline-intune`
