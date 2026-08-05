# Sales Content — Intune Wi-Fi Profile Remediation (Changes Not Applying)

## The hook
Your Wi-Fi change says **"Succeeded"** — but the devices never changed. You edited a password, added
a proxy, or corrected an SSID, and previously-joined devices keep the old settings no matter how many
times you re-push or sync.

## The core insight (why it happens)
It almost never *failed*. Intune does **not** reliably overwrite a Wi-Fi network a device has already
joined. The payload is **delivered** (hence "Succeeded"), but the live saved network is never
rewritten. Microsoft documents the canonical case: after you change the password on an existing Wi-Fi
profile, *"some users may not get the new profile."* The reliable fix is a **new replacement profile**
and a controlled remove-and-re-add — never an in-place edit.

## Run it yourself — simpler, cheaper, proven
- **Simpler** — a Step-0-plus-branches (A–F) decision tree with full navigation paths; every object
  named (`WIFIDX - WiFi - Corrected - <platform> - Pilot`) and reused throughout.
- **Cheaper** — one fixed price vs an open consulting meter (~$1,500–$3,000/day); reusable on every
  future Wi-Fi change, unlimited devices.
- **Tested** — Assess → Configure → Pilot → Validate → Expand, with pass/fail gates that prove the
  change **applied on a previously-joined device**, not just that Intune reported it.

## The three hard problems it solves head-on
1. **In-place SSID won't update** — why an edited profile doesn't reflect on devices that already knew
   the network; the reliable replacement-profile + remove-and-re-add remediation.
2. **Proxy in the wrong shape** — where the proxy lives per platform, and the #1 mistake: a URL or
   `host/path` in the **manual** field (host + port, never a URL) or a bare host in the **automatic**
   field (a full PAC URL). Verified against Microsoft Learn for Windows and Apple.
3. **Cisco Meraki overriding it** — telling whether the **Meraki dashboard** (wireless/SSID side) or
   **Meraki Systems Manager** (Meraki's competing MDM) is authoritative, with the one-MDM-per-Apple-
   device test that resolves it fast.

## What's inside
- Executive Summary, Solution Overview, Requirements Guide.
- The Diagnostic Playbook: Step 0 + branches A (in-place SSID), B (proxy placement), C (duplicates/
  conflicts), D (Meraki authority), E (reported vs applied), F (platform quirks).
- Testing gates that prove the fix on the device, Troubleshooting, Best Practices.
- 5 PowerShell scripts (read-only by default; cloud-aware for Commercial + US Gov):
  `WIFIDX-Preflight`, `WIFIDX-Get-WifiProfiles` (export + duplicate/conflict detection),
  `WIFIDX-Validate-Device` (on-device applied state), `WIFIDX-Report-ProfileState` (reported vs
  applied), `WIFIDX-Remediation` (guarded, `-WhatIf`).

## Pricing
- Commercial **$2,495** · Non-Profit **$1,497** (40% off) · Government **$2,120.75** (15% off).
- Discounted tiers are verified for eligibility before the discount applies.

## The bottom line
The exact reason your Wi-Fi change isn't reflecting — isolated to one cause — and a repeatable,
low-risk pattern to fix it and prove it applied, on Windows, iOS, and Android.

## Boundaries (honest scoping)
- General config-profile diagnosis (assignment/filters/sync/CSP conflicts) → the Intune Device
  Configuration & Policy Troubleshooting Toolkit.
- 802.1X **certificate** deployment → the certificate-Wi-Fi and Wi-Fi deployment products.
- Meraki console internals → verify against current Cisco Meraki documentation.
