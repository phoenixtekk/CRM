# Intune Managed App Configuration Policies (iOS & Android) — Zero-Touch App Setup & SSO Routing — v1.0.0

| | |
|---|---|
| Category | Intune Solutions |
| Solution code | APPCFG |
| Commercial | $2,295.00 (`PTK-APPCFG-COMM-001`) |
| Non-Profit | $1,377.00 (`PTK-APPCFG-NPO-001`) |
| Government | $1,950.75 (`PTK-APPCFG-GOV-001`) |
| Branding | off (white-label) |
| Version directive | New |
| Gov variant | false (feature identical in GCC/GCC High; endpoints documented inline) |

Push app settings so managed apps configure themselves on first launch — server host, tenant/realm,
environment, and role pre-filled — and route sign-in to Microsoft Entra ID / Conditional Access.
Cross-platform: iOS/iPadOS managed app configuration (plist) + Android Enterprise managed
configurations, with a full SAP Ariba Procurement worked example. The two delivery channels (managed
devices vs managed apps) explained, plus SSO routing (deferring the CA build to the Conditional Access
solution).

## What's included
- **Guide** (source → PDF + Word): overview, requirements, implementation (iOS + Android + SAP Ariba
  example), testing, troubleshooting, best practices, deliverables summary, executive summary.
- **5 PowerShell scripts** (Microsoft Graph; read-only / -WhatIf by default; cloud-aware Commercial +
  US Gov): `APPCFG-Preflight`, `APPCFG-Get-AppConfigPolicies`, `APPCFG-Validate-Assignment`,
  `APPCFG-Report-AppConfig`, `APPCFG-Remediation`.
- **Templates**: `ios-appconfig.plist`, `ios-appconfig-ariba.plist`, `android-managed-config.json`,
  `android-managed-config-ariba.json` (generic + Ariba placeholder; vendor keys flagged for
  confirmation).

## Deliverables
- `APPCFG-Complete-Solution.zip` — the single bundle attached to all three products (PDF + Word +
  scripts + templates).
- Also built: `APPCFG-Solution.pdf`, `APPCFG-Solution.docx`, `APPCFG-Scripts.zip`, `APPCFG-hero.png`.

## Notes
- **SAP Ariba keys are placeholders** — flagged "verify against SAP Ariba documentation" (authoritative
  source: SAP Ariba Procurement Mobile App Guide → "Configuring SAP Ariba Procurement mobile app in
  Mobile Device Management Tool"). SAP states Ariba is not MDM-certified on Android (iOS only).
- **Dedupe boundary:** owns the App **Configuration** Policy topic — distinct from MAM App
  **Protection**, Android managed-Google-Play app management, and the Conditional Access build (this
  product only routes the app to CA).
