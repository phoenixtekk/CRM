# Executive Summary — Oracle C2M Monitoring & Alerting with Dynatrace

Once Oracle Utilities Customer to Meter (C2M) is live, the job is to **see problems before users do** —
a slow endpoint, a leaking JVM, a stalled batch worker, an exhausted connection pool. Blind operations
finds those the expensive way: a phone call. This solution sets up **Dynatrace monitoring and
alerting** for C2M and its **WebLogic 14c** middleware: it instruments the online, batch (OUAF thread
pool worker), and integration tiers with the Dynatrace **OneAgent**, builds the service, JVM, and
infrastructure **dashboards** that show C2M health at a glance, and defines a **standardized, tuned set
of alerts** on the signals that matter — routed to on-call — so the team responds to health, not
surprises.

This is a complete, do-it-today package for an experienced C2M / monitoring administrator. Every object
is named once — the management zone, the environment tag, the three dashboards, the alerting profile,
the five alert rules, the notification — and reused across environments, so you configure it once and
repeat it. Deep Dynatrace product specifics (installer flags, metric keys, API shapes) are deferred to
the Dynatrace documentation and flagged "verify for your version"; Oracle/MOS-gated content is pointed
to, not reproduced.

## What you get
- A plain-language Solution Overview of what to monitor across C2M/WebLogic — JVM heap/GC/threads,
  WebLogic services and connection pools, batch worker health, and online/IWS endpoints — and how
  Dynatrace's OneAgent instruments it and its alerting profiles route it.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — a reachable
  Dynatrace tenant, installer and read-scoped API tokens, the C2M topology, OneAgent deployability, the
  JMX/connection-pool metrics, and the alert destination.
- An Implementation Guide of precise, ordered steps: instrument the tiers with OneAgent (host-group
  tagged per environment), enable the WebLogic JMX/connection-pool metrics, build the three C2M
  dashboards, define the standardized alerts as custom metric events, route them with an alerting
  profile and notification, then pilot, validate coverage, and expand.
- Five automation scripts (shell and the Dynatrace API via curl — not PowerShell) for coverage
  discovery, per-tier validation, a coverage/health report, safe remediation (dry-run by default), and
  a scope/target helper — authentic to C2M / WebLogic administration and Dynatrace read APIs, never
  printing a token.
- Testing and Troubleshooting guides with explicit pass/fail gates (instrumented, dashboards live,
  alerts fire and route), plus Best Practices for alert tuning and noise reduction.

## What this delivers
C2M health visible in Dynatrace — tiers instrumented, dashboards live, standardized alerts firing and
routed to on-call.

## The deployment model
Assess, then Configure, then Pilot, then Validate, then Expand — proven on a non-production pilot before
production, with a documented rollback (config export / disable) for every production change.

## Outcome
Full observability of C2M: no visibility, user-reported issues, and slow response replaced by
instrumented tiers, readable dashboards, and a deliberate, tuned alerting model that the team trusts —
validated on a pilot before you scale.
