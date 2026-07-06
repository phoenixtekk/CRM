# 5. Testing Guide — Vendor Technical Governance & Anti-Lock-In Playbook

Run after the pilot configuration (Implementation Step 5) and on the recurring governance cadence.
These are **governance and conformance gates**: they test that the method is being applied and that
designs actually meet the anti-lock-in bar — not that a live system is up.

## Test 1 — Register is complete
Do: Run `GWVEND-Discovery.ps1`.
Expected: Every in-flight vendor deliverable/design is listed with owner and status, and any
vendor-created object readable in the source Microsoft 365 / Entra environment is enumerated and
cross-checked against the register — a usable governance baseline.

## Test 2 — Every design is dispositioned
Do: Run `GWVEND-Validation.ps1`.
Expected: Every register entry has a disposition (proposed entries are in-review; no entry is at
build status without an Approved / conditions-met disposition).

## Test 3 — Anti-lock-in criteria are scored
Do: Run `GWVEND-Validation.ps1` and spot-check one flagged design against its Design Review Record.
Expected: Each design shows a pass/fail on all four criteria (portability, data ownership, standards
conformance, exit criteria); any design missing a criterion or failing one is flagged, and the flag
matches the recorded review.

## Test 4 — A non-conformant design is caught, not passed
Do: Enter (or use) a design that uses a proprietary-only pattern with no documented exit and run
`GWVEND-Validation.ps1`.
Expected: The design fails standards-conformance and/or exit-criteria and is reported as
non-conformant — it is **not** silently marked conformant.

## Test 5 — Assumptions are validated before build
Do: Review the Vendor Assumption Log for a design at build status.
Expected: No unvalidated assumption remains for a design that has proceeded to build; every
assumption is validated or rejected.

## Test 6 — No un-approved vendor object exists
Do: Run `GWVEND-Discovery.ps1` and compare the vendor-created objects found in the source
environment against the approved designs.
Expected: Every vendor-created object maps to an approved design; any object with no corresponding
approved design is flagged for review (built ahead of the gate).

## Test 7 — Findings report is accurate
Do: Run `GWVEND-Report.ps1`.
Expected: The report lists each design with its criteria results, disposition, open conditions, and
any past-due exception, and matches the Design Review Records.

## Test 8 — Exceptions are tracked
Do: Run `GWVEND-Validation.ps1` (exception section).
Expected: Every granted exception is listed with its close date; any exception past its close date
is flagged as standing lock-in debt.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-5 pass on the pilot design; the design is dispositioned and any conditions tracked |
| Expand pass | Tests 1-3, 6-8 pass across all partners; every build-status design is approved, no un-approved vendor object exists, and no exception is past due |
