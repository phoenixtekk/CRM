# 3. Runbook — Oracle C2M Hypercare & Production Support

This is the runbook: the go-live readiness checklist, the on-call/escalation model, incident and
known-issue handling, day-2 build support in the lower environments, and the daily health/monitoring
routine — each with an explicit gate. Follow it in order from readiness through cutover into
hypercare and out to steady-state. Object names are fixed — create them with the exact names shown
and reuse them everywhere. Pilot the whole model on a non-production dress rehearsal before the live
cutover.

> Model: assess readiness, configure the support structure, rehearse (pilot) on non-production,
> validate the readiness and health gates, then expand into the live cutover and hypercare. Assess,
> then Configure, then Pilot, then Validate, then Expand — with a documented rollback for every
> production change.

> All commands assume the environment is sourced first: `splenviron.sh -e your-env` (run as the
> product user). Utility and interface names (`threadpoolworker`/`starttpw`, the JMX batch connector
> `service:jmx:rmi:///jndi/rmi://your-host:your-jmx-port/oracle/ouaf/batchConnector`, WLST, the batch
> run-status tables) are from the OUAF Server Administration Guide — verify exact names/flags for your
> version. MOS-gated go-live checklists, patches, and known-issue notes are pointed to, not reproduced.

## Step 1 — Build the go-live readiness checklist (`C2M Runbook - Readiness - Go-Live Checklist`)
1. Source the environment and run `OC2MHYPER-Discovery.sh` to capture current state: WebLogic servers
   and the batch daemon, the JMX batch connector, configured integrations, backup presence, and the
   monitoring signals — read-only. This is the raw material for the checklist.
2. Assemble the checklist with an accountable owner and a go/no-go status per line, grouped by domain:
   - **Environment** — WebLogic Admin + managed servers RUNNING; `threadpoolworker`/batch daemon
     started on the designated node(s); certified stack confirmed.
   - **Data & migration** — final data load/sync signed off; reconciliation counts agreed.
   - **Integrations** — each inbound/outbound endpoint reachable and enabled; queues drained.
   - **Batch estate** — the nightly schedule and dependencies in place; a smoke batch completes.
   - **Security/SSO** — SSO, SSL/keystore, and access confirmed for production URLs.
   - **Monitoring** — the health routine, alerting, and the monitoring platform (e.g. Dynatrace) live.
   - **Backup & rollback** — backups taken and tested; the rollback documented.
   - **Support readiness** — rota staffed, escalation matrix and severity model agreed, known-issue
     register seeded.
3. Run `OC2MHYPER-Validation.sh` — it checks the technical readiness signals that back the checklist
   and reports PASS/FAIL per signal. Do not proceed past a red technical item without a signed
   exception.

> **Gate — Readiness.** Cutover starts only when every checklist item is green or carries a
> signed-off exception, and `OC2MHYPER-Validation.sh` returns overall PASS.

## Step 2 — Author the cutover plan (`C2M Runbook - Cutover - Plan`)
1. Write the cutover as a timeboxed, numbered sequence with a start time, a **go/no-go** decision
   point partway through, and a hard **rollback deadline**. A typical sequence: freeze change → take
   backups → final data load/sync → promote configuration → enable integrations → start the batch
   daemon and `threadpoolworker` → run smoke checks → go/no-go → open to users.
2. Attach the **rollback**: the exact steps to restore the pre-cutover backups and revert config if
   the go/no-go fails, with the person who authorizes rollback named.
3. Rehearse the whole sequence on the non-production dress rehearsal (Step 8) and time each step.

> **Gate — Cutover.** Production is open only when the smoke checks pass at the go/no-go point; if
> not, execute the documented rollback rather than pressing on.

## Step 3 — Define the severity model (`C2M Runbook - Severity - Model`)
1. Fix four severities so severity is a rule, not an argument:
   - **Sev-1** — production down or a critical business function (e.g. billing) blocked; immediate
     page, incident bridge, continuous comms.
   - **Sev-2** — major function degraded or at risk, workaround limited; fast page, frequent comms.
   - **Sev-3** — a contained issue with a workaround; handled in-hours by the on-call owner.
   - **Sev-4** — minor/cosmetic or a question; tracked, no page.
2. For each severity set the **response target** (time to acknowledge/engage) and the **comms
   cadence**. These targets drive the escalation matrix.

