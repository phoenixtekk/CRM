# 6. Troubleshooting Guide — Proof-of-Concept Kit: Microsoft Defender for Cloud

Common field issues, in **symptom → cause → fix** form. Run `POCMDC-Enable.ps1 -WhatIf` and `POCMDC-Validate.ps1` first — most causes surface there. All test signal is benign (sample alerts + a benign misconfigured test resource + EICAR).

## Plan not enabling
**Symptom:** CSPM or the workload plan does not turn **On** for the pilot subscription.
**Cause:** Insufficient role (needs Security Admin/Contributor/Owner), the wrong subscription is selected, or a policy blocks the change.
**Fix:** Confirm your role on the pilot subscription (**Access control (IAM)**); select the correct subscription (`Set-AzContext`); re-run `POCMDC-Enable.ps1 -WhatIf` and check the reported gaps.

## Signal not generated
**Symptom:** Sample alerts, the test resource, or EICAR did not generate.
**Cause:** The sample-alert action targeted the wrong subscription, the test-resource deployment failed (naming/quota), or the pilot VM is not covered by Defender for Servers.
**Fix:** Create sample alerts against the pilot subscription; confirm the test resource deployed in `MDC PoC – Pilot RG – Pilot`; confirm the VM is covered before using EICAR. Re-run `POCMDC-TestSignal.ps1`.

## No recommendation
**Symptom:** Test 3 fails — the misconfiguration does not raise a recommendation.
**Cause:** CSPM assessment has not run yet, or the resource is not actually misconfigured in an assessed way.
**Fix:** Allow assessment warm-up (recommendations populate over time); confirm the test resource has the intended misconfiguration (e.g. public blob access); re-run `POCMDC-Validate.ps1`.

## No Secure Score
**Symptom:** Test 4 fails — Secure Score returns nothing.
**Cause:** Assessment is too recent, or the account lacks read permission.
**Fix:** Allow warm-up; confirm **Security Reader** on the subscription; re-run `Get-AzSecuritySecureScore` via `POCMDC-Validate.ps1`.

## No security alert
**Symptom:** Test 5 fails — no sample or EICAR alert appears.
**Cause:** Sample alerts were created on a different subscription, the workload plan is off, or the alert is still propagating.
**Fix:** Recreate sample alerts on the pilot subscription; confirm the workload plan is **On**; allow propagation time; check **Security alerts** and re-run `POCMDC-Validate.ps1`.

## No compliance data
**Symptom:** Test 6 fails — Regulatory compliance shows nothing for the pilot subscription.
**Cause:** The compliance assessment has not populated, or the default benchmark is not applied.
**Fix:** Allow warm-up; confirm the Microsoft Cloud Security Benchmark is applied to the subscription; re-check **Regulatory compliance**. *Some standards are plan-gated — verify availability.*

## Script cannot authenticate
**Symptom:** `POCMDC-*.ps1` fails on connect or returns access-denied.
**Cause:** The Az modules are missing, you are not signed in, or the account lacks the role.
**Fix:** Let the script install the modules (it checks on run); `Connect-AzAccount` and `Set-AzContext` to the pilot subscription; confirm **Security Reader** (read) / **Security Admin + Contributor** (enable/teardown). Re-run.

## Teardown left residue
**Symptom:** After `POCMDC-Teardown.ps1`, the test resource remains or the plan is still **On** (still billing).
**Cause:** Teardown ran in `-WhatIf` only, or a delete/disable failed on a permission.
**Fix:** Run teardown **without** `-WhatIf`; confirm the plan shows **Off** in **Environment settings → Defender plans** (this stops billing); delete `MDC PoC Test Resource – Pilot RG – Pilot` (and the RG if PoC-only); resolve the `MDC-PoC-TESTSIGNAL` alerts; re-confirm with `POCMDC-Validate.ps1`.
