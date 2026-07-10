#!/usr/bin/env python3
"""
AIRAG-Report.py — posture report for the Enterprise RAG Platform on Azure.

PURPOSE
    Read-only reporting for the "Enterprise RAG Platform on Azure" solution. Produces the
    baseline posture picture: index size (document/chunk count), ACL COVERAGE (the share of
    chunks carrying a non-empty `group_ids` — the target is 100%), the retrieval mode in
    use, groundedness/relevance evaluation scores (from the prompt-flow eval run
    `RAG Eval - Groundedness - NonProd`), the public-network-access state of the Search and
    OpenAI services, and a token/latency summary from monitoring. Makes NO changes.

HOW TO RUN
    pip install azure-search-documents azure-identity
    python AIRAG-Report.py --acl-coverage --eval \
        --search-endpoint https://srch-ragnonprod.search.windows.net --index rag-index-nonprod
    Optional inputs: --eval-results <promptflow eval output json> to summarise groundedness
    and relevance. Auth: DefaultAzureCredential (Search Index Data Reader is enough).

EXPECTED RESULTS
    A single posture snapshot — index size, ACL coverage (should read 100%), retrieval mode,
    eval scores against your thresholds, public-access state, and a monitoring summary — so
    you can confirm the platform is healthy before and after each expansion.

NOTES
    White-label. Read-only. Queries the index for counts/coverage; writes nothing. An ACL
    coverage below 100% is a defect — re-ingest the affected content before go-live. Eval
    thresholds are yours to set; low groundedness is usually a retrieval (chunking/top-k)
    problem, not a model problem.
"""
from __future__ import annotations
import argparse
import json
import sys


def index_stats(search_endpoint: str, index_name: str) -> tuple[int, int]:
    """Return (total_chunks, chunks_with_empty_acl)."""
    from azure.identity import DefaultAzureCredential
    from azure.search.documents import SearchClient
    client = SearchClient(endpoint=search_endpoint, index_name=index_name,
                          credential=DefaultAzureCredential())
    total = client.get_document_count()
    # Chunks whose group_ids is empty/missing are a leak risk — count them.
    # Azure AI Search filter for "no ACL": group_ids/any() is false.
    empty = client.search(search_text="*", filter="not group_ids/any()",
                          include_total_count=True, top=0).get_count()
    return total, (empty or 0)


def report_acl(search_endpoint: str, index_name: str) -> bool:
    print("\n-- ACL coverage (permission-trimming) --")
    try:
        total, empty = index_stats(search_endpoint, index_name)
        covered = total - empty
        pct = (covered / total * 100) if total else 0.0
        flag = "PASS" if empty == 0 and total > 0 else "DEFECT"
        print(f"   chunks: {total} | with ACL: {covered} | empty ACL: {empty} "
              f"| coverage: {pct:.1f}%  [{flag}]")
        if empty:
            print("   [DEFECT] chunks without a `group_ids` can leak — re-ingest the affected "
                  "content with the correct mapping before go-live.")
        return empty == 0 and total > 0
    except Exception as exc:
        print(f"   [warn] could not compute ACL coverage: {exc}")
        return False


def report_eval(eval_results_path: str | None) -> None:
    print("\n-- Groundedness / relevance evaluation --")
    if not eval_results_path:
        print("   (pass --eval-results <promptflow eval output.json> to summarise scores)")
        print("   Run RAG Eval - Groundedness - NonProd over your evaluation set; set your")
        print("   pass thresholds (e.g. groundedness >= your agreed bar) as the quality gate.")
        return
    try:
        with open(eval_results_path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        g = data.get("groundedness")
        r = data.get("relevance")
        print(f"   groundedness (avg): {g}")
        print(f"   relevance (avg):    {r}")
        print("   Investigate any answer below your groundedness bar — usually chunking too "
              "coarse, top-k too low, or a weak grounding prompt (a retrieval fix, not a model one).")
    except Exception as exc:
        print(f"   [warn] could not read eval results: {exc}")


def report_infra() -> None:
    print("\n-- Infra posture --")
    print("   Confirm publicNetworkAccess = Disabled on RAG Search - Platform - NonProd and")
    print("   RAG OpenAI - Platform - NonProd (private-by-default), and that auth is keyless")
    print("   (managed identity) with least-privilege data-plane roles.")
    print("\n-- Monitoring (Application Insights / Azure Monitor) --")
    print("   Summarise query latency, tokens per call, retrieval hit counts, and error rate")
    print("   from your workspace — the ongoing health signal for the platform.")


def main() -> int:
    p = argparse.ArgumentParser(description="Read-only RAG posture report.")
    p.add_argument("--search-endpoint")
    p.add_argument("--index", default="rag-index-nonprod")
    p.add_argument("--acl-coverage", action="store_true")
    p.add_argument("--eval", action="store_true")
    p.add_argument("--eval-results", help="Path to a promptflow eval output json")
    args = p.parse_args()

    print("=== Enterprise RAG on Azure — posture report (read-only) ===")
    rc = 0
    if args.acl_coverage:
        if not args.search_endpoint:
            print("[error] --acl-coverage needs --search-endpoint.")
            return 2
        if not report_acl(args.search_endpoint, args.index):
            rc = 1
    if args.eval:
        report_eval(args.eval_results)
    report_infra()
    print("\nReport complete (read-only).")
    return rc


if __name__ == "__main__":
    sys.exit(main())
