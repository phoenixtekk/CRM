# 5. Testing & Validation

Run these on `Scope – Records-Pilot – Static` before any expansion, and re-run after each production
wave. Each test states the procedure and an explicit **Pass / Fail**. Retention and disposition run on
service timers — allow for propagation (often hours to a few days) before judging a Fail. Use the
provided scripts where noted; all are read-only except where a `-Commit` is explicitly passed.

---

## Test 1 — Labels exist and match the schedule
- **Procedure:** `Get-ComplianceTag | Where-Object Name -like "*Pilot*" | Select-Object Name,IsRecordLabel,Regulatory,RetentionAction,RetentionDuration,RetentionType,ReviewerEmail`.
  Compare each label's action, duration, trigger, record status, and reviewers to the records/legal
  schedule.
- **Pass:** every pilot schedule category has exactly one label whose settings match the schedule.
- **Fail:** any label missing, duplicated, or with a setting that differs from the schedule.

## Test 2 — Labels are applied to the pilot libraries
- **Procedure:** `Get-PnPLabel -List "Documents"` on each pilot library; run
  `Assess-SpoRetentionPosture.ps1` and read the coverage columns in `Retention Posture – SPO –
  Discovery`.
- **Pass:** each single-category pilot library reports its intended default label; labeled-item count
  matches expectation (allowing for propagation).
- **Fail:** a pilot library has no default label where one was intended, or coverage is materially
  below expectation after propagation.

## Test 3 — Record declaration locks content
- **Procedure:** apply `Record Label – Contracts – Pilot` to a test document; attempt to edit, delete,
  and move it.
- **Pass:** SharePoint blocks edit/delete/move (in-place record); the declare action appears in the
  audit log.
- **Fail:** the item can be edited/deleted after the record label is applied, or no audit entry exists.

## Test 4 — Regulatory-record irreversibility is understood (only if in scope)
- **Procedure:** confirm any `Regulatory Record Label – *` category is explicitly approved by
  records/legal and applied only where required; verify `Regulatory = True` on the label.
- **Pass:** every regulatory-record label is records/legal-approved and no regulatory record was
  applied to pilot content that was meant to stay reversible.
- **Fail:** a regulatory-record label was applied without sign-off, or applied to content that should
  have been a normal record.

## Test 5 — Retention policies are in the intended state
- **Procedure:** `Get-RetentionCompliancePolicy | Select-Object Name,Enabled,Mode; Get-RetentionComplianceRule -Policy "Retention Policy – SPO-Baseline – Pilot"`.
- **Pass:** the pilot baseline (and any auto-apply) policy is **Enabled = True**, scoped to the pilot
  sites only, with the designed retention action/duration; nothing tenant-wide is enabled in the pilot.
- **Fail:** a policy is disabled when it should be enabled, scoped beyond the pilot, or has a
  wrong action/duration.

## Test 6 — Auto-apply reaches matching content
- **Procedure:** for `Label Policy – Contracts-AutoApply – Pilot`, place a document matching the
  condition (keyword / sensitive-info type / classifier) in a pilot library; after propagation, confirm
  the label auto-applied.
- **Pass:** matching content receives the label automatically within the expected propagation window;
  non-matching content does not.
- **Fail:** matching content is never labeled, or the policy over-applies to non-matching content.

## Test 7 — Disposition review routes to reviewers
- **Procedure:** confirm reviewers are in the **Disposition Management** role group; for a label whose
  retention has elapsed (test/short-duration label), confirm the item appears in **Purview → Records
  management → Disposition** for `Disposition Reviewers – Records – Stage1`.
- **Pass:** the expired item is in the disposition queue and visible to the named reviewers only.
- **Fail:** the item never enters the queue, or is visible to accounts outside Disposition Management.

## Test 8 — A disposition decision is evidenced (defensible disposition)
- **Procedure:** have a reviewer **approve disposal** (or extend/relabel) on the queued test item;
  confirm the outcome and that a **disposition record / proof of disposal** is retained.
- **Pass:** the decision executes (disposed / extended / relabeled) and Purview retains an auditable
  disposition record naming the reviewer, decision, and date.
- **Fail:** the decision does not execute, or no disposition record is retained.

## Test 9 — Alignment with the broader Purview program (no conflict)
- **Procedure:** review the retention-precedence interaction of the new pilot labels/policies against
  pre-existing retention (from `Get-RetentionCompliancePolicy` and the Stage-1 baseline). Confirm no
  pilot content is unintentionally over-retained or deleted by a conflict.
- **Pass:** the effective retention outcome on pilot content matches the schedule after precedence
  rules; sensitivity labels/DLP owned by the broader program are untouched.
- **Fail:** a conflict changes the effective outcome, or this solution altered a broader-program
  artifact it should not own.

## Test 10 — Full compliance report reconciles
- **Procedure:** run `Get-SpoRecordsComplianceReport.ps1` to produce `Records Compliance – SPO –
  Report`; reconcile label coverage %, records declared count, and pending-disposition count against
  expectations.
- **Pass:** the report generates and its figures reconcile with the schedule and the pilot design.
- **Fail:** the report errors, or figures diverge from expectation without an explained cause.

---

**Overall pilot gate:** Tests 1–3, 5, 7, 8, and 10 must **Pass** (and 4, 6, 9 where those features are
in scope) before Stage 6 expansion. Any Fail loops back to Implementation Stage 3/4.
