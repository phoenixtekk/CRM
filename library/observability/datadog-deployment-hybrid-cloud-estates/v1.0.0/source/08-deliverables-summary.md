# 8. Deliverables Summary — Datadog Deployment for Hybrid & Cloud Estates

## What you receive
A complete, self-guided package to deploy **Datadog across a hybrid + multicloud estate as code** — the
agent on VMs/containers/Kubernetes, the Azure/AWS/Kubernetes integrations, and dashboards, SLOs,
monitors, and log pipelines defined in Terraform. Everything is **plan-first and pilot-first**, and
**API/APP keys come from a secret store and never appear in code or state**.

### Documentation
- **Executive Summary** — the problem (fragmented per-cloud monitoring), the five-part solution, the
  outcome, the boundary, and the product/pricing "verify" note (Datadog internals deferred to Datadog docs).
- **Solution Overview** — how the agent, cloud integrations, the Datadog Terraform provider, tags,
  monitors, SLOs, and log pipelines fit together; the components built; scope and out-of-scope.
- **Requirements Guide** — the Datadog-specific prerequisites (org + site + API/APP keys, pinned
  provider, an agent rollout channel, a secret store, Azure/AWS integration prerequisites, a pilot +
  notification targets, and the toolchain), each with Verify / Implement, on top of the category globals.
- **Implementation Guide** — ordered steps: assess → pin provider + secure backend (no keys in code) →
  pilot agent install (Linux/Windows/K8s) → wire integrations → plan/apply dashboard + SLO + pilot
  monitors + log pipeline → validate → expand in waves, with **every object named** using the
  `<Purpose>-<Scope>-<Stage>` convention.
- **Testing & Validation** — the four gates (agents report + tagged, integrations connected + no keys in
  code, a monitor fires and routes + log pipeline parses, dashboard + SLO render) as a pass/fail matrix.
- **Troubleshooting** — symptom → root-cause → fix for the common failures (agent not reporting,
  integration not connecting, provider auth, monitor not firing/routing, log parsing, cost/host sprawl).
- **Best Practices** — everything-as-code, never-keys-in-code, tag-first, monitor tuning, cost control,
  and where to go next.

### Deployable artifacts — plan-first / pilot-first, no keys in code
| Artifact | Purpose | Default mode |
|----------|---------|--------------|
| **`main.tf`** | The core Terraform (Datadog provider): Azure/AWS/K8s integrations, the estate dashboard, the SLO, the three pilot monitors, and the log pipeline — provider **pinned & flagged verify**; keys read from env/secret store | Declarative (plan before apply) |
| **`install-datadog-agent.sh`** | Linux agent installer: reads the API key from the **secret store**, sets site + `env`/`service`/`team` tags, optional logs/APM; supports uninstall | Idempotent install (key from vault) |
| **`Install-DatadogAgent.ps1`** | Windows agent installer: same inputs and secret-store key sourcing as the Linux installer | Idempotent install (key from vault) |
| **`OBSDDOG-Validate.ps1`** | Confirms provider auth (keys via env, not code), the expected Datadog resources exist, integrations report connected, and **no keys are in the repo/state** | Read-only |
| **`OBSDDOG-Report.ps1`** | Inventory/coverage report via the Datadog API: hosts by tag, monitors + states, SLO/error budget, ingestion snapshot for the cost plan | Read-only |

The installers and Terraform read the **API/APP keys from a secret store** at runtime; the PowerShell
helpers are **read-only**; every Datadog-resource change is a reviewed **`terraform plan` before
`apply`** — **no credentials or secrets live in the artifacts or state**.

## Outcomes
- **One pane of glass** over Azure + AWS + on-prem, correlated by consistent tags.
- **Observability as versioned code** — monitors, dashboards, SLOs, and pipelines reviewed as PRs.
- **Tuned alerting** — thresholds proven on a pilot before they page the estate, routed to on-call.
- **Secretless** — keys in a vault/secret store; the repo and state are safe to share.
- A **pilot-first**, wave-based, reversible rollout (revert + apply, mute/uninstall) with a coverage report.

## Assumptions & boundaries
- **Datadog console internals, plan/SKU selection, and pricing** are **deferred to Datadog's docs** — the
  solution deploys and manages, it does not choose your commercial plan.
- **Provider/agent versions** are pinned and flagged **"verify"** — confirm current versions first.
- **Monitor thresholds, SLO targets, on-call routing, and log retention/indexing** are the customer's/
  service-owner's decisions — the guide wires them up.
- **Deep per-service APM instrumentation** is out of scope (the APM *foundation* is enabled); **Azure-only**
  estates may prefer the first-party **Azure Monitor** solution in this category.

> Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the full documentation set plus
> all five deployable artifacts (Terraform, the Linux + Windows agent installers, and the PowerShell
> helpers) in a single ZIP, yours to keep and reuse on every rollout.
