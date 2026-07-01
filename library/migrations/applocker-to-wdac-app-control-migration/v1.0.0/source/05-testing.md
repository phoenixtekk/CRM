# 5. Testing Guide — AppLocker to WDAC (App Control for Business) Migration

Run after each ring's audit policy applies (Implementation Step 5) and again after enforcement
(Step 7) and after AppLocker retirement (Step 8).

## Test 1 — AppLocker baseline captured
Do: Run `WDACMIG-Discovery.ps1` on a representative device in the ring.
Expected: The effective AppLocker policy and its rule collections are reported and exported; current
WDAC state and managed-installer status are shown.

## Test 2 — Audit policy applied
Do: Intune to Endpoint security to App Control for Business to `App Control – Fleet – Audit` to Device
status; on a pilot device run `WDACMIG-Validation.ps1`.
Expected: Pilot devices show Succeeded; the script reports `WDAC ACTIVE (Audit)`.

## Test 3 — Audit events are logging (no enforcement yet)
Do: Exercise line-of-business apps on a pilot device, then run `WDACMIG-Report.ps1 -Days 14`.
Expected: Would-block events (Code Integrity 3076) are captured; nothing is actually blocked; apps
all run because AppLocker still coexists and WDAC is audit-only.

## Test 4 — Migration coverage / audit gate
Do: Run `WDACMIG-Report.ps1` after closing gaps.
Expected: The would-block report is clean of legitimate apps (only genuinely unwanted code remains).
This is the gate to enforce.

## Test 5 — Enforcement active
Do: After promoting to `App Control – Fleet – Enforce`, run `WDACMIG-Validation.ps1`.
Expected: The script reports `WDAC ACTIVE (Enforced)`; required apps run; untrusted code is blocked
(Code Integrity 3077).

## Test 6 — AppLocker retired, WDAC holds
Do: After removing AppLocker on the ring (Step 8), run `WDACMIG-Validation.ps1` and
`WDACMIG-Discovery.ps1`.
Expected: AppLocker rule collections are gone; WDAC remains `ACTIVE (Enforced)`; apps still run.

## Test 7 — Tenant-wide ring/coverage report
Do: Run `WDACMIG-Report.ps1` (tenant/Graph mode) to list App Control policies and assigned ring
groups.
Expected: The audit and enforce profiles are assigned to the expected ring groups, in the expected
order.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Audit gate (must pass before enforce) | Tests 1–4 pass; `WDACMIG-Report.ps1` shows no legitimate would-blocks |
| Pilot pass | Tests 5–6 pass on `App Control Migration – Pilot – Ring 1` |
| Ring expand pass | Tests 2–6 pass for the ring before retiring AppLocker on it |
