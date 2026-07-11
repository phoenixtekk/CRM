# 1. Solution Overview — AI Workload Security Assessment

## What this assessment is
This solution is a **security assessment of the Azure AI workloads your teams build** — **Azure OpenAI**, **Azure AI Foundry** (hub/project), **Azure AI Search**, and **Azure Machine Learning**. It **discovers** what AI resources exist, **reviews** each against an AI security baseline, and **prioritizes** the gaps into a risk-ranked findings report. It is not a deployment and not a remediation: every script is **read-only** and changes nothing. The output is evidence — an inventory and a ranked findings list — that tells you where an AI workload is exposed and which gap to close first.

AI workloads matter here because they add attack surface that a conventional cloud security review misses:
- **Prompt injection** — untrusted content (a document, a web page, a user message) that hijacks the model's instructions. Content filters and **prompt shields** exist to blunt it; the question is whether they're turned on.
- **Data leakage through RAG** — a retrieval-augmented-generation app surfaces answers from an index built over your files. If the **index isn't permission-trimmed**, a user can get answers drawn from documents they could never open directly. This is the single most common serious AI finding.
- **Over-permissioned identity and keys** — an Azure OpenAI **account key** is a long-lived, portable credential; **keyless** (managed identity + least-privilege RBAC) is the secure path.
- **Public endpoints** — an AI resource reachable from the internet is a data-exfiltration surface; **private endpoints** and **disabled public network access** close it.
- **Ungoverned model use** — models deployed with no content-filter policy, no responsible-AI review, and no owner.

Reviewing against a **named baseline** makes the findings comparable and defensible run-to-run. *The AI security baseline, the Azure AI resource model, and several safety features evolve quickly and some are in preview — verify current availability, resource types, and portal layout in your tenant when you run the assessment.*

## The review areas
- **Discovery.** Enumerate every Azure OpenAI / Cognitive Services (kind `OpenAI` / `AIServices`), AI Foundry hub/project, Azure AI Search service, and Azure ML workspace in scope, with its headline posture.
- **Network isolation.** For each AI resource: is **public network access disabled**? Is there a **private endpoint** on your VNet? Are there routes that still allow public egress/exfiltration? Public-by-default is the norm, so this is where most resources fail.
- **Keyless identity.** Is **local auth (account keys) disabled**? Does the app authenticate with a **managed identity** holding a least-privilege data-plane role (e.g. Cognitive Services OpenAI User; Search Index Data Reader) rather than a shared key? Are there keys in app settings?
- **Content safety, prompt shields, groundedness.** Does each model deployment have a **content-filter (RAI) policy** attached? Are **prompt-shield / jailbreak** and **protected-material** protections enabled? Is **groundedness detection** in use for RAG? *Several of these are preview — verify availability and preview status.* *The acceptable-content threshold itself is the customer's trust-and-safety decision.*
- **RAG data exposure and secrets.** For AI Search: are indexes **permission-trimmed** (security filters / document-level access), or do they expose the whole corpus to every user? How broadly scoped are the data sources? Are there **secrets / keys hard-coded** in connection strings or app settings instead of Key Vault?
- **Responsible-AI governance.** Is there an owner, a documented purpose, a content-filter standard, and a review for each model in use — or are models deployed ad hoc? *The governance policy itself is the customer's; the assessment scores whether controls exist.*

## How the assessment works
- **Read-only discovery** via **Az** modules (Az.CognitiveServices, Az.Search, Az.MachineLearningServices, Az.Network, Az.Monitor) and **Microsoft Graph** for identity/RBAC — authenticated as a **least-privilege reader** (Azure Reader + Security Reader), never with write access.
- **Posture rules** encode the AI security baseline (public access disabled, local auth disabled, custom subdomain set, private endpoint present, content filter attached, permission-trimming on indexes, no plaintext secrets) and flag each resource that deviates as a finding.
- **KQL where it adds signal.** Where diagnostics flow to Log Analytics / Sentinel, the guide supplies read-only KQL to corroborate posture (e.g. Azure OpenAI calls that authenticated with a key rather than a token) — evidence, never a change.
- **Ranking.** Findings are tagged with a **risk rating** (impact × exposure) — a public, keyless-disabled resource serving a non-permission-trimmed RAG index over sensitive data ranks Critical — and sequenced into a phased roadmap.

## What you can control
- **Scope** — which subscriptions, resource groups, and AI workloads are in the assessment.
- **Baseline** — the AI security baseline you score against (Microsoft AI security guidance + the paired build solutions' target state). *Verify the current baseline.*
- **Output handling** — where the (sensitive) findings report is stored and who may see it.

## Scope — what's in
- **Read-only discovery** of Azure OpenAI / AI Foundry / AI Search / Azure ML.
- **Network-isolation** review (public access, private endpoints).
- **Keyless-identity** review (local auth, managed identity + least-privilege RBAC, plaintext secrets).
- **Content-safety / prompt-shield / groundedness** posture (preview features flagged).
- **RAG data-exposure / permission-trimming** review and **secrets** review.
- **Responsible-AI governance** gap list, rolled into a risk-ranked findings report.

## Scope — what's out (be honest with buyers)
- **This does not remediate.** It observes and scores. The paired AI solutions deploy the fixes: **AIFOUNDRY** (private, keyless Azure OpenAI + Foundry), **AIRAG** (permission-trimmed RAG on AI Search), **AISAFETY** (content safety / responsible-AI guardrails), **AILZ** (AI landing-zone governance). Cross-referenced, not duplicated.
- **Not Microsoft 365 Copilot governance.** Governing Copilot over M365 data is the **Copilot** / **Purview-AI** areas; this assesses AI apps your teams build.
- **Not a model red-team / jailbreak engagement.** The assessment checks that safety controls are configured; adversarial prompt testing of a live model is a separate discipline.
- **No acceptable-use, data-classification, or regulatory determination.** The assessment states each gap and its risk; **what content is acceptable, what data is sensitive, whether to accept a risk, and any regulatory mapping are the customer's decisions** — trust-and-safety, legal, and security own them.

## Authentication and connections used
- **Az PowerShell** signed in as **Reader** at the Azure scope — for AI resource, network, and diagnostics discovery (Global Requirements G2, G3).
- **Microsoft Graph** (read scopes) signed in as **Security Reader** — for identity / RBAC / managed-identity role assignments (G2, G3).
- **Microsoft Sentinel / Log Analytics** read access where present — for the corroborating KQL (optional).
- No write scopes are requested or used — the read-only guarantee (G2).

## The standard deployment model
> **Assess the AI estate (discover every AI resource and its posture) → configure the scope and AI security baseline → pilot the review on one AI workload → validate the findings against the live Azure portal to remove false positives → expand to every AI workload and produce the risk-ranked report.** The repeatable pattern: **Assess → Configure → Pilot → Validate → Expand** — entirely read-only, re-runnable to trend progress, with remediation handed to the paired AI build solutions under change control.
