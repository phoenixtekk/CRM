# 5. Testing & Validation Guide — ITAR DLP Pack (Microsoft Purview)

Test in order. Every gate is **pass/fail** with a defined remediation. The golden rule: **prove detection
and behavior in simulation/test before you enforce**, and re-validate after every change. Use a
**synthetic technical-data test document** (fabricated content carrying the export-control markings/label
your classification targets — **never real ITAR technical data**) for match tests.

> Deploy model: Assess → Design → Configure (**simulate**) → Pilot & tune → Validate → Expand
> (**enforce**). Do not promote a policy to enforce with a failing gate.

## Test 1 — Toolchain & permissions
- **How:** `Connect-IPPSSession`; run `DLPITAR-Discovery.ps1`.
- **Pass:** the script connects, `Get-DlpCompliancePolicy` returns, and the existing-DLP/SIT inventory
  prints.
- **Fail:** "not connected" → install `ExchangeOnlineManagement` and re-run `Connect-IPPSSession` with the
  correct `-ConnectionUri` for your cloud (Requirement 2.3); access denied → confirm the least-privilege
  DLP role (Requirement 2.2).

## Test 2 — Coverage & licensing (scope map)
- **How:** run `DLPITAR-Scope-Health.ps1`.
- **Pass:** `Workload Scope – ITAR DLP – Map` lists the available workloads, endpoint onboarding status,
  and the DLP surfaces your licensing unlocks — with no *unexpected* gaps.
- **Fail:** a required surface (e.g. Endpoint DLP for USB/print) shows unlicensed/not-onboarded → record it
  as a coverage gap and either license/onboard it or de-scope it explicitly (Requirement 2.1, 2.5). Do not
  assume an un-onboarded surface is protected.

## Test 3 — Technical-data detection accuracy (the important one)
- **How:** with the technical-data classification authored (Step 2), test it against (a) a **synthetic
  technical-data document** carrying the export markings/label and (b) a set of **routine documents**
  (general admin, HR, marketing) that should NOT match. Use the portal SIT test pane and/or the pilot
  simulation results in `DLPITAR-Report.ps1`.
- **Pass:** the synthetic technical-data document matches at the configured confidence/instance threshold;
  the routine documents do **not** match.
- **Fail:** routine documents match (over-matching) → raise confidence, add required keyword evidence, or
  prefer the `Export Controlled // ITAR` label condition; technical-data document does not match
  (under-matching) → broaden the marking regex/dictionary or lower the threshold. Re-test until both hold.
  **Tuning detection is expected — budget pilot time for it.**

## Test 4 — Policy created in simulation (non-blocking)
- **How:** after `DLPITAR-Set-Policy.ps1 -Mode TestWithNotifications -Commit`, run
  `DLPITAR-Validation.ps1`.
- **Pass:** the policy `ITAR Technical-Data Egress – AllWorkloads – Pilot` exists with `Mode =
  TestWithNotifications`; the rule `Technical-Data Egress Rule – Markings+Label – v1` is present; users are
  **not** blocked (external send/share of the synthetic technical-data doc succeeds while an alert/tip is
  recorded).
- **Fail:** policy missing → re-run the create with `-Commit`; users blocked in "test" → confirm the mode
  is a `Test*` mode, not `Enable` (rollback with `-Disable -Commit`).

## Test 5 — Simulation evidence is produced
- **How:** trigger a match with the synthetic technical-data document on each in-scope egress path (email
  it externally, share it to an external/consumer address, post it in Teams), then run
  `DLPITAR-Report.ps1`.
- **Pass:** `ITAR DLP Evidence – Egress – Report` shows the simulated matches by workload/recipient and the
  action that *would* have been taken.
- **Fail:** no matches recorded → detection is under-matching (see Test 3), the workload/egress path is out
  of scope (see Test 2), or DLP alert latency (allow time; DLP events can take minutes to surface).

## Test 6 — Validation gates green before enforce
- **How:** run `DLPITAR-Validation.ps1` immediately before promoting.
- **Pass:** scope, rule presence, egress action, and mode all match the design; stakeholders have signed
  off the simulation results (Requirement 2.6).
- **Fail:** any gate red → do not promote; fix in test mode and re-validate.

## Test 7 — Enforcement behaves as designed
- **How:** after `DLPITAR-Set-Policy.ps1 -PromoteToEnforce -Commit`, attempt the same synthetic
  technical-data egress from a pilot-ring account.
- **Pass:** the configured action applies (e.g. external send blocked / external share restricted /
  override prompt shown), an alert is generated, and `DLPITAR-Report.ps1` records the enforced action.
- **Fail:** action not applied → confirm `Mode = Enable` and the rule action; action too broad (blocks
  legitimate internal work) → **rollback immediately** (`-Mode TestWithNotifications -Commit`) and re-tune.

## Test 8 — Rollback works
- **How:** run `DLPITAR-Set-Policy.ps1 -Disable -Commit` (or `-Mode TestWithNotifications -Commit`).
- **Pass:** the policy stops enforcing within the DLP propagation window; the synthetic technical-data
  action succeeds again; the change is stamped in `Change Record – ITAR DLP – ChangeControl`.
- **Fail:** still enforcing → confirm the command committed and allow propagation time; verify with
  `Get-DlpCompliancePolicy`.

## Test 9 — Drift detection
- **How:** run `DLPITAR-Discovery.ps1 -CompareBaseline` after establishing the baseline.
- **Pass:** no unexpected drift; any mode change on the ITAR policy is explained by a recorded change.
- **Fail:** an unexplained `ModeChanged` (e.g. policy moved to `Disable`) → treat as a change-control
  incident and investigate.

---
## Acceptance checklist
- [ ] Toolchain connects; least-privilege DLP role confirmed (Test 1)
- [ ] Scope map produced; coverage gaps recorded, not assumed (Test 2)
- [ ] Technical-data detection matches synthetic marked/labeled doc, not routine docs (Test 3)
- [ ] Policy created in **simulation/test**; users not blocked (Test 4)
- [ ] Simulation evidence produced across in-scope egress paths (Test 5)
- [ ] Validation gates green + stakeholder sign-off before enforce (Test 6)
- [ ] Enforcement behaves as designed (Test 7)
- [ ] Rollback verified and recorded (Test 8)
- [ ] Drift detection running against the baseline (Test 9)
