# Win32 App Uninstall & Removal Failure Remediation (Microsoft Intune)

- **Slug:** `win32-app-uninstall-removal-failure-remediation`
- **Category:** Intune Solutions (`intune-solutions`)
- **Solution code:** `APPUNIN`
- **Version:** v1.0.0
- **Branding:** off (white-label)
- **Status:** generated

## What it is

A branch-based diagnostic playbook and PowerShell toolkit for **Win32 app uninstall / removal
failures** in Microsoft Intune. Scoped deliberately to the **removal path** — the companion product
`intune-app-deployment-troubleshooting` (INTAPPDX) covers the install path only.

## Products & pricing

| SKU | Audience | Price |
|---|---|---|
| `PTK-APPUNIN-COMM-001` | Commercial | $2,495.00 |
| `PTK-APPUNIN-NPO-001` | Non-Profit | $1,497.00 |
| `PTK-APPUNIN-GOV-001` | Government | $2,120.75 |

Non-Profit = round(commercial × 0.60, 2); Government = round(commercial × 0.85, 2).

## What's included

- **Source docs** (`source/`): solution overview, requirements (+ category global requirements),
  the nine-branch Diagnostic Playbook (`03-implementation.md`), testing, troubleshooting, best
  practices, deliverables summary, executive summary.
- **5 PowerShell scripts** (`scripts/`): `APPUNIN-Discovery.ps1`, `APPUNIN-Validation.ps1`,
  `APPUNIN-Report.ps1`, `APPUNIN-LogParser.ps1`, `APPUNIN-Remediation.ps1` (read-only except
  Remediation, which defaults to `-WhatIf`). All Graph scripts accept
  `-GraphEnvironment Global | USGov | USGovDoD`.
- **Deliverables** (`deliverables/`): `APPUNIN-Solution.pdf`, `APPUNIN-Solution.docx`,
  `APPUNIN-Scripts.zip`, `APPUNIN-Complete-Solution.zip`, `APPUNIN-hero.png` / `.svg`.
- **Listing** (`listing/`): `bagisto-products.json` (3 products), `hero.json`, `sales-content.md`.

## Scope note

Owns the **uninstall/removal** path: intent reconciliation (Required beats Uninstall), detection
gating removal on both ends, ProductCode drift (1605), EXE switch/quoting (1603), per-user vs
per-machine/SYSTEM context, app-in-use (1618) and reboot codes (3010/1641), supersedence-driven
uninstall, and reporting/lifecycle (deleted app object orphaning installs). Gap-only relative to
INTAPPDX (install path) per the catalog dedupe rule.

## Government

`gov_variant: false` — removal behaviour is identical in Government tenants; only the console/Graph
endpoints differ (endpoint.microsoft.us / graph.microsoft.us, `Connect-MgGraph -Environment
USGov`/`USGovDoD`). Documented inline in `02-requirements.md` and handled by every script's
`-GraphEnvironment` parameter.
