# 5. Testing Guide — Attack Surface Reduction (ASR) Rules

Run during the audit phase (Implementation Step 5) and after switching rules to Block.

## Test 1 — Policy applied
**Do:** Intune → **Endpoint security → Attack surface reduction →** policy → **Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 2 — Rules are in the expected mode
**Do:** On a pilot device run `ASR-Validation.ps1` (reads the active rule IDs/actions).
**Expected:** Each configured rule shows the expected mode (Audit during pilot; Block after enforcement).

## Test 3 — Audit events are generated
**Do:** Trigger a benign test of a rule (e.g. an Office macro spawning a child process on a test doc), then run `ASR-AuditReport.ps1`.
**Expected:** A corresponding **Audit** event (ID 1122) appears — proving the rule is evaluating.

## Test 4 — Block enforces (after switching)
**Do:** With a rule in **Block**, repeat the benign test.
**Expected:** The behavior is **blocked** (event ID 1121); the action is prevented.

## Test 5 — Exclusions work
**Do:** For an excluded legitimate app, perform its normal action.
**Expected:** The app runs without being blocked; the exclusion is honored.

## Test 6 — No business-app breakage
**Do:** Have pilot users run core line-of-business apps with rules in Block.
**Expected:** No legitimate app is blocked (any that is gets an exclusion before fleet rollout).

## Test 7 — Report review
**Do:** Defender portal → **Reports → Attack surface reduction rules** (if MDE onboarded), or `ASR-AuditReport.ps1`.
**Expected:** A clear audit/block event summary you can act on.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Audit pass** | Tests 1–3 pass; false positives identified and excluded |
| **Block pass** | Tests 2, 4–6 pass; no legitimate app blocked |
