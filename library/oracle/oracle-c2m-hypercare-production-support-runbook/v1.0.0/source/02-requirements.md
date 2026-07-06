# 2. Requirements Guide — Oracle C2M Hypercare & Production Support Runbook

Verify every requirement before you gate cutover and stand up hypercare. Each entry: Description,
Why, Verify, Implement-if-missing. Category-wide prerequisites (licensing, certified stack,
environments, WLST/shell/SQL tooling, change control, collaborating teams and support model) are in
`global-requirements-oracle.md`.

## 2.1 A reachable C2M environment and product user
Description: The production C2M environment (and its OUAF product home) reachable, with the OS product
user that owns it — the account under which `threadpoolworker`/`starttpw` and the batch daemon run —
and the environment sourced via `splenviron.sh -e your-env`.
Why: Every readiness, health, and validation script needs the environment variables `splenviron.sh`
sets; without them the utilities cannot locate the WebLogic domain, the class path, or the
configuration. Hypercare's daily routine runs as this user.
Verify: As the product user, run `splenviron.sh -e your-env` then run `OC2MHYPER-Discovery.sh` — it
confirms the environment is sourced and the OUAF/WebLogic utilities are on the path.
Implement-if-missing: Obtain the product-user credentials and the environment name; confirm the OUAF
install is complete (`initialSetup`/`configureEnv` run) before proceeding.

## 2.2 A go-live readiness checklist and its owners
Description: A defined **Go-Live Readiness Checklist** (`C2M Runbook - Readiness - Go-Live Checklist`)
covering environment, data/migration sign-off, integrations, batch estate, security/SSO, monitoring,
backup/rollback, and support readiness — each item with an accountable owner and a go/no-go status.
Why: Cutover must begin from a gate, not a hunch; the checklist is what turns "are we ready?" into a
signed go/no-go with named owners for every open item.
Verify: The checklist exists with an owner per item; run `OC2MHYPER-Validation.sh`, which checks the
technical readiness signals (WebLogic servers, batch daemon, JMX, integration reachability) that back
the checklist.
Implement-if-missing: Build the checklist from this runbook (Implementation Step 1) and the program's
cutover plan; assign an owner to each line and to any pre-approved exception.

## 2.3 Monitoring and health-check access
Description: Read access to the signals the **daily health routine** depends on: the WebLogic
Administration Console / WLST for server state, the **JMX batch connector**
(`service:jmx:rmi:///jndi/rmi://your-host:your-jmx-port/oracle/ouaf/batchConnector` — verify for your
version) for live batch threads, the C2M schema for batch run status and integration queues, and the
OUAF/WebLogic log locations, plus whatever monitoring platform (e.g. Dynatrace) the environment uses.
Why: Hypercare closes the loop by measuring health daily; without read access to servers, batch, the
schema, and logs there is no `C2M Runbook - Health - Daily Routine` and problems surface from the
business instead of from operations.
Verify: You can reach WLST, query batch run status, and read the logs; run `OC2MHYPER-Report.sql`
(read-only) and confirm it returns recent batch and integration status.
Implement-if-missing: Grant the read-only reporting access (or use the product user); confirm WLST,
JMX, SQL, and log-path reachability per the global requirements.

## 2.4 On-call rota and contacts defined
Description: A staffed **on-call rota** (`C2M Runbook - OnCall - Rota`) — primary and secondary per
support window, by layer (application, middleware/WebLogic, database, integration, infrastructure) —
with current contact details and a shift-handover step.
Why: An incident with no named owner burns its first hour deciding who owns it; the rota makes
ownership immediate and continuous across shifts through hypercare.
Verify: The rota is published for the hypercare window with contacts for every layer; run
`OC2MHYPER-ScopeHelper.sh --scope rota` to render the current-window contact list from the rota file.
Implement-if-missing: Build the rota with the collaborating teams (global requirement 6); publish it
where the whole team can reach it and confirm every layer has a primary and a secondary.

## 2.5 Escalation matrix and severity model
Description: A defined **severity model** (`C2M Runbook - Severity - Model`, Sev-1…Sev-4 with response
targets) and an **escalation matrix** (`C2M Runbook - Escalation - Matrix`) mapping each severity to
who is engaged, in what order, within what time — up to the incident commander and the Oracle Service
Request path on My Oracle Support for product defects.
Why: Severity decides response time, who is paged, and comms cadence; without a rule it is argued live
during the incident. The matrix ensures the right people are engaged fast and the MOS path is known.
Verify: Severity definitions and the escalation matrix exist and are agreed; a tabletop walk of one
Sev-1 and one Sev-3 reaches the right owners within target. `OC2MHYPER-Validation.sh` confirms the
runbook files are present and non-empty.
Implement-if-missing: Adopt the severity model and matrix from this runbook (Implementation Steps 3-4)
and confirm the MOS account and SR process for defect escalation.

