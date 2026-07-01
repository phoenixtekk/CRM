# 5. Testing Guide — Phased GPO-to-Intune Transition Program

Run the gate for each phase **before advancing to the next**. Every phase boundary is a go/no-go gate;
the program does not skip ahead. Use `scripts\GPOPROG-Validation.ps1 -Phase "<Phase>"` on a device in
that phase's scope and `scripts\GPOPROG-Report.ps1` for the phase-status + conflict report.

## Test 1 — Precedence in effect (MDM wins over GP)
**Do:** On a Phase-1 pilot device run `GPOPROG-Validation.ps1 -Phase "Core OS"`.
**Expected:** `MDMWinsOverGP` reports **ENABLED**; where Intune and GPO set the same setting, the
Intune value is the applied value.

## Test 2 — Core-OS parity on pilot
**Do:** Run `GPOPROG-Validation.ps1 -Phase "Core OS"` (optionally with the GPO XML export for the
migrated areas).
**Expected:** Each migrated core-OS setting is applied by MDM; no migrated area is still driven by the
legacy GPO on the pilot device.

## Test 3 — No conflicts or evaluation loops
**Do:** Run `GPOPROG-Validation.ps1` across the phase scope, then re-run after a policy cycle.
**Expected:** Zero same-setting conflicts; **no flip/loop signature** (no setting alternating between
a GPO value and an Intune value across cycles).

## Test 4 — Stabilization gate (the security go/no-go)
**Do:** After core OS is expanded to broad and soaked, run `GPOPROG-Validation.ps1 -Phase "Core OS"`
and `GPOPROG-Report.ps1` across `Transition Wave – Core OS – Broad`.
**Expected:** Precedence in effect fleet-wide; core-OS parity validated; **zero** open conflicts/loops
on the broad scope. Only when this passes may any security phase begin.

## Test 5 — Firewall phase: parity + no lockouts
**Do:** On a `Transition Wave – Firewall – Pilot` device run `GPOPROG-Validation.ps1 -Phase
"Firewall"`; confirm required network access still works.
**Expected:** Firewall policy applied by Intune; no precedence conflict; **no network lockout** of
required services. Repeat for broad before advancing.

## Test 6 — App-control phase: parity + no required-app block-outs
**Do:** On a `Transition Wave – App Control – Pilot` device run `GPOPROG-Validation.ps1 -Phase "App
Control"`; confirm required apps still launch (review audit-mode events first where used).
**Expected:** App-control policy applied by Intune; no precedence conflict; **no block-out** of
required apps. Repeat for broad before advancing.

## Test 7 — One authority per setting (decommission readiness)
**Do:** Run `GPOPROG-Validation.ps1` across the fleet and `GPOPROG-Report.ps1`.
**Expected:** No migrated setting area is still driven by both authorities; legacy GPOs for migrated
areas are unlinked/scoped away.

## Test 8 — Phase report / KPIs
**Do:** Run `GPOPROG-Report.ps1`.
**Expected:** A per-phase status table (phase, scope group, precedence coverage, open conflicts/loops,
gate state) plus the conflict report — feeding the program KPIs.

---
## Pass/fail gates
| Gate | Requirement |
|---|---|
| **Phase 1 (Core OS pilot)** | Tests 1–3 pass on the core-OS pilot |
| **Phase 2 (Stabilization — security go/no-go)** | Test 4 passes: zero conflicts/loops on broad core OS, precedence fleet-wide. **Security phases blocked until green.** |
| **Phase 3 (Firewall)** | Test 5 passes on pilot then broad (parity, no lockouts) |
| **Phase 4 (App control)** | Test 6 passes on pilot then broad (parity, no required-app block-outs) |
| **Phase 5 (Decommission)** | Tests 7–8 pass: one authority per setting, all phases green |
