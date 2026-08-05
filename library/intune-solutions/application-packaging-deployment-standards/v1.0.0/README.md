# Application Packaging & Deployment Standards (Win32, MSIX & Store) — v1.0.0

| | |
|---|---|
| Category | Intune Solutions |
| Solution code | APPSTD |
| Commercial | $2,495.00 (`PTK-APPSTD-COMM-001`) |
| Non-Profit | $1,497.00 (`PTK-APPSTD-NPO-001`) |
| Government | $2,120.75 (`PTK-APPSTD-GOV-001`) |
| Branding | off (white-label) |
| Version directive | New |
| Gov variant | false (Government differences documented inline) |

The organisation-wide packaging **specification** that keeps an Intune app catalog consistent,
auditable, and clean at scale — a mandatory naming/version/metadata convention, a format decision tree
(Win32 vs MSIX vs Microsoft Store vs legacy LOB), detection-rule standards with ten banned patterns,
five package quality gates, a peer-review sign-off process with retained evidence, assignment-hygiene
rules, and five Microsoft Graph audit scripts. This is the standards layer **above** per-app packaging
— it complements, and does not duplicate, the `intune-win32-app-packaging-deployment` (WIN32) product.

## What's included

- 9 source documents (overview, requirements, implementation, testing, troubleshooting, best
  practices, deliverables summary, executive summary, category global requirements)
- 5 PowerShell scripts (Microsoft Graph): `APPSTD-Invoke-PackageStandardAudit.ps1`,
  `APPSTD-Test-DetectionRuleQuality.ps1`, `APPSTD-Get-AssignmentHygieneReport.ps1`,
  `APPSTD-Get-PackageMetadataCompleteness.ps1`, `APPSTD-Set-AppMetadataStandard.ps1` (preview by
  default; `-Apply` required to write)
- Deliverables: `APPSTD-Solution.pdf`, `APPSTD-Solution.docx`, `APPSTD-Scripts.zip`,
  `APPSTD-Complete-Solution.zip`, `APPSTD-hero.png`

## Scope note

Scoped to the standards/specification layer to avoid overlap with the existing WIN32 per-app packaging
product. WIN32 teaches how to package/deploy one app; APPSTD governs the org-wide standard (naming,
format decision matrix, detection standards + banned patterns, quality gates, sign-off, assignment
hygiene, intake template, and audit/enforcement over time).

Next: build already done — run `/publish-solution application-packaging-deployment-standards`.
