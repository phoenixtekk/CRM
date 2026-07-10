# 8. Deliverables Summary — Enterprise RAG Platform on Azure (AI Search + Private Data)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box — grounded, cited answers that honor source permissions |
| 1. Solution Overview | What the RAG platform is — chunking/embedding, hybrid + semantic + vector search, permission-trimming, grounded orchestration, evaluation; benefits, limitations |
| 2. Requirements Guide | Every solution-specific prerequisite with Verify / Implement-if-missing |
| Global Requirements (AI) | Category-wide prerequisites (G1–G8), published once |
| 3. Implementation Guide | Exact, ordered steps — Bicep what-if → deploy infra → build permission-trimmed index → ingest (dry-run) → wire grounded flow → negative test → evaluate → expand |
| 5. Testing Guide | Validation procedures with pass/fail gates — including the permission-trimming negative test |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## Automation & scripts
| File | What it does |
|---|---|
| `AIRAG-Discovery.py` | Read-only Python discovery — subscription context, existing Search/OpenAI resources, the pilot Entra group object IDs, and whether the sample source exposes a resolvable permission set; a readiness picture before you deploy. Makes no changes |
| `AIRAG-infra.bicep` | Bicep for the platform — Azure AI Search (with Semantic ranker), Azure OpenAI + `rag-embeddings` and `rag-chat` deployments, source storage, a user-assigned managed identity, and private endpoints with public access disabled. **Deploy what-if first** (`az deployment group what-if` before `create`) |
| `AIRAG-Ingest.py` | The ingestion/embedding pipeline — creates the permission-trimmed index (`--create-index-only`), then chunks each source document, resolves its Entra-group ACL, embeds each chunk with `rag-embeddings`, and loads it with `group_ids` stamped on. **Defaults to `--dry-run`** (reads/chunks/resolves ACLs and reports, writes nothing) until you confirm |
| `AIRAG-Validate.py` | Validation — checks private/keyless infra, the index security field, hybrid+semantic retrieval, and runs the **`--permission-trimming-test`** (authorised vs unauthorised query) that **fails if any restricted chunk reaches an unauthorised caller** |
| `AIRAG-Report.py` | Posture report — index size, **ACL coverage (target 100%)**, retrieval mode, groundedness/relevance eval scores, public-access state, and token/latency summary from monitoring |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- The **Bicep** template and four **Python** scripts (`azure-search-documents`, `openai`, `promptflow`) in a single ZIP — delivered as a **Complete Solution Package (PDF + Word + scripts)**.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand** — with a what-if gate before infra apply, a dry-run gate before index writes, and the permission-trimming negative test as a hard gate before expansion.

## Outcome
AI that answers from your private data, shows its sources, and never returns content a user isn't allowed to see — deployed private-by-default, proven in non-production (including the permission-trimming negative test) before it carries real content or real users, and reusable on every content set you onboard.
