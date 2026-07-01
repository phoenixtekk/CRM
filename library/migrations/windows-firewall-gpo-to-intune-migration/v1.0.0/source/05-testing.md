# 5. Testing Guide — Windows Firewall GPO to Intune Migration

Run after each ring is assigned (Implementation Step 7) and again before retiring any GPO firewall
settings. The firewall affects connectivity, so every ring must pass before the next.

## Test 1 — Intune policy applied
**Do:** Intune → `Endpoint security` → `Firewall` → `Firewall Policy – Migrated Rules – Pilot` →
`Device status`.
**Expected:** Ring devices show **Succeeded** (also for the `Firewall Rules` profiles).

## Test 2 — Profile defaults match the GPO
**Do:** On a ring device run `FWMIG-Validation.ps1`.
**Expected:** Domain/Private/Public enabled state and default inbound/outbound actions equal the
captured GPO inventory values.

## Test 3 — Rule parity (effective rule set equals the GPO inventory)
**Do:** Run `FWMIG-Validation.ps1` (compares the effective `Get-NetFirewallRule` set against the
captured GPO rule inventory).
**Expected:** Every migrated rule is present with matching direction, action, protocol/ports, program,
and address scope; no expected rule missing, no stray rule.

## Test 4 — Single authority (no double management)
**Do:** Run `FWMIG-Report.ps1` for the ring; on a device check the rule source via
`FWMIG-Validation.ps1`.
**Expected:** Firewall settings come from Intune (MDM) only; the device is out of GPO firewall scope —
no conflict, no merge loop, stable compliance across two check-ins.

## Test 5 — Connectivity preserved
**Do:** Exercise required inbound services (e.g. RDP/Remote Help, a LOB listener) and outbound paths
from a ring device.
**Expected:** All traffic that worked under GPO still works under Intune; nothing newly blocked.

## Test 6 — No merge-loop oscillation
**Do:** Re-run `FWMIG-Validation.ps1` after two device check-ins / a `gpupdate /force` on a migrated
device.
**Expected:** Effective firewall state is identical both times — no flipping values, no reintroduced
GPO rules.

## Test 7 — Coverage report
**Do:** Run `FWMIG-Report.ps1` for the ring.
**Expected:** A clear per-device coverage and conflict report — devices translated, parity status, and
zero conflicts before the gate.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Ring parity pass** | Tests 1–4 and 6 pass; effective Intune rule set equals the GPO inventory with one authority |
| **Connectivity pass** | Test 5 passes — no required service newly blocked |
| **Retire-GPO pass** | Test 7 shows no device depends on the GPO firewall settings (all rings migrated) |
