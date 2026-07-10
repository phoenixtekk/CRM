# 5. Testing Guide — Enterprise RAG Platform on Azure (AI Search + Private Data)

Run after the pilot ingest (Implementation Step 6), again after wiring the flow (Step 7–8), and after each expansion (Step 10). Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names, and the scripts are `AIRAG-Discovery.py`, `AIRAG-Ingest.py`, `AIRAG-Validate.py`, `AIRAG-Report.py`. **Test 4 is the headline gate — the platform does not ship until the permission-trimming negative test passes.**

## Test 1 — Infra is private and keyless
**Do:** `AIRAG-Validate.py --check-infra`.
**Expected:** `publicNetworkAccess` is **Disabled** on both `RAG Search – Platform – NonProd` and `RAG OpenAI – Platform – NonProd`; the runtime **managed identity** (not a key) authenticates; a query from *off* the private network fails (this is the point).

## Test 2 — The index has the security field
**Do:** `AIRAG-Validate.py --check-index`.
**Expected:** `rag-index-nonprod` exists with `content`, `contentVector` (vector profile + HNSW, dimensions matching `rag-embeddings`), the metadata fields, a **semantic configuration**, and the **`group_ids`** field present and **filterable**. If `group_ids` is missing, the check **fails** — an index without it can leak.

## Test 3 — Every chunk carries an ACL
**Do:** `AIRAG-Report.py --acl-coverage`.
**Expected:** **100% ACL coverage** — every document/chunk in the index has a **non-empty** `group_ids`. Any chunk with an empty `group_ids` is reported as a defect to fix (re-ingest with the correct mapping) before go-live.

## Test 4 — PERMISSION-TRIMMING negative test (the hard gate)
**Do:** `AIRAG-Validate.py --permission-trimming-test` — it runs the **same** question twice: once as a member of `RAG Readers – Finance – Pilot` (authorised for the restricted document) and once as `RAG Readers – General – Pilot` (**not** authorised).
**Expected:**
- **Authorised query:** returns the restricted document's chunks and a grounded, cited answer.
- **Unauthorised query:** returns **zero** restricted chunks; the grounded flow answers **"I don't have a source for that."**
The script **fails the run** if the unauthorised query returns any restricted chunk. **This is the pass/fail gate for the whole solution.**

## Test 5 — Hybrid + semantic ranking are actually applied
**Do:** `AIRAG-Validate.py --query "<pilot question>" --as-group <Finance object id> --explain`.
**Expected:** The output shows the search executed **hybrid** (keyword + vector) with **semantic ranking** on, and lists a **semantic reranker score** per result — not a plain keyword search.

## Test 6 — Grounded answer with citations
**Do:** Ask a question the pilot content answers, through `RAG Flow – Orchestration – NonProd`.
**Expected:** The answer is drawn from the retrieved chunks and includes **citations** back to the specific source documents; the cited passages actually support the answer.

## Test 7 — Refusal when unsupported
**Do:** Ask a question the pilot content does **not** answer.
**Expected:** The flow answers **"I don't have a source for that"** (or equivalent) rather than inventing content — grounding + refusal behaviour is working.

## Test 8 — Groundedness / relevance evaluation
**Do:** Run `RAG Eval – Groundedness – NonProd` over the evaluation set; collect with `AIRAG-Report.py --eval`.
**Expected:** Groundedness and relevance scores meet your agreed thresholds; any answer below the groundedness bar is flagged for investigation (chunking, `top-k`, or grounding prompt).

## Test 9 — Posture report
**Do:** Run `AIRAG-Report.py`.
**Expected:** A clear baseline — index size, **ACL coverage (should be 100%)**, retrieval mode, eval scores, public-access state of both services, and token/latency summary from monitoring.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Non-prod pass** | Tests 1–3, 5–7 pass; ACL coverage is 100% |
| **Security gate (hard)** | **Test 4 passes** — the unauthorised user is denied restricted content and no restricted chunk is returned |
| **Quality gate** | Test 8 meets your groundedness/relevance thresholds |
| **Expand pass** | Tests 1–4, 9 pass, and **Test 4 is re-run and passes for each new content domain** before it carries real users |
