# 7. Best Practices — Oracle C2M Hypercare & Production Support Runbook

Field-proven recommendations for a smooth stabilization from cutover through steady-state.

- Gate cutover; never start on hope. `C2M Runbook - Readiness - Go-Live Checklist` with an owner per
  line and a signed go/no-go is the difference between a controlled cutover and an unpatched node
  found at 2 a.m. A pre-approved exception is fine; an unexamined red item is not.
- Make cutover reversible before you make it live. A timeboxed plan with an explicit go/no-go and a
  **tested** rollback means a failed cutover is a rollback, not a crisis. A rollback that has not been
  walked on non-production is not a rollback.
- Rehearse the whole thing. The non-production dress rehearsal — cutover timed, health routine run for
  days, Sev-1/Sev-3 tabletops — finds the gaps while they are cheap. Programs that skip the rehearsal
  discover the same gaps live.
- Make severity a rule, not an argument. `C2M Runbook - Severity - Model` decides response time, who
  is paged, and comms cadence up front, so the incident bridge spends its first minutes fixing the
  problem, not classifying it.
- Give every incident an owner immediately. A staffed `C2M Runbook - OnCall - Rota` by layer, with a
  primary and a secondary and a real shift handover, means no incident spends its first hour deciding
  who owns it. Brief the incoming shift on open incidents and the day's health snapshot.
- Separate command from debugging in a major incident. Name an incident commander who coordinates and
  communicates while the engineers debug — one person doing both does neither well.
- Handle each incident once and write it down. Follow `C2M Runbook - Incident - Procedure` through to
  **record**; a recurring pattern becomes a `C2M Runbook - KnownIssue - Register` entry so it is
  worked around next time, not re-diagnosed.
- Seed and keep the known-issue register. Load it before go-live from UAT defects and the version's
  known-issue MOS notes (point to gated notes, do not copy them); each entry carries a workaround and
  a tracking reference. A recognized symptom is a two-minute fix; an unrecognized one is a fresh
  investigation.
- Keep day-2 work in the lower environments. During hypercare, build and test in Dev/Test/UAT and
  promote to production only through change control. Building in a stabilizing production system trades
  a little speed now for instability you will pay for later.
- Measure health every morning, the same way. `C2M Runbook - Health - Daily Routine` — WebLogic, batch
  completion and backlog, integration queues, database/disk, error-log deltas — turns "how are we
  doing?" into a green/amber/red snapshot. Attach it to the shift handover; any amber/red opens an
  incident.
- Prefer read-only diagnosis first. The discovery, validation, and report scripts read; remediation is
  dry-run by default. Understand the state before you change it, and change production only under
  change control with a rollback ready.
- Exit hypercare on evidence, not on the calendar. Leave the elevated model only when health is green
  for the agreed consecutive days, there are no open Sev-1/Sev-2, the incident rate is below
  threshold, and the day-2 backlog is controlled — then the runbook becomes the standing operations
  runbook.
- Escalate product defects the right way. When diagnosis points to a product bug, use the
  My Oracle Support Service Request path in the escalation matrix and reference the known-issue
  register — do not sit on a defect or reproduce gated content locally.
