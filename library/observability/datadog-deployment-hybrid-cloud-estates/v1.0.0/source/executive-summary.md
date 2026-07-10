# Executive Summary — Datadog Deployment for Hybrid & Cloud Estates

## The problem
Teams running **Azure, AWS, and on-prem** at the same time end up with **fragmented monitoring**: the
Azure portal shows Azure, CloudWatch shows AWS, some VMs have an agent and some don't, Kubernetes is a
black box, and there is no single place to answer "is the service healthy end-to-end?" Monitors get
hand-clicked in one console, never versioned, and drift. When an incident spans clouds, responders
stitch together three tools and a Slack thread. There is **no one pane of glass**, and nothing is
**repeatable**.

## The solution
This solution deploys **Datadog across the whole estate — managed as code** — so observability is
unified, versioned, and repeatable:
1. **Agent rollout as code** — the Datadog Agent deployed consistently to **VMs (Linux + Windows),
   containers, and Kubernetes**, hybrid and cloud, with the API key sourced from a **secret store** (not
   baked into images or scripts).
2. **Cloud integrations** — **Azure**, **AWS**, and **Kubernetes** integrations wired up so Datadog
   pulls metrics, logs, and inventory from each cloud's native services, not just the hosts.
3. **Curated dashboards + SLOs** — an estate-overview dashboard and **Service Level Objectives** defined
   as code, so the important views and targets exist by default and survive turnover.
4. **Monitors + alerting** — monitors with **tuned thresholds** and **notification routing**
   (Slack/Teams/PagerDuty/email), started on a pilot and widened deliberately — not a wall of noisy
   defaults.
5. **Log pipelines + APM foundations** — a log-ingestion pipeline (parsing, tags, indexes) and the
   groundwork for Application Performance Monitoring, all in **Terraform**.

Delivery follows a disciplined **Assess → Configure → Pilot → Validate → Expand** model: inventory the
estate and confirm access, author the Terraform and agent config, roll agents + monitors to a **pilot
host/cluster** first, validate that data and alerts flow, then expand across the estate in waves — every
change a reviewed `terraform plan` before `apply`.

## What's included
Full documentation (overview, requirements, ordered implementation, testing matrix, troubleshooting,
best practices) plus **five deployable artifacts**: the core **Terraform** (`main.tf`, Datadog provider —
integrations, dashboard, monitors, SLOs, log pipeline), a **Linux agent installer**
(`install-datadog-agent.sh`), a **Windows agent installer** (`Install-DatadogAgent.ps1`), a
**validation** script (`OBSDDOG-Validate.ps1`), and an **inventory/coverage report**
(`OBSDDOG-Report.ps1`). Everything is **plan-first and pilot-first**; **API and APP keys come from a
secret store and never appear in code**.

## Business value
- **One pane of glass** — Azure + AWS + on-prem in a single view, correlated by tags.
- **Repeatable & versioned** — monitors, dashboards, and SLOs are Terraform, reviewed as pull requests.
- **Tuned, not noisy** — thresholds proven on a pilot before they page the whole team.
- **Secretless** — keys live in a vault/secret store; the repo is safe to share.

## Effort and boundary
A competent admin comfortable with Terraform and package management can stand up the pilot (agent on a
few hosts + a cluster, the cloud integrations, one dashboard, a couple of monitors, one SLO) in a few
focused sessions, then expand. This guide provides the **technical deployment and the automation**. Your
organization's **monitor thresholds, SLO targets, on-call routing, log retention/indexing, and which
Datadog products to license** are operational/commercial decisions the guide wires up but does not make.

> **Product & pricing note:** Datadog's product SKUs, per-host/ingestion **pricing**, agent versions,
> Terraform provider resources, and console UI **change over time**, and the internals of Datadog
> billing/plans are **out of scope** — deferred to Datadog's own documentation. Every version- or
> pricing-sensitive point here is flagged **"verify"** — confirm current provider versions, agent
> releases, and plan/SKU availability against **Datadog's docs** before broad rollout.
