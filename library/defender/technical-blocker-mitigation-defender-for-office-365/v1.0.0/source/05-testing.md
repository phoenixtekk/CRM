# 5. Testing Guide — Technical Blocker Mitigation: Defender for Office 365

Run these checks after applying a fix on the affected recipients (`MDO Blocker Triage – Affected Recipients – Diagnose`) and again after each expansion wave. Each test has a **pass/fail gate**; do not resume the wider rollout until the affected recipients pass the test for their blocker class. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Blocker pinpointed (baseline captured)
**Procedure:** Run `TBMMDO-Discovery.ps1` and confirm `MDO-blocker-discovery.json` has the plan, policy inventory, priority order, enable-state, and scope populated.
**Pass:** A single earliest broken link is identifiable; the affected recipients are in the triage group.
**Fail:** Snapshot empty or access-denied — fix read access (Requirements 2.1) and re-run.

## Test 2 — Mail routing reaches EOP
**Procedure:** Run `TBMMDO-MailFlow.ps1`. Confirm the public MX resolves to EOP (or a documented gateway that forwards to EOP), accepted domains are correct, and no inbound connector bypasses filtering for the affected recipients.
**Pass:** Inbound mail for the affected recipients reaches EOP first.
**Fail:** Mail bypasses EOP — see Troubleshooting *Mail bypasses filtering (routing conflict)*.

## Test 3 — Correct policy wins on precedence
**Procedure:** Run `TBMMDO-Discovery.ps1`; in the precedence section confirm the **single** highest-priority policy of each type that applies to the affected recipients is the intended one.
**Pass:** The intended Safe Links / Safe Attachments / anti-phish policy is the winner for the affected recipients.
**Fail:** A preset or higher-priority custom policy or an exclusion wins instead — see Troubleshooting *Policy configured but never applies (precedence)*.

## Test 4 — Safe Links rewriting
**Procedure:** Send the safe test URL to a recipient in the subset; run `TBMMDO-Validate.ps1` and check `UrlClickEvents` / message trace.
**Pass:** The URL is rewritten/wrapped and the click is recorded by MDO.
**Fail:** URL not rewritten — see Troubleshooting *Safe Links not rewriting*.

## Test 5 — Safe Attachments detonation
**Procedure:** Send the benign test attachment (standard Microsoft procedure) to a recipient in the subset; run `TBMMDO-Validate.ps1` and check `EmailEvents` / message trace for the Safe Attachments action.
**Pass:** The attachment is detonated/held per policy and the action appears.
**Fail:** No Safe Attachments action — see Troubleshooting *Safe Attachments not detonating*.

## Test 6 — Licensing present
**Procedure:** Run `TBMMDO-Discovery.ps1` and confirm the MDO plan the feature needs is reported as licensed.
**Pass:** The required MDO plan (P1/P2) is present. *Verify current plan requirements in your tenant.*
**Fail:** Plan missing — see Troubleshooting *Licensing gap*.

## Test 7 — Before/after evidence produced
**Procedure:** Run `TBMMDO-Report.ps1` and confirm it emits a before/after comparison from the Step 1 snapshot versus current state.
**Pass:** The report shows the blocker's link moved from broken to cleared.
**Fail:** No change captured — re-run discovery to refresh the baseline.

## Test 8 — Escalation bundle valid (only if escalating)
**Procedure:** If protection still does not apply after a correct fix, run `TBMMDO-SupportBundle.ps1` and confirm `MDO Support Bundle – <case> – Escalate` contains the discovery snapshot, mail-flow analysis, affected recipients, message-trace IDs, and timestamps.
**Pass:** A complete, attachable bundle exists.
**Fail:** Bundle incomplete — re-run discovery/mail-flow first, then rebuild.

---
### Exit gate
The affected recipients pass the tests for their blocker class **before** you resume the wider rollout (Implementation Step 6). Re-run Tests 3–5 and 7 after each expansion wave and compare against the saved baseline.
