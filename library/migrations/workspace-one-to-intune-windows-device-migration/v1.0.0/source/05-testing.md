# 5. Testing Guide — Workspace ONE to Intune (Windows Device Migration)

Run after the pilot ring cuts over (Implementation Step 8) and again for each broad wave. The goal of
every test is to prove the device is managed by **only** Intune, has **parity**, is **compliant**, and
keeps **access**.

## Test 1 — Source MDM removed (no Workspace ONE)
**Do:** On a migrated device run `WS1WIN-Discovery.ps1`; in Intune check
`Devices > Windows > Windows devices` for the device.
**Expected:** No Workspace ONE MDM enrollment remains; the device shows a single MDM authority.

## Test 2 — Enrolled in Intune (single authority)
**Do:** Run `WS1WIN-Validation.ps1` on the device.
**Expected:** Exactly one MDM enrollment, and it is Intune; no dual-enrollment warning.

## Test 3 — Parity configuration applied
**Do:** Intune → `Devices > Windows > Configuration` → `Parity Configuration – Windows – Migration` →
`Device status`; and run `WS1WIN-Validation.ps1`.
**Expected:** The device reports the parity profile(s) as `Succeeded`/applied; key settings match the
Workspace ONE baseline.

## Test 4 — Compliance green
**Do:** Intune → `Devices > Compliance > Compliance Policy – Windows – Migration > Device status`; and
run `WS1WIN-Report.ps1`.
**Expected:** The migrated device is `Compliant` (not `Not evaluated` / `Not compliant`).

## Test 5 — Conditional Access continuity (access works)
**Do:** From the migrated, compliant device sign in to a Conditional Access target resource.
**Expected:** Access is granted; `Conditional Access Continuity – Windows – Migration` shows the device
satisfied the `compliant device` grant. The Entra sign-in log confirms the policy applied.

## Test 6 — No dual management across the ring
**Do:** Run `WS1WIN-Report.ps1` for the whole ring.
**Expected:** No device appears with both a Workspace ONE and an Intune enrollment; none appear
unmanaged.

## Test 7 — Ring targeting correct
**Do:** Run `WS1WIN-Set-MigrationRingTargeting.ps1` with `-WhatIf` and review the report.
**Expected:** Pilot members are in `Group – Migration Pilot – Windows`; broad members in
`Group – Migration Broad – Windows`; un-migrated devices remain in `Group – Workspace ONE Managed –
Windows`.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass (gate before broad)** | Tests 1–5 pass for **every** device in `Migration Ring – Pilot – Windows`; no device dual- or un-managed (Test 6) |
| **Broad wave pass** | Tests 1–4 and 6 pass for the wave before the next wave begins; access (Test 5) spot-checked |
| **Migration complete** | `Group – Workspace ONE Managed – Windows` empty; all devices single-MDM (Intune), parity applied, compliant |
