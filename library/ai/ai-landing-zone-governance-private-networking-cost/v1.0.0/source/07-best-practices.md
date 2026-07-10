# Best Practices — AI Landing Zone & Governance (Private Networking, Content Safety, Cost)

Keep-it-clean guidance for a governed AI landing zone that stays private, safe, budgeted, and
reproducible over time.

## Treat the landing zone as code, always

- **No portal click-ops on the foundation.** The network, private DNS, private endpoints, Key Vault,
  RBAC, policy, and cost controls change through `terraform plan` / `what-if` → review → apply
  (`azure-pipelines.yml`), in version control. A foundation changed by hand is a foundation no one can
  reproduce or audit.
- **Plan/what-if-first, non-prod-first.** Read every plan before applying, and apply to the pilot
  scope before production. The plan is your safety net — use it.
- **Protect the state like production data.** Remote, encrypted, versioned, locked state (R6) is the
  source of truth for the whole AI estate; losing it is an incident. Restrict who can touch the state
  backend.

## Private by default — close the internet path

- **Public access OFF, private endpoints ON.** Every AI service, Key Vault, and storage account in the
  zone has **public network access disabled** and is reached over a private endpoint. If a service can
  be reached from the internet, it is not in the landing zone's posture.
- **Get DNS right or nothing resolves.** The private endpoint is only useful if the service hostname
  resolves to its private IP — keep the `privatelink.*` zones **linked to the VNets** and prefer your
  organization's **central** private DNS if one exists, rather than duplicating zones. *Verify current
  privatelink zone names.*
- **One hub, many spokes.** Centralize DNS and connectivity in `vnet-ailz-hub-platform`; peer each new
  AI workload spoke to it, rather than each team rebuilding networking.

## Guardrails: audit first, then enforce — and keep the exits open

- **Simulate before you enforce.** Assign the `AILZ-AI-Guardrails-Initiative` in **`DoNotEnforce`
  (audit)** mode, read the compliance report, understand the impact, then flip to **enforce (Deny)**.
  Never enforce a broad deny estate-wide before validating in audit.
- **Enforce what you decided, not more.** `Policy-AllowedRegions-AILZ`, `Policy-AllowedModels-AILZ`,
  `Policy-PrivateOnly-AILZ`, and `Policy-RequireTags-AILZ` enforce the **lists you set** (R4) — the
  solution doesn't choose your regions, models, or tags.
- **Never lock out administration.** Keep an **owner-level break-glass identity exempt** from any deny
  policy that could block management, and confirm you can still operate the scope after enforcing. Use
  scoped **Azure Policy exemptions** for legitimate exceptions rather than weakening the policy.
- **Fewer, clearer policies.** A handful of well-named guardrails beats a sprawl of overlapping
  assignments — keep the initiative legible. *Built-in AI policy definitions evolve and some are
  preview — verify availability before relying on an effect.*

## Keyless identity over keys, every time

- **Managed identity + RBAC, not API keys.** Give the workload (`id-ailz-aiworkload-nonprod`)
  least-privilege data-plane roles (e.g. *Cognitive Services OpenAI User*, *Key Vault Secrets User*).
  Keys are the single biggest AI credential-leak vector — remove them.
- **Key Vault for the unavoidable secret only, and privately.** Reach Key Vault over its private
  endpoint, grant access via RBAC, and keep purge-protection on. Don't put secrets in code, pipeline
  variables in plaintext, or app config.

## Safety and cost are platform defaults, not afterthoughts

- **Content safety on at the platform.** New AI workloads should inherit content-safety defaults, not
  each team deciding — the deeper tuning (prompt shields, jailbreak detection, RAI review) is the
  companion Content-Safety solution. *Acceptable-content thresholds and the AI-use policy are the
  customer's trust-and-safety / legal decision, not this guide's.*
- **Budget and quota before rollout.** Set `Budget-AILZ-Platform` thresholds and per-service quotas
  (e.g. Azure OpenAI tokens-per-minute) **before** workloads scale. Watch `Workbook-AILZ-AIUsage`.
  *Spend limits are the customer's FinOps decision; verify current AI pricing — it changes.*

## Mind the cost of the foundation itself

- **The zone is billable.** Private endpoints, Log Analytics ingestion, Key Vault operations, and any
  AI services placed in the zone all cost money, and cost scales with workloads and traffic.
  Right-size Log Analytics retention and review spend per resource group. *Verify current Azure pricing
  for your cloud (Commercial vs GCC/GCC-High) before you scale.*

## Where to go next

With the governed AI landing zone in place, the natural next steps in this catalog are:

- **Secure Azure AI Foundry / OpenAI Deployment** — deploy and harden the AI service itself **into**
  this zone (private, keyless, content-safety-on) now that the foundation exists.
- **Enterprise RAG Platform (Azure AI Search, private data)** — ground AI on your permission-trimmed
  data using the private network and identity baseline this zone provides.
- **Azure AI Content Safety & Responsible-AI Guardrails** — take the platform content-safety default
  and configure it in depth (prompt shields, jailbreak detection, RAI review workflow).
- **MLOps (Azure Machine Learning pipelines, registry, monitoring)** — operationalize custom models on
  the same governed base.
- **Azure Security Baseline & Governance** — apply the same governed-foundation discipline to the
  broader Azure estate for a consistent posture.
