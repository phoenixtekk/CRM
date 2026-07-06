# 5. Testing Guide — Architecture & Design Review Board (ARB) Governance Framework

Run these after the board is stood up and the pilot cycle is complete (Implementation Step 7), and
again each governance cadence cycle. These test governance *effectiveness* — not a technical
configuration, but whether the board actually makes, records, and enforces decisions. Use
`GWARB-Discovery.ps1` and `GWARB-Report.ps1` for the tracker reads and `GWARB-Validation.ps1` for
conformance.

## Test 1 — Charter and decision rights are unambiguous
Do: Open the `ARB Charter - Transformation - Ratified` and `Decision Rights Matrix - ARB - Program`.
Expected: For every gate you can state who submits, who votes, the quorum number, who may
approve/reject, and the escalation path. The vendor/enterprise authority boundary is written. No
role or quorum is undefined.

## Test 2 — Membership groups exist and match the roster
Do: Run `GWARB-Set-ScopeTargeting.ps1` (review the `-WhatIf` plan) and confirm in Entra.
Expected: `ARB - Voting Members - Board` and `ARB - Advisory Reviewers - Panel` exist with the
intended members; their IDs are recorded in the charter.

## Test 3 — Every gate has a submission template and checklist
Do: Inspect the five gates.
Expected: Each of Migration Wave Plan, Identity & Sync Model, Security Configuration, Data-Migration
Pattern, and Work-Transformation Approach has a `Submission Template` variant and a `Review
Checklist`. No gate is open without both.

## Test 4 — Submissions are inventoried and classified
Do: Run `GWARB-Discovery.ps1` against the tracker.
Expected: Every submitted design appears with a gate, state, workstream, and owner. No design is
missing a gate or owner; any gate outside the standard five is flagged and explained.

## Test 5 — Conformance is checked against the approved baseline
Do: Run `GWARB-Validation.ps1` with the `Standards Baseline - Target Architecture - Approved` and the
designs' declared attributes.
Expected: Each design is Conformant, Conditional (approved exception), or Non-Conformant. The
conformance rate is reported; every Non-Conformant row is a drift finding that blocks approval until
adjudicated.

## Test 6 — Every decision has a record
Do: Run `GWARB-Report.ps1`; review the Decision Register roll-up.
Expected: Every gate-stage design has an Architecture Decision Record (HasRecord = yes) or appears in
the Gap Register as missing one. No approved/rejected design lacks an ADR.

## Test 7 — The Gap Register captures all open drift
Do: Review the `Gap Register - Design Drift - Rolling` from `GWARB-Report.ps1`.
Expected: Every Non-Conformant finding and every gate-stage design missing a decision record appears
in the Gap Register with an owner. Nothing open is untracked.

## Test 8 — Remediation opens owned, dated actions (safely)
Do: Run `GWARB-Remediation.ps1` (default `-WhatIf`) against the Gap Register.
Expected: It prints the actions it WOULD open — each with a required board decision, an owner, and a
due date — and makes no change. Re-running with `-Confirm` records exactly those actions.

## Test 9 — Governance is not the bottleneck
Do: Review time-in-gate and the undecided backlog from the KPI block.
Expected: Average time-in-gate is within the target the charter sets, and the count of designs stuck
undecided is not growing cycle over cycle.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 8 pass for the pilot workstream; every pilot design has a decision and an ADR; Test 9 shows time-in-gate within target |
| Program pass | Tests 1 to 9 pass across all workstreams; open drift is trending down and no gate is running without a template, checklist, and quorum |
