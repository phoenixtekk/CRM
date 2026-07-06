# 2. Requirements Guide — Oracle C2M Monitoring & Alerting with Dynatrace

Verify every requirement before instrumenting tiers, building dashboards, or defining alerts. Each
entry: Description, Why, Verify, Implement-if-missing. Category-wide prerequisites (licensing, certified
stack, environments, WLST/shell/SQL tooling, change control, and the monitoring/support model) are in
`global-requirements-oracle.md`. Dynatrace product specifics move between releases — where a step names
a Dynatrace path or metric key, **verify it against the current Dynatrace documentation** for your
tenant version.

## 2.1 A Dynatrace tenant reachable from the C2M hosts
Description: A Dynatrace environment (SaaS `https://your-tenant.live.dynatrace.com`, or Managed) that
the C2M/WebLogic hosts can reach outbound (directly or via an ActiveGate), with an environment ID you
know.
Why: OneAgent must reach the tenant to register hosts and ship telemetry, and the dashboards/alerts
you build live in that tenant; without it there is nothing to instrument into.
Verify: From a C2M host, confirm outbound reachability to the tenant (or the ActiveGate) and note the
environment ID; run `OC2MDYNA-Discovery.sh`, which checks tenant reachability (read-only).
Implement-if-missing: Provision or obtain access to the tenant (and an ActiveGate if the hosts have no
direct egress); confirm the environment ID and base URL.

## 2.2 A PaaS/installer token and an API token (least privilege)
Description: A **OneAgent installer (PaaS) token** to download/install OneAgent, and a separate
**API token** scoped for read (for example metrics read and entities read) used by the discovery and
report scripts. Tokens are held in the environment/secrets store — never printed or committed.
Why: OneAgent install and the API-based coverage checks each need a token; least-privilege, separate
tokens keep install rights and read rights distinct and revocable.
Verify: The tokens exist and are stored as environment variables/secrets; run `OC2MDYNA-Discovery.sh`
with the API token set (via env var) — it confirms the token authenticates for read (it never echoes
the token).
Implement-if-missing: Generate the installer token and a read-scoped API token in the Dynatrace tenant
(Access tokens), store them in the secrets store, and reference them by env var only.

## 2.3 The C2M / WebLogic topology in scope
Description: A known inventory of the hosts and JVMs to monitor — the WebLogic AdminServer and managed
servers (online tier), the OUAF **thread pool worker** hosts (batch), any IWS/integration nodes, and
the database host — with which environment (dev/test/prod) each belongs to.
Why: Coverage is only "complete" against a known target list; you cannot confirm every C2M JVM is
instrumented if you do not know how many there are.
Verify: You can list the C2M hosts/JVMs per environment; run `OC2MDYNA-ScopeHelper.sh --scope pilot`
to emit the pilot target list, then `all` for expansion.
Implement-if-missing: Compile the topology from the WebLogic domain (managed servers/machines) and the
OUAF worker configuration with the infrastructure team; record host, role, and environment for each.

## 2.4 OneAgent deployable on every C2M host (root/sudo, host group tag)
Description: The ability to install OneAgent on each in-scope host (root/sudo for the install), and a
decided **host group** naming so environment is tagged at install time — this solution uses the host
group tag `C2M-Env` with a value per environment (`dev`/`test`/`prod`).
Why: Deep-code monitoring of the WebLogic and worker JVMs comes from OneAgent on the host; the host
group/tag is what lets dashboards and alerting profiles scope and mute per environment.
Verify: You can run the installer on a host and set its host group; run `OC2MDYNA-Validation.sh`, which
reports which in-scope hosts already report a running OneAgent and whether the `C2M-Env` tag is set.
Implement-if-missing: Obtain install privileges and agree the host-group value per environment before
the pilot install.

## 2.5 WebLogic connection-pool / JMX metrics enabled
Description: The Dynatrace **Java Metric Extensions 2.0 (JMX)** feature (or the Connection Pools
WebLogic extension) enabled so JDBC connection-pool depth, waits, and capacity are captured for the
managed servers.
Why: Connection-pool exhaustion stalls the whole online application; without the JMX/extension metrics
there is no pool-depth signal to dashboard or alert on. ([Dynatrace Docs — Connection Pools
WebLogic](https://docs.dynatrace.com/docs/observe/infrastructure-observability/extensions/connection-pools-weblogic))
Verify: Pool metrics appear for the WebLogic processes in Dynatrace; `OC2MDYNA-Validation.sh` checks
whether connection-pool metrics are present for the in-scope managed servers.
Implement-if-missing: Enable the JMX metric extension / Connection Pools WebLogic extension per the
current Dynatrace documentation and confirm the metrics populate.

## 2.6 Environment access to build dashboards, alerts, and notifications
Description: Dynatrace user access with permission to create **management zones**, **dashboards**,
**metric events (custom alerts)**, **alerting profiles**, and **notification integrations**, plus the
details of the notification destination (email list, or the Slack/Opsgenie/PagerDuty target).
Why: The deliverable is the configured dashboards and the standardized, routed alerts; without config
rights and a destination there is nowhere for an alert to go.
Verify: You can create a test dashboard and a test alerting profile in the tenant, and you have the
destination details; recorded against the checklist.
Implement-if-missing: Obtain the tenant role/permissions and confirm the on-call notification
destination with the operations team before building alerts.

## 2.7 Alert destination and on-call routing decided
Description: A decided routing for C2M production alerts — who is notified, by what channel, and the
severity that pages versus emails — realized as the notification `C2M - OnCall Notification` bound to
the `C2M - Production Alerts` profile.
Why: An alert nobody receives is not an alert; standardized routing is what turns a fired problem into
a response, and per-environment scoping keeps non-production noise off the on-call channel.
Verify: The destination is confirmed and a test problem/notification reaches it; validated in the pilot.
Implement-if-missing: Agree the channel and on-call schedule with operations; create the notification
integration and bind it to the production alerting profile.

## 2.8 A non-production pilot environment and change control
Description: A non-production C2M environment to instrument, dashboard, and prove the alerts on before
production, plus change control and backups (config exports of dashboards/alerting profiles) per the
global requirements.
Why: Instrumentation and alert definitions are changes to a live monitoring surface; the model is
Assess → Configure → Pilot → Validate → Expand with a documented rollback (delete/disable the added
alert or restore the prior dashboard export).
Verify: A non-production environment is available and you can export/re-import the dashboard and
alerting-profile config for rollback.
Implement-if-missing: Stand up or obtain the non-production environment and establish the config-export
backup and change window before any production change.

---
## Checklist
- [ ] Dynatrace tenant reachable from C2M hosts, environment ID known — `OC2MDYNA-Discovery.sh`
- [ ] Installer (PaaS) token + read-scoped API token, stored as secrets (never printed) — `OC2MDYNA-Discovery.sh`
- [ ] C2M/WebLogic topology in scope (online, workers, IWS, DB) per environment — `OC2MDYNA-ScopeHelper.sh`
- [ ] OneAgent deployable on every host; host-group tag `C2M-Env` decided — `OC2MDYNA-Validation.sh`
- [ ] WebLogic connection-pool / JMX metrics enabled — `OC2MDYNA-Validation.sh`
- [ ] Access to build management zone, dashboards, metric events, alerting profiles, notifications
- [ ] Alert destination + on-call routing decided — `C2M - OnCall Notification`
- [ ] Non-production pilot + change control and config-export backups
