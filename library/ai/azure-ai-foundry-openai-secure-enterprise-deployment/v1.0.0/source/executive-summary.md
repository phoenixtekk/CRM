# Executive Summary — Azure AI Foundry & Azure OpenAI: Secure Enterprise Deployment

**White-label · AI**

Most teams stand up Azure OpenAI the fast way: create the resource in the portal, leave the **public endpoint on**, copy the **account key** into an app setting, and start calling models — with **no quota ceiling** and **no cost alert**. It demos in an afternoon and works until it doesn't. That key is a portable, long-lived credential that can be leaked or committed; the public endpoint is a data-exfiltration surface reachable from anywhere; and an unbounded token meter turns a runaway loop or a launch spike into a five-figure bill. This solution deploys **Azure AI Foundry** (hub + project) and an **Azure OpenAI** resource the enterprise way — **private-by-default, keyless, quota-managed, and monitored** — as versioned infrastructure-as-code, so the foundation your teams build custom AI apps on is governed from day one.

This is a complete, **deploy-it-today** package written for an administrator who has used the Azure portal but has never authored Bicep, disabled a Cognitive Services public endpoint, wired a private endpoint and private DNS, or made an Azure OpenAI call with a **managed identity instead of a key**.

## What you get
- A plain-language **Solution Overview** of the platform — what an AI Foundry hub and project are, how the Azure OpenAI resource, private endpoints, managed-identity (keyless) auth, model deployments/quota, and content filtering fit together, and how `what-if`-first deployment keeps it safe.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite (the category-wide ones live in the separate **Global Requirements — AI**).
- An **Implementation Guide** of precise, ordered steps — discover the current estate, deploy the hub/project + Azure OpenAI as code with **public access disabled** and **local-auth (keys) disabled**, wire private endpoints and DNS, assign **least-privilege data-plane RBAC** to a managed identity, deploy a model with an explicit **TPM quota** and a **content filter**, turn on **diagnostics and a budget**, then pilot before you expand.
- Five automation artifacts: a read-only **PowerShell discovery** script, the core **`AIFOUNDRY-main.bicep`** infrastructure template, a **Python** posture-validation script (azure SDK, keyless), a **PowerShell** cost/usage/posture report, and a **Python** keyless smoke-test that proves managed-identity access and a live model call end to end.
- **Testing** and **Troubleshooting** guides for a confident, pilot-first rollout.

## What this delivers
An **Azure AI Foundry hub and project** plus an **Azure OpenAI** resource deployed from Bicep, with **`publicNetworkAccess` = Disabled** and a **private endpoint** on the organization's VNet resolving through **private DNS**; **`disableLocalAuth` = true** so account keys cannot be used at all; a **user-assigned managed identity** holding the least-privilege **Cognitive Services OpenAI User** data-plane role; a **model deployment** with an explicit **tokens-per-minute (TPM) quota** and rate limit; a **content-filter (RAI) policy** in front of generation; **diagnostic logging** to Log Analytics; and a **budget with cost alerts** — a private, keyless, quota-managed, monitored foundation, proven in a non-production project before it reaches production.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — every deployment is preview-first (`what-if`), reviewed in a pull request, and approval-gated, with a documented rollback via deployment-stack delete/update. Content-acceptability, acceptable-AI-use, and data-classification decisions belong to your legal, trust-and-safety, and compliance functions; this package delivers the technical controls, not those determinations.

## Outcome
A secure, governed **Azure OpenAI + AI Foundry** platform expressed as code in Git — private, keyless, quota-managed, and monitored — that your developers build enterprise AI applications on with confidence, deployable by a single administrator and validated before you scale.

## Scope boundary
This solution **builds and operates custom AI** on Azure OpenAI / AI Foundry. It is **not** Microsoft 365 Copilot governance — that is covered by the **Copilot** and **Purview AI** catalog areas. Where those govern a Microsoft-hosted assistant over your M365 data, this gives your teams a private, controlled Azure OpenAI platform to build their own AI apps on. The two are complementary; cross-reference, don't duplicate.
