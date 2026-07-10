# Solution Overview — AI Landing Zone & Governance (Private Networking, Content Safety, Cost)

## What this is

A complete, self-guided method for standing up a **governed AI landing zone on Azure** — a hub/spoke
network with **private endpoints** for AI services, **Azure Policy** guardrails (allowed
models/regions, private-only, content-safety-on, tagging), an **identity/RBAC baseline** with **Key
Vault**, **content-safety and responsible-AI defaults** applied at the platform, and **cost
management** (budgets, quotas, usage dashboards) — delivered as **real Infrastructure-as-Code**
(Terraform + Az/PowerShell + a YAML pipeline) that runs **plan/what-if-first and approval-gated**.

It is the **foundation** layer for AI on Azure. Everything above it — a secure Azure OpenAI / AI
Foundry deployment, a private-data RAG platform, MLOps pipelines — assumes this governed base exists
and lands **into** it.

## How the technology works (the mental model)

- **Landing zone.** An opinionated, pre-governed environment that workloads deploy **into** so they
  inherit the network, identity, policy, and cost decisions instead of re-making them. An *AI* landing
  zone specializes this for AI services (Azure OpenAI, AI Foundry, AI Search, Content Safety) — which
  are unusually sensitive (they touch private data and can emit harmful output), so the defaults are
  **private, keyless, guardrailed, and budgeted**.
- **Hub/spoke network.** A **hub** virtual network holds shared platform services (private DNS,
  connectivity, and later a firewall/gateway); one or more **spoke** virtual networks hold the AI
  workloads, **peered** to the hub. This centralizes DNS and connectivity and isolates workloads from
  each other. *Verify current hub/spoke reference topology for your connectivity model.*
- **Private endpoints + private DNS.** A **private endpoint** gives an Azure service (Azure OpenAI,
  Key Vault, AI Search, storage) a **private IP inside your VNet**; **public network access is
  disabled** on the service. A **private DNS zone** (e.g. `privatelink.openai.azure.com`) makes the
  service's normal hostname resolve to that private IP. Result: the service is reachable **only** from
  inside your network — the internet path is closed.
- **Azure Policy + initiatives.** **Policy definitions** are rules evaluated against resources; an
  **initiative** (policy set) groups them. Policies have **effects** — `Audit` (report only), `Deny`
  (block the create/update), `DeployIfNotExists`/`Modify` (remediate). Assigning an initiative at a
  **management-group or subscription scope** makes the rules apply to everything beneath it. Assigning
  in **DoNotEnforce (audit) mode first** lets you see impact before flipping to `Deny` — the
  simulate-before-enforce pattern. *Built-in policy definitions for AI services evolve — verify which
  definitions and effects exist in your cloud.*
- **Managed identity + RBAC.** A **managed identity** is an Azure-managed credential a workload uses to
  authenticate to services **without keys**. **Azure RBAC** grants it least-privilege **data-plane**
  roles (e.g. *Cognitive Services OpenAI User*, *Key Vault Secrets User*). Keyless auth removes the
  single biggest AI credential-leak vector.
- **Key Vault.** A managed secret/key store (itself reached via private endpoint) for any secret that
  genuinely can't be replaced by managed identity — accessed via RBAC, never embedded in code.
- **Content safety & responsible-AI defaults.** **Azure AI Content Safety** screens prompts and
  outputs for harmful content; enabling it (and responsible-AI defaults) **at the platform** means new
  AI workloads inherit safety rather than each team deciding. *Content-safety features and the
  responsible-AI toolset evolve and some are in preview — verify current availability. The acceptable-
  content thresholds and AI-use policy are the customer's trust-and-safety / legal decision.*
- **Cost management.** **Budgets** raise alerts as spend approaches thresholds; **quotas** (e.g. Azure
  OpenAI tokens-per-minute) cap consumption per deployment; a **usage dashboard/workbook** makes token
  and resource spend visible. AI bills on tokens/compute, so these are set **before** broad rollout.

## The standard deployment model

Every solution in this program follows the same five stages:

