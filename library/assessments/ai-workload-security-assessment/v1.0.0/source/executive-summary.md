# Executive Summary — AI Workload Security Assessment

**White-label · Assessments**

Teams stand up Azure AI the fast way: create an Azure OpenAI resource, leave the **public endpoint on**, paste the **account key** into an app setting, point a **RAG** pipeline at a SharePoint site, and ship. It demos brilliantly — and it quietly opens a new class of attack surface that traditional security reviews don't cover: **prompt injection**, **data leakage through over-shared RAG indexes**, **over-permissioned identities**, **public model endpoints**, **disabled content safety**, and **ungoverned model use** with no responsible-AI review. This assessment finds those gaps before an attacker or an auditor does. It discovers your Azure AI estate — **Azure OpenAI, Azure AI Foundry, Azure AI Search, and Azure Machine Learning** — reviews it against an **AI security baseline**, and delivers a **prioritized findings report**.

This is a complete, **run-it-yourself** package written for a competent administrator or ML engineer who has used the Azure portal but has never systematically security-reviewed an AI workload — never checked whether an Azure OpenAI resource is keyless and private, whether a search index is permission-trimmed, or whether content-safety filters are actually attached. The assessment is **strictly read-only**: every script observes and reports; **nothing in your environment is changed**.

## What you get
- A plain-language **Solution Overview** of the AI attack surface — what makes AI workloads different, the review areas (discovery, network isolation, keyless identity, content safety / prompt shields / groundedness, RAG data exposure and secrets, responsible-AI governance), and how they roll up into a prioritized findings report.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite (the category-wide ones live in the separate **Global Requirements — Assessments**).
- An **Implementation Guide** of precise, ordered steps — validate read-only access, discover every AI resource, review network isolation and keyless identity, check content-safety and groundedness posture, inspect RAG indexes for over-exposure and hard-coded secrets, and surface responsible-AI governance gaps. Pilot on one workload first, validate the findings, then expand.
- Five read-only **PowerShell** automation scripts (Az / Microsoft Graph / Cognitive Services + Search management) — discovery, access validation, network-isolation review, content-safety review, and the prioritized findings report.
- **Testing** and **Troubleshooting** guides so you can trust the findings before you present them.

## What this delivers
A **scored security picture of your AI workloads**: an inventory of every Azure OpenAI / AI Foundry / AI Search / Azure ML resource with its risk posture; a **network-isolation** review (public network access, private endpoints, disabled DNS exfiltration paths); a **keyless-identity** review (local-auth/key usage vs managed identity + least-privilege RBAC); a **content-safety** posture (content filters attached, prompt-shield / jailbreak protection, groundedness detection — noting preview features to verify); a **RAG data-exposure** review (search indexes without permission-trimming, over-broad data-source scope, secrets in connection strings); and a **responsible-AI governance** gap list — all sequenced into a **risk-ranked findings report**. A point-in-time snapshot you can re-run as you remediate.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — discover the AI estate, configure the scope and baseline, pilot the review on one workload, validate the findings against the live portals to remove false positives, then expand to every AI workload and produce the report. The assessment supplies the technical evidence; **acceptable-AI-use policy, data-classification, risk-acceptance, and any regulatory determination remain the customer's decision** — made by your trust-and-safety, legal, and security functions, not by this guide.

## Outcome
A defensible answer to "is the AI we're building secure?" — an inventory, a ranked list of the prompt-injection, data-leakage, identity, network, and governance gaps that carry the most risk, and a clear hand-off to the fixes — produced by a single administrator, entirely read-only, and re-runnable to prove progress.

## Scope boundary
This assessment **reviews Azure AI workloads you build** (Azure OpenAI / AI Foundry / AI Search / Azure ML). It **pairs with, and does not duplicate,** the AI-platform build solutions — **Azure AI Foundry & OpenAI secure deployment (AIFOUNDRY)**, **Enterprise RAG platform (AIRAG)**, **AI Content Safety & Responsible-AI guardrails (AISAFETY)**, and **AI Landing Zone governance (AILZ)** — which *deploy* the secure configurations this assessment checks for. It is **not** Microsoft 365 Copilot governance (that is the Copilot / Purview-AI areas), and it does **not** remediate — the paired AI solutions do that, pilot-first. Cross-referenced, not duplicated.
