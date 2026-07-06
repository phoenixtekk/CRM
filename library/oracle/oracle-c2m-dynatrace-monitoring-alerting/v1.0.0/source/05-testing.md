# 5. Testing Guide — Oracle C2M Monitoring & Alerting with Dynatrace

Run after the pilot on the non-production environment (Implementation Step 7) and again after
production expansion. Each test confirms one part of the monitoring and alerting is working end to end.
Set the read-scoped API token as an environment variable first (never inline it); the scripts never
print it.

## Test 1 — Every in-scope tier is instrumented
Do: Run `OC2MDYNA-Validation.sh` against the scope from `OC2MDYNA-ScopeHelper.sh`.
Expected: Every in-scope host (WebLogic online servers, each OUAF thread pool worker, IWS nodes, DB
host) reports a **running OneAgent**, and Dynatrace sees the WebLogic and worker JVMs — no in-scope
host missing coverage.

## Test 2 — The environment tag is set
Do: Check the host group / tag on the instrumented hosts; `OC2MDYNA-Validation.sh` reports it.
Expected: Every C2M host carries the `C2M-Env` tag with the correct environment value (`dev`/`test`/
`prod`) so dashboards and alerting profiles can scope and mute per environment.

## Test 3 — Connection-pool metrics are present
Do: Confirm JDBC connection-pool metrics populate for the managed servers; `OC2MDYNA-Validation.sh`
checks it.
Expected: Pool depth/waits appear for the in-scope WebLogic managed servers (the JMX / Connection Pools
extension is active) — pool exhaustion is observable.

## Test 4 — The dashboards render live C2M data
Do: Open `C2M - Service Health`, `C2M - JVM & Batch`, and `C2M - Infrastructure`.
Expected: Each dashboard shows real, current data scoped to the `C2M - Monitoring Zone` — endpoints and
failure rate, per-tier heap/GC/threads and worker health, and hosts plus connection pools — with no
empty tiles for an in-scope tier.

## Test 5 — The standardized alert rules exist and are scoped
Do: List the metric events / alert rules; `OC2MDYNA-Validation.sh` reports their presence.
Expected: All five named rules exist in the zone — `C2M Alert - JVM Heap High`, `C2M Alert - GC Time
High`, `C2M Alert - Connection Pool Exhausted`, `C2M Alert - Endpoint Failure Rate`, `C2M Alert - Batch
Worker Down` — each with a threshold.

## Test 6 — An alert fires on a real condition (non-production)
Do: On a throwaway non-production load, drive a monitored signal past its threshold (for example heap
utilization or endpoint failure rate).
Expected: The corresponding metric event opens a problem in Dynatrace within its detection window — the
alert actually fires on the condition it is meant to catch.

## Test 7 — The alert routes to the destination
Do: With a non-production test alerting profile bound to the destination, confirm the fired problem
notifies.
Expected: The notification reaches `C2M - OnCall Notification` (or its non-production test equivalent) —
the on-call destination receives the alert. Production `C2M - Production Alerts` is scoped to `prod`
only, so non-production does not page the on-call channel.

## Test 8 — Coverage report is clean
Do: Run `OC2MDYNA-Report.sh` and review the coverage/health snapshot.
Expected: The report shows all in-scope tiers instrumented and tagged, dashboards and alert rules
present, and no coverage gaps — the artifact you attach to the change record and reuse as a baseline.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-6 pass on non-production: every tier instrumented and tagged, connection-pool metrics present, dashboards live, all five alert rules exist, and an alert proven to fire; plus Test 7 (routing) verified with a non-production test profile |
| Expand pass | Tests 1-5 and 8 pass in production after instrumenting the production tiers, and the `C2M - Production Alerts` profile + `C2M - OnCall Notification` are live and confirmed reachable |
