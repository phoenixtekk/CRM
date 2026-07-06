# 5. Testing Guide — Microsoft Defender for Endpoint for macOS (Deployment & Onboarding via Intune)

Run after the pilot objects apply (Implementation Step 10). Tests 1–5 confirm the **capability
profiles landed before onboarding**; Tests 6–9 confirm the **agent is genuinely healthy** — not just
showing a green tick.

## Test 1 — System Extensions profile applied to the pilot
**Do:** Intune → **Devices → macOS → Configuration →** `MDE macOS – System Extensions` **→ Device status**. On the Mac: Terminal `systemextensionsctl list`.
**Expected:** Pilot Macs show **Succeeded**; the Microsoft Defender endpoint-security and network extensions are listed **activated enabled** with no pending user approval.

## Test 2 — Full Disk Access (PPPC/TCC) granted
**Do:** Intune → `MDE macOS – Full Disk Access` **→ Device status**. On the Mac: **System Settings → Privacy & Security → Full Disk Access**.
**Expected:** Profile **Succeeded**; Microsoft Defender appears **granted** Full Disk Access **without** the user having toggled it.

## Test 3 — Network filter profile applied
**Do:** Intune → `MDE macOS – Network Filter` **→ Device status**. On the Mac: **System Settings → General → VPN & Device Management** (or Network) shows the Microsoft Defender content filter present.
**Expected:** Profile **Succeeded**; the Microsoft Defender network extension/content filter is attached and enabled.

## Test 4 — Background services and Notifications profiles applied
**Do:** Intune → `MDE macOS – Background Services` and `MDE macOS – Notifications` **→ Device status**. On the Mac: the user cannot disable Microsoft Defender background items, and Defender can post notifications.
**Expected:** Both profiles **Succeeded**; MDE background daemons are protected and notifications are allowed.

## Test 5 — Capability-before-onboarding gate
**Do:** Confirm Tests 1–4 all pass **before** checking onboarding. On the Mac run nothing new — just verify the five profiles are Succeeded.
**Expected:** All five capability profiles **Succeeded**. Only then is an onboarding pass meaningful.

## Test 6 — Microsoft Defender app installed and onboarding profile applied
**Do:** Intune → `MDE macOS – Defender App` **→ Device install status**; Intune → `MDE macOS – Onboarding` **→ Device status**.
**Expected:** App **Installed**; onboarding profile **Succeeded**.

## Test 7 — Agent health on the device (the real finish line)
**Do:** On a pilot Mac (Terminal): `mdatp health`.
**Expected:** `healthy : true`, `real_time_protection_enabled : true`, `licensed : true`, and onboarding fields true. Run `MACMDE-Validation.ps1 -DeviceName "MAC-001"` for the Intune-side confirmation.

## Test 8 — Cloud connectivity and portal activity
**Do:** On the Mac: `mdatp connectivity test`. In the **Microsoft Defender portal** → **Assets → Devices**, find the pilot Mac.
**Expected:** Connectivity test passes; the Mac appears **onboarded** with **Active** health status (allow ~15–30 minutes after first onboarding).

## Test 9 — Detection test (EDR sensor working)
**Do:** On a pilot Mac, run the Microsoft-documented macOS EDR detection test (a benign test that triggers an alert), then check the Defender portal.
**Expected:** An alert appears for the pilot Mac in the Defender portal, proving the EDR sensor is reporting.

## Test 10 — Fleet posture and drift report
**Do:** Run `MACMDE-Report.ps1`.
**Expected:** A per-object breakdown across the pilot (profiles Succeeded, app Installed, onboarding Succeeded); pilot Macs show no drift.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Capability gate** | Tests 1–5 pass — all five profiles Succeeded **before** onboarding is evaluated |
| **Pilot pass** | Tests 6–9 pass; `mdatp health` reports healthy with extensions running and real-time protection on; device Active in the Defender portal |
| **Production pass** | Tests 1–8 and 10 pass for `MDE macOS – Production Devices` after each rollout wave (profiles first, then app, then onboarding) |
