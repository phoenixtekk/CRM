# Application Retirement, Offboarding & Decommissioning (Microsoft Intune) — v1.0.0

| | |
|---|---|
| Category | Intune Solutions |
| Solution code | APPRET |
| Commercial | $2,295.00 (`PTK-APPRET-COMM-001`) |
| Non-Profit | $1,377.00 (`PTK-APPRET-NPO-001`) |
| Government | $1,950.75 (`PTK-APPRET-GOV-001`) |
| Branding | off (white-label) |
| Version directive | New |
| Government variant | No (endpoint-only difference; documented inline, scripts take `-Environment`) |

The end of the application lifecycle on an Intune-managed Windows fleet: a governed retirement
campaign — signed decision record, impact analysis, data-preservation checkpoint, staged uninstall
waves (pilot to broad), license reclamation, cleanup of every leftover artefact (groups, scripts,
WDAC/App Control rules, Conditional Access references, SCCM remnants), and a decommission evidence
pack that proves the app is genuinely gone — piloted before you scale.

## What's included
- 9 source documents (overview, requirements, global-requirements, 15-step implementation, testing,
  troubleshooting, best-practices, deliverables-summary, executive-summary).
- 5 PowerShell scripts (Microsoft Graph SDK, read-only by default, GCC High/DoD-aware):
  `APPRET-Discovery.ps1`, `APPRET-ImpactAnalyzer.ps1`, `APPRET-WaveReporter.ps1`,
  `APPRET-ArtifactFinder.ps1`, `APPRET-EvidenceExport.ps1`.
- Deliverables: `APPRET-Solution.pdf`, `APPRET-Solution.docx`, `APPRET-Scripts.zip`,
  `APPRET-Complete-Solution.zip`, `APPRET-hero.png`.

## Scope boundary
Owns the retirement PROCESS + planned removal CAMPAIGN. Deep per-device Win32 uninstall FAILURE
debugging belongs to the sibling `win32-app-uninstall-removal-failure-remediation`; installer-level
failures here are escalated as stragglers, not re-diagnosed.

Next: `/publish-solution application-retirement-offboarding-decommissioning`.
