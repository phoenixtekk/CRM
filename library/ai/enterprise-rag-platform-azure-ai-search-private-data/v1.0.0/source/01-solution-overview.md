# 1. Solution Overview — Enterprise RAG Platform on Azure (AI Search + Private Data)

## What the RAG platform is
Retrieval-Augmented Generation (RAG) makes a large language model answer from **your** content instead of only from what it was trained on. Rather than asking the model to "know" your policies, contracts, or tickets, you **retrieve** the most relevant passages from your own data at query time and hand them to the model as grounding, so the answer is based on real source text and can be **cited**. This solution builds that whole pipeline on Azure, and adds the one control most home-grown RAG demos skip: it **enforces the source document's permissions on every retrieval**.

It combines five capabilities:

- **Ingestion, chunking, and embedding (as code)** — a pipeline reads your source documents, splits them into overlapping **chunks** small enough to retrieve precisely, generates a **vector embedding** for each chunk with an Azure OpenAI embedding model, and writes the chunk text + vector + metadata into the search index.
- **Azure AI Search index — hybrid + semantic + vector** — each query runs **keyword (BM25)** and **vector (nearest-neighbour)** search together (**hybrid**), and the combined results are re-ordered by Azure AI Search **semantic ranking** so the passages the model sees are the most relevant, not just the most keyword-similar.
- **Permission-trimmed / security-filtered retrieval** — every chunk carries an **ACL field** (`group_ids`) copied from the source document's permissions. Every query is executed with a **security filter** that keeps only the chunks whose `group_ids` intersect the **asking user's Entra group memberships**. Content the user can't open in the source system is never even retrieved — so it can never reach the model or the answer.
- **Grounded orchestration with citations (prompt flow)** — a **prompt flow** takes the user's question, retrieves the permitted chunks, builds a **grounded prompt** ("answer only from the sources below; if the sources don't contain the answer, say so"), calls the Azure OpenAI chat model, and returns the answer **with citations** back to the specific source chunks.
- **Evaluation harness + monitoring** — an evaluation flow scores answers for **groundedness** (is the answer supported by the retrieved sources?) and **relevance** (does it address the question?), and the platform's telemetry (Application Insights / Azure Monitor) tracks latency, token cost, and failure rates.

## Why this matters
Two failure modes make private-data chatbots dangerous. The first is **hallucination**: an ungrounded model invents plausible-sounding answers, and users can't tell the fabricated ones from the real ones. RAG fixes this by grounding the answer in retrieved source text and citing it, so answers are checkable. The second — and the reason this solution exists — is the **data leak**: a naive RAG index ingests every document into one pool and returns the best semantic match **regardless of who is asking**. A contractor asks an innocent question and the model quotes a passage from a board deck or an HR file they were never allowed to open. The permission-trimming layer closes this by construction: the ACL travels with each chunk, and the security filter is applied **inside the search query** on every call, so unauthorised content is never retrieved in the first place. Because the whole platform is defined as code and proven in non-production — including an explicit **negative test** that a user is *denied* content they can't see — you validate the security boundary before any real content or real users are involved.

