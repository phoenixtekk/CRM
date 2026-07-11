# 6. Troubleshooting Guide — Proof-of-Concept Kit: Microsoft Defender for Office 365

Common field issues, in **symptom → cause → fix** form. Run `POCMDO-Enable.ps1 -WhatIf` and `POCMDO-Validate.ps1` first — most causes surface there. All test signal is benign (Attack Simulation / GTUBE / EICAR / benign test URL).

## Preset scope wrong
**Symptom:** The Standard preset applies org-wide or to the wrong recipients.
**Cause:** The preset recipient scope was not restricted to `MDO PoC – Pilot Users – Pilot`, or a prior preset already covers the org.
**Fix:** In **Policies & rules → Preset security policies**, set the Standard preset recipients to the pilot group only; confirm no broader preset overlaps. Re-run `POCMDO-Enable.ps1 -WhatIf`.

## Test message not delivered
**Symptom:** A GTUBE / EICAR / Safe Links test message never arrives at the pilot mailbox.
**Cause:** The message was blocked before delivery (expected for EICAR/GTUBE — check quarantine), the sending account is not permitted, or mail flow is misrouted.
**Fix:** Check **Review → Quarantine** — EICAR/GTUBE messages are *meant* to be caught; that is a pass, not a delivery failure. Confirm the sender and Exchange Online mail flow. Re-run `POCMDO-TestSignal.ps1`.

## Safe Links not rewriting
**Symptom:** Test 3 fails — the benign test URL is not rewritten in the pilot mailbox.
**Cause:** The preset is not applied to the pilot users, Safe Links is off in the applied policy, or the message bypassed policy (e.g. internal sender exceptions).
**Fix:** Confirm the Standard preset covers the pilot users and Safe Links is enabled; send the link from an external test sender; allow a moment and re-check `UrlClickEvents` with `POCMDO-Validate.ps1`.

## Safe Attachments not detonating
**Symptom:** Test 4 fails — the EICAR attachment is delivered without action.
**Cause:** Safe Attachments is not in the applied preset, the MDO plan is not licensed, or the file was stripped upstream.
**Fix:** Confirm Safe Attachments is on for the pilot users and the MDO plan is licensed (P1+); resend the EICAR attachment; check `EmailAttachmentInfo`. *Verify current plan features.*

## GTUBE not actioned
**Symptom:** Test 5 fails — the GTUBE spam-test message lands in the inbox.
**Cause:** Anti-spam policy is not applied to the pilot users or an allow-rule/safe-sender overrides it.
**Fix:** Confirm anti-spam (EOP) applies to the pilot users and no allow-list overrides the sender; resend GTUBE from an external address and check quarantine.

## No Explorer visibility
**Symptom:** Test 6 fails — Threat Explorer or the simulation shows nothing.
**Cause:** Threat Explorer / Attack Simulation Training require **P2**, or signal has not populated yet.
**Fix:** Confirm **P2** licensing (*verify current availability*); allow warm-up time for `EmailEvents`; re-run `POCMDO-Validate.ps1`. If P2 is unavailable, record the Explorer/simulation demos as "not licensed," not "failed."

## Simulation will not launch
**Symptom:** The Attack Simulation campaign cannot be created.
**Cause:** Missing **Attack Simulation Administrator** role or P2 licensing, or the target group is empty.
**Fix:** Assign the role and confirm P2; ensure `MDO PoC – Pilot Users – Pilot` has members; retry the launch per Implementation Step 3.

## Script cannot authenticate
**Symptom:** `POCMDO-*.ps1` fails on connect or returns access-denied.
**Cause:** The Exchange Online Management / Microsoft Graph modules are missing, scopes were not consented, or the account lacks the role.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-ExchangeOnline` / `Connect-MgGraph` and consent to the read-only scopes; confirm **Security Reader** plus **Exchange Administrator** for scoping. Re-run.

## Teardown left residue
**Symptom:** After `POCMDO-Teardown.ps1`, the pilot scope or test messages remain.
**Cause:** Teardown ran in `-WhatIf` only, or quarantine purge needs the quarantine role.
**Fix:** Run teardown **without** `-WhatIf`; confirm the Quarantine Administrator/Security Administrator role; purge the `MDO-PoC-TESTSIGNAL` items and re-confirm with `POCMDO-Validate.ps1`.
