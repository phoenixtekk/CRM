# Windows Domain Secure-Channel & Netlogon Health Diagnostics Toolkit

**Category:** Intune Solutions · **Solution code:** NETLOGONDX · **Version:** 1.0.0 · **Status:** generated

An **endpoint diagnostics toolkit** (read-heavy PowerShell) that pinpoints and repairs the root cause of
**Netlogon Event ID 5719** / a **broken domain secure channel** on domain-joined Windows devices, and
restores **IPv6 to a recommended configuration**. Runs **locally** on the affected device or **at scale
via Intune Proactive Remediations**. Read-only by default; the repair script defaults to `-WhatIf`.

## Products & pricing (3 tiers)
| SKU | Audience | Price |
|-----|----------|-------|
| PTK-NETLOGONDX-COMM-001 | Commercial | $2,495.00 |
| PTK-NETLOGONDX-NPO-001  | Non-Profit (−40%) | $1,497.00 |
| PTK-NETLOGONDX-GOV-001  | Government (−15%) | $2,120.75 |

## What's included
- **Documentation** — Executive Summary, Solution Overview, Requirements (+ category Global
  Requirements), Implementation, Testing, Troubleshooting, Best Practices, Deliverables Summary.
- **5 endpoint PowerShell scripts** — `NETLOGONDX-Discovery.ps1`, `NETLOGONDX-Validation.ps1`,
  `NETLOGONDX-Report.ps1`, `NETLOGONDX-Remediation.ps1`, `NETLOGONDX-Collect.ps1`
  (Discovery/Validation/Report/Collect are read-only; Remediation defaults to `-WhatIf`).
- **Deliverables** — `NETLOGONDX-Solution.docx`, `NETLOGONDX-Solution.pdf`, `NETLOGONDX-Scripts.zip`,
  `NETLOGONDX-hero.png`.

## Scope notes
- **Gap-only:** a **diagnostics toolkit** (sibling of the endpoint performance/diagnostics toolkits),
  **not** a configuration baseline and **not** a domain-controller health tool. Resolves the two
  availability findings: **Event ID 5719 (Netlogon)** and **IPv6 recommended configuration**.
- **Root-cause tree covered:** DNS/DC-locator (SRV records), secure channel/trust password, Kerberos
  time skew, DC ports 88/135/389/445, no DC path, boot-time NIC/power-management race, and IPv6.
- **IPv6:** keep it **enabled** (dual-stack `0x0`); correct **invalid** `DisabledComponents` (e.g.
  `0xffffffff`) back to a supported value; never disable IPv6 (breaks DirectAccess/Remote
  Assistance/HomeGroup, unsupported by Microsoft testing).
- **Scripts are endpoint PowerShell** (in-box commands only) — run locally or as SYSTEM via Intune
  **Proactive Remediations** (Validation = detection, Remediation = remediation).
- **Branding:** off (white-label). **Version directive:** New. **Gov:** price-only this run
  (Commercial-only deliverable).

## Files
```
source/            8 markdown docs + global-requirements-intune-solutions.md
scripts/           5 PowerShell scripts (endpoint)
listing/           bagisto-products.json, hero.json, sales-content.md
solution.meta.json
```

Next: `/publish-solution windows-domain-secure-channel-netlogon-health-diagnostics`
