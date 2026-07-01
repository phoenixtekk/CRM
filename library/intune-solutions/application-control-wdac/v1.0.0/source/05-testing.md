# 5. Testing Guide — Application Control (WDAC)

Run during the audit phase (Implementation Step 5) and after switching to Enforce.

## Test 1 — Policy applied
**Do:** Intune → **Endpoint security → Application control →** policy → **Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 2 — Policy active on device
**Do:** On a pilot device run `WDAC-Validation.ps1` (checks for an active App Control policy and its mode).
**Expected:** An App Control policy is active; mode reflects Audit (pilot) or Enforced (post-switch).

## Test 3 — Audit events generated
**Do:** Run an untrusted test binary (a benign unsigned EXE) on an Audit-mode device, then run `WDAC-AuditReport.ps1`.
**Expected:** A Code Integrity **audit** event (3076) is logged for the binary — proving the policy evaluates.

## Test 4 — Enforce blocks untrusted code
**Do:** With the policy **Enforced**, run the same untrusted test binary.
**Expected:** Execution is **blocked** (Code Integrity event 3077); the binary does not run.

## Test 5 — Trusted apps still run
**Do:** With Enforce on, launch all line-of-business apps (deployed via Intune / Store / signed).
**Expected:** All legitimate apps run normally; no false blocks.

## Test 6 — Managed-installer trust works
**Do:** Deploy a new app via Intune to an enforced device and run it.
**Expected:** The Intune-deployed app runs (trusted via managed installer) without manual rules.

## Test 7 — Recovery path works
**Do:** On a test device, unassign the policy in Intune and run `WDAC-Remediation.ps1`.
**Expected:** The enforced policy is removed/cleared and the device returns to normal — confirming rollback.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Audit pass** | Tests 1–3 pass; audit log clean of legitimate-app blocks after trust added |
| **Enforce pass** | Tests 4–6 pass (no false blocks); Test 7 recovery confirmed |
