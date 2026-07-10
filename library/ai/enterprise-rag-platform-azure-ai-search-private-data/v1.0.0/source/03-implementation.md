# 3. Implementation Guide — Enterprise RAG Platform on Azure (AI Search + Private Data)

Follow these steps **in order**. Infrastructure is deployed by **Bicep** (`az deployment group what-if` **before** `create`), then the index, ingestion, orchestration, and evaluation are built with **Python**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Everything runs **what-if / dry-run first** and on the **non-production** resource group first. Deploy the infra with `what-if`, build the index, ingest a **small pilot set in dry-run** before writing, then run the **permission-trimming negative test** — expanding only after it passes. Keep a rollback (delete the non-prod resource group / drop-and-rebuild the index) for every change.

## Naming (set once, reuse verbatim)
- Non-prod resource group: `RAG RG – Platform – NonProd` (`rg-rag-platform-nonprod`)
- Azure AI Search service: `RAG Search – Platform – NonProd` (`srch-rag-nonprod`)
- Search index: `RAG Index – Content – NonProd` (`rag-index-nonprod`)
- Azure OpenAI resource: `RAG OpenAI – Platform – NonProd` (`oai-rag-nonprod`)
- Embedding deployment: `RAG Embeddings – Model – NonProd` (`rag-embeddings`, e.g. `text-embedding-3-large`)
- Chat deployment: `RAG Chat – Model – NonProd` (`rag-chat`, e.g. `gpt-4o`)
- Source storage account: `RAG Storage – Source – NonProd` (`stragrsrcnonprod`)
- Managed identity: `RAG Identity – Platform – NonProd` (`id-rag-platform-nonprod`)
- Orchestration prompt flow: `RAG Flow – Orchestration – NonProd`
- Evaluation run: `RAG Eval – Groundedness – NonProd`
- Pilot reader groups: `RAG Readers – Finance – Pilot` (restricted), `RAG Readers – General – Pilot`
- Security (ACL) field on every document/chunk: **`group_ids`** (`Collection(Edm.String)`, filterable)

## Step 1 — Assess and set variables
1. Run `AIRAG-Discovery.py` to capture the pre-change picture: subscription context, any existing Search/OpenAI resources, the pilot Entra group object IDs you supply, and whether the sample source exposes a resolvable permission set.
2. Copy `AIRAG-infra.bicepparam` (or a parameters file you create) and set: resource group `rg-rag-platform-nonprod`, region, Search tier, the OpenAI model names for `rag-embeddings` / `rag-chat`, the VNet/subnet + Private DNS IDs for the private endpoints, and `publicNetworkAccess = Disabled`.
3. Confirm the operator/pipeline host has a **network path to the private endpoints** — the later ingestion and query steps depend on it.

## Step 2 — Deploy the infrastructure (Bicep what-if = the gate)
1. `az login`, then `az group create -n rg-rag-platform-nonprod -l <region>`.
2. Run **what-if** and read the whole plan — **nothing is created yet**:
   `az deployment group what-if -g rg-rag-platform-nonprod -f AIRAG-infra.bicep -p AIRAG-infra.bicepparam`
3. Review every resource: the Search service (with **Semantic ranker**), the OpenAI resource + the two model deployments, the source storage account, the **user-assigned managed identity**, and the **private endpoints** with public access disabled.
4. Only when the plan matches intent and the change is approved:
   `az deployment group create -g rg-rag-platform-nonprod -f AIRAG-infra.bicep -p AIRAG-infra.bicepparam`
5. Assign the runtime identity its **least-privilege data-plane roles** (Search Index Data Contributor + Reader on the Search service; Cognitive Services OpenAI User on the OpenAI resource) at the narrowest scope.

## Step 3 — Create the permission-trimmed index
1. Run `AIRAG-Ingest.py --create-index-only` (no data written yet). This creates `rag-index-nonprod` with the fields RAG needs:
   - `id` (key), `content` (chunk text, searchable), `title` / `url` / `lastModified` (metadata),
   - `contentVector` (`Collection(Edm.Single)`, the embedding, tied to a **vector search profile + HNSW** config with the **same dimensions** as `rag-embeddings`),
   - **`group_ids`** (`Collection(Edm.String)`, **filterable**) — the per-chunk ACL, and
   - a **semantic configuration** naming `content` as the semantic content field so semantic ranking can run.
2. Confirm the index exists: `AIRAG-Validate.py --check-index` reports the field set and confirms `group_ids` is present and filterable. **An index without the `group_ids` field must never be loaded** — the validator fails the run if it is missing.

