# 2. Requirements Guide — Enterprise RAG Platform on Azure (AI Search + Private Data)

Verify **every** requirement before deploying. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites — the Azure subscription and AI-service access, Entra + managed identity + RBAC, private networking, IaC + Python tooling, CI/CD, data source + classification, content-safety posture, and cost controls — are in `global-requirements-ai.md` (G1–G8) and are **not** repeated here. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim.

## 2.1 Azure AI Search service at a tier that supports semantic ranking + vector
**Description:** An **Azure AI Search** service (`RAG Search – Platform – NonProd`) on a tier that supports **vector search** and **semantic ranking** — Basic or higher; semantic ranking is a billable add-on you enable on the service.
**Why:** The whole retrieval layer (hybrid keyword+vector, semantic re-ranking, and the `group_ids` security filter) runs in this service; the free tier and older configurations do not support the full feature set.
**Verify:** `portal.azure.com` → **Azure AI Search** → the service's **Semantic ranker** setting and tier; `AIRAG-Discovery.py` reports the service, tier, and semantic status.
**Implement-if-missing:** Create the service (deployed by `AIRAG-infra.bicep`), pick a supported tier, and enable **Semantic ranker**. *Verify current tier requirements, availability, and pricing for vector + semantic ranking in your region.*

## 2.2 Azure OpenAI resource with an embedding deployment and a chat deployment
**Description:** An **Azure OpenAI** resource (`RAG OpenAI – Platform – NonProd`) with two model deployments: an **embedding** model deployment `rag-embeddings` (e.g. `text-embedding-3-large`) and a **chat** model deployment `rag-chat` (e.g. `gpt-4o`).
**Why:** Embeddings turn each chunk and each query into vectors for vector search; the chat model generates the grounded, cited answer. The embedding model used at **ingestion** must match the one used at **query** (same model + dimensions).
**Verify:** `portal.azure.com` → **Azure OpenAI** → **Model deployments** show both deployments; `AIRAG-Discovery.py` lists the resource and deployments.
**Implement-if-missing:** Request Azure OpenAI access if gated; create both deployments (Bicep provisions the resource; you confirm model availability). *Verify current model names, versions, dimensions, regions, and TPM quota in your subscription — models are versioned and retired on a schedule.*

## 2.3 A source data set with a known, resolvable permission (ACL) model
**Description:** The private content to ground on (e.g. SharePoint/OneDrive documents, a file share, a database export) **plus** a way to determine, per document, the **Entra group object IDs** that are permitted to read it.
**Why:** Permission-trimming is only correct if each chunk is stamped with the *right* ACL. You must be able to map every source document to the group IDs that can read it; a missing or wrong ACL is a leak the search filter cannot catch.
**Verify:** For a sample of documents you can state which Entra groups may read them; `AIRAG-Discovery.py` reports whether the sample source exposes a resolvable permission set.
**Implement-if-missing:** Define the mapping from source permissions to `group_ids` (e.g. SharePoint site/library groups → Entra groups). Where a source has no usable ACL, decide a default group and **document it**. *Data-classification and "who should see what" determinations are the compliance team's decision (see `global-requirements-ai.md` G6).*

## 2.4 Entra groups for the pilot content and test users
**Description:** At least **two** Entra security groups representing distinct audiences for the pilot — e.g. `RAG Readers – Finance – Pilot` and `RAG Readers – General – Pilot` — and **two test users**: one who is a member of the restricted group and one who is **not**.
**Why:** The permission-trimming **negative test** requires a user who *should* be denied restricted content. Without a genuinely-unauthorised test user you cannot prove trimming works.
**Verify:** `entra.microsoft.com` → **Groups** → both groups exist with the expected members; capture each **Object ID**. `AIRAG-Discovery.py` echoes the IDs you supply.
**Implement-if-missing:** Create the two groups, add the restricted content's readers to one, and keep the second test user out of it. Record both **object IDs** for ingestion and testing.

