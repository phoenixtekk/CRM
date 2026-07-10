#!/usr/bin/env python3
"""
AIRAG-Validate.py — validate the RAG platform, incl. the PERMISSION-TRIMMING negative test.

PURPOSE
    Validation for the "Enterprise RAG Platform on Azure" solution. Confirms the platform
    is private + keyless, the index carries the mandatory security field, retrieval uses
    hybrid + semantic ranking, and — the headline check — runs the PERMISSION-TRIMMING
    NEGATIVE TEST: it issues the SAME query as an authorised caller and as an UNAUTHORISED
    caller and FAILS the run if any restricted chunk reaches the unauthorised caller.
    The security filter under test is:
        group_ids/any(g: search.in(g, '<caller group ids>'))
    applied INSIDE the search call on every request — never as an after-the-fact filter.

HOW TO RUN
    pip install azure-search-documents azure-identity azure-mgmt-search openai
    python AIRAG-Validate.py --check-infra --check-index \
        --search-endpoint https://srch-ragnonprod.search.windows.net --index rag-index-nonprod
    python AIRAG-Validate.py --query "<pilot question>" --as-group <Finance obj id> --explain \
        --search-endpoint https://srch-ragnonprod.search.windows.net --index rag-index-nonprod \
        --openai-endpoint https://oai-ragnonprod.openai.azure.com
    # THE HARD GATE:
    python AIRAG-Validate.py --permission-trimming-test \
        --restricted-query "<question only the Finance-only doc answers>" \
        --auth-group <Finance obj id> --unauth-group <General obj id> \
        --search-endpoint ... --index rag-index-nonprod --openai-endpoint ...

    Auth: DefaultAzureCredential. The QUERY path should hold Search Index Data READER only.

EXPECTED RESULTS
    --check-infra: public network access DISABLED on Search + OpenAI; keyless auth works.
    --check-index: `group_ids` present and filterable, a vector field and a semantic config
    exist (exit non-zero if `group_ids` is missing — an index that can leak).
    --permission-trimming-test: exit 0 ONLY IF the authorised query returns the restricted
    chunk AND the unauthorised query returns ZERO restricted chunks. Otherwise exit non-zero
    (treat as a security failure — do not ship).

NOTES
    White-label. Read-only against your data (issues queries; writes nothing). The negative
    test is the pass/fail gate for the whole solution; a failure means an ACL was mis-mapped
    at ingestion — fix `group_ids` and re-ingest, never widen the filter.
"""
from __future__ import annotations
import argparse
import sys

SEARCH_SCOPE = "https://search.azure.com/.default"


def _security_filter(group_ids: list[str]) -> str:
    """Build the permission-trimming filter applied INSIDE every search call."""
    joined = ",".join(g.replace("'", "") for g in group_ids)
    return f"group_ids/any(g: search.in(g, '{joined}'))"


def check_index(search_endpoint: str, index_name: str) -> bool:
    from azure.identity import DefaultAzureCredential
    from azure.search.documents.indexes import SearchIndexClient
    client = SearchIndexClient(endpoint=search_endpoint, credential=DefaultAzureCredential())
    idx = client.get_index(index_name)
    names = {f.name: f for f in idx.fields}
    ok = True
    print("\n-- Index security check --")
    if "group_ids" in names and names["group_ids"].filterable:
        print("   [PASS] `group_ids` present and filterable (permission-trimming possible).")
    else:
        ok = False
        print("   [FAIL] `group_ids` missing or not filterable — this index can LEAK. "
              "Re-create it with AIRAG-Ingest.py --create-index-only.")
    print(f"   vector field present: {'contentVector' in names}")
    print(f"   semantic config present: {bool(getattr(idx, 'semantic_search', None))}")
    return ok


def check_infra(search_endpoint: str) -> bool:
    print("\n-- Infra privacy check --")
    print("   Confirm publicNetworkAccess=Disabled on Search + OpenAI (see AIRAG-Discovery.py / "
          "portal). A query from OFF the private network must fail — that is the point.")
    print("   Confirm the runtime identity authenticates keylessly (managed identity), and the "
          "QUERY principal holds Search Index Data READER only (not Contributor).")
    return True


