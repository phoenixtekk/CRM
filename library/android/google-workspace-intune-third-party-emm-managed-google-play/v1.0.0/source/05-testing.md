# 5. Testing & Validation Guide — Google Workspace ↔ Intune Third-Party EMM Integration

Testing proves two things: (A) the integration is **active and healthy**, and (B) enabling it did **not**
cause **unexpected** re-enrollment or loss of management on existing devices. Run these checks on the
**pilot** first and pass every gate before expanding. All test scripts are **read-only**.

> **The re-enrollment result is observed, not assumed.** Every impact check below compares the pilot's
> real state to the Step 2 baseline and asks you to **verify the interpretation against current
> Microsoft/Google guidance and your tenant** — the tests measure; they do not predict.

---

## Test 1 — Binding is active and app sync is healthy
- **How:** Run `ANDROIDGW-Discovery.ps1` (read-only) after Step 6.
- **Pass:** The managed Google Play connection shows a **bound** state, an owning account/organization
  consistent with your Google Workspace domain, and a **recent successful** last app sync.
- **Fail:** Not bound, bound to an unexpected account, or a failed/stale app sync → re-check the Google
  Admin console third-party EMM enablement and the Intune connection (Implementation Steps 5–6).

## Test 2 — Existing-device baseline captured (pre-change)
- **How:** Confirm `Device Impact – Android – Assess` was captured **before** the Google Admin console
  change (Implementation Step 2) with `ANDROIDGW-DeviceImpact.ps1`.
- **Pass:** A saved baseline lists every existing Android device with enrollment type, ownership,
  management state, and last check-in.
- **Fail:** No pre-change baseline → you cannot answer the re-enrollment question objectively. Do **not**
  proceed to broad rollout; recapture on any devices still in the prior state if possible.

## Test 3 — Re-enrollment / impact assessment on the pilot (the critical gate)
- **How:** After the binding is in place, re-run `ANDROIDGW-DeviceImpact.ps1` and **diff** it against the
  Test 2 baseline for the pilot devices — compare enrollment type, management state, and
  enrolled/last-check-in dates per device.
- **Pass:** Pilot devices behave as your **verified expectation** requires (e.g. they keep checking in,
  stay compliant, and did not silently re-enrol or drop out of management), and users report no loss of
  access.
- **Fail:** Any device shows an **unexpected** change (new enrolled date, changed enrollment type,
  fell out of management) that your verification does **not** account for → invoke rollback
  (Implementation Step 10) and reassess.
- **⚠️ Verify:** Confirm whether an observed change is expected against **current Microsoft/Google
  guidance and your tenant** before calling this pass or fail — do not assume.

## Test 4 — End-user experience on the pilot
- **How:** Have pilot users use their devices normally for the agreed observation window; collect what
  they saw (any account prompt, work-profile change, app re-provisioning).
- **Pass:** No unexpected prompts or interruptions beyond what your verified expectation allows; users
  retain access to work apps and data.
- **Fail:** Users hit account-add prompts, lost work profiles, or missing apps not explained by your
  verified expectation → rollback and reassess.

## Test 5 — Account add on a fresh enrollment
- **How:** On a representative pilot device for each enrollment model in scope, have a pilot user add the
  managed Google account and complete enrollment.
- **Pass:** The account adds cleanly and the device enrols in the intended model.
- **Fail:** "Can't add a Google account" / account resolution errors → check identity/account mapping
  (Requirement 2.5) and endpoint reachability (Requirement 2.7); see Troubleshooting.

## Test 6 — App delivery to the pilot
- **How:** Assign a known managed Google Play app to `MGP Pilot – Android – Stage1`; run
  `ANDROIDGW-Validation.ps1` and confirm on-device install.
- **Pass:** The app appears in managed Google Play and installs on pilot devices; `Account Add + App
  Delivery – Pilot – Validation` shows the expected assigned apps and install/compliance state.
- **Fail:** App not synced or not installing → re-check app sync (Test 1) and assignment scope.

## Test 7 — Connection health holds as scope expands
- **How:** During Expand (Implementation Step 9), re-run `ANDROIDGW-Validation.ps1` at each stage to
  refresh `MGP Sync Health – Android – Report`.
- **Pass:** Bind state stays bound, app sync stays successful, and newly-scoped devices deliver apps and
  stay compliant.
- **Fail:** Any regression → pause expansion, investigate, and keep rollback ready.

## Test 8 — Rollback is exercised and understood
- **How:** Confirm the documented rollback (Requirement 2.8 / Implementation Step 10) is written and the
  Google super-admin knows the reversal step; dry-run the decision path.
- **Pass:** A verified rollback procedure exists and returns pilot devices to baseline in a table-top
  check.
- **Fail:** No verified rollback → do not proceed to broad rollout.

---
### Exit criteria (all must hold before Expand)
1. Binding **bound** with a healthy, recent app sync (Test 1).
2. A pre-change device baseline exists (Test 2).
3. Pilot re-enrollment/impact matches your **verified** expectation — no unexpected changes (Test 3).
4. Pilot end-user experience acceptable (Test 4).
5. Account add + app delivery succeed on the pilot (Tests 5–6).
6. A verified rollback is ready (Test 8).

> If any exit criterion fails, **do not expand.** Roll back per current Microsoft/Google guidance, return
> to baseline, and reassess. The value of this solution is a clear, evidence-based impact read — honor it.
