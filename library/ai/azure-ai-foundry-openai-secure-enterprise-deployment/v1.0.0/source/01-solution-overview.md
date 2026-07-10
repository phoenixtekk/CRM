# 1. Solution Overview — Azure AI Foundry & Azure OpenAI: Secure Enterprise Deployment

## What this platform is
This solution stands up the **foundation your teams build custom AI applications on** — an **Azure AI Foundry** hub and project, and an **Azure OpenAI** resource — configured the enterprise way from the first deploy: **private networking**, **no keys**, **managed model quota**, **content filtering**, and **monitoring**, all expressed as **infrastructure-as-code** (Bicep) in Git rather than clicked together in the portal.

Two things are worth separating up front, because people conflate them:
- **Azure OpenAI** is the *service* that hosts the models (GPT-family chat/completions, embeddings, and others) behind an Azure endpoint you call from your apps. It is a **Cognitive Services** account of kind `OpenAI`.
- **Azure AI Foundry** (the platform formerly surfaced as *Azure AI Studio*) is the *workspace* where teams build, test, and manage AI projects — a **hub** provides shared security, networking, and connections, and one or more **projects** under it are where individual teams work and connect to model deployments. *The Foundry resource model has evolved (hub/project workspaces, and a newer unified Foundry resource) — verify the current resource types and portal layout in your tenant.*

The point of doing this as a governed platform, not a quick portal resource, is that **custom AI touches sensitive data and can emit harmful or ungrounded output**. So the platform is **private-by-default** (nothing reachable from the public internet), **keyless** (identities, not shared secrets, authenticate), **quota-bounded** (a token ceiling per model so spend and load are predictable), and **guarded and observed** (a content filter in front of generation, full diagnostic logs behind it).

## How the key pieces work
- **Private networking.** By default an Azure OpenAI resource has a **public endpoint** reachable from anywhere. Setting **`publicNetworkAccess` = Disabled** turns that off, and a **private endpoint** gives the resource a private IP inside your VNet. A **private DNS zone** (for example `privatelink.openai.azure.com` — *verify the exact zone name(s) for OpenAI / AI Services in your cloud*) makes the resource's hostname resolve to that private IP, so your apps reach it entirely over the Microsoft backbone. Reaching Azure OpenAI over the public internet becomes impossible.
- **Keyless (managed identity + RBAC) auth.** Every Cognitive Services account is created with two **account keys** — long-lived, portable secrets that authenticate as the whole resource. Setting **`disableLocalAuth` = true** switches them off entirely. Your app then authenticates with a **managed identity**: Azure issues it an Entra token, and the token is authorized by an Azure **role** on the resource — the least-privilege data-plane role is **Cognitive Services OpenAI User** (call models) or **Cognitive Services OpenAI Contributor** (also manage deployments). Nothing to leak, rotate, or commit. Keyless auth requires the resource to have a **custom subdomain** (`customSubDomainName`).
- **Model deployments, versioning, and quota.** You do not call "GPT-4o" directly — you create a **deployment** (a named instance of a specific model **version**) on the resource, and your app calls the *deployment name*. Each deployment carries a **capacity** measured in **tokens-per-minute (TPM)** drawn from your regional **quota**; TPM also sets the requests-per-minute rate limit. This is your primary lever against both **load** and **bill shock** — a deployment cannot burn more than the TPM you granted it. *Model and version availability, regional availability, and quota defaults vary and change — verify current availability in your subscription and region.*
- **Content filtering (Responsible AI).** Azure OpenAI applies a **content filter** to prompts and completions across hate, sexual, violence, and self-harm categories. You attach a **RAI (content-filter) policy** to each deployment and set severity thresholds; additional protections (prompt-shield / jailbreak detection, protected-material detection, asynchronous filtering) exist and **some are in preview** — *verify current availability and preview status*. The **acceptable-content threshold is your trust-and-safety decision**; the platform enforces whatever you choose.
- **Monitoring and cost.** A **diagnostic setting** streams the resource's audit, request/response metadata, and metrics to a **Log Analytics** workspace, so every call is observable. A **budget** with **cost alerts** on the resource group warns you long before an overrun, and per-deployment TPM caps the theoretical maximum spend.
- **Key Vault for any unavoidable secret.** Keyless is the default. If a specific downstream connection genuinely needs a secret (a third-party API key a Foundry connection uses, say), it goes in **Key Vault** referenced by the managed identity — never in code or app settings.

## What you can control
- **Isolation** — public access disabled, private endpoint(s) and DNS on your chosen VNet/subnet.
- **Identity** — which managed identity/identities authenticate, and at which least-privilege role.
- **Models** — which models/versions are deployed, their deployment names, and their **TPM quota** and rate limits.
- **Safety** — the content-filter policy attached to each deployment and its severity thresholds.
- **Observability & spend** — the Log Analytics destination, the budget amount, and the alert thresholds.
- **Rollout scope** — a non-production Foundry project first, production only after validation and approval.

## Scope — what's in
- An **Azure AI Foundry hub + project** and an **Azure OpenAI** resource, deployed from Bicep.
- **Private endpoint(s)**, private DNS, and **disabled public access** on the AI resources.
- **Keyless** auth: `disableLocalAuth`, a user-assigned **managed identity**, and least-privilege data-plane RBAC; **Key Vault** for any unavoidable secret.
- One or more **model deployments** with explicit **TPM quota**/rate limits and a **content-filter policy**.
- **Diagnostic logging** to Log Analytics and a **budget** with cost alerts.

## Scope — what's out (be honest with buyers)
- **This is not Microsoft 365 Copilot governance.** Governing Copilot over your M365 data is the **Copilot** and **Purview AI** catalog areas; this is a platform for building your *own* AI apps. Cross-referenced, not duplicated.
- **Not a RAG / grounding build.** Connecting the platform to your private data with Azure AI Search and permission-trimming is the sibling **Enterprise RAG Platform** solution.
- **Not the enterprise landing zone.** Management groups, org-wide policy, and hub-spoke backbone are the **AI Landing Zone** / DevOps landing-zone solutions; this deploys the AI platform *into* an existing VNet.
- **Not the application.** This is the governed model platform; the app that consumes it (prompt design, orchestration, UX) is yours to build on top.
- **No content-policy or acceptable-use determination.** The platform enforces the thresholds you set; *what* is acceptable is your legal / trust-and-safety decision.

## Authentication and connections used
- **Azure CLI / Az PowerShell** signed in as an identity with **Contributor/Owner** at the deployment scope, for local `what-if`, discovery, and the deploy helper (per Global Requirements G1).
- A **user-assigned managed identity** that your application runs as, holding the **Cognitive Services OpenAI User** data-plane role — the keyless path apps use at runtime (G2).
- A **CI/CD service connection** to Azure using **workload identity federation (OIDC)** — no stored secret — for the pipeline (G5).
- **Private endpoints** on your existing **VNet/subnet** with **private DNS** (G3); the Python scripts authenticate via `DefaultAzureCredential`, so they use your signed-in identity or the managed identity with **no key**.

## The standard deployment model
> **Assess the current estate (existing OpenAI resources, public endpoints, keys in use, quota) → configure the Bicep for a private, keyless, quota-bounded platform → pilot by deploying to a non-production Foundry project with a low TPM quota → validate isolation, keyless access, the content filter, quota, diagnostics, and the budget → expand to production behind pipeline approval, then onboard more projects/models.** The repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, `what-if`-first and approval-gated, with deployment-stack rollback.