1. **Assess.** Discover the subscription, registered resource providers, existing VNets/DNS, current
   policy assignments, Key Vault, and whether any AI services already exist with public access on (run
   `AILZ-Discovery.ps1`). Confirm deploy rights and remote state (category G1–G5).
2. **Configure.** Author the landing zone **as code** — hub/spoke VNets + peering, the private DNS
   zones, private endpoints, Key Vault, Log Analytics, the managed identity + RBAC, the policy
   initiative **in audit/DoNotEnforce mode**, and the budget — in `main.tf`, against remote state.
3. **Pilot.** Apply to a **non-production scope first** (a pilot subscription or resource group /
   management group), with policies **auditing, not denying**, using **`terraform plan` / `what-if`
   before every apply** (`azure-pipelines.yml` is plan-first and approval-gated).
4. **Validate.** Confirm AI services are **private** (no public path) and **keyless**, the policy
   initiative **reports** the expected compliance, the budget **alerts** fire, and content-safety
   defaults are in place (run `AILZ-Validate.ps1`, `AILZ-Report.ps1`).
5. **Expand.** Flip the policy guardrails from **audit to enforce (Deny)**, extend the assignment to
   the broader management-group scope, and institute the plan → review → apply loop for every future
   change.

## Scope — what this solution covers

- **Hub/spoke network with private endpoints for AI services** — VNets, peering, private DNS zones,
  and private endpoints (with public access disabled), as code.
- **Azure Policy guardrails** — an initiative enforcing allowed regions, allowed models, private-only,
  content-safety-on, and required tagging, audit-first then enforced.
- **Identity & RBAC baseline + Key Vault** — managed identity, least-privilege data-plane roles, and a
  private Key Vault for secrets.
- **Content-safety & responsible-AI defaults at the platform** — safety on by default for AI workloads
  that land in the zone.
- **Cost management** — budgets, alerts, per-service quotas, and a usage dashboard/workbook.

## Out of scope (handled elsewhere)

- **A secure Azure OpenAI / AI Foundry deployment** — deploying and hardening the AI service itself is
  the companion *Azure AI Foundry / OpenAI Secure Enterprise Deployment* solution (it lands **into**
  this zone).
- **A private-data RAG platform** — Azure AI Search over your permission-trimmed data is the companion
  *Enterprise RAG Platform* solution.
- **MLOps** — Azure ML pipelines, registry, and monitoring are the companion *MLOps* solution.
- **Content-safety / responsible-AI in depth** — the full guardrail configuration, jailbreak/prompt-
  shield tuning, and RAI review workflow are the companion *Azure AI Content Safety & Responsible-AI
  Guardrails* solution; this landing zone sets the **defaults** it builds on.
- **The governance decisions** — which models and regions are allowed, the tagging standard, the
  budget thresholds, and every production apply approval are **the customer's cloud-governance /
  FinOps / trust-and-safety determinations**; this solution provides the technical guardrails and the
  code, and the **acceptable-AI-use policy is the customer's legal decision**.

## Authentication and connections used

- **Azure Resource Manager** at a **subscription** (pilot) and later **management-group** scope, with
  **Owner or Contributor + User Access Administrator** (RBAC role assignments and policy assignment
  with remediation identities require the elevated role). *Verify the exact roles for policy
  remediation in your tenant.*
- **Terraform** (pinned `azurerm`/`azapi` provider — *verify current versions*) against **remote
  state** (an Azure Storage backend, category G4–G5), authenticating via a **workload-identity-
  federated (OIDC) pipeline identity** — **never a client secret on a laptop** (category G2, G5).
- **Az PowerShell** (`Az.Accounts`, `Az.Network`, `Az.Resources`, `Az.KeyVault`, `Az.PolicyInsights`,
  `Az.CostManagement` — *verify current module versions*) for the read-only discovery, validation, and
  reporting helpers, signed in with `Connect-AzAccount` (managed identity in CI).
- Everything is **plan/what-if-first**: `terraform plan` (or ARM `what-if`) precedes every apply, run
  through the pipeline with an approval gate. **GCC / GCC-High** use different clouds/endpoints and may
  lack some AI services or policies — *verify cloud-specific availability, endpoints, and pricing*.
