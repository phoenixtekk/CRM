# 5. Testing — Remediation Playbook for Defender Security Optimization Assessments

These procedures validate that remediation is **safe, effective, and reversible** — that preview truly changes nothing, the apply is scoped to the pilot, the control is verified, and the re-score proves closure. Each test has an explicit **pass/fail gate**. Reference the scripts by the names used in Section 3.

## Test 1 — Ingest is read-only and maps findings
**Procedure:** Run `.\SOAREM-Discovery.ps1 -FindingsReportPath ... -OutputPath ...`.
**Pass:** It writes `Remediation Plan - Defender SOA - Assess.json` with each finding mapped to a remediation and its gate; no write scope was requested.
**Fail:** A write scope prompt, or a finding with no mapped remediation — re-check the findings report and the map.

## Test 2 — Preview (`-WhatIf`) changes nothing
**Procedure:** Run `.\SOAREM-Remediate.ps1 ... -WhatIf` for a finding.
**Pass:** The script prints exactly what *would* change and confirms **no change was made**; a subsequent read of the target shows the old state unchanged.
**Fail:** Any actual change occurs in `-WhatIf` mode — a critical defect; stop and do not use the apply path until fixed.

## Test 3 — Apply requires the explicit switch (and disruptive confirmation)
**Procedure:** Run the remediate script **without** `-Apply`, then **with** `-Apply` on a monitor-capable control; then attempt an approval-gated (disruptive) category without `-ConfirmDisruptive`.
**Pass:** Without `-Apply` nothing changes; with `-Apply` the pilot-scope change is made; a disruptive category **refuses** to enforce without `-ConfirmDisruptive` (and applies in monitor/audit where supported).
**Fail:** The script applies without `-Apply`, or enforces a disruptive control without the confirmation — a gating defect.

## Test 4 — Apply is scoped to the pilot only
**Procedure:** After a pilot apply, confirm the change affects **only** the named pilot scope and the break-glass account is excluded.
**Pass:** Only the pilot group/subscription/policy changed; break-glass is untouched.
**Fail:** The change hit production or the break-glass account — roll back immediately (Section 6) and re-scope.

## Test 5 — Verification confirms the specific control
**Procedure:** Run `.\SOAREM-Validate.ps1 -FindingId ...`.
**Pass:** It confirms the specific control is now correct on the pilot (e.g. policy present, plan on, session policy in monitor), read-only.
**Fail:** Verification says the control is not in place though you applied it — the apply did not take (Troubleshooting).

## Test 6 — Re-score proves closure
**Procedure:** Run `.\SOAREM-Rescore.ps1 -BaselinePath ... ` and compare to the pre-change baseline.
**Pass:** The relevant domain/overall score **rises** versus the baseline, proving the finding closed (allowing for warm-up).
**Fail:** The score does not move after a verified change — allow warm-up and re-run; if still flat, the change may not affect the scored control.

## Test 7 — Rollback works
**Procedure:** On the pilot, exercise the documented rollback for the applied remediation.
**Pass:** The change is cleanly reverted and the target returns to its prior state.
**Fail:** Rollback leaves a partial/broken state — do not expand the rollout until rollback is proven.

## Test 8 — Evidence report is complete and traceable
**Procedure:** Run `.\SOAREM-Report.ps1 ...` and open the evidence report.
**Pass:** Each remediated finding shows what changed, when, by whom, the stage (monitor→enforce), and the before/after score.
**Fail:** A remediation lacks change-tracking or before/after evidence — the closure is not auditable.

## Exit criteria
For each finding: preview verified harmless, apply scoped to pilot with approval, control verified, re-score risen, rollback proven, and the evidence report complete. Only then expand to enforce/broad scope.
