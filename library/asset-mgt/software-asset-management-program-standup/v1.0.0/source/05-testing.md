# 5. Testing Guide — Software Asset Management (SAM) Program Standup & Governance

Run after the first governance cycle on the pilot scope (Implementation Step 9) and after each
expansion. Each test confirms one part of the standing program works end to end.

## Test 1 — System of record is authoritative
Do: Open `SAM Register - Entitlements - System of Record` and pick a representative pilot product.
Expected: Entitlement quantity, contract ID, and renewal date are present and agreed as the single
source of truth.

## Test 2 — Intake routes a request
Do: Raise a test request through `SAM Intake - Software Requests - Request Stage`; run
`SAMPROG-Validation.ps1`.
Expected: The request is captured and routed to the approver/Procurement Liaison; validation reports
the intake-coverage signal present.

## Test 3 — Roles are owned
Do: For each lifecycle stage, name the Responsible and Accountable person from
`SAM RACI - Program - All Stages`.
Expected: Every stage has a named owner; no stage is unassigned.

## Test 4 — Discovery data is available
Do: Run `SAMPROG-Discovery.ps1` for the pilot scope.
Expected: A discovery/usage source is reachable and returns installed-software or license-usage data
for the pilot sample.

## Test 5 — Reconciliation computes an ELP
Do: Execute the Reconciliation SOP for the pilot scope, then run `SAMPROG-Report.ps1`.
Expected: An Effective License Position (compliant / over / under) is computed and recorded in the
register for each pilot product.

## Test 6 — KPI set reports
Do: Run `SAMPROG-Report.ps1`.
Expected: License compliance, reconciliation coverage, renewal lead time, reharvest savings, and
request cycle time render for the pilot scope without gaps.

## Test 7 — Governance cadence runs
Do: Hold the first `SAM Governance Cadence - Program - Reconciliation & Renewal` session.
Expected: The SAM Lead presents the KPI set/ELP, the sponsor chairs, and at least one renewal decision
is recorded back into the register.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-6 pass; the lifecycle ran end to end and an ELP is computed for the pilot scope |
| Expand pass | Tests 1-6 pass for each new scope and Test 7 (cadence) is running before estate-wide rollout |
