# 5. Testing — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

These procedures validate that the suite assessment **ran correctly and completely** — that the enumeration is trustworthy, the scoring is reproducible, and the findings report is sound. The assessment is read-only, so "testing" proves the *evidence* is reliable. Each test has a **pass/fail gate**. Reference the scripts by the names used in Section 3.

## Test 1 — Read-only connection succeeds
**Procedure:** Run the `Connect-MgGraph`/`Connect-AzAccount` commands, then `.\SOAXDR-Discovery.ps1`.
**Pass:** The script completes and writes `Posture Baseline - Defender Suite - Assess.json`; no write scope/role was used.
**Fail:** A permissions error, or a prompt for a write scope — re-check R3/R4/R5.

## Test 2 — Discovery captured all four domains and five pillars
**Procedure:** Open the baseline JSON.
**Pass:** It contains sections for **cross-pillar coverage** (with a per-pillar entry for each of the five), **unified RBAC**, **incident correlation**, and **suite-wide Secure Score** — even where a pillar is dark or marked N/A (that is itself a finding/note).
**Fail:** A domain or pillar section is missing entirely. Re-run; confirm portal access.

## Test 3 — RBAC audit enumerates privileged assignments
**Procedure:** Run `.\SOAXDR-RBACAudit.ps1 -OutputPath ".\rbac-audit.json"`.
**Pass:** The output lists privileged directory-role assignments and flags broad/over-privileged ones (or notes none found).
**Fail:** The script cannot enumerate role assignments — confirm `RoleManagement.Read.Directory` / `Directory.Read.All` (R4).

## Test 4 — Control validation returns evidence, not just a verdict
**Procedure:** Run `.\SOAXDR-Validate.ps1 -BaselinePath ... -PillarsOnboarded ... -UnifiedRbacActivated ...`.
**Pass:** Each domain check returns **Pass** or **Gap** with evidence (e.g. "identity pillar: not onboarded", "unified RBAC: legacy per-product", "Secure Score = 55%").
**Fail:** A check returns a verdict with no evidence, or throws.

## Test 5 — Scoring is reproducible
**Procedure:** Run `.\SOAXDR-Score.ps1` twice against the **same** validation output.
**Pass:** Both runs produce the same per-domain and overall scores (deterministic).
**Fail:** Scores differ for identical input — a defect; do not trust the score until reproducible.

## Test 6 — Findings report is prioritized and traceable
**Procedure:** Run `.\SOAXDR-Report.ps1 ...` and open the report.
**Pass:** Findings are sorted by **risk rank**; each names its **domain**, **severity**, **evidence**, and a **remediation pointer** (to the Remediation Playbook, or to a per-pillar deep-dive assessment where relevant).
**Fail:** Findings are unsorted, or a finding lacks evidence or a remediation pointer.

## Test 7 — Drift is detected across runs
**Procedure:** After a second run, confirm `SOAXDR-Report.ps1` compares to the prior report/baseline.
**Pass:** The report shows **new**, **resolved**, and **unchanged** findings (or notes "no prior baseline" on the first run).
**Fail:** No drift comparison when a prior baseline exists — check `-PriorReportPath`.

## Test 8 — Output is stored securely
**Procedure:** Confirm the report and score/baseline JSON live in the restricted location agreed in R6.
**Pass:** Files are in the secure destination with restricted access.
**Fail:** The report is in an open location — move it (Global Requirements G7).

## Exit criteria
All eight tests pass, the security owner has reviewed **`Findings Report – Defender Suite – Validate`**, and risk-acceptance/priority decisions are recorded. The backlog is ready for the Remediation Playbook (and the per-pillar deep-dive assessments where needed).
