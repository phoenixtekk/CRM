# Global Requirements — Observability (category-level)

These requirements apply to every solution in the Observability category (Azure Monitor / Log Analytics,
Datadog, and related telemetry/monitoring platforms). Published once at the category level so listings
stay small. Confirm before deploying any observability solution. Each entry: Description / Why / Verify /
Implement-if-missing.

> Observability collects telemetry across the estate — collect what you will act on, control ingestion
> cost deliberately, and roll agents/diagnostics out in a ring before fleet-wide. This is ops/platform
> monitoring, distinct from security SIEM (see the Sentinel category).

## G1. Target cloud/estate with sufficient rights
Description: The Azure subscription(s), AWS account(s), and/or hosts to be monitored, with rights to configure diagnostics and deploy agents.
Why: Monitoring configuration (diagnostic settings, agents, integrations) needs contributor-level access at the target scope.
Verify: `az account show` (Azure) / access to the target hosts succeeds with the needed role.
Implement: Obtain Contributor (or scoped monitoring) rights at the target scope.

## G2. A telemetry destination (workspace / monitoring account)
Description: A Log Analytics workspace (Azure Monitor) or a Datadog organization/account.
Why: Telemetry needs a governed destination with retention and access control.
Verify: The workspace/Datadog org exists and is access-controlled.
Implement: Provision the workspace / Datadog account before wiring sources to it.

## G3. Agent / collection rollout channel
Description: A way to deploy agents and collection config at scale — Azure Policy + Azure Monitor Agent / Data Collection Rules, or a config-management/IaC channel for the Datadog agent.
Why: Manual per-host agent installs don't scale and drift.
Verify: The rollout channel (Policy/DCR, Intune/CM, Ansible, Terraform) is available.
Implement: Establish the at-scale rollout mechanism before onboarding hosts.

## G4. IaC tooling and source control
Description: Terraform / Bicep, the relevant CLI (Az / Datadog), and Git.
Why: The observability stack is delivered as versioned code so it is repeatable and reviewable.
Verify: `terraform version` / `az version` and `git --version` return supported builds. *Verify current provider versions.*
Implement: Install and pin the toolchain; store config in Git.

## G5. Secrets management
Description: A secure store for API/app keys (Datadog API+APP keys, service principals) — Key Vault / pipeline secrets, never in code.
Why: Monitoring keys grant broad read (and some write); committed keys leak.
Verify: No keys in the repo; the pipeline reads them from a secret store.
Implement: Move keys to Key Vault / secret store; enable secret scanning.

## G6. Ingestion cost plan
Description: An understanding of expected data volume and a cost/retention plan (table tiers, sampling, filters).
Why: Observability platforms bill on ingestion/retention; uncontrolled collection is expensive.
Verify: A volume estimate and retention decision exist. *Verify current pricing/tier availability.*
Implement: Define what to collect vs drop, retention, and (Azure) table tiers before broad rollout.

## G7. Alerting and notification targets
Description: Notification channels (email, Teams/Slack, PagerDuty) and an on-call/routing model.
Why: Alerts are only useful if they reach the right responder with context.
Verify: Action groups / Datadog notification integrations and routing are defined.
Implement: Configure notification channels and routing before enabling alert rules.

## G8. A pilot scope
Description: A defined pilot set of resources/hosts to onboard first.
Why: Diagnostics/agents and alert thresholds are validated on a pilot before fleet-wide rollout.
Verify: A pilot resource group / host set exists.
Implement: Define the pilot scope before scaling collection and alerting. *Alert thresholds and SLOs are the service owner's decision; this guide provides the technical wiring.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.
