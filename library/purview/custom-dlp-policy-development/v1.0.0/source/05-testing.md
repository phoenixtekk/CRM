# 5. Testing Guide — Custom DLP Policy Development (Microsoft Purview)

Run after building the discovery baseline and after each configuration step. Every test is safe (read-only
or a `-WhatIf` preview). Validate on the pilot scope in **simulation** before any move to enforcement.

## Test 1 — Environment discovery is complete
**Do:** Run `DLPCUSTOM-Assess-DlpEnvironment.ps1`; compare its policy/SIT/licensing output against the
Purview portal `Data loss prevention → Policies` and `Billing → Licenses`.
**Expected:** Existing DLP policies, their modes and locations, the available sensitive info types, and the
DLP-relevant licensing all match the portal; you can confirm the SITs your design needs are present.

## Test 2 — Policy creation dry-run makes no changes
**Do:** Run `DLPCUSTOM-New-DlpPolicy.ps1 -PolicyName 'Custom DLP – Sensitive Data – Pilot' -DesignPath .\DlpDesign.json -WhatIf`;
afterward run `Get-DlpCompliancePolicy` and confirm the policy does not exist yet.
**Expected:** The dry-run prints the exact `New-DlpCompliancePolicy` / `New-DlpComplianceRule` it would run
(mode, locations, conditions, exceptions) and the reverse (`Remove-DlpCompliancePolicy`) command; no policy
was created — `-WhatIf` truly changed nothing. Any missing referenced SIT/label is flagged.

## Test 3 — Policy is created in simulation / test mode, on the pilot scope
**Do:** After `-Commit`, run `DLPCUSTOM-Test-DlpPolicy.ps1 -PolicyName 'Custom DLP – Sensitive Data – Pilot'`
(or `Get-DlpCompliancePolicy`/`Get-DlpComplianceRule`).
**Expected:** The policy reports a **test** mode (`TestWithoutNotifications`), is scoped to the **pilot**
locations only, its rule conditions and exceptions match `Custom DLP – Sensitive Data – Design`, and **no
block action is active**. No user is notified and nothing is blocked.

## Test 4 — Simulation generates matches with no user impact
**Do:** After the simulation period, run `DLPCUSTOM-Report-DlpMatches.ps1 -PolicyName 'Custom DLP – Sensitive Data – Pilot'`;
have a pilot user perform a would-match action (e.g. email a test document containing the sample data).
**Expected:** The match is **recorded** in `Custom DLP – Matches – Report`, but the pilot user sees **no
policy tip and no block** (test-without-notifications) — DLP is observing, not enforcing.

## Test 5 — Known-sensitive samples are caught (false-negative check)
**Do:** Seed the pilot scope with **known-sensitive test samples** for each data class the policy targets;
re-run the match report.
**Expected:** Every seeded sample appears as a match — the conditions detect the data they are meant to.
Any miss is a false negative to tune (add/broaden the SIT, lower an over-strict threshold).

## Test 6 — Approved flows are not caught (false-positive / exception check)
**Do:** Have a pilot user perform an **approved** flow that the exceptions cover (e.g. send to an approved
partner domain, or from a service mailbox); review the match report.
**Expected:** The approved flow does **not** register as a policy match — the `ExceptIf…` exceptions hold.
An unexpected match is a false positive to tune (add/adjust the exception, raise confidence/instance count).

## Test 7 — Tuning changes are previewed before applied
**Do:** Run a tuning change with `DLPCUSTOM-New-DlpPolicy.ps1 … -Update -WhatIf`, then `-Commit`; re-run the
match report after re-simulation.
**Expected:** The `-WhatIf` shows the exact `Set-DlpComplianceRule`/`Set-DlpCompliancePolicy` change and its
reverse; after `-Commit` and re-simulation the false-positive/negative counts move in the intended
direction.

## Test 8 — Enforcement cut-over is staged and reversible
**Do:** Move the tuned policy to `TestWithNotifications` (or `Enable` with tips only) via
`DLPCUSTOM-New-DlpPolicy.ps1 … -Update -Mode TestWithNotifications -Commit`; confirm with
`DLPCUSTOM-Test-DlpPolicy.ps1`; then verify an approved flow still succeeds.
**Expected:** Policy tips appear while nothing is blocked; approved flows still work; the script prints the
rollback (`Set-DlpCompliancePolicy -Mode TestWithoutNotifications` / `-Mode Disable`). Only after this does
the restrictive action get enabled.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Simulation pass** | Tests 1–4 pass on the pilot scope: environment discovered, policy created in a test mode with no user impact, matches recorded |
| **Tuning pass** | Tests 5–7 pass: known-sensitive samples caught, approved flows excepted, false-positive/negative rates within the agreed target after tuning |
| **Enforcement pass** | Test 8 passes: staged cut-over (notify → restrict/block), approved flows still succeed, rollback confirmed available — before broadening scope beyond the pilot |
