# 6. Troubleshooting Guide — Proof-of-Concept Kit: Microsoft Defender for Cloud Apps

Common field issues, in **symptom → cause → fix** form. Run `POCMDCA-Enable.ps1 -WhatIf` and `POCMDCA-Validate.ps1` first — most causes surface there. All test signal is benign (sample discovery log + benign policy-matching activity) and everything runs in audit mode.

## Policy scope or action wrong
**Symptom:** The activity policy applies to more than the pilot users, or it has a governance action.
**Cause:** The policy filter was not scoped to `MDCA PoC – Pilot Users – Pilot`, or a governance action was left set.
**Fix:** Edit `MDCA PoC Activity Policy – Pilot Users – Audit` — restrict the filter to the pilot group and set **Governance actions = none**. Re-run `POCMDCA-Enable.ps1 -WhatIf`.

## Signal not generated
**Symptom:** The sample log did not upload, or the benign activity did not register.
**Cause:** The upload used the wrong format/source, or the test account is not in the pilot group.
**Fix:** Use Microsoft's sample Cloud Discovery log with a matching data source in the snapshot report; confirm the test account is in `MDCA PoC – Pilot Users – Pilot`; re-run `POCMDCA-TestSignal.ps1`.

## Discovery report empty
**Symptom:** Test 3 fails — `MDCA PoC Discovery – Pilot – Report` shows no data.
**Cause:** The snapshot report is still processing, or the log/source mismatched.
**Fix:** Allow processing time (discovery reports take time to parse); confirm the sample log matched the chosen data source; re-check `Cloud apps → Cloud discovery → Dashboard`.

## Policy did not match
**Symptom:** Test 4 fails — the audit policy did not match the benign activity.
**Cause:** The activity did not meet the policy filter/threshold, the connector is not yet returning activity, or signal has not propagated.
**Fix:** Confirm the benign action matches the policy's trigger (threshold/activity type); if using a connector, confirm it is returning activity; allow warm-up and re-run `POCMDCA-Validate.ps1`.

## No activity visibility
**Symptom:** Test 5 fails — `Cloud apps → Activity log` or `CloudAppEvents` shows nothing.
**Cause:** No connector/discovery source is feeding activity yet, or hunting tables have not populated.
**Fix:** Confirm a discovery source or connector is active; allow warm-up (tables populate over minutes to hours); confirm `ThreatHunting.Read.All` consent; re-run the validate script.

## No alert surfaced
**Symptom:** Test 6 fails — the policy matched but no alert appears.
**Cause:** The policy's alerting is off, or the alert is still propagating to Incidents & alerts.
**Fix:** Confirm the policy raises an alert on match (alerting can be independent of governance actions); allow propagation time; check both `Cloud apps → Alerts` and **Incidents & alerts**.

## Script cannot authenticate
**Symptom:** `POCMDCA-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, read scopes were not consented, or the account lacks the role.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm **Security Reader** (or Security Administrator for enable/teardown). Re-run.

## Teardown left residue
**Symptom:** After `POCMDCA-Teardown.ps1`, the policy, report, or connector remains.
**Cause:** Teardown ran in `-WhatIf` only, or an item must be removed in the portal.
**Fix:** Run teardown **without** `-WhatIf`; delete the policy, the discovery report `MDCA PoC Discovery – Pilot – Report`, and the connector in `Cloud apps`; resolve the `MDCA-PoC-TESTSIGNAL` alerts; re-confirm with `POCMDCA-Validate.ps1`.
