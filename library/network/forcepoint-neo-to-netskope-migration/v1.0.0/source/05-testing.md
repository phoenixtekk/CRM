# 5. Testing Guide — Forcepoint Neo to Netskope Migration (Legacy Web Filtering)

Run per ring after that ring is cut over (Implementation Steps 6-8), and re-run the parity tests
whenever the translated policy changes. The pilot ring must pass before any broad ring; the legacy
agent is removed from a ring only after that ring passes.

## Test 1 — Coexistence is safe (no dual enforcement)
Do: On a passive-stage device run `NSMIG-Validation.ps1`.
Expected: Both agents may be present, but only one is steering — Forcepoint enforces while Netskope is passive. No dual SSL inspection.

## Test 2 — Cutover swapped enforcement
Do: After moving a ring to `Steering Group - Netskope - Enforce`, run `NSMIG-Validation.ps1` on those devices.
Expected: Netskope is steering/enforcing; Forcepoint is no longer steering. Exactly one enforcing agent.

## Test 3 — Allowed traffic still works (parity)
Do: From a cut-over device, browse the allowed URLs in the parity test set.
Expected: Each allowed site loads as it did under Forcepoint — no new over-blocking.

## Test 4 — Blocked categories still blocked (parity)
Do: Browse the blocked-category URLs in the parity test set.
Expected: Each is blocked by Netskope, matching the legacy policy — no under-blocking.

## Test 5 — SSL inspection and exceptions match
Do: Visit SSL-inspected sites and exception URLs from the test set.
Expected: Inspected sites present the expected Netskope certificate; exceptions bypass inspection exactly as the legacy policy did.

## Test 6 — Legacy agent removed cleanly
Do: After `NSMIG-Remediation.ps1` runs for a ring, run `NSMIG-Validation.ps1`.
Expected: Forcepoint Neo is no longer present; Netskope is the sole enforcing agent; the device still filters correctly.

## Test 7 — Coverage and conflict report
Do: Run `NSMIG-Report.ps1`.
Expected: Per-device view of agents present and steering owner; no device is dual-enforced or left unprotected; the `Legacy Estate - Forcepoint Neo - Inventory` count shrinks as rings complete.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Coexistence safe | Test 1 passes for the ring (no dual enforcement) before cutover |
| Pilot parity gate | Tests 2-5 pass on `Migration Ring - Pilot - Cutover` before the legacy agent is removed or any broad ring starts |
| Per-ring complete | Tests 2-6 pass for the ring; report (Test 7) shows it covered with no conflict |
| Decommission gate | Test 7 shows `Legacy Estate - Forcepoint Neo - Inventory` empty and full Netskope coverage before Forcepoint is decommissioned |
