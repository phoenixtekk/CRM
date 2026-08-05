# Intune Wi-Fi Profile Remediation — Changes Not Applying (Proxy, SSID & Meraki)

**Category:** Intune Solutions · **Version:** v1.0.0 · **Solution code:** WIFIDX · **Branding:** off (white-label)

A symptom-driven diagnostic/remediation playbook for Intune **Wi-Fi configuration profiles that will
not update or reflect a change** across Windows, iOS/iPadOS, and Android — with **proxy placement** and
**Cisco Meraki** as the worked scenarios.

## Products & pricing
| Audience | SKU | Price |
|---|---|---|
| Commercial | PTK-WIFIDX-COMM-001 | $2,495.00 |
| Non-Profit | PTK-WIFIDX-NPO-001 | $1,497.00 |
| Government | PTK-WIFIDX-GOV-001 | $2,120.75 |

Pricing tier **T3** (Wi-Fi profile diagnostic toolkit; parity with INTCFG/INTAPPDX). Non-Profit =
round(2495×0.60,2); Government = round(2495×0.85,2).

## What's included
- **Docs:** executive-summary, 01-solution-overview, 02-requirements,
  global-requirements-intune-solutions, 03-implementation (Step 0 + branches A–F), 05-testing,
  06-troubleshooting, 07-best-practices, 08-deliverables-summary.
- **5 scripts (read-only by default; cloud-aware `-Environment Global|USGov|USGovDoD`):**
  `WIFIDX-Preflight.ps1`, `WIFIDX-Get-WifiProfiles.ps1`, `WIFIDX-Validate-Device.ps1`,
  `WIFIDX-Report-ProfileState.ps1`, `WIFIDX-Remediation.ps1` (guarded, `-WhatIf`).
- **Deliverables:** `WIFIDX-Complete-Solution.zip` (PDF + Word + scripts), plus `WIFIDX-Solution.pdf`,
  `WIFIDX-Solution.docx`, `WIFIDX-Scripts.zip`, and `WIFIDX-hero.png`.

## Key verified facts (with sources)
- **Crux — no reliable in-place SSID update.** After changing a password on an existing Wi-Fi profile,
  Microsoft states *"some users may not get the new profile."* "Succeeded" = delivered, not applied.
  Reliable fix = new/replacement profile + remove-and-re-add.
  ([MS Learn — Troubleshoot Wi-Fi profiles](https://learn.microsoft.com/en-us/troubleshoot/mem/intune/device-configuration/troubleshoot-wi-fi-profiles))
- **Proxy shape.** Manual = host/IP + port (not a URL); Automatic = full PAC URL. Windows
  ([ref-wifi-settings-windows](https://learn.microsoft.com/en-us/intune/device-configuration/templates/ref-wifi-settings-windows)),
  Apple ([ref-wifi-settings-apple](https://learn.microsoft.com/en-us/intune/device-configuration/templates/ref-wifi-settings-apple)).
- **Meraki.** Meraki SM Wi-Fi payload proxying is Apple-only; distinguished Meraki dashboard (network
  side) from Meraki Systems Manager (competing MDM).
  ([Meraki SM Wi-Fi Settings Payload](https://documentation.meraki.com/Platform_Management/SM_-_Endpoint_Management/Design_and_Configure/Profiles_and_Settings/Systems_Manager_Wi-Fi_Settings_Payload))

## Government decision
`gov_variant: false` — behavior identical in GCC/GCC High/DoD; only portal/Graph endpoints differ,
documented inline. GCC High uncertainties flagged "verify for GCC High".

## Dedupe boundary
Owns Wi-Fi-profile **changes-not-reflecting** only. Defers general config-profile diagnosis to INTCFG;
defers 802.1X certificate deployment to the certificate-Wi-Fi (ISE8021X) and Wi-Fi deployment sibling.
