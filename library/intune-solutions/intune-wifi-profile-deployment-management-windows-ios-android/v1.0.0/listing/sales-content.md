# Sales Content — Intune Wi-Fi Profile Deployment & Management (Windows, iOS & Android)

## Hook
**Every device joins corporate Wi-Fi automatically — on all three platforms.**

Handing users an SSID and a password is slow, inconsistent, and leaks a shared key onto every device.
And the proxy field is a minefield — one URL pasted where a host belongs and the whole network breaks.
This solution deploys **Wi-Fi configuration profiles from Microsoft Intune** to **Windows,
iOS/iPadOS, and Android Enterprise**, so each device connects on its own with the correct network name,
security type, and proxy — authored once per platform, piloted, then expanded to the fleet.

## Run it yourself — simpler, cheaper, and proven
You do **not** need a consultant. The package is self-guided, click-by-click documentation a competent
admin can follow end to end, plus tested PowerShell.

- **Simpler** — exact ordered steps with full navigation for each platform; every object named
  (`WIFIMGT - Corp WiFi - Windows - Pilot`) and reused through testing and troubleshooting.
- **Cheaper** — one fixed price vs an open meter; comparable consulting runs ~$1,500–$3,000/day.
  Reusable on every rollout and every new SSID.
- **Tested** — pilot-first (**Assess → Configure → Pilot → Validate → Expand**) with three pass/fail
  gates: profile deployed, device auto-joins the SSID, proxy applied correctly.

## What's inside
- **Solution Overview** — what a Wi-Fi profile carries (SSID, security type, proxy), cross-platform
  delivery, and where the 802.1X certificate build is deferred to the companion Cisco ISE product.
- **Requirements Guide** — network facts, the proxy decision, roles, per-platform enrollment, Apple
  APNs, managed Google Play, the certificate/RADIUS chain for enterprise networks, pilot/prod groups,
  Government cloud — each with Verify / Implement-if-missing.
- **Implementation Guide** — click-by-click on Windows, iOS/iPadOS, and Android Enterprise
  (corporate-owned and BYOD work profile), with exact field labels; the proxy done right per platform
  (manual = host + port; automatic = PAC URL).
- **5 PowerShell scripts** — preflight, export existing Wi-Fi profiles + assignments, validate which
  devices received the profile, fleet deployment-state report, and guarded remediation (default
  -WhatIf). Cloud-aware for Commercial and US Government.
- **Testing & Troubleshooting Guides** with pass/fail gates, plus Best Practices.

## The repeatable way
Every solution follows the same repeatable shape — buy once, reuse the playbook for the next SSID, the
next platform, and the next project. Unlimited devices.

## The bottom line
Every managed device on every platform joins corporate Wi-Fi automatically and correctly — profiles
delivered from Intune, proven on a pilot before you scale.

## Pricing
- **Commercial:** $2,295.00
- **Non-Profit:** $1,377.00 (40% off; eligibility verified)
- **Government:** $1,950.75 (15% off; eligibility verified)

## Scope boundary
- **This product** = deploy and manage Wi-Fi profiles across Windows + iOS/iPadOS + Android Enterprise
  (author, assign pilot → prod, update/supersede, validate).
- **Cisco ISE 802.1X product** = builds the client certificate + trusted root + RADIUS/EAP-TLS trust
  chain that a WPA-Enterprise profile authenticates against (referenced, not reproduced here).
- **"Wi-Fi changes not applying" product** = deep diagnosis/remediation of profiles that deployed but
  aren't reflected on the device (referenced from troubleshooting, not reproduced here).
