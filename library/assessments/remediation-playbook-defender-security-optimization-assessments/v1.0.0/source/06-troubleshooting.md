# 6. Troubleshooting — Remediation Playbook for Defender Security Optimization Assessments

Common failures when remediating, in **symptom → cause → fix** form. Because this playbook changes configuration, several fixes involve **rollback** — always keep the pilot scope small and break-glass excluded.

## `SOAREM-Discovery.ps1` can't map a finding
**Symptom:** Ingest leaves a finding with no mapped remediation.
**Cause:** The findings report is from an unrecognized format/product, or the finding category is not in the map.
**Fix:** Confirm the findings report is a current SOA report (R1). If the category is genuinely new, treat it as a manual remediation and record it; do not force an unrelated fix.

## `-WhatIf` seems to make a change
**Symptom:** You suspect the preview altered something.
**Cause:** This must never happen — `-WhatIf` is preview-only.
**Fix:** Stop using the apply path. Re-read the target to confirm state, and treat any real change under `-WhatIf` as a critical defect (Testing Test 2). Do not proceed until preview is proven harmless.

## Apply fails with an authorization error
**Symptom:** `SOAREM-Remediate.ps1 -Apply` errors on permissions.
**Cause:** The scoped admin role (R5) or the specific write scope (R6) is not granted for the change window.
**Fix:** Request the minimal scoped role (via PIM) and consent the specific write scope for the apply step. Never fall back to standing Global Admin.

## The remediation refuses to enforce
**Symptom:** An approval-gated category (blocking policy, response action, paid plan) will not enforce.
**Cause:** By design — it requires `-ConfirmDisruptive` and applies in monitor/audit first.
**Fix:** Obtain change-approval (R2), review the monitor-mode results, then pass `-ConfirmDisruptive` to move to enforce. This gate is intentional.

## The change hit more than the pilot scope
**Symptom:** Users/resources outside the pilot were affected.
**Cause:** The pilot scope was too broad, or a policy applied tenant-wide instead of to the pilot group.
**Fix:** **Roll back immediately** using the documented rollback (R3). Re-scope to a tighter pilot group and re-run in `-WhatIf` before re-applying. Confirm break-glass was excluded.

## Verification says the control isn't in place
**Symptom:** `SOAREM-Validate.ps1` reports the control missing after an apply.
**Cause 1:** The apply did not complete (transient error), or targeted a different scope than verified.
**Cause 2:** Propagation delay.
**Fix:** Confirm the apply's scope matches the verify's scope. Allow propagation and re-run verify. If still missing, re-apply after reviewing the preview.

## Re-score doesn't move after a verified change
**Symptom:** `SOAREM-Rescore.ps1` shows no score improvement though the control is verified.
**Cause 1:** Warm-up — Secure Score / Defender assessments take time to reflect changes.
**Cause 2:** The fixed control isn't the one the score measures (partial match to the finding).
**Fix:** Allow a warm-up window and re-run the re-score (Global Requirements G5). If still flat, re-check that the remediation targets the exact scored control; the finding may need a deeper solution.

## Rollback leaves a partial state
**Symptom:** Reverting the change doesn't fully restore the prior state.
**Cause:** The rollback step was incomplete, or the change had dependent side effects.
**Fix:** Do not expand the rollout until rollback is proven clean on the pilot (Testing Test 7). Restore from the documented prior configuration; for policy changes, keep the pre-change export to re-import.

## Locked out after a tightening change
**Symptom:** Admins/users can't access after an access/CA/session/RBAC change.
**Cause:** Break-glass was not excluded, or the change was broader than intended.
**Fix:** Use the **break-glass account** (preserved per R3) to sign in and roll back. This is exactly why break-glass exclusion is mandatory before any tightening.
