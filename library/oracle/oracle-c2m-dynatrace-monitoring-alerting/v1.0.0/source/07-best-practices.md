# 7. Best Practices — Oracle C2M Monitoring & Alerting with Dynatrace

- Alert on the signal, not on everything. Ship the deliberate, standardized set — heap, GC, connection
  pool, endpoint failure rate, batch worker down — and resist adding an alert for every metric on the
  dashboard. A curated set that always means "act now" beats a hundred rules the team learns to ignore.
- Tune thresholds off the pilot's own baseline, not a guess. Watch each signal on `C2M - JVM & Batch`
  and `C2M - Service Health` over a normal cycle, then set the static threshold above the observed
  healthy range so the alert marks a real deviation. Re-tune after the first weeks in production; a
  threshold that fires nightly on normal batch is noise, not signal.
- Let Dynatrace's built-in detection do its job, then add yours. Dynatrace already alerts on long
  garbage-collection time and on out-of-memory / out-of-threads events for Java; add
  `C2M Alert - GC Time High` and `C2M Alert - JVM Heap High` as your own tuned bounds rather than
  duplicating what the platform already catches. ([Dynatrace Docs — Java OOM/OOT
  alerting](https://docs.dynatrace.com/docs/setup-and-configuration/technology-support/application-software/java/set-up-event-and-memory-alerting))
- Scope every alerting profile to the `C2M - Monitoring Zone` and the environment. Filter
  `C2M - Production Alerts` to `prod` so non-production never pages on-call; management zone + severity +
  event filters combine with AND, so a tight scope is a quiet on-call channel. ([Dynatrace Docs —
  Alerting profiles](https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/alerting-profiles))
- Tag environment at install time, not after. Set the `C2M-Env` host group when you install OneAgent so
  every entity carries it from the first data point — retro-tagging a live fleet is error-prone, and
  every dashboard filter and alert scope depends on it.
- One OneAgent per host covers all the JVMs on it. You do not instrument WebLogic and each thread pool
  worker separately — installing OneAgent on the host deep-monitors every Java process on it. Confirm
  coverage per *host*, and confirm the JVMs are *seen* per tier. ([Dynatrace Hub —
  WebLogic](https://www.dynatrace.com/technologies/java-monitoring/weblogic/))
- Watch the connection pool as closely as the JVM. Pool exhaustion stalls the whole online application
  while the JVM still looks "up"; the JMX / Connection Pools extension is what makes it visible, so keep
  that metric on `C2M - Infrastructure` and alerted via `C2M Alert - Connection Pool Exhausted`.
- Keep the dashboards role-shaped and stable. `C2M - Service Health` for the duty operator,
  `C2M - JVM & Batch` for the middleware/app team, `C2M - Infrastructure` for the platform team — name
  them once and reuse across environments so everyone reads the same view.
- Mute deliberately during maintenance, do not delete. Use maintenance windows / profile muting for
  planned batch or patching so expected conditions do not page, rather than deleting the alert and
  forgetting to restore it.
- Version-control your monitoring config. Export dashboards and alerting profiles (config as JSON) so a
  change is reviewable and reversible — that export is your rollback when you expand to production.
- Prove the alert path before you rely on it. An alert that has never fired is untested; exercise each
  new rule on a throwaway non-production load and confirm it reaches `C2M - OnCall Notification` before
  trusting it in production.
- Defer deep Dynatrace specifics to the vendor docs. Metric keys, Settings paths, and API shapes change
  between Dynatrace releases; keep this solution's names and thresholds, but verify the mechanics
  against the current Dynatrace documentation for your tenant version.
