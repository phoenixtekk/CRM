# 5. Testing — Security Optimization Assessment: Defender for Cloud Apps

These procedures validate that the assessment **ran correctly and completely** — that the enumeration is trustworthy, the scoring is reproducible, and the findings report is sound. Because the assessment is read-only, "testing" here means proving the *evidence* is reliable, not that a change took effect. Each test has an explicit **pass/fail gate**. Reference the scripts by the names used in Section 3.

## Test 1 — Read-only connection succeeds
**Procedure:** Run `Connect-MgGraph -Scopes "SecurityEvents.Read.All","Application.Read.All","Directory.Read.All"`, then `.\SOAMCA-Discovery.ps1`.
**Pass:** The script completes and writes `Posture Baseline - Cloud Apps - Assess.json`; no write scope was requested.
**Fail:** A permissions error, or any prompt for a write/`ReadWrite` scope — re-check R3/R4 and confirm you are using a read-only role.

## Test 2 — Discovery captured all four domains
**Procedure:** Open `Posture Baseline - Cloud Apps - Assess.json`.
**Pass:** It contains sections for **connectors/discovery**, **app-governance/OAuth policies**, **session/access policies**, and **alerts** — even if a section is empty (an empty section is itself a finding).
**Fail:** A domain section is missing entirely (not empty — absent). Re-run discovery; check that the account can view **Cloud apps → Policies**.

## Test 3 — Control validation returns evidence, not just a verdict
**Procedure:** Run `.\SOAMCA-Validate.ps1 -BaselinePath ".\Posture Baseline - Cloud Apps - Assess.json"`.
**Pass:** Each domain check returns **Pass** or **Gap** *with the underlying evidence* (e.g. "app governance: not enabled", "session policies: 0 found").
**Fail:** A check returns a verdict with no evidence, or throws — inspect the baseline JSON for the expected section.

## Test 4 — OAuth audit enumerates app grants
**Procedure:** Run `.\SOAMCA-OAuthAudit.ps1 -OutputPath ".\oauth-audit.json"`.
**Pass:** The output lists OAuth applications with their granted scopes and flags (over-permissioned / unverified-publisher / dormant). If the tenant genuinely has no third-party OAuth grants, the output is an empty set with that note.
**Fail:** The script cannot enumerate applications — confirm `Application.Read.All` / `Directory.Read.All` are consented (R4).

## Test 5 — Scoring is reproducible
**Procedure:** Run `.\SOAMCA-Score.ps1` twice against the **same** baseline.
**Pass:** Both runs produce the **same** per-domain and overall scores (scoring is deterministic for a fixed input).
**Fail:** Scores differ for identical input — a defect; do not trust the score until reproducible.

## Test 6 — Findings report is prioritized and traceable
**Procedure:** Run `.\SOAMCA-Report.ps1 ...` and open `Findings Report - Cloud Apps - Validate.json`.
**Pass:** Findings are sorted by **risk rank** (highest first); each finding names its **domain**, **severity**, **evidence**, and a **remediation pointer** to the Remediation Playbook.
**Fail:** Findings are unsorted, or a finding lacks evidence or a remediation pointer.

## Test 7 — Drift is detected across runs
**Procedure:** After a second run, confirm `SOAMCA-Report.ps1` compares to the prior saved baseline.
**Pass:** The report shows **new**, **resolved**, and **unchanged** findings versus the prior run (or notes "no prior baseline" on the first run).
**Fail:** No drift comparison appears when a prior baseline exists — check the baseline path argument.

## Test 8 — Output is stored securely
**Procedure:** Confirm the `Findings Report - Cloud Apps - Validate` and score/baseline JSON live in the restricted location agreed in R6.
**Pass:** Files are in the secure destination with access restricted to the security owner and assessor.
**Fail:** The report is in an open location — move it; it is a map of your weaknesses (Global Requirements G7).

## Exit criteria
All eight tests pass, the security owner has reviewed **`Findings Report – Cloud Apps – Validate`**, and risk-acceptance/priority decisions are recorded. The backlog is ready for the Remediation Playbook.
