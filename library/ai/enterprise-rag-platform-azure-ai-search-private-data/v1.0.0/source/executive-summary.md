# Executive Summary — Enterprise RAG Platform on Azure (AI Search + Private Data)

**White-label · AI**

A chatbot that can't see your data hallucinates and is worthless. A chatbot that *can* see your data but ignores who is allowed to read it is worse — it is a **data-leak engine** that will happily quote a layoff memo or a salary spreadsheet to anyone who asks. This solution builds an **enterprise Retrieval-Augmented Generation (RAG) platform on Azure** that grounds Azure OpenAI on your own private content **and enforces the source's permissions on every answer** — so it responds from your data, cites where each fact came from, and **never returns content the asking user isn't allowed to see**.

The platform is delivered **as code**: an ingestion pipeline that chunks and embeds your documents, an **Azure AI Search** index with **hybrid (keyword + vector) search and semantic ranking**, a **permission-trimmed / security-filtered** retrieval layer that respects each document's ACLs, and an orchestration layer (grounded prompts, citations, evaluation) built with **prompt flow**. It is written for an administrator with no prior RAG, Azure AI Search, or prompt-engineering experience. Everything runs **private-by-default** (no public endpoints, keyless auth) and is proven in a **non-production** environment before it touches anything real.

## What you get
- A plain-language **Solution Overview** of chunking, embeddings, hybrid + semantic + vector search, permission-trimming, and grounded orchestration.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite.
- An **Implementation Guide** of precise, ordered steps — deploy the infra (Bicep what-if first) → build the permission-trimmed index → run the ingestion/embedding pipeline → wire the grounded prompt flow → evaluate → expand — non-prod first.
- Real automation: a **Bicep** infrastructure template, and four **Python** scripts (`azure-search-documents`, `openai`, `promptflow`) for discovery, ingestion + embedding, permission-trimming validation, and reporting.
- **Testing** and **Troubleshooting** guides — including the critical **negative** permission-trimming test (a user must be *denied* content they can't see).

## What this delivers
A working RAG platform: private documents **chunked and embedded** into an **Azure AI Search** index that carries a per-document **ACL field (`group_ids`)**; **hybrid retrieval** (BM25 keyword + vector similarity) re-ranked by **semantic ranking**; a **security filter applied on every query** so the index only ever returns chunks the caller's Entra groups are permitted to read; and a **grounded orchestration flow** that feeds only those permitted chunks to Azure OpenAI, returns an answer **with citations**, and is scored for **groundedness and relevance** by an evaluation harness — all validated in non-prod first.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a **Bicep what-if gate** before any infra apply, a **dry-run gate** before any index write, and the permission-trimming **negative test** as a hard pass/fail gate before expansion.

## Outcome
AI that answers from *your* data, shows its sources, and honors your permissions — instead of a chatbot that either makes things up or leaks. Deployable by a single administrator, proven in non-production, and reusable on every content set you onboard. **Data-classification, acceptable-AI-use, and records/regulatory determinations remain the customer's compliance, legal, and security decisions** — this guide provides the technical controls, not those decisions.
