#!/usr/bin/env python3
"""
AIRAG-Ingest.py — build the permission-trimmed index, then chunk + embed + load private data.

PURPOSE
    The ingestion/embedding pipeline for the "Enterprise RAG Platform on Azure" solution.
    Two jobs:
      1. --create-index-only : create the Azure AI Search index `rag-index-nonprod` with
         the fields RAG needs — including the SECURITY field `group_ids`
         (Collection(Edm.String), filterable), a vector field `contentVector` tied to an
         HNSW/vector-search profile, and a semantic configuration for semantic ranking.
      2. (ingest) : for each source document, resolve the Entra group object IDs permitted
         to read it, chunk the text, embed each chunk with the `rag-embeddings` model, and
         load each chunk into the index with the parent document's `group_ids` STAMPED on
         it. No chunk is ever written without a non-empty ACL — this is what makes
         permission-trimming enforceable at query time.

    SAFETY: this script DEFAULTS TO --dry-run. In dry-run it reads, chunks, and resolves
    each document's `group_ids` and prints a per-document summary, but WRITES NOTHING to
    the index. Pass --commit to actually embed and load. Any document that resolves an
    EMPTY `group_ids` is flagged and SKIPPED (never defaulted to "everyone").

HOW TO RUN
    pip install azure-search-documents azure-identity openai azure-storage-blob
    # 1) create the index (safe; creates schema only)
    python AIRAG-Ingest.py --create-index-only \
        --search-endpoint https://srch-ragnonprod.search.windows.net \
        --index rag-index-nonprod
    # 2) dry-run the pilot content (writes nothing — inspect ACL resolution)
    python AIRAG-Ingest.py --source ./pilot-docs --index rag-index-nonprod \
        --search-endpoint https://srch-ragnonprod.search.windows.net \
        --openai-endpoint https://oai-ragnonprod.openai.azure.com
    # 3) commit (embed + load) once dry-run looks correct
    python AIRAG-Ingest.py --source ./pilot-docs --index rag-index-nonprod ... --commit

    Auth: DefaultAzureCredential (managed identity). Needs Search Index Data Contributor
    (to load) + Cognitive Services OpenAI User (to embed). Run from a host with a network
    path to the private endpoints.

EXPECTED RESULTS
    --create-index-only: an index with a filterable `group_ids`, a vector `contentVector`,
    metadata fields, and a semantic configuration.
    dry-run: a per-document report showing chunk counts and the resolved `group_ids`, with
    any empty-ACL documents flagged; nothing written.
    --commit: chunks embedded and loaded, each stamped with its parent document's ACL.

NOTES
    White-label. Change-gated: DRY-RUN by default, --commit required to write. Empty ACLs
    block ingestion, they are never defaulted open. Embedding model/dimensions must match
    the index vector field and the query-time embedding. The `resolve_group_ids` and
    `load_documents` bodies are the integration points you wire to YOUR source system and
    its permission model — data-classification is the compliance team's decision.
"""
from __future__ import annotations
import argparse
import sys
from dataclasses import dataclass, field

EMBEDDING_DEPLOYMENT = "rag-embeddings"   # RAG Embeddings - Model - NonProd
CHAT_DEPLOYMENT = "rag-chat"              # RAG Chat - Model - NonProd
VECTOR_DIMENSIONS = 3072                  # text-embedding-3-large; MUST match the model. Verify.
CHUNK_CHARS = 1200                        # ~ chunk size; tune for retrieval precision
CHUNK_OVERLAP = 200


@dataclass
class SourceDoc:
    doc_id: str
    title: str
    url: str
    text: str
    # The Entra group object IDs permitted to read this document (the ACL).
    group_ids: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Index schema — the security field `group_ids` is mandatory.
# ---------------------------------------------------------------------------
def create_index(search_endpoint: str, index_name: str) -> None:
    from azure.identity import DefaultAzureCredential
    from azure.search.documents.indexes import SearchIndexClient
    from azure.search.documents.indexes.models import (
        SearchIndex, SearchField, SearchFieldDataType, SimpleField, SearchableField,
        VectorSearch, HnswAlgorithmConfiguration, VectorSearchProfile,
        SemanticConfiguration, SemanticSearch, SemanticPrioritizedFields, SemanticField,
    )
    cred = DefaultAzureCredential()
    client = SearchIndexClient(endpoint=search_endpoint, credential=cred)

    fields = [
        SimpleField(name="id", type=SearchFieldDataType.String, key=True),
        SearchableField(name="content", type=SearchFieldDataType.String),
        SimpleField(name="title", type=SearchFieldDataType.String, filterable=True),
        SimpleField(name="url", type=SearchFieldDataType.String),
        SimpleField(name="lastModified", type=SearchFieldDataType.DateTimeOffset,
                    filterable=True, sortable=True),
        # ---- THE SECURITY FIELD: per-chunk ACL used for permission-trimming ----
        SimpleField(name="group_ids",
                    type=SearchFieldDataType.Collection(SearchFieldDataType.String),
                    filterable=True),
        # ---- vector field for hybrid/vector search ----
        SearchField(name="contentVector",
                    type=SearchFieldDataType.Collection(SearchFieldDataType.Single),
                    searchable=True, vector_search_dimensions=VECTOR_DIMENSIONS,
                    vector_search_profile_name="rag-vector-profile"),
    ]
    vector_search = VectorSearch(
        algorithms=[HnswAlgorithmConfiguration(name="rag-hnsw")],
        profiles=[VectorSearchProfile(name="rag-vector-profile",
                                      algorithm_configuration_name="rag-hnsw")],
    )
    semantic = SemanticSearch(configurations=[
        SemanticConfiguration(
            name="rag-semantic",
            prioritized_fields=SemanticPrioritizedFields(
                title_field=SemanticField(field_name="title"),
                content_fields=[SemanticField(field_name="content")]))
    ])
    index = SearchIndex(name=index_name, fields=fields,
                        vector_search=vector_search, semantic_search=semantic)
    client.create_or_update_index(index)
    print(f"[ok] index '{index_name}' created/updated with a filterable `group_ids` "
          f"security field, a vector field, and a semantic configuration.")


