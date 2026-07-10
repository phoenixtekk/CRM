# 1. Solution Overview — Azure AI Content Safety & Responsible-AI Guardrails

## What Azure AI Content Safety is
Azure AI Content Safety is a cloud service that inspects **text and images** — both the input going
into your AI app and the output coming out of it — and returns a structured safety judgment your code
can act on. It does not replace the language model; it sits **around** the model as a guardrail. Your
app calls Content Safety before it sends a prompt to the model (to catch harmful or adversarial
input) and after the model responds (to catch harmful or ungrounded output) — the **pre-generation /
post-generation filter** pattern this solution builds.

It exposes several capabilities through one resource and SDK:

- **Text moderation** — `analyze_text` scores content across four harm categories: **Hate**,
  **Sexual**, **Violence**, and **Self-Harm**. Each category comes back with a **severity** level
  (a 0–7 scale, or a coarser 0/2/4/6 four-level mode). Your app compares the severity to a threshold
  *you* set per category and decides to allow, block, or route for human review.
- **Image moderation** — `analyze_image` scores images across the same four categories with severity,
  for apps that accept or generate images.
- **Custom blocklists** — term lists you define (`analyze_text` with `blocklist_names`) so specific
  words or phrases are always flagged regardless of the category model — useful for brand-specific,
  domain-specific, or competitor/PII terms.
- **Prompt Shields** — a detector for **jailbreak** attacks (user attempts to override the app's
  instructions, e.g. "ignore your rules and…") and **indirect prompt-injection** attacks (malicious
  instructions hidden inside a document, web page, or email the app was asked to process). *Prompt
  Shields, and the exact API shape, evolve — verify current availability and API version in your
  region.*
- **Groundedness detection** — checks whether a model's answer is actually **supported by the source
  material** you grounded it on (your RAG documents), flagging confident hallucinations. *Preview
  capability — verify current availability in your tenant/region.*
- **Protected-material detection** — flags output that reproduces known **copyrighted text** (and, in
  preview, code). *Verify current availability.*

## How it fits into your app (the filtering pattern)
```
                 ┌──────────────── PRE-GENERATION FILTER ────────────────┐
  user input ──▶ │ analyze_text (harm categories + severity) + blocklist │──▶  block / allow
                 │ Prompt Shields (jailbreak + indirect injection)       │
                 └───────────────────────────────────────────────────────┘
                                        │ allowed
                                        ▼
                                  language model (Azure OpenAI / other)
                                        │ response
                                        ▼
                 ┌──────────────── POST-GENERATION FILTER ───────────────┐
  final output ◀─│ analyze_text on the answer (harm categories)          │◀── block / allow / review
                 │ groundedness check (vs. RAG sources) + protected-mat. │
                 └───────────────────────────────────────────────────────┘
```
1. **Pre-generation:** run the user's input (and any retrieved documents) through text moderation, the
   blocklist, and Prompt Shields. If input exceeds your severity policy or trips a shield, block it or
   sanitize it **before** it ever reaches the model.
2. **Generation:** the model produces a candidate answer.
3. **Post-generation:** run the candidate answer through moderation again (the model can produce harm
   even from clean input), check it for groundedness against the sources, and check for protected
   material. Block, redact, or route to human review per policy before returning it to the user.
4. **Log every decision** (categories, severities, shield hits, groundedness) for the responsible-AI
   review and the incident/appeal process.

## The severity model (what you actually tune)
Content Safety returns a severity per category; **you** own the threshold. A typical starting policy
is "block at severity ≥ 4 (medium/high) for all four categories, flag 2 for review, allow 0" — but the
correct thresholds depend on your audience and use case and are a **trust-and-safety decision**, not a
technical default. This solution gives you the mechanism and a safe starting point; the policy numbers
are ratified by the customer.

## Auth and connections used
- **Azure AI Content Safety resource** (an Azure AI Services / Cognitive Services resource) — the
  endpoint your app calls.
- **Keyless authentication by default** — the app authenticates with a **managed identity** assigned
  the **Cognitive Services User** role on the resource (`DefaultAzureCredential`), so no API key is
  stored in the app. A key is supported only as a fallback and, if used, lives in **Key Vault**, never
  in code (see global requirements G2).
- **Your existing AI app** and, for groundedness, your **RAG source documents**.
- **Private networking** where required (global requirement G3) — the Content Safety resource can be
  reached over a private endpoint with public access disabled.

## The standard deployment model
> **Assess** which of your AI apps generate or accept content and have no guardrails today →
> **Configure** the Content Safety resource (keyless), the severity policy, and the blocklist →
> **Pilot** the safety filter on one app in **audit/observe mode** (log, don't block) →
> **Validate** with red-team prompts and groundedness tests against a pass/fail gate →
> **Expand** to enforce blocking and roll the pattern out to more apps.
> The pattern is **Assess → Configure → Pilot → Validate → Expand**, with observe-before-enforce and a
> rollback at every stage.

## Scope
- Adding Azure AI Content Safety guardrails (text/image moderation, blocklists, Prompt Shields,
  groundedness, protected-material) to **custom AI apps you own**.
- Building the reusable pre/post-generation **safety filter** integration and its logging.
- Standing up the responsible-AI review, red-team prompt set, and incident/appeal process.

## Out of scope
- **Microsoft 365 Copilot / Purview AI governance** — permissions, sensitivity labels, and DLP over
  tenant data are a *different* problem; use the Copilot and Purview solutions (cross-referenced, not
  duplicated here).
- **Building the AI app itself, the model deployment, or the RAG pipeline** — this solution guardrails
  an app you already have (see the AI landing-zone / RAG solutions for building it).
- **Deciding what content is acceptable or setting the responsible-AI policy** — those determinations
  belong to the customer's legal / trust-and-safety / compliance functions; this guide enforces them.

## Benefits
- **Harm moderated to policy** — text and images scored against four categories with thresholds you own.
- **Attacks shielded** — jailbreak and indirect prompt-injection detected before they reach the model.
- **Hallucinations caught** — groundedness checks flag answers unsupported by your sources.
- **Brand & IP protected** — blocklists and protected-material detection catch specific terms and
  copyrighted output.
- **Defensible process** — a responsible-AI review, red-team set, and incident/appeal process behind
  the controls, all logged and repeatable.

## Limitations (be honest with buyers)
- Content Safety is **probabilistic** — it reduces risk, it does not guarantee zero harmful output;
  keep human review in the loop for high-stakes uses.
- **Groundedness and protected-material detection are preview/evolving** capabilities — confirm current
  availability, region support, and API versions in your tenant before you depend on them.
- Prompt Shields catch known attack patterns; **novel jailbreaks will appear** — red-teaming is
  ongoing, not one-time.
- **Latency and cost** — every pre/post call adds a round trip and a per-transaction charge; budget and
  quota accordingly (global requirement G8).
- **Thresholds are a policy call** — the service gives you severities; where to draw the line is the
  customer's trust-and-safety decision.
