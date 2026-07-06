# 6. Troubleshooting Guide — Oracle C2M Monitoring & Alerting with Dynatrace

Use `OC2MDYNA-Discovery.sh` and `OC2MDYNA-Validation.sh` for coverage and configuration state,
`OC2MDYNA-Report.sh` for the coverage/health snapshot, and `OC2MDYNA-Remediation.sh` (dry-run by
default) for safe fixes to coverage/config gaps. Set the read-scoped API token as an environment
variable first — the scripts never print it. Dynatrace product specifics move between releases: verify
paths, metric keys, and API shapes against the current Dynatrace documentation for your tenant version.
Oracle/MOS-gated notes are pointed to, not reproduced.

## A. A host is not reporting an OneAgent
| Symptom | Cause | Remediation |
|---|---|---|
| Host absent from coverage | OneAgent not installed on that host | Install OneAgent (`--set-host-group=C2M-Env-<env>`); `OC2MDYNA-Remediation.sh` prints the install command (dry-run) |
| Host present but stale/offline | Agent stopped, or host lost egress to the tenant | Confirm the OneAgent service is running and the host can reach the tenant/ActiveGate; re-check with `OC2MDYNA-Validation.sh` |
| JVMs not seen though host is up | Deep monitoring not active for that process | Confirm OneAgent deep monitoring is enabled for the host and the WebLogic/worker processes are running; verify Java support for your OS per Dynatrace docs |

## B. A C2M JVM is instrumented but a metric is missing
| Symptom | Cause | Remediation |
|---|---|---|
| No connection-pool metrics | JMX / Connection Pools WebLogic extension not enabled | Enable the Java Metric Extensions 2.0 (JMX) feature / Connection Pools extension per Dynatrace docs; `OC2MDYNA-Validation.sh` re-checks presence |
| No batch worker signal | Worker process not detected / worker host not covered | Confirm the thread pool worker host has OneAgent and the worker JVM is running; scope it in `OC2MDYNA-ScopeHelper.sh` |
| Endpoint timing absent | Service not detected / no traffic during the window | Generate representative traffic; confirm the online/IWS service is detected before dashboarding it |

## C. The environment tag is wrong or missing
- An entity has no `C2M-Env` tag, or the wrong value, so it slips a dashboard filter or an alerting
  profile scope. The host group was not set (or set wrong) at install. Re-install/adjust the host group
  to the correct `C2M-Env-<env>`; `OC2MDYNA-Validation.sh` reports which hosts lack the tag. Tag at
  install time — retro-tagging a live fleet is error-prone.

## D. A dashboard tile is empty
| Symptom | Cause | Remediation |
|---|---|---|
| Tile empty for an in-scope tier | That tier not instrumented, or metric not populated | Confirm coverage (Section A) and the underlying metric (Section B) before assuming the tile is wrong |
| Whole dashboard empty | Management-zone scope excludes the entities | Confirm `C2M - Monitoring Zone` includes the C2M hosts/processes (by host group/tag) |

## E. An alert does not fire
| Symptom | Cause | Remediation |
|---|---|---|
| Condition clearly breached, no problem | Metric event threshold/window too loose, or wrong metric selected | Re-check the metric event's metric, threshold, and detection window; tune off the pilot baseline (Best Practices) |
| Rule missing entirely | Alert rule never created in the zone | `OC2MDYNA-Validation.sh` reports which of the five named rules are missing; create them per Implementation Step 5 |
| Fires but only sometimes | Sustained-breach requirement not met | Confirm the "for N intervals" condition matches how the signal behaves; C2M batch spikes may need a sustained window, not a single sample |

## F. An alert fires but nobody is notified
- A problem opens in Dynatrace but on-call gets nothing. The alerting profile or notification is
  misconfigured. Confirm `C2M - Production Alerts` scopes the `C2M - Monitoring Zone` and matches the
  event/severity, and that `C2M - OnCall Notification` is bound to it and points at the live destination
  (email/Slack/Opsgenie/PagerDuty). Profile conditions combine with AND — an over-tight filter silences
  everything. ([Dynatrace Docs — Alerting profiles](https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/alerting-profiles))

## G. Too many alerts / alert fatigue
- The on-call channel is noisy. Either a threshold is set inside the normal range, or non-production is
  leaking onto the production profile. Re-tune the threshold above the observed healthy baseline, and
  confirm `C2M - Production Alerts` is filtered to the `prod` value of `C2M-Env` so non-production never
  pages. Use maintenance windows / muting for planned batch and patching rather than deleting rules.

## H. Diagnostics quick reference
```bash
export DT_API_TOKEN=...            # read-scoped token, from the secrets store (never committed/echoed)
export DT_ENV_URL=https://your-tenant.live.dynatrace.com
./OC2MDYNA-Discovery.sh            # tenant reachable; which hosts/JVMs are already seen (read-only)
./OC2MDYNA-Validation.sh           # coverage, C2M-Env tag, pool metrics, dashboards/alerts present (read-only)
./OC2MDYNA-Report.sh               # one coverage/health snapshot to attach to a change record (read-only)
./OC2MDYNA-Remediation.sh          # dry-run by default; prints the intended fix (install/tag/alert)
```

## I. When to escalate
If every in-scope tier reports a running OneAgent, the dashboards render, the alert rules exist and are
scoped, and an expected condition still does not alert or route after tuning, capture
`OC2MDYNA-Validation.sh` and `OC2MDYNA-Report.sh` output and review the metric-event and
alerting-profile configuration against the current Dynatrace documentation for your tenant version — the
mechanics (metric keys, profile filters) may have changed release-to-release. For C2M/WebLogic-side
questions consult the version's My Oracle Support notes and open a service request — gated content is
pointed to, not reproduced here.
