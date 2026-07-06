# 3. Implementation Guide — Oracle C2M Monitoring & Alerting with Dynatrace

Follow these steps in order. This guide instruments the C2M / WebLogic 14c tiers with Dynatrace
OneAgent first, then builds the C2M dashboards, then defines the standardized alerts and their
notification, then validates coverage — pilot-first on a non-production environment, then expand to
production under change control. Object names are fixed — create them with the exact names shown and
reuse them everywhere.

> Model: assess what Dynatrace already sees, configure coverage plus dashboards and alerts, prove it on
> a non-production pilot, validate against the gate, then expand to production. Assess, then Configure,
> then Pilot, then Validate, then Expand — with a documented rollback for every production change.

> **Dynatrace specifics move between releases.** Installer flags, Settings menu paths, metric keys, and
> API request shapes below are the current, authentic approach; **verify each against the Dynatrace
> documentation for your tenant version** before running it. Never print or commit a token — reference
> it from an environment variable / secrets store.

## Step 1 — Assess current coverage
1. Run `OC2MDYNA-ScopeHelper.sh --scope pilot` to fix the pilot target list (the WebLogic online
   servers, the OUAF thread pool worker hosts, IWS nodes, and the DB host for the pilot environment),
   then `--scope all` for the full expansion set.
2. With the read-scoped API token set as an environment variable, run `OC2MDYNA-Discovery.sh`. It
   confirms tenant reachability and reports which in-scope hosts already report a running OneAgent and
   which C2M JVMs/processes Dynatrace already sees (read-only). Record gaps against the Requirements
   Guide checklist. Do not proceed past a missing tenant, missing token, or unknown topology — implement
   those first.

