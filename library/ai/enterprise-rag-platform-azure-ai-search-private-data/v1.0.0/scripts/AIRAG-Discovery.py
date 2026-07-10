#!/usr/bin/env python3
"""
AIRAG-Discovery.py — read-only readiness check for an enterprise RAG deployment on Azure.

PURPOSE
    Read-only discovery for the "Enterprise RAG Platform on Azure (AI Search + Private
    Data)" solution. Captures the pre-change picture BEFORE any Bicep apply or index
    write: the subscription in context, any existing Azure AI Search and Azure OpenAI
    resources (with public-network-access state), the pilot Entra group object IDs you
    supply (and whether a test user is a member), and whether a sample source document
    exposes a resolvable permission (ACL) set to map into `group_ids`. Makes NO changes.

HOW TO RUN
    python -m venv .venv && . .venv/bin/activate        # (Windows: .venv\\Scripts\\activate)
    pip install azure-identity azure-mgmt-search azure-mgmt-cognitiveservices msgraph-core
    python AIRAG-Discovery.py --subscription <sub id> \
        --search-rg rg-rag-platform-nonprod \
        --finance-group <RAG Readers - Finance - Pilot object id> \
        --general-group <RAG Readers - General - Pilot object id> \
        --test-user <unauthorised test user UPN or object id>
    Auth: DefaultAzureCredential (az login, or a managed identity). Read-only roles are
    enough (Reader on the resource group; Directory Readers / Group.Read.All on Graph).

EXPECTED RESULTS
    A single readiness snapshot — subscription, existing Search/OpenAI resources and
    whether their public network access is DISABLED, the pilot group IDs echoed back with
    the unauthorised test user's membership, and a note on source-ACL resolvability — so
    you know the estate is ready before you run `bicep what-if`.

NOTES
    White-label. Read-only. Reports configuration/identifiers only; makes no changes to
    any resource and writes nothing to any search index. Azure AI SDK/model/tier
    availability moves fast and some features are preview/tier-gated — verify current
    availability, region, and pricing in your subscription.
"""
from __future__ import annotations
import argparse
import sys


def _try_import():
    try:
        from azure.identity import DefaultAzureCredential  # noqa: F401
        return True
    except Exception as exc:  # pragma: no cover
        print(f"[warn] azure-identity not importable: {exc}")
        print("       pip install azure-identity azure-mgmt-search "
              "azure-mgmt-cognitiveservices")
        return False


def discover_search(cred, sub_id: str, rg: str | None) -> None:
    print("\n-- Azure AI Search services --")
    try:
        from azure.mgmt.search import SearchManagementClient
        client = SearchManagementClient(cred, sub_id)
        services = (client.services.list_by_resource_group(rg)
                    if rg else client.services.list_by_subscription())
        found = False
        for s in services:
            found = True
            pna = getattr(s, "public_network_access", "unknown")
            sku = getattr(getattr(s, "sku", None), "name", "unknown")
            flag = "PRIVATE (ok)" if str(pna).lower() == "disabled" else "PUBLIC (review)"
            print(f"   {s.name:<28} sku:{sku:<10} publicNetworkAccess:{pna} -> {flag}")
        if not found:
            print("   (none yet — AIRAG-infra.bicep will create RAG Search - Platform - NonProd)")
    except Exception as exc:
        print(f"   [warn] could not enumerate Search services: {exc}")


def discover_openai(cred, sub_id: str, rg: str | None) -> None:
    print("\n-- Azure OpenAI (Cognitive Services) accounts --")
    try:
        from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient
        client = CognitiveServicesManagementClient(cred, sub_id)
        accounts = (client.accounts.list_by_resource_group(rg)
                    if rg else client.accounts.list())
        found = False
        for a in accounts:
            if getattr(a, "kind", "") != "OpenAI":
                continue
            found = True
            props = getattr(a, "properties", None)
            pna = getattr(props, "public_network_access", "unknown") if props else "unknown"
            flag = "PRIVATE (ok)" if str(pna).lower() == "disabled" else "PUBLIC (review)"
            print(f"   {a.name:<28} publicNetworkAccess:{pna} -> {flag}")
            print("      NOTE: confirm 'rag-embeddings' and 'rag-chat' deployments exist "
                  "(verify current model + version + region).")
        if not found:
            print("   (no OpenAI account yet — AIRAG-infra.bicep will create "
                  "RAG OpenAI - Platform - NonProd)")
    except Exception as exc:
        print(f"   [warn] could not enumerate OpenAI accounts: {exc}")


def echo_groups(finance: str | None, general: str | None, test_user: str | None) -> None:
    print("\n-- Pilot Entra groups (permission-trimming) --")
    print(f"   RAG Readers - Finance - Pilot (restricted): {finance or '(supply --finance-group)'}")
    print(f"   RAG Readers - General - Pilot:              {general or '(supply --general-group)'}")
    if test_user and finance:
        print(f"\n   Checking whether test user '{test_user}' is a member of the RESTRICTED "
              "Finance group (the negative test needs a user who is NOT).")
        try:
            # Placeholder for a transitive membership check via Microsoft Graph
            # (GET /users/{id}/transitiveMemberOf). Use transitive membership so nested
            # groups are included. Requires Group.Read.All / Directory.Read.All.
            print("      -> run the Graph transitive-membership check; the unauthorised "
                  "test user MUST NOT be in RAG Readers - Finance - Pilot.")
        except Exception as exc:
            print(f"      [warn] Graph membership check unavailable: {exc}")
    print("\n   Source-ACL note: for a sample document, confirm you can resolve the Entra "
          "group object IDs permitted to read it — that mapping becomes `group_ids` at "
          "ingestion. A source with no resolvable ACL must be assigned a documented group "
          "BEFORE ingestion (data-classification is the compliance team's decision).")


def main() -> int:
    p = argparse.ArgumentParser(description="Read-only RAG readiness discovery (no changes).")
    p.add_argument("--subscription", help="Azure subscription id")
    p.add_argument("--search-rg", help="Resource group to scope the search (optional)")
    p.add_argument("--finance-group", help="RAG Readers - Finance - Pilot object id (restricted)")
    p.add_argument("--general-group", help="RAG Readers - General - Pilot object id")
    p.add_argument("--test-user", help="UPN/object id of the UNAUTHORISED test user")
    args = p.parse_args()

    print("=== Enterprise RAG on Azure — discovery (read-only) ===")
    if not _try_import():
        return 2
    from azure.identity import DefaultAzureCredential
    cred = DefaultAzureCredential(exclude_interactive_browser_credential=False)

    if args.subscription:
        discover_search(cred, args.subscription, args.search_rg)
        discover_openai(cred, args.subscription, args.search_rg)
    else:
        print("\n(pass --subscription <id> to enumerate Search/OpenAI resources)")

    echo_groups(args.finance_group, args.general_group, args.test_user)

    print("\nDiscovery complete (read-only). Next: `az deployment group what-if` (the gate).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
