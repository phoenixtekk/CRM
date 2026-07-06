# 1. Solution Overview — Oracle C2M Monitoring & Alerting with Dynatrace

## What this monitors
Once Oracle Utilities Customer to Meter (C2M) is live, the job changes from *installing* it to *seeing
it* — catching a slow endpoint, a leaking JVM, or a stalled batch run before a business user does. C2M
runs as Java on **Oracle WebLogic Server 14c**: an online tier (the servlet application), one or more
**thread pool worker** JVMs that run batch, and integration endpoints (IWS / REST), all over an Oracle
database. This solution instruments those tiers with **Dynatrace** (the **OneAgent** deep-code
monitor), builds the **service and infrastructure dashboards** that show C2M health at a glance, and
defines a standardized set of **alerts** on the signals that actually matter — JVM/heap/GC, WebLogic
services and connection pools, batch throughput, and online/IWS endpoints — so the team responds to
health, not to surprises. It is configured the repeatable way: named dashboards, named alerting
profiles, and named alert rules you define once and reuse across every environment.

> **Vendor & version boundary.** C2M, OUAF, and WebLogic 14c terminology is from Oracle's product and
> Server Administration documentation; version-specific details (C2M 25.4 / minimum v2.9, WebLogic
> 14c) are **cited or flagged "verify for your version"** — never invented. **Dynatrace product
> internals** (OneAgent installer flags, exact Settings paths, metric keys, API request shapes) move
> between releases: this solution gives the authentic, current approach and **defers deep specifics to
> the Dynatrace documentation** rather than reproducing them. Some Oracle notes/patches are gated on My
> Oracle Support (MOS) and are pointed to, not reproduced. See `global-requirements-oracle.md`.

## Why this matters
Blind operations is expensive. Without instrumentation, the first sign of a problem is a phone call:
online response has degraded, the nightly batch window overran, an integration is timing out. Without
dashboards, "is C2M healthy?" is answered by logging into servers one at a time. Without standardized
alerts, either nothing fires (and problems are found late) or everything fires (and the team learns to
ignore the noise). A real monitoring solution fixes the cause of blindness: it puts a deep-code agent
on every tier so the signals exist, curates them into dashboards a duty operator can read in seconds,
and defines a *deliberate, tuned* set of alerts routed to the right destination — turning "did anyone
notice?" into "we saw it first."

## What Dynatrace gives you on this stack
Dynatrace's **OneAgent** installs once per host and auto-detects the Java processes on it, including
WebLogic managed servers and OUAF thread pool workers, providing deep-code tracing, JVM metrics
(heap, garbage collection, threads), and service-level timing without per-app configuration. ([Dynatrace
Hub — WebLogic](https://www.dynatrace.com/technologies/java-monitoring/weblogic/)) For WebLogic
connection-pool depth it exposes the **Java Metric Extensions 2.0 (JMX)** feature / the Connection
Pools WebLogic extension. ([Dynatrace Docs — Connection Pools
WebLogic](https://docs.dynatrace.com/docs/observe/infrastructure-observability/extensions/connection-pools-weblogic))
Alerting is layered: Dynatrace auto-detects anomalies (for example long garbage-collection time, and
out-of-memory / out-of-threads events for Java), and you add **custom metric events** with static
thresholds for the signals you care about, then route them with **alerting profiles** filtered by
**management zone**, severity, and event type to a notification destination. ([Dynatrace Docs — Metric
events](https://www.dynatrace.com/support/help/how-to-use-dynatrace/problem-detection-and-analysis/basic-concepts/event-types/resource-events),
[Alerting profiles](https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/alerting-profiles))

## The four things to monitor across C2M / WebLogic
1. **JVM health (per tier)** — heap used vs committed, garbage-collection time and suspension, thread
   count, and out-of-memory / out-of-threads events. The online tier and each thread pool worker are
   separate JVMs and are watched separately. Dynatrace alerts by default on long GC time; you add
   heap-utilization and OOM/OOT alerting explicitly. ([Dynatrace Docs — Java OOM/OOT
   alerting](https://docs.dynatrace.com/docs/setup-and-configuration/technology-support/application-software/java/set-up-event-and-memory-alerting))
2. **WebLogic services & resources** — managed-server availability, JDBC **connection-pool** capacity
   and waits (pool exhaustion stalls the whole application), and stuck/active thread counts on the
   online servers.
3. **Batch throughput** — the OUAF thread pool workers: are threads completing, is the Batch Job
   Submission backlog draining, are runs finishing inside the window. (Batch run status itself lives in
   the C2M schema and via the JMX batch client; Dynatrace watches the *JVMs and hosts* that run it and
   can alert on the process health and the database/host signals around it.)
4. **Online & integration endpoints** — response time and failure rate of the key C2M online services
   and the IWS/REST inbound integration endpoints, so a slow or failing endpoint is seen as a service
   problem, not a user complaint.

## Named objects this solution defines
So the configuration is repeatable, the artifacts are named once and reused:

- **Management zone** — `C2M - Monitoring Zone`, scoping every C2M host/process so dashboards and
  alerting profiles filter to C2M only.
- **Host group tag** — `C2M-Env` (values such as `dev`, `test`, `prod`), applied at OneAgent install so
  environment shows on every entity and alerts can be scoped/muted per environment.
- **Dashboards** — `C2M - Service Health` (endpoints, response time, failure rate), `C2M - JVM & Batch`
  (heap/GC/threads per tier and batch worker health), and `C2M - Infrastructure` (hosts, CPU/memory,
  WebLogic connection pools).
- **Alerting profile** — `C2M - Production Alerts`, filtered to the `C2M - Monitoring Zone` and the
  `prod` environment, routing to the on-call destination.
- **Alert rules (custom metric events)** — `C2M Alert - JVM Heap High`, `C2M Alert - GC Time High`,
  `C2M Alert - Connection Pool Exhausted`, `C2M Alert - Endpoint Failure Rate`, and
  `C2M Alert - Batch Worker Down`.
- **Notification** — `C2M - OnCall Notification`, the destination (email/Slack/Opsgenie/PagerDuty)
  bound to the production alerting profile.

## What this is not
This solution instruments C2M and WebLogic with Dynatrace and defines the dashboards and alerts. It
does not replace C2M's own batch run-status tables or the JMX batch client (those remain the system of
record for batch), does not tune WebLogic or C2M itself (a monitoring signal tells you *where* to
tune), and does not reproduce Dynatrace's own product manual — deep OneAgent/API specifics are deferred
to the Dynatrace docs. Where the included scripts touch live systems they **read**: discovery,
validation, and report are read-only; remediation runs **dry-run by default**. Any change lands on a
non-production environment first and goes to production under change control.

## The deployment model
> Assess the C2M topology and what Dynatrace already sees, configure the OneAgent coverage plus the
> dashboards and standardized alerts, pilot on a non-production environment, validate that coverage is
> complete and alerts fire correctly against a gate, then expand to production. The repeatable way:
> Assess, then Configure, then Pilot, then Validate, then Expand — with a documented rollback for every
> production change.