## 2.5 Managed identity with least-privilege data-plane roles
**Description:** A **user-assigned managed identity** (`RAG Identity – Platform – NonProd`) granted **Search Index Data Contributor** (to load), **Search Index Data Reader** (to query), and **Cognitive Services OpenAI User** (to embed + chat).
**Why:** Keys leak; the pipeline and orchestration authenticate keylessly via managed identity + RBAC, least-privilege (see `global-requirements-ai.md` G2). Loading and querying are deliberately separate roles.
**Verify:** The identity exists and holds exactly those roles at the Search service and OpenAI resource scope; `AIRAG-Validate.py` confirms it can query but the *query* principal cannot write.
**Implement-if-missing:** Bicep creates the identity; assign the three data-plane roles at the narrowest scope. Do **not** grant Owner/Contributor to the runtime identity.

## 2.6 Python 3.x with the RAG SDK toolchain
**Description:** Python 3.10+ with `azure-search-documents`, `openai` (Azure OpenAI), `azure-identity`, `azure-storage-blob`, and `promptflow` installed in a virtual environment.
**Why:** Ingestion, embedding, querying, permission-trimming validation, and the evaluation flow are delivered as Python using these SDKs (see `global-requirements-ai.md` G4).
**Verify:** `python --version` ≥ 3.10 and `pip show azure-search-documents openai promptflow` resolve; `AIRAG-Validate.py` checks module presence.
**Implement-if-missing:** `python -m venv .venv` then `pip install azure-search-documents openai azure-identity azure-storage-blob promptflow`. *Verify current SDK versions — the Azure AI SDKs move fast; pin them.*

## 2.7 Private networking for the AI services
**Description:** A VNet with the ability to create **private endpoints** and **private DNS** for Azure AI Search and Azure OpenAI, so **public network access can be disabled** on both.
**Why:** Public endpoints are a data-exfiltration surface; enterprise RAG on private data is private-by-default (see `global-requirements-ai.md` G3). The pipeline runs from a host with a network path to the private endpoints.
**Verify:** The VNet/subnets and Private DNS zones exist or can be created; after deploy, `publicNetworkAccess` is **Disabled** on both services; `AIRAG-Validate.py` reports public-access state.
**Implement-if-missing:** Provision the VNet/subnets/Private DNS and the private endpoints (Bicep parameters), and run the pipeline from a host on that network (peering / VPN / jumpbox). See the AI landing-zone solution for the full pattern.

## 2.8 Cost controls, quotas, and a non-prod environment with rollback
**Description:** A **budget + alerts**, an **Azure OpenAI TPM quota** sized for ingestion (embedding a large corpus is token-heavy), a named **non-production** resource group to prove the platform first, and a documented rollback.
**Why:** Embedding a whole corpus and running eval loops consume tokens and search units; unmanaged usage causes bill shock (see `global-requirements-ai.md` G8). Index writes and infra changes must be proven in non-prod with a back-out.
**Verify:** A budget/alert exists, TPM quota is set for `rag-embeddings`, the non-prod resource group name is fixed, and a written rollback exists.
**Implement-if-missing:** Set the budget, request/confirm TPM quota, define `rg-rag-platform-nonprod` (`RAG RG – Platform – NonProd`), and write the rollback (delete the non-prod resource group / drop-and-rebuild the index). *Spend limits are the customer's business decision.*

---
## Checklist
- [ ] Azure AI Search service (tier + **Semantic ranker** enabled) — `AIRAG-Discovery.py`
- [ ] Azure OpenAI resource + `rag-embeddings` + `rag-chat` deployments
- [ ] Source data with a resolvable per-document Entra-group ACL model
- [ ] Two pilot Entra groups + an authorised **and** an unauthorised test user (object IDs captured)
- [ ] User-assigned managed identity with Search Data Contributor/Reader + OpenAI User (least privilege)
- [ ] Python 3.10+ with azure-search-documents / openai / azure-identity / promptflow — `AIRAG-Validate.py`
- [ ] VNet + private endpoints + Private DNS; public network access disabled on both services
- [ ] Budget/alerts, embedding TPM quota, non-prod resource group, and rollback documented