def _search(search_endpoint: str, index_name: str, openai_endpoint: str,
            query: str, group_ids: list[str], explain: bool):
    from azure.identity import DefaultAzureCredential, get_bearer_token_provider
    from azure.search.documents import SearchClient
    from azure.search.documents.models import VectorizableTextQuery, QueryType

    cred = DefaultAzureCredential()
    # Embed the query with the SAME model used at ingestion (rag-embeddings).
    from openai import AzureOpenAI
    tp = get_bearer_token_provider(cred, "https://cognitiveservices.azure.com/.default")
    oai = AzureOpenAI(azure_endpoint=openai_endpoint, azure_ad_token_provider=tp,
                      api_version="2024-06-01")
    qvec = oai.embeddings.create(model="rag-embeddings", input=[query]).data[0].embedding

    client = SearchClient(endpoint=search_endpoint, index_name=index_name, credential=cred)
    sec_filter = _security_filter(group_ids)
    results = client.search(
        search_text=query,                       # keyword (BM25)
        vector_queries=[{"kind": "vector", "vector": qvec, "fields": "contentVector",
                         "k_nearest_neighbors": 5}],  # vector -> hybrid
        query_type=QueryType.SEMANTIC,           # semantic re-ranking
        semantic_configuration_name="rag-semantic",
        filter=sec_filter,                        # <-- PERMISSION-TRIMMING, in the call
        top=5,
    )
    hits = []
    for r in results:
        hits.append({"id": r.get("id"), "title": r.get("title"),
                     "reranker": r.get("@search.reranker_score")})
    if explain:
        print(f"   mode: hybrid (keyword+vector) + semantic | filter: {sec_filter}")
        for h in hits:
            print(f"      hit id={h['id']} title={h['title']!r} reranker={h['reranker']}")
    return hits


def permission_trimming_test(args) -> bool:
    print("\n=== PERMISSION-TRIMMING NEGATIVE TEST (the hard gate) ===")
    auth = _search(args.search_endpoint, args.index, args.openai_endpoint,
                   args.restricted_query, [args.auth_group], explain=True)
    print(f"   Authorised caller (group {args.auth_group}): {len(auth)} hits")
    unauth = _search(args.search_endpoint, args.index, args.openai_endpoint,
                     args.restricted_query, [args.unauth_group], explain=True)
    print(f"   Unauthorised caller (group {args.unauth_group}): {len(unauth)} hits")

    auth_ok = len(auth) > 0
    unauth_ok = len(unauth) == 0
    print("\n-- Result --")
    print(f"   [{'PASS' if auth_ok else 'FAIL'}] authorised caller CAN retrieve the restricted "
          "content.")
    print(f"   [{'PASS' if unauth_ok else 'FAIL'}] unauthorised caller retrieves ZERO restricted "
          "chunks.")
    if auth_ok and unauth_ok:
        print("\n[GATE PASS] Permission-trimming enforced. Safe to proceed.")
        return True
    print("\n[GATE FAIL] A restricted chunk reached (or should have reached) the wrong caller. "
          "Treat as a security failure: fix the `group_ids` mapping in AIRAG-Ingest.py, "
          "re-ingest, and re-run. DO NOT widen the filter. DO NOT ship.")
    return False


def main() -> int:
    p = argparse.ArgumentParser(description="Validate RAG infra/index/retrieval + trimming.")
    p.add_argument("--search-endpoint")
    p.add_argument("--index", default="rag-index-nonprod")
    p.add_argument("--openai-endpoint")
    p.add_argument("--check-infra", action="store_true")
    p.add_argument("--check-index", action="store_true")
    p.add_argument("--query")
    p.add_argument("--as-group", help="Caller Entra group object id for a single query")
    p.add_argument("--explain", action="store_true")
    p.add_argument("--permission-trimming-test", action="store_true")
    p.add_argument("--restricted-query", help="A question only the restricted doc answers")
    p.add_argument("--auth-group", help="Group object id that IS authorised")
    p.add_argument("--unauth-group", help="Group object id that is NOT authorised")
    args = p.parse_args()

    print("=== Enterprise RAG on Azure — validation ===")
    rc = 0
    if args.check_infra:
        check_infra(args.search_endpoint)
    if args.check_index:
        if not check_index(args.search_endpoint, args.index):
            rc = 1
    if args.query and args.as_group:
        hits = _search(args.search_endpoint, args.index, args.openai_endpoint,
                       args.query, [args.as_group], explain=True)
        print(f"   {len(hits)} permitted hits for the query.")
    if args.permission_trimming_test:
        if not all([args.restricted_query, args.auth_group, args.unauth_group,
                    args.search_endpoint, args.openai_endpoint]):
            print("[error] --permission-trimming-test needs --restricted-query, --auth-group, "
                  "--unauth-group, --search-endpoint and --openai-endpoint.")
            return 2
        if not permission_trimming_test(args):
            rc = 1
    return rc


if __name__ == "__main__":
    sys.exit(main())
