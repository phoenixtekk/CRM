# 5. Testing Guide — Windows Firewall Management

Run after the pilot policy applies (Implementation Step 7) and after each production wave.

## Test 1 — Policy applied
**Do:** Intune → **Endpoint security → Firewall →** `Firewall - Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 2 — All profiles enabled
**Do:** On a pilot device run `WFM-Validation.ps1` or `Get-NetFirewallProfile`.
**Expected:** Domain, Private, and Public profiles all **Enabled = True**.

## Test 3 — Default inbound is Block
**Do:** `Get-NetFirewallProfile | Select Name, DefaultInboundAction, DefaultOutboundAction`.
**Expected:** **DefaultInboundAction = Block**, **DefaultOutboundAction = Allow** for all profiles.

## Test 4 — Legitimate inbound still works
**Do:** Exercise required inbound services (e.g. Remote Help, remote management) on a pilot device.
**Expected:** Allowed services still work (via explicit allow rules); everything else inbound is blocked.

## Test 5 — Rules applied (if a rules policy is used)
**Do:** Run `WFM-RuleReport.ps1`.
**Expected:** The deployed allow/block rules are present and effective.

## Test 6 — No conflicts
**Do:** Run `WFM-ConflictCheck.ps1`; review Intune device → firewall policy status.
**Expected:** No GPO/baseline policy contesting the firewall settings.

## Test 7 — Compliance intact
**Do:** Intune → **Devices → Compliance** (with a firewall compliance rule, if used).
**Expected:** Devices remain **Compliant**; the firewall requirement passes.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; required inbound services confirmed working |
| **Wave pass** | Tests 2–3, 7 pass before the next wave |
