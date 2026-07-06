# 5. Testing Guide — Oracle C2M Hypercare & Production Support Runbook

Run these on the non-production dress rehearsal (Runbook Step 9) and again during live hypercare.
Each test confirms one part of the operating model works end to end: readiness gated, cutover
reversible, on-call and escalation reaching the right owner, incidents handled and recorded, day-2
builds staying in the lower environments, and health measured daily. Source the environment first:
`splenviron.sh -e your-env`.

## Test 1 — Readiness is actually gated
Do: Run `OC2MHYPER-Discovery.sh` and `OC2MHYPER-Validation.sh` against the environment; review the
`C2M Runbook - Readiness - Go-Live Checklist` with owners.
Expected: Every technical readiness signal returns PASS (WebLogic servers RUNNING, batch daemon up,
JMX reachable, integrations reachable, backups present); every checklist line is green or carries a
signed-off exception. A red technical item blocks cutover — the gate holds.

## Test 2 — Cutover is reversible
Do: On the dress rehearsal, execute `C2M Runbook - Cutover - Plan` end to end, then execute the
rollback from a mid-cutover point.
Expected: The cutover runs within its timebox; the go/no-go decision point is exercised; the rollback
restores the pre-cutover state cleanly from the tested backups. A failed go/no-go leads to rollback,
not to pressing on.

## Test 3 — On-call and escalation reach the right owner
Do: Tabletop one Sev-1 and one Sev-3. Render the current rota with
`OC2MHYPER-ScopeHelper.sh --scope rota`; walk each incident through `C2M Runbook - Severity - Model`
and `C2M Runbook - Escalation - Matrix`.
Expected: Each severity engages the correct owner in the correct order within its response target;
the Sev-1 reaches the incident commander and the MOS Service Request path is known; the Sev-3 is
handled by the on-call owner in-hours. Ownership is immediate, not debated.

## Test 4 — An incident is handled and recorded
Do: Run a simulated incident through `C2M Runbook - Incident - Procedure` (detect → triage → assign →
diagnose → mitigate → communicate → record); render the summary with `OC2MHYPER-Report.sh`.
Expected: The incident gets a severity, an owner, a timeline, a resolution/workaround, and a written
record; a recurring pattern produces a `C2M Runbook - KnownIssue - Register` entry.

## Test 5 — A known issue is recognized, not re-diagnosed
Do: Trigger (or simulate) a symptom already in the known-issue register; have the on-call owner
consult `OC2MHYPER-Report.sh` / the register.
Expected: The symptom is matched to its register entry and the recorded workaround is applied in
minutes; the recurrence is logged. It is not diagnosed from scratch.

## Test 6 — Day-2 builds stay in the lower environments
Do: Run a representative day-2 change through the `C2M Runbook - Day2 - Build Lane`; list the lane
with `OC2MHYPER-ScopeHelper.sh --scope day2`.
Expected: The change is built and tested in a lower environment and promoted to production only
through change control — nothing is built directly in production during hypercare.

## Test 7 — The daily health routine produces a clean snapshot
Do: Run the routine (`OC2MHYPER-Report.sh` for the operational summary, `OC2MHYPER-Report.sql` for
batch/integration/database detail) as it would run each morning.
Expected: A green/amber/red snapshot covering WebLogic, batch completion and backlog, integration
queues, database/disk, and error-log deltas. Green = stable; any amber/red opens an incident at the
right severity. The routine runs the same way every day.

## Test 8 — Health is stable across the hypercare window
Do: Run the daily routine for the agreed number of consecutive days during hypercare and track the
snapshots.
Expected: Health trends green with no open Sev-1/Sev-2 and an incident rate below threshold — the
steady-state exit gate. A downward trend in daily amber/red items shows stabilization.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-7 pass on the non-production dress rehearsal: readiness gated, cutover reversible, on-call/escalation reach the right owner, an incident is handled and recorded, a known issue is recognized, day-2 stays in lower environments, the daily health snapshot is clean |
| Hypercare exit pass | Tests 1-7 continue to pass in live hypercare and Test 8 holds — health green for the agreed consecutive days, no open Sev-1/Sev-2, incident rate below threshold, day-2 backlog controlled |