## How it works
1. **Infrastructure as code** — a **Bicep** template (`AIRAG-infra.bicep`) is run **what-if first**, then deploys the platform: an **Azure AI Search** service, an **Azure OpenAI** resource with an **embedding** deployment and a **chat** deployment, a **storage account** for source documents, a **user-assigned managed identity** for keyless service-to-service auth, and (per the category requirements) **private endpoints** with public network access disabled.
2. **Index creation** — the pipeline creates the index with the fields RAG needs: `id`, `content` (chunk text), `contentVector` (the embedding, with a vector search + HNSW profile), source metadata (`title`, `url`, `lastModified`), and the **security field `group_ids`** (`Collection(Edm.String)`, filterable) — plus a **semantic configuration** so semantic ranking can run.
3. **Ingestion + embedding** — `AIRAG-Ingest.py` reads each source document **together with its permission set** (the Entra group object IDs that can read it), chunks the text, embeds each chunk, and **stamps every chunk with the parent document's `group_ids`**. Nothing is written to the index without an ACL.
4. **Permission-trimmed retrieval** — at query time the orchestration resolves the **caller's** Entra group memberships and executes the search with the filter `group_ids/any(g: search.in(g, '<caller group ids>'))`, combined with hybrid + semantic ranking. Only permitted, relevant chunks come back.
5. **Grounded generation** — the prompt flow (`RAG Flow – Orchestration – NonProd`) passes those chunks to the Azure OpenAI **chat** deployment inside a grounded prompt and returns the answer **with citations**; if no permitted chunk supports an answer, the flow returns "I don't have a source for that" rather than inventing one.
6. **Evaluation + monitoring** — an evaluation run (`RAG Eval – Groundedness – NonProd`) scores a test-question set for groundedness and relevance, and Application Insights captures latency, token usage, and errors for ongoing monitoring.

## What you can control
- **Chunking** — chunk size and overlap (retrieval precision vs. context completeness).
- **Retrieval mix** — keyword-only, vector-only, or hybrid; whether **semantic ranking** is on; and `top-k` (how many chunks feed the model).
- **The security model** — which source-permission field maps to `group_ids`, and whether trimming is by **Entra group** (default) or another ACL scheme; trimming is **on by default and non-optional** in this design.
- **Grounding behaviour** — the system prompt, the "refuse if unsupported" instruction, and the citation format.
- **Models** — which embedding model and which chat model deployment are used, and their token/rate limits.
- **Evaluation thresholds** — the minimum groundedness/relevance scores that gate expansion.

## Limitations (be honest with buyers)
- **Permission-trimming is only as correct as the ACLs you feed it.** The platform enforces the `group_ids` you stamp on each chunk; **you** must map each source system's real permissions to those group IDs accurately. A wrong or missing ACL at ingestion is a leak the search filter cannot catch. The validation script's **negative test** exists precisely to catch this before go-live.
- **Azure AI Search semantic ranking** and some **integrated vectorization** features have **tier requirements and, in places, preview status** — *verify current availability, tier, and pricing in your region and subscription.*
- **Azure OpenAI model and region availability, quotas (TPM), and pricing vary** and models are versioned/retired on a schedule — *verify the current models, versions, regions, and quota in your subscription.*
- RAG grounds and cites; it does **not** guarantee a correct answer if your source content is wrong, stale, or contradictory. Content quality and **data-classification** are upstream of this platform and are the compliance team's remit.
- **Acceptable-AI-use, content-safety thresholds, and records/regulatory** determinations are the customer's legal / trust-and-safety / compliance decisions (see `global-requirements-ai.md` G6/G7). This guide delivers the technical controls, not the policy.

## Auth and connections used
- **Microsoft Entra ID** — the identity behind the **user-assigned managed identity** (keyless auth to Search and OpenAI) and the source of the **caller's group memberships** used for permission-trimming.
- **Azure Resource Manager** — the Bicep deployment operates against ARM with **Owner** or scoped **Contributor + role assignment** rights on the target resource group.
- **Azure AI Search data plane** — index create/load and query, authenticated by managed identity with least-privilege data-plane roles (**Search Index Data Contributor** to load, **Search Index Data Reader** to query).
- **Azure OpenAI data plane** — embeddings and chat completions, authenticated by managed identity (**Cognitive Services OpenAI User**).
- **Microsoft Graph** (read-only) — resolves a user's **group memberships** and, where used, a document's permission set for the ACL mapping.

## The standard deployment model
> **Assess prerequisites → deploy the infra (bicep what-if → apply, non-prod) → create the permission-trimmed index → run the ingestion/embedding pipeline (dry-run first) → wire the grounded prompt flow → validate (including the permission-trimming NEGATIVE test) → evaluate groundedness/relevance → expand to more content and production.** The repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with a **what-if gate** before infra apply, a **dry-run gate** before index writes, and the **permission-trimming negative test as a hard gate** before expansion.