## Step 2 — Instrument the tiers with OneAgent
1. In the Dynatrace tenant, obtain the OneAgent Linux install command for your environment (it embeds
   the environment URL and the installer token). ([Dynatrace Docs — Install OneAgent on
   Linux](https://docs.dynatrace.com/docs/ingest-from/dynatrace-oneagent/installation-and-operation/linux/installation/install-oneagent-on-linux))
2. On each in-scope host, install OneAgent as root/sudo and set the **host group** so the environment
   is tagged from the start — this solution standardizes the host-group tag `C2M-Env` with a value per
   environment:
   ```bash
   # download (token supplied via env var — never inline it), then install with the host group set
   sudo /bin/sh Dynatrace-OneAgent-Linux.sh --set-host-group=C2M-Env-prod
   ```
   (The exact installer name and the `--set-host-group` flag are Dynatrace's — verify for your version.
   Installing OneAgent is sufficient to deep-monitor the WebLogic managed servers and the OUAF thread
   pool worker JVMs on that host; no per-app configuration is required. ([Dynatrace Hub —
   WebLogic](https://www.dynatrace.com/technologies/java-monitoring/weblogic/)))
3. Enable the **Java Metric Extensions 2.0 (JMX)** feature / the Connection Pools WebLogic extension so
   JDBC connection-pool depth and waits are captured for the managed servers (Requirement 2.5).
   ([Dynatrace Docs — Connection Pools
   WebLogic](https://docs.dynatrace.com/docs/observe/infrastructure-observability/extensions/connection-pools-weblogic))
4. Run `OC2MDYNA-Validation.sh` to confirm each pilot host now reports a running OneAgent with the
   `C2M-Env` tag and that connection-pool metrics are present.

## Step 3 — Define the management zone and environment tag
1. Create the management zone `C2M - Monitoring Zone` scoped to the C2M hosts/processes (by the host
   group / tag). This is what every dashboard and alerting profile filters on so they see C2M only.
2. Confirm the `C2M-Env` host-group tag is present on every entity (it flows from the install in Step 2)
   so alerts can be scoped and muted per environment.

## Step 4 — Build the C2M dashboards
Build three named dashboards so C2M health reads at a glance. (Use the tenant's dashboard editor;
tile/metric names are the current Dynatrace ones — verify for your version.)
1. **`C2M - Service Health`** — the online and IWS/REST endpoints: response time, failure rate, and
   throughput of the key C2M services, plus service availability. This is the "are users being served"
   view.
2. **`C2M - JVM & Batch`** — per tier (online servers and each thread pool worker): heap used vs
   committed, garbage-collection time / suspension, thread count, and worker process availability. This
   is the "are the JVMs healthy and is batch running" view.
3. **`C2M - Infrastructure`** — hosts (CPU, memory, disk), WebLogic managed-server availability, and the
   JDBC **connection-pool** depth/waits from the JMX extension. This is the "is the platform under it
   healthy" view.
Scope all three to the `C2M - Monitoring Zone`.

## Step 5 — Define the standardized alerts (custom metric events)
Dynatrace already auto-detects some conditions (long garbage-collection time; out-of-memory /
out-of-threads events for Java). ([Dynatrace Docs — Java OOM/OOT
alerting](https://docs.dynatrace.com/docs/setup-and-configuration/technology-support/application-software/java/set-up-event-and-memory-alerting))
Add the following **custom metric events** with static thresholds (Settings → Anomaly detection →
Metric events, or the equivalent for your version) so the signals that matter to C2M alert
deliberately. Name each exactly:
- **`C2M Alert - JVM Heap High`** — heap-utilization percentage over threshold, sustained (for example
  used/committed high for several intervals), per WebLogic/worker JVM.
- **`C2M Alert - GC Time High`** — garbage-collection time / suspension above threshold (complements
  Dynatrace's built-in long-GC detection with your own tuned bound).
- **`C2M Alert - Connection Pool Exhausted`** — JDBC active-vs-max connections at capacity or waiters
  present, from the JMX/Connection Pools extension.
- **`C2M Alert - Endpoint Failure Rate`** — failure rate of a key online/IWS service over threshold.
- **`C2M Alert - Batch Worker Down`** — a thread pool worker process/host not reporting (worker JVM
  unavailable).
Give each a clear title, threshold, and (where useful) a dimension split per entity, and keep them in
the `C2M - Monitoring Zone`. Static thresholds are the metric-key-based event type; use auto-adaptive
or seasonal baselines only where a fixed number does not fit. ([Dynatrace Docs — Metric
events](https://www.dynatrace.com/support/help/how-to-use-dynatrace/problem-detection-and-analysis/basic-concepts/event-types/resource-events))

## Step 6 — Route alerts with an alerting profile and notification
1. Create the alerting profile `C2M - Production Alerts`. Set its scope to the `C2M - Monitoring Zone`
   and filter to the `prod` value of `C2M-Env`, with severity rules and event filters for the C2M alert
   rules from Step 5. An event must satisfy the profile's management-zone, severity, and event
   conditions (AND) to notify. ([Dynatrace Docs — Alerting
   profiles](https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/alerting-profiles))
2. Create the notification `C2M - OnCall Notification` (email, or a Slack/Opsgenie/PagerDuty
   integration) and bind it to the `C2M - Production Alerts` profile so C2M production problems reach
   on-call. Non-production stays off this profile so it does not page.

## Step 7 — Pilot on non-production
1. On the non-production environment, confirm every pilot tier is instrumented, the three dashboards
   render real data, and the alert rules exist and are scoped to the zone.
2. Run `OC2MDYNA-Validation.sh` to confirm OneAgent coverage across the pilot topology, the `C2M-Env`
   tag, connection-pool metrics, and that the named dashboards/alerting profile exist.
3. Deliberately exercise an alert in non-production (for example drive heap or endpoint failure on a
   throwaway load) and confirm the metric event fires and — via a non-production test profile — routes
   as expected. Capture the state with `OC2MDYNA-Report.sh`.

## Step 8 — Validate against the pilot gate
1. Complete the Testing Guide. The pilot passes only when: every in-scope tier reports a running
   OneAgent with the `C2M-Env` tag; the three dashboards show live C2M data; connection-pool metrics are
   present; every named alert rule exists in the zone; and at least one alert was proven to fire and
   route.
2. Remediate any coverage or config gap with `OC2MDYNA-Remediation.sh` (dry-run by default — it prints
   the intended action, such as the OneAgent install command for a missing host or the missing
   tag/alert to create; apply only in a change window) before re-running validation.

## Step 9 — Expand to production
1. After the pilot passes the gate, instrument the remaining production hosts (`--set-host-group=
   C2M-Env-prod`), and create the same management zone, dashboards, alert rules, alerting profile, and
   notification in production, with a config export of the dashboards/alerting profiles taken first as
   the rollback.
2. Re-run `OC2MDYNA-Validation.sh` and `OC2MDYNA-Report.sh` in production; keep the dashboards as the
   standing operational view and confirm the on-call notification is live so C2M problems are seen
   first, not reported by users.

---
### Order of operations
`Assess coverage -> Instrument tiers (OneAgent + JMX) -> Management zone & tag -> Build dashboards -> Define standardized alerts -> Route via profile + notification -> Pilot -> Validate gate -> Expand to production`
