# 7. Best Practices

## Naming and hygiene
- Keep the `WIFIMGT - <Purpose> - <Platform> - <Stage>` convention on every object and reuse the exact
  name in profiles, assignments, testing, and scripts. It makes audit, handoff, and cleanup trivial.
- One SSID → one active profile per device. Because Intune **won't target two profiles with the same
  SSID to the same device**, never leave an old and a new profile for the same network both assigned —
  supersede and remove the old one.

## Security type
- Prefer **WPA2/WPA3-Personal** over open networks; prefer **WPA2/WPA3-Enterprise (EAP-TLS)** over
  pre-shared keys wherever a certificate + RADIUS chain exists — a leaked PSK is the same on every
  device you deployed it to.
- Treat the **pre-shared key as a secret**: rotate it on a schedule and whenever a device is lost.
  Changing the PSK means updating and redeploying the profile.
- For certificate (Enterprise) networks, deploy the **Wi-Fi profile, client-certificate profile, and
  trusted-root profile to the same groups** so every device can validate the chain — a Microsoft-
  recommended practice. The certificate build itself belongs to the companion Cisco ISE 802.1X product.

## Proxy
- Decide proxy per network **before** authoring, and put the value in the right field: **Manual =
  host/IP + port** (no scheme, no path); **Automatic = PAC URL**. This single discipline prevents the
  most common Wi-Fi failure.
- On Android **personally-owned work profiles**, manual proxy is unavailable — standardize on a **PAC
  URL** for BYOD networks that need a proxy.

## Change management
- Always **pilot first** (`WIFIMGT - Pilot Devices`), validate the three gates, then expand to
  `WIFIMGT - Production Devices`. Keep the pilot assignment in place after expansion.
- Before changing a **trusted root** on an existing enterprise profile, make sure devices have a
  **backup internet path** so the updated profile can be delivered (critical on Android).
- Profile edits apply on the **next device check-in**, not instantly. Don't conclude a change "didn't
  work" until devices have synced — for stuck changes, use the companion *Wi-Fi changes not applying*
  troubleshooting product.
- Document every change (what SSID/security/proxy value changed, when, and the rollback) so an
  expansion can be reversed cleanly.

## Platform parity
- Author all three platforms from the **same network facts** so a user on any device gets the same
  SSID, security, and proxy behavior.
- Re-verify field labels against current Microsoft Learn documentation before large rollouts — Intune
  Wi-Fi templates evolve, and the Settings Catalog exposes additional Wi-Fi settings not in the
  templates.

## Validation as a habit
- Run `WIFIMGT-Report-Connectivity.ps1` on a schedule to catch profiles drifting into Error/Conflict
  as the fleet changes.
- Keep `WIFIMGT-Remediation.ps1` in its default **-WhatIf** preview posture; only pass `-Apply` after
  reviewing exactly which assignments it will add.