# ---------------------------------------------------------------------------
# INTEGRATION POINT: map YOUR source system's permissions to Entra group IDs.
# Return the group object IDs that are permitted to read this document. If you
# cannot resolve any, return [] — the caller will FLAG and SKIP it (never default open).
# ---------------------------------------------------------------------------
def resolve_group_ids(raw_doc) -> list[str]:
    # Example: SharePoint library group -> Entra group object IDs (via Graph), or a
    # metadata column on the source. Replace with your real permission lookup.
    return list(getattr(raw_doc, "permitted_group_ids", []) or [])


def read_source(path: str) -> list[SourceDoc]:
    """INTEGRATION POINT: enumerate source documents from `path`/your connector.
    Here we return an empty list; wire this to your file share / SharePoint / blob."""
    print(f"[info] read_source('{path}') — wire this to your source connector.")
    return []


def chunk_text(text: str, size: int = CHUNK_CHARS, overlap: int = CHUNK_OVERLAP):
    step = max(1, size - overlap)
    return [text[i:i + size] for i in range(0, len(text), step) if text[i:i + size].strip()]


def embed(openai_endpoint: str, texts: list[str]) -> list[list[float]]:
    from azure.identity import DefaultAzureCredential, get_bearer_token_provider
    from openai import AzureOpenAI
    token_provider = get_bearer_token_provider(
        DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default")
    client = AzureOpenAI(azure_endpoint=openai_endpoint, azure_ad_token_provider=token_provider,
                         api_version="2024-06-01")  # verify current api-version
    resp = client.embeddings.create(model=EMBEDDING_DEPLOYMENT, input=texts)
    return [d.embedding for d in resp.data]


def load_documents(search_endpoint: str, index_name: str, docs: list[dict]) -> None:
    from azure.identity import DefaultAzureCredential
    from azure.search.documents import SearchClient
    client = SearchClient(endpoint=search_endpoint, index_name=index_name,
                          credential=DefaultAzureCredential())
    result = client.upload_documents(documents=docs)
    ok = sum(1 for r in result if r.succeeded)
    print(f"[ok] uploaded {ok}/{len(docs)} chunks.")


def ingest(args) -> int:
    raw_docs = read_source(args.source)
    source_docs: list[SourceDoc] = []
    for rd in raw_docs:
        gids = resolve_group_ids(rd)
        source_docs.append(SourceDoc(doc_id=getattr(rd, "id", ""), title=getattr(rd, "title", ""),
                                     url=getattr(rd, "url", ""), text=getattr(rd, "text", ""),
                                     group_ids=gids))

    print("\n-- Ingestion plan (per document) --")
    to_write: list[dict] = []
    skipped = 0
    for d in source_docs:
        chunks = chunk_text(d.text)
        if not d.group_ids:
            skipped += 1
            print(f"   [SKIP - EMPTY ACL] {d.title!r} — no resolvable group_ids; will NOT "
                  "be indexed (assign a documented group and re-ingest).")
            continue
        print(f"   [OK] {d.title!r}: {len(chunks)} chunks, group_ids={d.group_ids}")
        if args.commit:
            vectors = embed(args.openai_endpoint, chunks) if chunks else []
            for i, (c, v) in enumerate(zip(chunks, vectors)):
                to_write.append({
                    "id": f"{d.doc_id}-{i}",
                    "content": c,
                    "title": d.title,
                    "url": d.url,
                    "group_ids": d.group_ids,     # <-- ACL stamped on EVERY chunk
                    "contentVector": v,
                })

    print(f"\nDocuments: {len(source_docs)} | to index: {len(source_docs) - skipped} "
          f"| skipped (empty ACL): {skipped}")
    if not args.commit:
        print("\nDRY-RUN — nothing written. Re-run with --commit once the ACL resolution "
              "above is correct. (Empty-ACL documents are always skipped.)")
        return 0
    if to_write:
        load_documents(args.search_endpoint, args.index, to_write)
    print("Ingestion complete. Next: run AIRAG-Validate.py --permission-trimming-test.")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description="Create the permission-trimmed index and ingest data.")
    p.add_argument("--search-endpoint", help="https://<search>.search.windows.net")
    p.add_argument("--index", default="rag-index-nonprod")
    p.add_argument("--openai-endpoint", help="https://<openai>.openai.azure.com")
    p.add_argument("--source", help="Path/identifier for the source content to ingest")
    p.add_argument("--create-index-only", action="store_true",
                   help="Create/update the index schema and exit (safe).")
    p.add_argument("--commit", action="store_true",
                   help="Actually embed + load. WITHOUT this flag the script is a DRY-RUN.")
    args = p.parse_args()

    print("=== Enterprise RAG on Azure — ingestion pipeline ===")
    if args.create_index_only:
        if not args.search_endpoint:
            print("[error] --search-endpoint is required to create the index.")
            return 2
        create_index(args.search_endpoint, args.index)
        return 0

    if not (args.search_endpoint and args.openai_endpoint and args.source):
        print("[error] ingestion needs --search-endpoint, --openai-endpoint and --source.")
        return 2
    if not args.commit:
        print("[mode] DRY-RUN (default) — no index writes. Pass --commit to load.")
    return ingest(args)


if __name__ == "__main__":
    sys.exit(main())
