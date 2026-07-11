# 5. Testing — Security Optimization Assessment: Defender for Cloud

These procedures validate that the assessment **ran correctly and completely** — that the enumeration is trustworthy, the scoring is reproducible, and the findings report is sound. The assessment is read-only, so "testing" proves the *evidence* is reliable. Each test has a **pass/fail gate**. Reference the scripts by the names used in Section 3.

## Test 1 — Read-only connection succeeds
**Procedure:** Run `Connect-AzAccount`, then `.\SOAMDC-Discovery.ps1 -SubscriptionId '<pilot>'`.
**Pass:** The script completes and writes `Posture Baseline - Defender for Cloud - Assess.json`; no write role was used.
**Fail:** A permissions error, or a prompt for a write role — re-check R2/R3.

## Test 2 — Discovery captured all four domains
**Procedure:** Open the baseline JSON.
**Pass:** It contains sections for **Secure Score & recommendations**, **plan coverage**, **regulatory compliance**, and **agent/agentless coverage** — even if a section is empty (an empty section is a finding).
**Fail:** A domain section is missing entirely. Re-run; confirm `Microsoft.Security` is registered (R1).

## Test 3 — Resource Graph coverage query returns
**Procedure:** Run `.\SOAMDC-Coverage.ps1 -SubscriptionId '<pilot>'`.
**Pass:** The output lists resource types with/without a matching plan and machine agentless-coverage state (or notes "no machines in scope").
**Fail:** `Search-AzGraph` errors — confirm `Az.ResourceGraph` is installed and the Reader role covers the scope (R3).

## Test 4 — Control validation returns evidence, not just a verdict
**Procedure:** Run `.\SOAMDC-Validate.ps1 -BaselinePath ... -RequiredStandard "..."`.
**Pass:** Each domain check returns **Pass** or **Gap** with the underlying evidence (e.g. "Secure Score = 42%", "Defender for Servers: Off", "required standard not mapped").
**Fail:** A check returns a verdict with no evidence, or throws.

## Test 5 — Scoring is reproducible
**Procedure:** Run `.\SOAMDC-Score.ps1` twice against the **same** validation output.
**Pass:** Both runs produce the same per-domain and overall scores (deterministic).
**Fail:** Scores differ for identical input — a defect; do not trust the score until reproducible.

## Test 6 — Findings report is prioritized and traceable
**Procedure:** Run `.\SOAMDC-Report.ps1 ...` and open the report.
**Pass:** Findings are sorted by **risk rank**; each names its **domain**, **severity**, **evidence**, and a **remediation pointer** to the Remediation Playbook.
**Fail:** Findings are unsorted, or a finding lacks evidence or a remediation pointer.

## Test 7 — Drift is detected across runs
**Procedure:** After a second run, confirm `SOAMDC-Report.ps1` compares to the prior report/baseline.
**Pass:** The report shows **new**, **resolved**, and **unchanged** findings (or notes "no prior baseline" on the first run).
**Fail:** No drift comparison when a prior baseline exists — check the `-PriorReportPath` argument.

## Test 8 — Output is stored securely
**Procedure:** Confirm the report and score/baseline JSON live in the restricted location agreed in R6.
**Pass:** Files are in the secure destination with restricted access.
**Fail:** The report is in an open location — move it (Global Requirements G7).

## Exit criteria
All eight tests pass, the security owner has reviewed **`Findings Report – Defender for Cloud – Validate`**, and risk-acceptance/priority decisions (including paid-plan cost acceptance) are recorded. The backlog is ready for the Remediation Playbook.