## Step 4 — Ingest a small pilot set (dry-run first)
1. Run `AIRAG-Ingest.py --source <pilot path/site> --dry-run`. In dry-run the script **reads, chunks, and resolves each document's `group_ids`, and prints a per-document summary — but writes nothing.** Confirm every document resolved a **non-empty** `group_ids` (any document with no ACL is flagged; decide its group before proceeding).
2. Re-run **without** `--dry-run` to embed and load: `AIRAG-Ingest.py --source <pilot path/site>`. Each chunk is embedded with `rag-embeddings` and written with its parent document's `group_ids` stamped on it.
3. Deliberately include, in the pilot set, **at least one document readable only by `RAG Readers – Finance – Pilot`** — this is the document the negative test will try (and must fail) to retrieve as the unauthorised user.

## Step 5 — Verify hybrid + semantic retrieval works
1. Run `AIRAG-Validate.py --query "<a question answered by the pilot content>" --as-group <RAG Readers – Finance – Pilot object id>`.
2. Confirm the query returns relevant chunks, that **hybrid** (keyword + vector) and **semantic ranking** are both applied (the script prints the search mode and the semantic reranker score), and that citations point back to the correct source documents.

## Step 6 — Run the PERMISSION-TRIMMING negative test (the hard gate)
1. Run the **same query** as the **unauthorised** user's groups — omit the Finance group:
   `AIRAG-Validate.py --query "<question that only the Finance-only document answers>" --as-group <RAG Readers – General – Pilot object id>`
2. **Expected — the gate:** the restricted document's chunks are **NOT** returned (the security filter `group_ids/any(g: search.in(g, '<caller groups>'))` excludes them), and the grounded flow answers **"I don't have a source for that"** rather than leaking the content. `AIRAG-Validate.py --permission-trimming-test` runs both the authorised and unauthorised query and **fails the run if the unauthorised query returns any restricted chunk.**
3. **Do not proceed past this gate until the negative test passes.** A failure here means an ACL was mis-mapped at ingestion (Step 4) — fix the `group_ids` mapping and re-ingest, do not weaken the filter.

## Step 7 — Wire the grounded orchestration (prompt flow)
1. Open the prompt flow `RAG Flow – Orchestration – NonProd`. Its nodes: **resolve caller groups** (Graph) → **embed the question** (`rag-embeddings`) → **hybrid+semantic search with the `group_ids` security filter** → **build the grounded prompt** → **chat completion** (`rag-chat`) → **format answer + citations**.
2. Set the grounded system prompt to instruct the model to **answer only from the supplied sources, cite each source, and explicitly refuse when the sources don't contain the answer.**
3. Run the flow interactively with the authorised and unauthorised test users and confirm the answer, the citations, and the refusal behaviour match Step 5/6.

## Step 8 — Evaluate groundedness and relevance
1. Prepare a small **evaluation set** (questions with known good answers drawn from the pilot content).
2. Run the evaluation flow: `RAG Eval – Groundedness – NonProd` scores each answer for **groundedness** (supported by retrieved sources) and **relevance** (addresses the question). `AIRAG-Report.py` collects the scores.
3. Set your **pass thresholds** (e.g. groundedness ≥ your agreed bar) — these gate expansion. Investigate any low-groundedness answer (usually chunking too coarse, `top-k` too low, or a weak grounding prompt).

## Step 9 — Turn on monitoring
1. Confirm the flow and services log to **Application Insights / Azure Monitor**: query latency, tokens per call, retrieval hit counts, and errors.
2. Run `AIRAG-Report.py` to produce the baseline posture: index size, **ACL coverage** (chunks with a non-empty `group_ids`), retrieval mode, eval scores, and public-access state of both services.

## Step 10 — Expand to more content and production
1. Re-run `AIRAG-infra.bicep` targeting the **production** resource group (same template, prod parameters) — **what-if first** — to create the prod Search/OpenAI/identity/private endpoints.
2. Ingest the broader corpus in **batches**, each with a **dry-run ACL check first**; re-run the **permission-trimming negative test** after each new content domain is added (new content = new ACLs = re-prove trimming).
3. Re-validate with `AIRAG-Validate.py` and track index growth, ACL coverage, eval scores, and drift with `AIRAG-Report.py` on a schedule.

---
### Order of operations
`Assess → bicep what-if (gate) → deploy infra (non-prod) → create permission-trimmed index → ingest pilot (dry-run gate → load) → verify retrieval → PERMISSION-TRIMMING negative test (hard gate) → wire grounded flow → evaluate → monitor → expand to prod (what-if + re-test trimming per domain)`
