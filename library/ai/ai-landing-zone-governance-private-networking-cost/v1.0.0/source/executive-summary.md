# Executive Summary — AI Landing Zone & Governance (Private Networking, Content Safety, Cost)

## The problem

Most organizations adopt AI the same way: a team spins up an **Azure OpenAI** or **Azure AI Foundry**
resource, wires it to some data, ships something useful — and then the next team does it all again,
differently. Within a quarter you have a dozen AI resources, each having re-solved networking,
identity, safety, and cost **on its own, inconsistently and insecurely**:

- **Public endpoints everywhere.** AI services reachable over the internet are a
  data-exfiltration surface — exactly the wrong default for services that touch your most sensitive
  data.
- **No guardrails.** Nothing *stops* a team from deploying an unapproved model, in an unapproved
  region, with public access on and content safety off.
- **Keys on laptops.** Service-to-service auth done with API keys that get copied into code and
  config, instead of managed identity and RBAC.
- **Bill shock.** Token-metered services with no budgets, no quotas, and no usage visibility until the
  invoice arrives.

Every one of these is a foundation problem, and foundation problems don't get better by adding more
workloads on top of them.

## The solution

This solution stands up a **governed AI landing zone** — the base every AI workload deploys **into**,
so the networking, identity, safety, and cost decisions are made **once, correctly**, and inherited.
It delivers:

- **A hub/spoke network with private endpoints for AI services** — Azure OpenAI, AI Search, Key
  Vault, and storage reached over **private endpoints and private DNS**, with **public network access
  disabled** — defined as **Infrastructure-as-Code**.
- **Azure Policy guardrails** — an initiative that enforces **allowed regions**, **allowed models**,
  **private-only** AI services, **content-safety-on**, and **required tagging** — deployed
  **audit/simulate-first**, then enforced.
- **An identity and RBAC baseline plus Key Vault** — **managed identity** and least-privilege
  data-plane roles for keyless auth, with Key Vault for any unavoidable secret.
- **Content-safety and responsible-AI defaults at the platform** — safety is a platform default, not a
  per-team afterthought.
- **Cost management** — **budgets, alerts, per-service quotas**, and a **usage dashboard**, so spend
  is visible and bounded before broad rollout.

## How it works

We follow the same repeatable model every solution in this program uses — **Assess → Configure →
Pilot → Validate → Expand**. We first discover the current subscription and network state, then author
the landing zone (network, private endpoints, Key Vault, RBAC, policy, cost controls) **as Terraform
run through a plan/what-if-first pipeline**, apply it to a **non-production scope first** with the
policy guardrails in **audit/DoNotEnforce** mode, validate that AI services are private, keyless, and
guardrailed and that budgets fire, and only then **enforce** the policies and **expand** the landing
zone across the estate. Every change is **`terraform plan` / `what-if` before apply**, in version
control, approval-gated — never click-ops in the portal, never long-lived keys on a laptop.

The solution ships as **self-guided, click-by-click documentation plus real Infrastructure-as-Code** —
a Terraform baseline (`main.tf`), a plan-first Azure Pipelines YAML pipeline (`azure-pipelines.yml`),
and Az/PowerShell helpers that **discover** the current state, **validate** the guardrails, and
**report** posture and cost — all **read-only or plan/what-if-first**, with **no secrets in code**.

## Why it matters

- **Private by default** — AI services are unreachable from the public internet; access is over
  private endpoints inside your network.
- **Guardrails that actually stop things** — Azure Policy *prevents* the unapproved model, region, or
  public endpoint, rather than detecting it after the fact.
- **Keyless identity** — managed identity + RBAC instead of API keys that leak.
- **Safety and cost as platform defaults** — content safety on and budgets set before workloads land,
  not bolted on after an incident or an invoice.
- **A fraction of consulting cost** — the same disciplined method a cloud-platform team would use,
  delivered as a repeatable, tested runbook you reuse on every AI rollout.

## Important boundaries

This solution builds the **governed foundation** — network, private endpoints, identity/RBAC, Key
Vault, the policy guardrails, and cost controls. It **is not** an AI application, a RAG platform, an
MLOps pipeline, or the content-safety product itself — securely deploying Azure OpenAI / AI Foundry,
building a private-data RAG platform, standing up Azure ML pipelines, and configuring the content-
safety and responsible-AI guardrails in depth are **separate catalog solutions** that this landing
zone makes deployable. It **creates real, billable Azure resources** (private endpoints, Key Vault,
Log Analytics, and any AI services placed in the zone have cost) — everything runs **plan/what-if
first in a non-production scope before production**, and production apply is **the customer's
change-approval decision**. Azure **Policy and feature availability, built-in policy definitions,
model and region availability, GCC/GCC-High parity, and pricing all evolve and differ by cloud** —
*verify current provider/module versions, policy/feature availability, and pricing before you apply*.
The **acceptable-AI-use policy and content-acceptability thresholds** are the customer's legal /
trust-and-safety / compliance decision — this guide provides the technical controls, not the policy.
