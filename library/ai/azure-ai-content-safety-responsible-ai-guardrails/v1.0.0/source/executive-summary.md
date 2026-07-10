# Executive Summary — Azure AI Content Safety & Responsible-AI Guardrails

A custom AI application — a chatbot, a copilot, a document assistant — is only as safe as the
guardrails around it. Ship one with no safety layer and it can emit hateful or violent content, be
talked out of its own rules by a jailbreak prompt, follow instructions hidden in a document it was
asked to summarize, hallucinate a confident answer that has no basis in your data, or reproduce
copyrighted text. Each of those is a brand, legal, and compliance risk — and none of them is caught
by the language model itself. They are caught by a **guardrail layer** you put in front of and behind
generation.

This is a complete, deploy-it-in-order package for adding that guardrail layer to your **own** custom
AI apps using **Azure AI Content Safety**, written for a competent developer or administrator who has
not built AI safety controls before. It gives you the repeatable way to moderate text and images
against harm categories with severity thresholds, shield your prompts against jailbreak and indirect
prompt-injection attacks, enforce a custom blocklist, check answers for groundedness and protected
material, wire all of it into a **pre-generation / post-generation filter**, and stand up a
responsible-AI review, red-team, and incident/appeal process — proven on a pilot app before you put it
in front of users.

## What this is (and is not)
This solution is content-safety **guardrails for custom AI apps you build** — apps that call Azure
OpenAI or another model directly. It is deliberately **distinct from AI governance for Microsoft 365
Copilot** (which is about permissions, sensitivity labels, and DLP over your tenant data — see the
*Microsoft 365 Copilot Secure Adoption & Governance* and *Microsoft Purview* solutions). If your risk
is "Copilot can see too much," that is the other solution. If your risk is "the app I built could say
or be tricked into something harmful," this is the one.

## What you get
- A plain-language Solution Overview of how Azure AI Content Safety works — the four harm categories
  and severity scale, Prompt Shields, blocklists, groundedness detection, protected-material
  detection — and the pre/post-generation filtering pattern that ties them into your app.
- A Requirements Guide with verify / implement-if-missing for every prerequisite specific to content
  safety (the category-wide Azure/AI prerequisites are published once in the global requirements).
- An Implementation Guide of precise, ordered steps — provision the Content Safety resource keyless,
  define a severity policy and blocklist, build the safety filter, add Prompt Shields and groundedness
  checks, then pilot on one app and validate with red-team prompts before expanding.
- Five Python scripts (using the `azure-ai-contentsafety` SDK) for discovery, configuration
  validation, a moderation-posture report, a ready-to-adapt pre/post-generation **safety filter**
  integration sample, and a safe blocklist manager.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus a responsible-AI review and
  incident/appeal process.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — pilot the guardrails on one app, in
audit/observe mode first, with a rollback at every stage before you enforce blocking in production.

## The boundary
This guide delivers the **technical controls and the process scaffolding**. What content is
"acceptable," where each severity threshold should sit, and what your responsible-AI and acceptable-use
policy says are **the customer's legal / trust-and-safety / compliance decisions** — the guide shows
you how to enforce those decisions once they are made, not what they should be.

## Effort
A competent developer/admin can stand up the Content Safety resource and a working safety filter on a
pilot app in about a day, then spend a few days red-teaming, tuning thresholds with trust & safety,
and wiring the incident process before expanding to more apps. No consultant required.

## Outcome
Custom AI apps with real guardrails a single team can run and defend at review: harmful content
moderated to a defined policy, jailbreak and injection attacks shielded, answers checked for
groundedness and protected material, and a responsible-AI review, red-team, and incident/appeal
process behind it — validated on a pilot before any app ships.
