# Application Management Current-State Assessment & Modernization Roadmap (Microsoft Endpoint / Intune)

**Category:** Intune Solutions · **SOL code:** APPASMT · **Version:** v1.0.0 · **Branding:** off (white-label)
**Status:** generated · **Version directive:** New

The consultative **entry-point** product for the application-management catalog: a structured,
evidence-based assessment of an organization's current application-management maturity across nine
dimensions, producing a risk-rated findings register and a sequenced modernization roadmap. It
**assesses and sequences**; it does not re-teach the implementation detail of the deeper sibling
products it feeds.

## Products & pricing (T3 — assessment + roadmap archetype)
| SKU | Audience | Price |
|---|---|---|
| PTK-APPASMT-COMM-001 | Commercial | $2,295.00 |
| PTK-APPASMT-NPO-001 | Non-Profit | $1,377.00 (×0.60) |
| PTK-APPASMT-GOV-001 | Government | $1,950.75 (×0.85) |

## What's included
- **Documentation** (Word + PDF): Executive Summary, Solution Overview, Requirements Guide, Global
  Requirements (Intune), Implementation Guide (8 phases), Testing Guide, Troubleshooting Guide, Best
  Practices, Deliverables Summary.
- **5 read-only PowerShell scripts** (Graph `.Read.All` scopes only; Intune Read Only Operator):
  `APPASMT-Estate-Inventory.ps1`, `APPASMT-Assignment-Analysis.ps1`, `APPASMT-Install-Health.ps1`,
  `APPASMT-Unmanaged-Detection.ps1`, `APPASMT-Maturity-Evidence.ps1`.
- **Named artifacts / templates:** Assessment Charter, Maturity Model (9 Dimensions × 5 Levels),
  Artifact Request List, Discovery Interview Guide, Evidence Pack, Scoring Sheet, Findings Register,
  Risk Matrix, Roadmap One-Pager, Wave Plan, Executive Readout.

## Deliverable files (deliverables/)
- `APPASMT-Solution.pdf`, `APPASMT-Solution.docx`
- `APPASMT-Scripts.zip`
- `APPASMT-Complete-Solution.zip`
- `APPASMT-hero.png` / `APPASMT-hero.svg`

## Government
`gov_variant: false` — Government (GCC High / DoD) differs only in endpoints (intune.microsoft.us /
portal.azure.us / graph.microsoft.us, `Connect-MgGraph -Environment USGov`), documented inline in
Requirement 2.7 and every script's `-Environment` switch. No separate Government deliverable required.

## Positioning
Front-door engagement. Findings state remediation **direction + effort** only and reference the deeper
workstreams: `enterprise-application-management-governance-operating-model` (D1),
`application-packaging-deployment-standards` (D2), `application-retirement-offboarding-decommissioning`
(D6), `win32-app-uninstall-removal-failure-remediation`, and
`application-estate-monitoring-reporting-supportability` (D7).
