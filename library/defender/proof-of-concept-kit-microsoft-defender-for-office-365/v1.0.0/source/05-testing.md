# 5. Testing Guide — Proof-of-Concept Kit: Microsoft Defender for Office 365

Run these checks during the PoC (Steps 2–6 of the Implementation Guide). Each test has a **pass/fail gate**. All signal is **benign** (Attack Simulation Training / GTUBE / EICAR / benign test URL). Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Pilot scope applied
**Procedure:** Run `POCMDO-Enable.ps1 -WhatIf`, then confirm the **Standard preset** applies to `MDO PoC – Pilot Users – Pilot` and to no one else.
**Pass:** The preset is scoped to the pilot group only; the wider org is unchanged.
**Fail:** Scope is wrong or org-wide — see Troubleshooting *Preset scope wrong*.

## Test 2 — Benign signal generated
**Procedure:** Run `POCMDO-TestSignal.ps1`; confirm the simulation launched and the GTUBE / EICAR / Safe Links test messages were sent to pilot users.
**Pass:** All benign signals were generated; no real phishing/malware used.
**Fail:** A signal did not send — see Troubleshooting *Test message not delivered*.

## Test 3 — Safe Links rewriting
**Procedure:** In a pilot mailbox open the benign link test; confirm the URL was rewritten; `POCMDO-Validate.ps1` checks `UrlClickEvents`.
**Pass:** The test URL is rewritten by Safe Links and click telemetry appears.
**Fail:** URL not rewritten — see Troubleshooting *Safe Links not rewriting*.

## Test 4 — Safe Attachments detonation
**Procedure:** Confirm the EICAR attachment message was actioned (blocked/quarantined); `POCMDO-Validate.ps1` checks `EmailAttachmentInfo` / `EmailEvents`.
**Pass:** Safe Attachments detonated/actioned the EICAR message.
**Fail:** Attachment delivered clean — see Troubleshooting *Safe Attachments not detonating*.

## Test 5 — Spam/phish handling
**Procedure:** Confirm the GTUBE message was treated as spam (quarantined/junked); check advanced hunting and quarantine.
**Pass:** The spam-test message was actioned per policy.
**Fail:** GTUBE delivered to inbox — see Troubleshooting *GTUBE not actioned*.

## Test 6 — Threat Explorer / simulation visibility
**Procedure:** `security.microsoft.com` → **Explorer** (P2) and **Attack simulation training** show the campaign and test messages; `POCMDO-Validate.ps1` confirms `EmailEvents` rows.
**Pass:** The simulation and test signal are visible for investigation.
**Fail:** Nothing appears — allow warm-up; see Troubleshooting *No Explorer visibility*.

## Test 7 — Scorecard produced
**Procedure:** Run `POCMDO-Scorecard.ps1` and confirm `MDO PoC Scorecard – Pilot Users – Validate.json` is written with a pass/fail per criterion.
**Pass:** A complete scorecard maps every observation to your criteria.
**Fail:** Missing observations — re-run the relevant validate step first.

## Test 8 — Clean teardown
**Procedure:** Run `POCMDO-Teardown.ps1 -WhatIf`, then for real; re-run `POCMDO-Validate.ps1`.
**Pass:** The pilot scope is removed, the simulation ended, and test messages purged — validate reports the scope gone.
**Fail:** Residue remains — see Troubleshooting *Teardown left residue*.

---
### Exit gate
Tests 1–7 pass to call the PoC conclusive; Test 8 passes to close it out cleanly. Keep the scorecard file as the decision record.
