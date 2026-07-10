# 7. Best Practices — Datadog Deployment for Hybrid & Cloud Estates

Keep the deployment unified, cheap, and secretless. These habits separate a Datadog estate people trust
from a noisy, expensive one nobody tunes.

## Manage everything as code
- **Monitors, dashboards, SLOs, integrations, and log pipelines belong in Terraform** — reviewed as pull
  requests, `plan` before `apply`, versioned in Git. A dashboard someone hand-edits in the console will
  drift and get clobbered on the next apply; if a change is worth keeping, put it in code.
- **Pin the provider and the agent version** and re-verify before a big rollout — both change.
- **Store Terraform state in a secured backend**, never in the repo (it can contain resource metadata).

## Never put keys in code
- The **API key** (agent) and **API+APP keys** (provider) come from a **secret store / env vars** at
  runtime — never in `.tf`, images, installer scripts, or committed state. Run **secret scanning** in CI.
- Integration credentials (Azure app-registration secret, AWS role) are **referenced**, not inlined.
- Scope automation keys to least privilege and **rotate** them; a leaked key exposes the whole estate's
  telemetry and can incur cost.

## Tag first — tags are the whole game
- Apply consistent **`env`, `service`, `team`** (and cloud/region) tags at the **agent and integration**
  level. Cross-cloud dashboards, monitors, and SLOs only work if the tags line up.
- Decide the tag taxonomy **once** and enforce it in the installer defaults and Terraform variables.

## Monitors that page, not spam
- **Tune on the pilot before you widen.** Start monitors scoped to `env:pilot`; only expand thresholds
  that proved meaningful. A monitor that fires constantly gets muted — and then the real one is missed.
- **Route with @-handles**, not personal emails — Slack/Teams channel + on-call (PagerDuty), by team.
- Use **downtimes/mutes** for maintenance windows instead of disabling monitors and forgetting them.
- Give every monitor a clear name (`<Purpose>-<Scope>-<Stage>`), a **priority**, and a **runbook link**
  in the message.

## Control cost deliberately (Datadog-side decisions)
- Datadog bills on **hosts, ingestion, indexed logs, and per-product** — roll out in **waves** and watch
  `OBSDDOG-Report.ps1` after each. Don't enable every product on every host reflexively.
- **Index logs selectively** — parse everything, but index (retain/searchable) only what you'll query;
  route the rest to cheaper archives. *Retention/index and plan/SKU choices are Datadog-side decisions —
  verify current pricing in Datadog's docs.*
- Watch for **agent sprawl** — decommissioned hosts still counted; keep the inventory clean.

## Roll out safely
- **Pilot-first, waves, plan-first.** Never install the agent estate-wide or apply monitors globally in
  one shot — that risks a notification storm and a cost spike.
- Keep an **uninstall / mute** path ready (the installers support removal; monitors support downtime) so
  a bad wave is quickly reversible.

## Where to go next (adjacent catalog areas)
- **Azure Monitor & Log Analytics** (this **Observability** category) — if part of the estate is
  Azure-only, the first-party option is lighter and cheaper for that slice; Datadog gives the unified
  multicloud pane.
- **Application Performance Monitoring** — extend the APM foundation by instrumenting each service's code
  (a per-service development task) to get distributed traces.
- **DevOps / IaC (Terraform)** solutions — fold this Datadog Terraform into your existing IaC pipeline so
  observability ships with the workload, plan→approve→apply.
- **Incident response / on-call** process work — connect the tuned monitors and SLOs to a defined on-call
  rotation and runbooks so alerts drive action.
