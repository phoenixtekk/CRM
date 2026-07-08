# 5. Testing & Validation Guide — Managing Microsoft Purview: Operations & Governance

Validate that the **operating model actually runs** — not that Purview is merely configured. Each test
below has an explicit **pass/fail** signal and, where relevant, a **rollback**. Run the Part-A tests once
when you stand the program up, then treat the Part-B tests as the acceptance gate for each recurring cycle.
All checks are **read-only or `-WhatIf`** unless a step is explicitly a controlled change.

## Test 1 — Policy inventory + drift detection (RB-01)
1. Run `PURVOPS-Discovery.ps1` and confirm it returns a non-empty inventory of DLP, label, auto-labeling,
   and retention policies, each with a resolved **mode** (Enable / Test / Disable).
2. Run `PURVOPS-Discovery.ps1 -SaveBaseline`, then make **no** changes and run `-CompareBaseline`.
   - **Pass:** the diff reports **zero drift**.
   - **Fail:** drift reported with no change made → the baseline or comparison key is wrong; re-baseline.
3. In a **test** policy, change the mode (or add a benign test policy), re-run `-CompareBaseline`.
   - **Pass:** the exact policy and mode change is reported as drift.
   - **Rollback:** revert the test change; confirm the next diff is clean.

## Test 2 — Config helper is safe by default (RB-01 / change control)
1. Run `PURVOPS-Remediation.ps1 -Action PromotePolicy -PolicyName "<a test policy>" -WhatIf`.
   - **Pass:** it prints the intended change and confirms **no change was made**; re-running Discovery shows
     the policy mode unchanged.
   - **Fail:** any change occurs under `-WhatIf` → stop and do not use `-Commit` until fixed.
2. Only in a change window, against a **non-production/test** policy, run the same with `-Commit`.
   - **Pass:** the mode changes as previewed **and** a row is written to `Change Record – Purview –
     ChangeControl`.
   - **Rollback:** `-Action RollbackPolicy -PolicyName "<a test policy>" -Commit` returns it to its prior mode.

## Test 3 — Alert rollup across categories (RB-03)
1. Run `PURVOPS-Report.ps1`. Confirm it authenticates to Graph and returns alerts grouped by **category**
   (DLP / insider risk / information-protection / audit), **severity**, and **status**.
   - **Pass:** counts render and totals reconcile with the Purview/Defender alert views for the same window.
   - **Fail:** a permissions error → the Graph security read scope is not consented (Requirement 2.3).
2. Confirm the mean triage time (where status/timestamps are available) is computed against your SLA.
   *(If no alerts exist in the window, the script reports an empty rollup cleanly — this is a valid pass.)*

## Test 4 — Role & access review diff (RB-04)
1. Run `PURVOPS-Validation.ps1 -SaveApprovedList` to capture the current membership baseline.
2. Add a **test** account to a low-risk role group, then run `PURVOPS-Validation.ps1 -ApprovedListCsv
   <approved.csv>`.
   - **Pass:** the test account is flagged as an **unapproved addition**.
   - **Rollback:** remove the test account; the next run shows zero unexplained additions.
3. Confirm accounts in multiple sensitive role groups are flagged for justification.

## Test 5 — Compliance Manager cadence + KPI dashboard (RB-02 / RB-05)
1. Export improvement actions from Compliance Manager, then run `PURVOPS-KpiReport.ps1 -ComplianceManagerCsv
   <export.csv>`.
   - **Pass:** `Improvement Actions – Compliance Manager – Cadence` lists actions with owner/status/due date,
     and `KPI Dashboard – Purview – ProgramHealth` renders the KPI set (policy-mode distribution, alert
     volume, coverage, improvement-action burn-down, compliance-score trend, privileged-role count).
   - **Fail:** the CSV does not parse → re-export from the portal (column layout can change; the script
     reports the columns it found).
2. Confirm each KPI is compared to its agreed threshold and out-of-threshold values are highlighted.

## Test 6 — The cadence actually fires (operating model)
1. Confirm `Review Calendar – Purview – Operating` has scheduled owners for daily triage, weekly drift +
   rollup, monthly CM + KPI, quarterly access + policy review, and the annual program review.
   - **Pass:** each cadence has a named owner and a scheduled occurrence; one full cycle of each has run and
     produced its artifact.
   - **Fail:** any cadence with no owner or no evidence of a run → assign and run before sign-off.

---
## Acceptance gate (all must pass before declaring the program "operating")
- [ ] Discovery returns a full policy inventory with modes; baseline diff is clean, and a real change is
      caught as drift.
- [ ] `PURVOPS-Remediation.ps1` makes no change under `-WhatIf`; `-Commit` changes as previewed **and** writes
      a change record; rollback works.
- [ ] Alert rollup renders by category/severity/status and reconciles with the portal.
- [ ] Access-review diff flags an unapproved addition and privileged multi-role accounts.
- [ ] Compliance Manager export ingests; KPI dashboard renders all KPIs against thresholds.
- [ ] Every operating cadence has a named owner and one completed cycle on the calendar.
