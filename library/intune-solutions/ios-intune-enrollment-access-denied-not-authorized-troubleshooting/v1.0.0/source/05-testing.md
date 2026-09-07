# Testing & Validation

Validation is objective: the same failed enrollment sign-in that produced the "Access Denied" screen must
now show **Success**, and the device must appear in Intune.

## Test 1 — Reproduce and capture (baseline)
1. On the affected iOS/iPadOS device, attempt enrollment and reproduce the **"Access Denied / not
   authorized"** screen. Record the **Activity Id**, **Session Id**, **Timestamp**, and UPN.
2. **Pass criteria:** you have a captured failure with correlation IDs to anchor the diagnosis.

## Test 2 — Root cause is identified from evidence (not guessed)
1. Run **`ENRLDX-Get-EnrollmentSignin.ps1`** (with `-CorrelationId` where possible). Confirm it returns
   the failed enrollment sign-in with a **failure reason** and the CA result.
2. **Pass criteria:** exactly one gate is named — license (2A), MDM scope (2B), restriction (2C), CA
   (2D), or account (2E) — supported by the sign-in log and the matching gate script.

## Test 3 — Gate script confirms the finding
1. Run the gate-specific script for the identified cause and confirm it reports the blocking condition:
   - **2A** `ENRLDX-Get-UserIntuneLicense.ps1` → Intune plan NOT enabled.
   - **2B** `ENRLDX-Get-MdmUserScope.ps1` → scope None, or user not in the scoped group.
   - **2C** `ENRLDX-Get-EnrollmentRestrictions.ps1` → iOS/personal blocked, or device limit reached.
   - **2D** `ENRLDX-Get-EnrollmentCA.ps1` → a blocking/incompatible CA policy targets the enrollment apps.
2. **Pass criteria:** the script's output matches the sign-in failure reason. Two independent signals agree.

## Test 4 — Remediation applied (single, scoped change)
1. Apply only the remediation for the identified gate (Phase 2A–2E). Record the exact change made.
2. **Pass criteria:** one change, matching the named gate, with an approved change record.

## Test 5 — Clean re-enrollment (the definitive test)
1. Remove the management profile on the device and retry enrollment (Company Portal for BYO; Setup
   Assistant for ADE).
2. Re-run **`ENRLDX-Get-EnrollmentSignin.ps1`**.
3. **Pass criteria:** the enrollment sign-in for the user now shows **Success**; the device appears in
   **Intune → Devices**; the "Access Denied" screen no longer appears.

## Test 6 — No collateral impact
1. Confirm the change did not open a hole: an enrollment restriction still blocks unintended platforms;
   a CA exclusion is scoped to the enrollment apps only, not broadened globally.
2. **Pass criteria:** the fix is surgical — other users/platforms/policies behave exactly as before.

## Evidence to keep
- The before (failed) and after (success) enrollment sign-ins.
- The gate-script output naming the cause.
- The change record and the device now visible in Intune.