## Step 4 — Build the on-call rota and escalation matrix
1. **On-call rota** (`C2M Runbook - OnCall - Rota`): define primary and secondary for each support
   window, by layer — application, middleware/WebLogic, database, integration, infrastructure — with
   current contacts and a **shift-handover** step (outgoing shift briefs incoming on open incidents
   and the day's health snapshot). Render the current window with
   `OC2MHYPER-ScopeHelper.sh --scope rota`.
2. **Escalation matrix** (`C2M Runbook - Escalation - Matrix`): for each severity, list who is engaged
   and in what order and within what time — on-call owner → layer lead → incident commander →
   vendor/Oracle Service Request (MOS) for a suspected product defect. Make the MOS SR path explicit
   for defects; gated notes are pointed to, not reproduced.

## Step 5 — Adopt the incident procedure (`C2M Runbook - Incident - Procedure`)
1. Standardize the incident lifecycle: **detect** (health routine, alert, or user report) → **triage
   and set severity** (per the severity model) → **assign an owner** (per the rota) → **diagnose**
   (health scripts, logs, JMX, schema) → **mitigate/resolve** (workaround now, root-cause after) →
   **communicate** (per the severity's cadence) → **record** (timeline, cause, fix, and — if
   recurring — a known-issue entry).
2. For a major incident (Sev-1/Sev-2), open an **incident bridge**, name an **incident commander**
   (coordinates, does not debug), and keep a running timeline. After resolution, run a brief
   **post-incident review** and feed any recurring pattern into the known-issue register.

## Step 6 — Handle known issues (`C2M Runbook - KnownIssue - Register`)
1. Seed the register before go-live from testing/UAT defects and the version's known-issue MOS notes
   — each entry: symptom, affected area, severity, **workaround**, and the tracking reference (a MOS
   note/patch number or an internal ticket). Do not reproduce gated content; point to it.
2. During hypercare, when an incident matches a known issue, apply the recorded workaround
   immediately and log the recurrence; when a new recurring issue appears, add it. Render the current
   register and open incidents with `OC2MHYPER-Report.sh` (read-only).

## Step 7 — Set up the day-2 build lane (`C2M Runbook - Day2 - Build Lane`)
1. Keep all further configuration and development in the **lower environments** (Dev/Test/UAT) during
   hypercare; nothing is built directly in the stabilizing production system.
2. Promote day-2 changes to production **only through change control** and the existing
   code-promotion path — same discipline as any production change: proven in a lower environment,
   backed up, with a rollback. List the day-2 environments and controls with
   `OC2MHYPER-ScopeHelper.sh --scope day2`.
3. Coordinate day-2 promotions with the on-call/hypercare team so a build change never collides with
   incident work or the daily cutover of the health snapshot.

## Step 8 — Configure the daily health/monitoring routine (`C2M Runbook - Health - Daily Routine`)
1. Fix the morning routine as a repeatable, read-only set — run it the same way every day:
   - **WebLogic** — Admin and managed servers RUNNING (WLST); no failed deployments.
   - **Batch** — last night's cycle completed; no errored threads; the Batch Job Submission backlog
     drained (via the JMX batch connector and the run-status report).
   - **Integration** — inbound/outbound queues within threshold; no stuck messages.
   - **Database & disk** — schema reachable, key tablespaces and log/filesystem space within
     threshold, no runaway sessions.
   - **Errors** — the delta of new ERROR/FATAL lines in the OUAF/WebLogic logs since yesterday.
2. Produce a **green/amber/red health snapshot** each morning: `OC2MHYPER-Report.sh` renders the
   operational summary and `OC2MHYPER-Report.sql` renders the batch/integration/database detail
   (both read-only). Attach the snapshot to the shift handover.
3. Any amber/red item opens an incident at the appropriate severity (Step 5).

## Step 9 — Pilot the whole model on a non-production dress rehearsal
1. On the non-production environment, **rehearse the cutover plan** end to end (Step 2), time each
   step, and prove the rollback works.
2. **Run the daily health routine** for several days against non-production so the snapshot,
   thresholds, and scripts are proven before go-live.
3. **Tabletop the support structure**: walk one Sev-1 and one Sev-3 through the severity model,
   rota, escalation matrix, incident procedure, and known-issue register — confirm each reaches the
   right owner within its target and is recorded.
4. Run `OC2MHYPER-Validation.sh` to confirm the technical readiness and health signals are present.

> **Gate — Pilot.** The dress rehearsal passes only when: the cutover ran within its timebox and the
> rollback was proven; the health routine ran clean for the agreed number of days; and the Sev-1 and
> Sev-3 tabletops reached the right owners within target and were recorded.

## Step 10 — Expand into the live cutover and hypercare
1. Execute the live cutover per `C2M Runbook - Cutover - Plan` under change control with backups taken
   first; make the go/no-go call at the decision point; roll back rather than force a failed cutover.
2. Enter hypercare: staff the rota, run the daily health routine every morning, handle incidents
   through the procedure, keep the known-issue register current, and run day-2 builds through the
   lower-environment lane.
3. Re-run `OC2MHYPER-Validation.sh` and the health reports each day of hypercare; keep the snapshot in
   the shift handover so health stays visible day over day.
4. **Exit hypercare to steady-state** only when the exit gate is met: health green for the agreed
   number of consecutive days, incident rate below threshold, no open Sev-1/Sev-2, and the day-2
   backlog controlled. The runbook then becomes the standing operations runbook.

> **Gate — Steady-state exit.** Hypercare ends only when the exit criteria above are met; until then
> the elevated support model stays in force.

---
### Order of operations
`Readiness checklist -> Cutover plan -> Severity model -> On-call + escalation -> Incident procedure -> Known-issue register -> Day-2 lane -> Daily health routine -> Pilot (dress rehearsal) -> Expand (live cutover + hypercare) -> Steady-state exit`
