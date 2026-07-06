# 6. Troubleshooting Guide — Architecture & Design Review Board (ARB) Governance Framework

Field issues that arise when running the board and its tooling, with the cause and the fix. Governance
problems are usually process problems wearing a technical mask — most of these are cured in the
charter or cadence, not the scripts.

## The board's decisions are ignored
Symptom: A design the board rejected (or approved with conditions) ships anyway.
Cause: No enforced authority — the mandate is verbal, or the vendor/enterprise boundary was never
written into the SOW.
Fix: Quote the written mandate (Requirement 2.1) in the charter and add the authority boundary
(Requirement 2.4) to the SOW or a governance addendum. Escalate the specific breach to the sponsor
via the charter's escalation path and record it as an open drift finding so it is visible.

## Governance has become the bottleneck
Symptom: Designs pile up undecided; workstreams route around the board to keep to schedule.
Cause: Cadence too infrequent, quorum too hard to assemble, or every design forced through a full
board.
Fix: Increase cadence or add an out-of-band fast-track; shrink the quorum to a tight, senior voting
core; delegate standard-conformant, low-risk designs (a wave plan identical to an approved template)
to the chair with a lightweight record. Watch time-in-gate (Test 9) as the health signal.

## Reviewers disagree and decisions stall on ties
Symptom: The board cannot reach a decision; the same design returns meeting after meeting.
Cause: No defined escalation for a tie or a blocked-but-insisted design.
Fix: Define escalation in the `Decision Rights Matrix - ARB - Program` before you need it — a named
escalation to the sponsor with a decision deadline. Record the escalated decision as an ADR so it is
not re-litigated.

## `GWARB-Validation.ps1` flags everything as No-Baseline
Symptom: Every row comes back `No-Baseline` and the conformance rate is meaningless.
Cause: The `Standard` values in the designs CSV do not match the `Standard` keys in the baseline CSV
(a naming or casing mismatch), or the baseline was never populated.
Fix: Confirm the `Standards Baseline - Target Architecture - Approved` is ratified and exported as
`Standard,ExpectedValue` rows whose names match exactly the `Standard` values in the designs export.
Ratify the baseline first (Requirement 2.2) — do not run conformance against an empty standard.

## Designs appear with a gate outside the standard five
Symptom: `GWARB-Discovery.ps1` flags designs whose gate is not one of the five standard gates.
Cause: A submitter used a free-text gate, or a genuinely new category of design has appeared.
Fix: Reclassify the design into its correct gate (its primary risk) in the tracker. If a real new
category exists, decide deliberately at the board whether to add a sixth gate — do not let ad-hoc
gates accrete, because a gate with no template or checklist cannot make a defensible decision.

## Decisions are made but not recorded
Symptom: `GWARB-Report.ps1` shows approved/rejected designs with HasRecord = no.
Cause: The board decided in the meeting but no Architecture Decision Record was written.
Fix: Make the ADR part of the decision, not a follow-up — write it at the moment of decision and link
it in the `Decision Register` before the design leaves the queue. Every unrecorded design shows in
the Gap Register until its ADR exists.

## Approved exceptions are quietly becoming the norm
Symptom: The exception count in the KPI set keeps rising cycle over cycle.
Cause: The baseline no longer matches reality, or gate discipline is slipping so deviations are waved
through as exceptions.
Fix: Review whether the standard itself is wrong — if so, update the `Standards Baseline` deliberately
through the board rather than absorbing the drift as repeated exceptions. If the standard is right,
tighten the gate so exceptions return to being rare and deliberate.

## `Connect-MgGraph` fails or the tracker list cannot be read
Symptom: The discovery/remediation scripts error on connect or on reading the Microsoft List.
Cause: The Microsoft Graph PowerShell SDK is missing, the required scope was not consented, or the
Site/List IDs are wrong.
Fix: Install the SDK (`Install-Module Microsoft.Graph -Scope CurrentUser`) and consent the
least-privilege scope — `Sites.Read.All` for reads, `Sites.ReadWrite.All` only for remediation
writes, `Group.ReadWrite.All` for the group builder. Confirm the Site ID and List ID for the tracker.
Or fall back to CSV mode with an export from the tracker.

## `GWARB-Remediation.ps1` or `GWARB-Set-ScopeTargeting.ps1` made no changes
Symptom: You ran the script and nothing was created.
Cause: Both default to `-WhatIf` (preview) by design — they never change anything until you confirm.
Fix: Review the previewed plan, then re-run the same command with `-Confirm` to apply. This is the
intended safety behavior, not a fault.

## The board outlives its usefulness / becomes a rubber stamp
Symptom: The approval rate is near 100% and meetings are pro forma.
Cause: Either the gates no longer catch real architectural choices, or the program has matured past
active design.
Fix: If designs are genuinely low-risk now, move more to fast-track and reduce cadence. As the
transformation closes, retire the board deliberately — fold its standing decisions and baseline into
steady-state architecture governance so the decisions outlive the program, rather than letting the
forum lapse silently.
