# Intune Wi-Fi Profile Deployment & Management (Windows, iOS & Android)

- **Category:** Intune Solutions (`intune-solutions`)
- **Solution code:** WIFIMGT
- **Version:** v1.0.0 (new solution; version directive: New)
- **Branding:** off (white-label)
- **Status:** generated

## What it is
Deploy and manage **Intune Wi-Fi configuration profiles** across **Windows, iOS/iPadOS, and Android
Enterprise** — SSID, connect-automatically/hidden options, security type (Open, WPA2/WPA3-Personal
pre-shared key, or WPA2/WPA3-Enterprise/802.1X at the deployment level), and proxy (None / Manual
host+port / Automatic PAC URL) — authored per platform, assigned pilot → production, and validated.

## Scope boundary
- Defers the deep 802.1X certificate build (SCEP/PKCS, trusted root, Cisco ISE RADIUS/EAP-TLS) to the
  `cisco-ise-8021x-certificate-wifi-wired-intune` (ISE8021X) product — references those cert objects.
- Defers deep "changes not applying" diagnosis to the sibling WIFIDX troubleshooting product.

## Pricing (T3)
| Tier | SKU | Price |
|---|---|---|
| Commercial | PTK-WIFIMGT-COMM-001 | $2,295.00 |
| Non-Profit | PTK-WIFIMGT-NPO-001 | $1,377.00 |
| Government | PTK-WIFIMGT-GOV-001 | $1,950.75 |

## Included
- **Docs:** 01-solution-overview, 02-requirements (+ global-requirements-intune-solutions),
  03-implementation, 05-testing, 06-troubleshooting, 07-best-practices, 08-deliverables-summary,
  executive-summary.
- **Scripts (5, read-only by default, cloud-aware):** WIFIMGT-Preflight, WIFIMGT-Get-WifiProfiles,
  WIFIMGT-Validate-Assignment, WIFIMGT-Report-Connectivity, WIFIMGT-Remediation (-WhatIf).
- **Deliverables:** `WIFIMGT-Complete-Solution.zip` (Word + PDF + Scripts), plus `WIFIMGT-Solution.pdf`,
  `WIFIMGT-Solution.docx`, `WIFIMGT-Scripts.zip`, `WIFIMGT-hero.png`.

## Government
`gov_variant: false` — Wi-Fi profile fields/navigation match Commercial; only the portal host
(intune.microsoft.us) and Graph endpoint (`-Environment USGov|USGovDoD`) differ, documented inline.
Verify feature rollout for GCC High.

## Verified facts
Field labels/navigation verified against Microsoft Learn (Aug 2026) — Wi-Fi settings for Windows,
Apple (iOS/iPadOS), and Android Enterprise, plus the create-profile navigation. See
`solution.meta.json` → `author_notes` for URLs.
