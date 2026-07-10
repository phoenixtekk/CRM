# 7. Best Practices — Azure Monitor & Log Analytics: Foundation, Alerts & Dashboards

Keep the foundation clean, cheap, and trustworthy. These are the habits that separate an observability
platform people rely on from an expensive log dump nobody reads.

## Collect what you will act on
- **Every log category has a cost.** Don't enable "all logs" on every resource reflexively — route the
  categories you would actually query or alert on. Use `OBSAZMON-Report.ps1` to find the **top
  ingesters** and question whether that volume earns its keep.
- **Use table tiers deliberately.** Put high-volume, rarely-queried data on **Basic/Auxiliary** tiers
  and keep interactive Analytics data lean (*verify current tiers/pricing in your tenant*).
- **Set retention to the requirement, not the maximum.** Interactive retention for operational
  querying; long-term/archive only where compliance demands it.
- **Guard cost with a daily cap** on non-critical workspaces so a runaway resource can't produce a
  surprise bill — but understand a cap **drops** data once hit.

## One workspace, governed
- Prefer **one (or few) well-governed workspaces** over many ad-hoc ones — cross-resource queries and
  dashboards need the data in one place. Scope **access with RBAC** (Reader vs Contributor) rather than
  giving everyone full workspace rights.
- Keep the **ops** telemetry here and let the **security** team run Sentinel (which can share the
  workspace) — don't blur the two roles.

## Diagnostics by policy, not by hand
- Apply diagnostic settings with **Azure Policy `DeployIfNotExists`** so **new** resources are covered
  automatically — hand-clicked settings drift and get forgotten.
- **Stage it:** DoNotEnforce/audit → pilot remediation → estate-wide remediation **in waves**. Never
  remediate the whole estate in one action (cost + noise spike).

## Alerts that page, not spam
- **Tune before you widen.** Start alerts on the pilot; only expand thresholds that proved meaningful.
  An alert that fires constantly gets muted, and then the real one is missed.
- **Route with action groups, not inboxes.** One reusable action group per responder team, with
  Teams/Slack + on-call (PagerDuty) — not a personal mailbox.
- **Prefer metric alerts** for simple numeric conditions (cheaper, faster) and **log alerts** for
  cross-resource / KQL logic. Give every rule a **severity** and a clear name (`<Purpose>-<Scope>-<Stage>`).
- **Use alert processing rules** for suppression during maintenance windows instead of disabling rules
  and forgetting to re-enable them.

## Secrets and access hygiene
- Webhook URLs and PagerDuty keys are **secrets** — store them in Key Vault / secure input, never in
  the Bicep or a committed file.
- The diagnostics policy's **managed identity** should hold only the roles it needs (Monitoring / Log
  Analytics Contributor) at the assignment scope — no broader.

## Version & cost discipline
- The **Azure Monitor Agent**, DCRs, table plans, and pricing **change** — re-verify before a big
  rollout, and keep the Bicep parameterized so a tier/retention change is a one-line edit.
- Review ingestion **monthly** with `OBSAZMON-Report.ps1`; a creeping bill is usually one noisy new
  resource type.

## Where to go next (adjacent catalog areas)
- **Datadog Deployment for Hybrid & Cloud Estates** (this **Observability** category) — when you need a
  single pane over **Azure + AWS + on-prem**, not just Azure.
- **Microsoft Sentinel** (the **Sentinel / security** category) — layer **security** analytics, UEBA,
  and threat hunting on top of (or sharing) this workspace.
- **Azure Landing Zone (Bicep/Terraform)** (the **DevOps / IaC** category) — bake this diagnostics
  policy and a central workspace into the landing zone so every new subscription is observed by default.
- **Azure Policy governance** solutions — extend the same `DeployIfNotExists` pattern to tagging,
  security baselines, and cost guardrails.
