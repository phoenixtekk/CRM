# Windows Ready Print & Windows Protected Print Mode (WPP) — Intune Deployment

- **Category:** Intune (intune-solutions) · **Code:** WPPRINT · **Version:** 1.0.0 · **Status:** generated · **Branding:** off

## Pricing (new model, T4 implementation)
| Audience | SKU | Price |
|---|---|---|
| Commercial | PTK-WPPRINT-COMM-001 | $899.00 |
| Non-Profit | PTK-WPPRINT-NPO-001 | $539.40 |
| Government | PTK-WPPRINT-GOV-001 | $764.15 |

## What it solves
Deploys Microsoft's modern **driverless** print platform (**Windows Ready Print**) and hardens it with
**Windows Protected Print mode (WPP)** through Intune on **Windows 11 24H2+**. Because enabling WPP
**removes** printers on third-party drivers, it leads with a **compatibility assessment**, then the exact
**Custom OMA-URI** profile (`ConfigureWindowsProtectedPrint = <enabled/>` — not in Settings Catalog yet),
a pilot, and **migration off legacy print servers/Point-and-Print**. Phase 1–7 runbook.

## Included
- Docs: 01 Overview · 02 Requirements (+ intune global) · 03 Deployment Strategy (Phase 1–7) · 05 Testing
  · 06 Troubleshooting · 07 Best Practices · 08 Deliverables · Exec Summary.
- 5 PowerShell scripts (5.1+): WPPRINT-Get-PrintDriverInventory, WPPRINT-Test-MopriaReadiness,
  WPPRINT-Test-ScanCapability, WPPRINT-Get-WPPState, WPPRINT-Validate-Deployment.

## Scope note
CSP + method identical Commercial + GCC/GCC High/DoD (portal intune.microsoft.us). Universal Print
availability differs by sovereign cloud — flagged inline. No Government variant.

## Next
`/publish-solution windows-ready-print-and-protected-print-mode-intune-deployment`
