# 5. Testing Guide — Microsoft Purview Optimization & Tune-Up

Run after the noise baseline and after each tuning change. Every test is safe; the simulation-mode check
and the **true-positive probe** are the gates before any policy is re-enforced. All commands are
`Connect-IPPSSession` / `Connect-ExchangeOnline`.

## Test 1 — Inventory and current mode are captured
**Do:** Run `OPSOPT-Discovery.ps1`; compare against the Purview portal policy list.
**Expected:** Every DLP, auto-labeling, and alert policy appears with its correct **Mode/threshold**;
audit ingestion state is reported. Matches the portal.

## Test 2 — Noise baseline is quantified
**Do:** Run `OPSOPT-Report.ps1 -Days 30 -OutputFolder .\OPSOPT-out`; inspect `dlp-noise-by-rule.csv`.
**Expected:** Rules are ranked by match volume with an **override / reported-false-positive rate** per
rule; the noisiest rules are identifiable (confirms Requirement 2.4).

## Test 3 — A change lands in simulation, not enforce
**Do:** Run `OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -ToSimulation -Commit`; re-run
`OPSOPT-Discovery.ps1`.
**Expected:** The policy Mode is a **Test** mode (`TestWithoutNotifications`) — it is **not** enforcing
while tuned. No user notifications were sent.

## Test 4 — Dry-run makes no changes
**Do:** Run `OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -Rule "PII - High Volume" -MinConfidence High
-WhatIf`; afterward re-run `OPSOPT-Discovery.ps1`.
**Expected:** The dry-run prints the intended `Set-DlpComplianceRule` change; the rule's confidence is
**unchanged** — `-WhatIf` truly changed nothing.

## Test 5 — Rollback baseline is recorded before a commit
**Do:** Run a tuning `-Commit`; inspect `.\OPSOPT-out\rollback-<policy>.json`.
**Expected:** The file records the **prior** confidence/instance/threshold/mode values before the change
— rollback is possible.

## Test 6 — False positives drop after tuning
**Do:** After the observation window, re-run `OPSOPT-Report.ps1` and compare `dlp-noise-by-rule.csv`
before vs after for each tuned rule.
**Expected:** The tuned rule's match volume and override/false-positive rate are **lower**.

## Test 7 — The true-positive probe still fires (signal not lost)
**Do:** Run `OPSOPT-Validation.ps1 -OutputFolder .\OPSOPT-out` with a known-sensitive sample (or a
labeled prior true match) in scope.
**Expected:** The tuned rule **still matches** the genuinely sensitive item — proving the tuning removed
**noise, not signal**. A FAIL here blocks re-enforcement.

## Test 8 — Alert noise is reduced
**Do:** Run `OPSOPT-Report.ps1`; compare `alert-volume.csv` before vs after tuning the alert policy.
**Expected:** Alert volume for the tuned policy drops to the raised-threshold / aggregated level;
recipients are trimmed to those who act.

## Test 9 — Rollback works
**Do:** Run `OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -Rollback`; re-run `OPSOPT-Discovery.ps1`.
**Expected:** The policy/rule returns to its recorded prior values — the change is fully reversible.

## Test 10 — Re-enforce is a separate, validated step
**Do:** Only after Tests 6–7 pass, run `OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -Enforce -Commit`.
**Expected:** `Get-DlpCompliancePolicy | Select Name,Mode` shows **Enable** — the tuned policy is
enforcing again, with the noise removed. No policy that failed Test 7 is here.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Tuning pass** | Tests 1–5 pass; every change is in simulation with a rollback baseline recorded, nothing enforced blind |
| **Validation pass** | Tests 6–8 pass **and** Test 7 (true-positive probe) passes for every tuned policy — false positives down, signal retained |
| **Enforce pass** | Test 10 passes only for policies that cleared the Validation gate; failed policies are rolled back (Test 9), not enforced |
