# 1. Solution Overview — Datadog Deployment for Hybrid & Cloud Estates

## What this solution is
**Datadog** is a SaaS observability platform that unifies metrics, logs, traces (APM), and events from
across an estate into one place. This solution **deploys Datadog across a hybrid + multicloud estate as
code** — the agent on every host/container/cluster, the cloud integrations for Azure/AWS/Kubernetes, and
the dashboards, SLOs, monitors, and log pipelines defined in **Terraform** so the whole observability
stack is versioned and repeatable. The Datadog console's internals and its pricing/plans are **deferred
to Datadog's own documentation**; this solution is the **deployment and management-as-code** layer.

## How the technology works
- **The Datadog Agent** runs on each host (VM or container node) and collects system metrics, logs, and
  (with APM) traces, forwarding them to your Datadog **organization** (a regional Datadog site). It
  authenticates with a **Datadog API key**. It is configured via `datadog.yaml` and per-integration
  config files (or, on Kubernetes, a Helm chart / DaemonSet).
- **Cloud integrations** pull telemetry Datadog can't see from a host: the **Azure** integration uses an
  Entra **app registration** (service principal) with **Monitoring Reader**; the **AWS** integration
  uses a cross-account **IAM role**; the **Kubernetes** integration uses the cluster agent. These pull
  cloud-service metrics, inventory, and (optionally) logs.
- **The Datadog Terraform provider** manages Datadog *resources* — dashboards, monitors, SLOs, log
  pipelines, integrations — via the Datadog API, authenticated with an **API key + APP key**. `terraform
  plan` shows what will change; `terraform apply` makes it so. Because it is code in Git, monitors and
  dashboards are reviewed, versioned, and reproducible.
- **Tags** are the connective tissue — `env`, `service`, `team`, cloud/region — applied at the agent and
  integration level so one dashboard/monitor/SLO can span Azure + AWS + on-prem.
- **Monitors** evaluate a metric/log/APM condition and notify via **@-handles** (Slack, Teams, PagerDuty,
  email). **SLOs** track a target (e.g. 99.9% availability) over a window. **Log pipelines** parse and
  enrich incoming logs and route them to **indexes** (which control retention/cost).

## What this solution builds (the components)
1. **Agent rollout as code**
   - Linux (`install-datadog-agent.sh`) and Windows (`Install-DatadogAgent.ps1`) installers that read
     the **API key from a secret store**, set the **site** and base **tags**, and enable logs/APM as
     chosen; Kubernetes via the official **Helm chart / DaemonSet** (referenced from Terraform/CI).
2. **Cloud integrations**
   - **Azure** (`datadog_integration_azure`), **AWS** (`datadog_integration_aws`), and **Kubernetes**
     wired in Terraform, with the credentials/role **referenced from a secret store**, never inline.
3. **Curated dashboards + SLOs**
   - An estate-overview dashboard `OBSDDOG-Dashboard-EstateOverview` and an SLO
     `OBSDDOG-SLO-APIAvailability`, defined as code.
4. **Monitors + alerting**
   - Monitors such as `OBSDDOG-Monitor-HostUnreachable-Pilot`, `OBSDDOG-Monitor-CPUHigh-Pilot`, and
     `OBSDDOG-Monitor-K8sPodCrashloop-Pilot`, with tuned thresholds and **notification routing**,
     started on the **pilot** scope.
5. **Log pipeline + APM foundation**
   - A log pipeline `OBSDDOG-Pipeline-AppLogs` (parsing + tags + index) and the APM enablement flags,
     ready to extend to instrumented services.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand** — inventory hosts/clusters/clouds and confirm
> access and keys (Assess); author the Terraform + agent config and pin provider/agent versions
> (Configure); install the agent and apply integrations/monitors against a **pilot host + cluster**
> first, `plan` before `apply` (Pilot); prove metrics/logs flow and a monitor fires and routes
> (Validate); then roll agents and monitors across the estate in **waves**, widening thresholds
> deliberately (Expand). Every change is a reviewed `terraform plan`.

## Scope
- Deploy the **Datadog Agent** across VMs, containers, and Kubernetes (hybrid + cloud) as code.
- Wire the **Azure / AWS / Kubernetes** cloud integrations.
- Deliver a **dashboard**, at least one **SLO**, a curated set of **monitors** with routing, and a **log
  pipeline** + **APM foundation** — all in Terraform.

## What is out of scope
- **Datadog console internals, plan/SKU selection, and pricing** — deferred to Datadog's documentation;
  this solution deploys and manages, it does not choose your Datadog commercial plan.
- The **decisions** of monitor thresholds, SLO targets, on-call routing, and log retention/indexing —
  the guide encodes your choices; the choices are the service owners'.
- **Deep application instrumentation** (adding APM tracing libraries into every service's source) — the
  APM *foundation* is enabled; instrumenting each app is a per-service development task.
- **Azure-native-only** observability — if you are Azure-only, the **Azure Monitor** solution in this
  category is the lighter-weight, first-party option.

## Authentication and connections used
- **Datadog API key** — used by the **agent** to submit data; sourced from a **secret store** at install
  time, never written into images/scripts/repo.
- **Datadog API key + APP key** — used by the **Terraform provider** to manage Datadog resources;
  supplied via environment variables / secret store, never in `.tf` or state-in-repo.
- **Azure integration** — an Entra **app registration** with **Monitoring Reader**; **AWS integration**
  — a cross-account **IAM role**; both referenced from a secret store.

## Limitations (be honest with buyers)
- **Datadog bills on hosts, ingestion, and per-product** — an uncontrolled rollout (all logs, all hosts,
  every product) is expensive. Collect and index deliberately; that plan is a Datadog-side decision
  (*verify current pricing/SKUs in Datadog's docs*).
- **Version sensitivity** — the agent, the Terraform provider, and integration behavior change; all
  versions here are **pinned and flagged "verify."**
- **`terraform apply` changes real monitoring config.** Everything is **plan-first** and **pilot-first**;
  keys are **never** in code — the repo must be safe to share.
