# 5. Testing & Validation

The single rule of this product: **Intune saying "Succeeded" is not a pass.** A pass is the **new
setting present on a device that previously joined the SSID**. Every gate below is written that way —
it validates *applied* state, not *reported* state. Run them on a **`WIFIDX - Pilot Devices`** member
that already knew `CORP-WIFI`, and only promote to `- Prod` after every gate passes.

Each gate: **What you're proving · How to check · PASS / FAIL.**

---

## Gate 0 — Reproduce and baseline (before any fix)

**Proving:** the problem is real and you have a device that shows it.
**How to check:** On a previously-joined device, read the live setting — Windows:
`WIFIDX-Validate-Device.ps1`; Apple: **Settings → Wi-Fi → (i) next to CORP-WIFI**; Android: saved
network details. Compare to Intune → profile → **Device status**.
- **PASS (problem confirmed):** Intune shows **Succeeded** *and* the device still shows the **old**
  value. (This is the Branch A/E signature — proceed to fix.)
- **FAIL (different problem):** Intune shows **Error / Not applicable**, or the device isn't syncing →
  this is a delivery/assignment problem — go to the configuration toolkit first, not this playbook.

---

## Gate 1 — Corrected replacement profile exists and is scoped (Branch A)

**Proving:** you built a **new** profile rather than editing the old one in place.
**How to check:** Intune → **Devices → Configuration** → confirm **`WIFIDX - WiFi - Corrected -
<platform> - Pilot`** exists, has the corrected settings, and is assigned to **`WIFIDX - Pilot
Devices`** only. Confirm the **old** profile is unassigned from that group.
- **PASS:** the corrected profile exists and is the **only** Intune Wi-Fi profile targeting
  `CORP-WIFI` on the pilot devices.
- **FAIL:** you edited the original in place, or both old and new profiles still target the group
  (→ Branch C).

---

## Gate 2 — The change is APPLIED on a previously-joined device (the core gate)

**Proving:** the device that already knew `CORP-WIFI` now has the **new** value — the exact failure
this product exists to fix.
**How to check:** Force a sync, allow one check-in cycle, then read the live saved network:
- **Windows:** `WIFIDX-Validate-Device.ps1` — the saved profile / effective proxy shows the new value.
- **iOS/iPadOS:** **Settings → Wi-Fi → (i)** shows the new proxy/settings; management profile lists
  the corrected payload.
- **Android:** saved-network details show the new value.
- **PASS:** the **new** value is present on a **previously-joined** device (not just a fresh one).
- **FAIL:** the device still shows the old value → the stale saved network was not replaced; run
  `WIFIDX-Remediation.ps1 -WhatIf:$false` to remove the stale saved network (or unassign/reassign on
  Apple/Android) and re-test.

---

## Gate 3 — Proxy is in the correct shape and effective (Branch B)

**Proving:** the proxy is in the right mode and field, and traffic actually works.
**How to check:** `WIFIDX-Get-WifiProfiles.ps1` shows the profile's proxy mode/value; confirm:
- **Manual** = host/IP + port, with **no** `http://` and **no** `/path`.
- **Automatic** = a full **PAC URL** (scheme + `.pac`) the device can reach.
Then on the device, confirm the **effective** proxy (Windows: `WIFIDX-Validate-Device.ps1`; Apple:
**Wi-Fi → (i) → HTTP Proxy**) and that browsing/authentication succeeds over `CORP-WIFI`.
- **PASS:** proxy value is correctly shaped, effective on the device, and traffic works.
- **FAIL:** a URL/slash sits in a manual field, a bare host sits in an automatic field, or the PAC URL
  is unreachable → correct the shape in the replacement profile and re-test.

---

## Gate 4 — Exactly one Wi-Fi authority for the SSID (Branches C & D)

**Proving:** only one system/profile owns `CORP-WIFI` on the device.
**How to check:** `WIFIDX-Get-WifiProfiles.ps1` confirms a single Intune profile per SSID per device.
If Meraki is present: on Apple, **Settings → General → VPN & Device Management** shows a single MDM of
record; confirm no second (Meraki SM) Wi-Fi payload for `CORP-WIFI`, and that any dashboard-enforced
setting is intended.
- **PASS:** one Intune Wi-Fi profile owns the SSID; no competing Intune profile and no competing
  Meraki SM payload; dashboard enforcement (if any) is deliberate.
- **FAIL:** duplicate Intune profiles, or a Meraki SM payload also targets the SSID → resolve to a
  single authority (Branch C/D).

---

## Gate 5 — Reported vs applied reconciled (Branch E)

**Proving:** the console now matches reality.
**How to check:** `WIFIDX-Report-ProfileState.ps1` — the previously-mismatched device now reads
**Succeeded / applied-match**. On Android where a profile "failed but worked," confirm the Intune app
is **2021.05.02 or later**.
- **PASS:** reported and applied state agree for the pilot devices.
- **FAIL:** still Succeeded/applied-mismatch → return to Gate 2 (application gap) or Branch D (wrong
  authority).

---

## Gate 6 — New-device regression

**Proving:** the fix also works for devices that never had the old network.
**How to check:** On a freshly-enrolled device that **never** joined `CORP-WIFI`, confirm the
corrected profile installs the network with the new value on first sync.
- **PASS:** new device gets the correct network first time.
- **FAIL:** new device also wrong → the profile itself (not the stale-network problem) is
  misconfigured → re-check Branch B and the profile settings.

---

## Promotion gate — Pilot → Production

Only after Gates 0–6 pass on the pilot group:
1. Rename/duplicate the corrected profile to **`WIFIDX - WiFi - Corrected - <platform> - Prod`** and
   assign it to the production group.
2. Remove every superseded/old Wi-Fi profile for `CORP-WIFI` from production.
3. Re-run `WIFIDX-Report-ProfileState.ps1` against production and confirm applied-state matches for a
   sample of **previously-joined** production devices before declaring done.
