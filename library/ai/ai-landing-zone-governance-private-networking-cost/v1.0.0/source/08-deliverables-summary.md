# Deliverables Summary — AI Landing Zone & Governance (Private Networking, Content Safety, Cost)

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page business framing: the AI-sprawl problem (public endpoints, no guardrails, keys, bill shock), the governed AI landing zone solution, and the boundary (foundation only; secure AI deployment / RAG / MLOps / content-safety-in-depth are separate; plan-first, production apply and AI-use policy are the customer's decisions). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how the technology works (landing zone, hub/spoke, private endpoints + private DNS, Azure Policy initiatives + audit-first, managed identity + RBAC, Key Vault, content-safety defaults, cost management), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (elevated deploy role, hub/spoke + address plan, private-DNS strategy, allowed regions/models/tags, provider registration, encrypted remote state, the pinned OIDC toolchain, a non-prod scope) — layered on the shared `global-requirements-ai.md` (G1–G8). |
| **Implementation** (`03-implementation.md`) | Exact, ordered build: discover state, author the zone as code, plan/what-if-first apply of network/private-endpoints/identity/Key Vault/policy(audit)/budget to a non-prod scope, place a pilot AI service, validate private+keyless+guardrailed, then flip policies to enforce and expand to the management group — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates from hub/spoke+peering, private DNS, public-access-disabled, private-resolution, keyless identity, policy-reporting-in-audit, content-safety default, budget+usage, through plan-first-with-protected-state, referencing the helpers by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (private hostname resolving public, peering fails on overlap, private-endpoint approval pending, policy blocking legitimate work, definition unavailable/preview, OIDC/state failures, keyless 401, budget silent, GCC/GCC-High gaps, foundation cost) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Foundation-as-code, private-by-default, audit-then-enforce-and-keep-exits-open, keyless-over-keys, safety-and-cost-as-defaults, mind-the-cost — plus where to go next in the catalog. |

## Infrastructure-as-Code + helpers (5)

The core is **real Terraform**; the pipeline is **plan/what-if-first and approval-gated**; the helpers
are **read-only**. Nothing uses secrets — everything authenticates via **workload-identity federation
(OIDC)** / interactive `Connect-AzAccount` (never a client secret in code). *Verify current provider/
module versions, built-in policy-definition availability (some AI/content-safety definitions may be
preview or absent), privatelink zone names, model/region availability, and pricing for your cloud
(Commercial vs GCC/GCC-High).*

| File | Type | What it does |
| --- | --- | --- |
| **`main.tf`** | Terraform (plan-first) | Declares the AI landing zone as code: hub/spoke VNets + peering, the five `privatelink.*` DNS zones (linked), the OpenAI + Key Vault private endpoints, `kv-ailz-nonprod-<suffix>` (public access **disabled**), `log-ailz-platform`, `id-ailz-aiworkload-nonprod` + RBAC, the `AILZ-AI-Guardrails-Initiative` and its five `Policy-*-AILZ` assignments in **DoNotEnforce (audit)** mode, and `Budget-AILZ-Platform` + `ag-ailz-cost-alerts`. Applied only through the pipeline. |
| **`azure-pipelines.yml`** | YAML pipeline (plan-first, approval-gated) | The **only** sanctioned way to apply `main.tf`: fmt/validate → **plan** (changes nothing, publishes the plan artifact) → **Environment approval gate** → **apply** the reviewed plan (non-prod first, never on a PR) → **read-only validate**. Authenticates via OIDC. |
| **`AILZ-Discovery.ps1`** | Read-only (Az PowerShell) | Inventories current state: effective role, registered/missing providers, existing VNets + address spaces (overlap check), private DNS zones, policy assignments, Key Vaults, and any **AI service with public access ON**. Calls only Get/List. |
| **`AILZ-Validate.ps1`** | Read-only (Az PowerShell) | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL: hub/spoke+peering, private DNS, public-access-disabled, a private-resolution DNS probe, keyless identity, policy assigned+audit, content-safety default, and budget — with a non-zero exit on hard failure. |
| **`AILZ-Report.ps1`** | Read-only (Az PowerShell) | Posture + cost snapshot for governance/FinOps: private-endpoint coverage, guardrail compliance (what would be denied once enforced), budget vs actual spend, and AI spend by service. |

## Named objects (verbatim — used across docs, IaC, and tests)

- **Resource groups:** `rg-ailz-hub-platform`, `rg-ailz-spoke-nonprod`
- **Network:** `vnet-ailz-hub-platform`, `vnet-ailz-spoke-nonprod`, `snet-ailz-privateendpoints`,
  `snet-ailz-aiworkload`, `peer-ailz-hub-to-spoke`, `peer-ailz-spoke-to-hub`
- **Private DNS zones:** `privatelink.openai.azure.com`, `privatelink.cognitiveservices.azure.com`,
  `privatelink.search.windows.net`, `privatelink.vaultcore.azure.net`, `privatelink.blob.core.windows.net`
- **Private endpoints:** `pep-ailz-openai-nonprod`, `pep-ailz-keyvault-nonprod`
- **Platform:** `kv-ailz-nonprod-<suffix>` (Key Vault), `log-ailz-platform` (Log Analytics),
  `id-ailz-aiworkload-nonprod` (managed identity), `Workbook-AILZ-AIUsage` (usage dashboard)
- **Policy:** `AILZ-AI-Guardrails-Initiative` with `Policy-AllowedRegions-AILZ`,
  `Policy-AllowedModels-AILZ`, `Policy-PrivateOnly-AILZ`, `Policy-ContentSafetyOn-AILZ`,
  `Policy-RequireTags-AILZ`
- **Cost:** `Budget-AILZ-Platform`, `ag-ailz-cost-alerts`
- **RBAC:** `Cognitive Services OpenAI User` (and `Key Vault Secrets User`) → `id-ailz-aiworkload-nonprod`

## What this solution deliberately does NOT do

- It does **not** deploy or harden the AI service itself (Azure OpenAI / AI Foundry), build a
  private-data RAG platform, stand up MLOps pipelines, or configure content-safety / responsible-AI in
  depth — those are separate catalog solutions this landing zone makes deployable.
- It does **not** apply anything without a plan — every change is **plan/what-if-first, non-prod-first**,
  guardrails start in **audit (DoNotEnforce)** mode, and production apply / policy enforcement require
  the customer's change approval.
- It does **not** decide **which models/regions are allowed, the tagging standard, or the budget
  thresholds** — those are governance/FinOps determinations; the solution enforces what you set. The
  **acceptable-AI-use policy and content-acceptability thresholds are the customer's legal / trust-and-
  safety decision.**
- It does **not** use client secrets or API keys — the pipeline uses **OIDC** and the workload uses
  **managed identity**.
- It does **not** invent version, feature, policy, or pricing facts — where these are preview or differ
  by cloud it says **verify current provider/module versions, policy/feature availability, and
  pricing** (Commercial vs GCC/GCC-High).

## How it is delivered

This solution is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the
documentation as a formatted Word document and PDF, plus the Terraform, YAML pipeline, and Az/
PowerShell files, in a single ZIP (`AILZ-Complete-Solution.zip`) — yours to keep and reuse on every
AI rollout.