## 2.6 Incident and known-issue handling process
Description: A standard **incident procedure** (`C2M Runbook - Incident - Procedure`: detect → triage →
assign → diagnose → mitigate/resolve → communicate → record) and a **known-issue register**
(`C2M Runbook - KnownIssue - Register`) that captures recurring defects and their workarounds, many
tracked to a MOS note or patch.
Why: Without a procedure the same incident is diagnosed repeatedly and fixes are not recorded; without
a register a known symptom is re-diagnosed from scratch each time instead of worked around in minutes.
Verify: The procedure and an initialized register exist; run `OC2MHYPER-Report.sh` to render the
current open-incident / known-issue summary from the register file (read-only).
Implement-if-missing: Adopt the procedure and seed the register from testing/UAT defects and the
version's known-issue MOS notes before go-live.

## 2.7 Lower-environment access for day-2 build support
Description: Access to the **lower environments** (Dev/Test/UAT) so day-2 configuration and development
continue during hypercare without touching production — the `C2M Runbook - Day2 - Build Lane` — with
promotion to production only through change control (per the global requirements and any existing
code-promotion process).
Why: Hypercare does not stop the roadmap; day-2 work must keep flowing, but it must flow through lower
environments and change control, never directly into a stabilizing production system.
Verify: You can reach the lower environments and a promotion/change-control path to production exists;
`OC2MHYPER-ScopeHelper.sh --scope day2` lists the environments and controls in the day-2 lane.
Implement-if-missing: Obtain lower-environment access and confirm the change-control/promotion path
before hypercare begins.

## 2.8 Cutover plan, backups, and rollback
Description: A timeboxed **cutover plan** (`C2M Runbook - Cutover - Plan`) with a go/no-go decision
point, verified **backups** (WebLogic domain config, OUAF product/config, database) taken before
cutover, and a documented **rollback** to the pre-cutover state.
Why: Cutover is the single highest-impact change of the program; it must be sequenced, timeboxed,
gated with a go/no-go, and reversible. A rollback that is not written down is not a rollback.
Verify: The cutover plan, a confirmed backup/restore path, and a documented rollback all exist and
have been walked in a dress rehearsal on non-production.
Implement-if-missing: Author the cutover plan, take and test the backups, and document the rollback —
and rehearse the whole sequence on a lower environment before the live cutover.

## 2.9 A non-production dress rehearsal and change control
Description: A non-production environment to **rehearse** the cutover and the daily health routine, and
prove the support structure end to end before go-live, plus change control and backups per the global
requirements.
Why: The model is Assess → Configure → Pilot → Validate → Expand; the pilot is a dress rehearsal that
finds the gaps while they are cheap, not during the live cutover.
Verify: A non-production environment is available and the cutover, health routine, and an incident
tabletop have been rehearsed on it with a documented rollback.
Implement-if-missing: Stand up or obtain the non-production environment and schedule the dress
rehearsal before the go-live window.

---
## Checklist
- [ ] C2M environment reachable, product user, `splenviron.sh -e your-env` sources cleanly — `OC2MHYPER-Discovery.sh`
- [ ] Go-live readiness checklist with owners — `C2M Runbook - Readiness - Go-Live Checklist`, `OC2MHYPER-Validation.sh`
- [ ] Monitoring/health-check access (WLST, JMX batch connector, schema, logs) — `OC2MHYPER-Report.sql`
- [ ] On-call rota with contacts by layer — `C2M Runbook - OnCall - Rota`, `OC2MHYPER-ScopeHelper.sh --scope rota`
- [ ] Escalation matrix + severity model — `C2M Runbook - Escalation - Matrix`, `C2M Runbook - Severity - Model`
- [ ] Incident procedure + known-issue register — `C2M Runbook - Incident - Procedure`, `OC2MHYPER-Report.sh`
- [ ] Lower-environment access for day-2 builds — `C2M Runbook - Day2 - Build Lane`, `OC2MHYPER-ScopeHelper.sh --scope day2`
- [ ] Cutover plan, backups, documented rollback — `C2M Runbook - Cutover - Plan`
- [ ] Non-production dress rehearsal + change control
