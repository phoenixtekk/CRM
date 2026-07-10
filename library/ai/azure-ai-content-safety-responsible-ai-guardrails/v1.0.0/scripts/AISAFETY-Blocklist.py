#!/usr/bin/env python3
"""
.SYNOPSIS
    AISAFETY-Blocklist.py — safe manager for the custom Content Safety blocklist (preview by default).

.DESCRIPTION
    PURPOSE
        Create/update the custom blocklist `Prohibited Terms - App Guardrails - Pilot` and add terms to
        it. LISTING is always read-only. Any CHANGE (create blocklist, add terms) defaults to a SAFE
        PREVIEW that prints exactly what it WOULD do and makes NO change; it applies only when you pass
        --apply. Idempotent: re-running updates the same blocklist without creating duplicates.

    HOW TO RUN
        pip install azure-ai-contentsafety azure-identity
        export CONTENT_SAFETY_ENDPOINT="https://<resource>.cognitiveservices.azure.com/"

        # Read-only: list existing blocklists
        python AISAFETY-Blocklist.py --list

        # PREVIEW (default, no change): what it would create/add
        python AISAFETY-Blocklist.py --name "Prohibited Terms - App Guardrails - Pilot" \
               --terms-file terms.txt

        # APPLY the change (explicit, gated)
        python AISAFETY-Blocklist.py --name "Prohibited Terms - App Guardrails - Pilot" \
               --terms-file terms.txt --apply

        terms.txt: one term/phrase per line (owned/reviewed by trust & safety, not invented here).

    EXPECTED RESULTS
        --list prints existing blocklists. Without --apply, prints the create/add plan and exits with a
        "PREVIEW — no changes made" banner. With --apply, creates/updates the blocklist and reports the
        terms added. Keyless auth via DefaultAzureCredential (managed identity).

.NOTES
    White-label. CHANGES ARE GATED behind --apply; default is a no-op preview. Term lists are a
    trust & safety / legal responsibility — this tool loads a reviewed list, it does not author one.
"""
import argparse
import os
import sys


def _blocklist_client(endpoint):
    from azure.ai.contentsafety import BlocklistClient
    from azure.identity import DefaultAzureCredential
    return BlocklistClient(endpoint, DefaultAzureCredential())


def load_terms(path):
    if not path:
        return []
    with open(path, "r", encoding="utf-8") as fh:
        return [ln.strip() for ln in fh if ln.strip() and not ln.startswith("#")]


def do_list(client):
    print("=== Existing text blocklists (read-only) ===")
    found = list(client.list_text_blocklists())
    if not found:
        print("  (none)")
    for b in found:
        print(f"  - {b.blocklist_name}: {getattr(b, 'description', '') or ''}")
    return [b.blocklist_name for b in found]


def main():
    ap = argparse.ArgumentParser(description="Safe custom-blocklist manager (preview by default).")
    ap.add_argument("--endpoint", default=os.environ.get("CONTENT_SAFETY_ENDPOINT", ""))
    ap.add_argument("--list", action="store_true", help="Read-only: list existing blocklists and exit.")
    ap.add_argument("--name", default="Prohibited Terms - App Guardrails - Pilot",
                    help="Blocklist name to create/update.")
    ap.add_argument("--description", default="Custom prohibited terms for AI app guardrails (pilot).")
    ap.add_argument("--terms-file", help="Path to a reviewed one-term-per-line file.")
    ap.add_argument("--apply", action="store_true",
                    help="Actually create/update (default is a no-op preview).")
    args = ap.parse_args()

    if not args.endpoint:
        print("[FAIL] CONTENT_SAFETY_ENDPOINT not set (pass --endpoint or set the env var).")
        sys.exit(2)

    client = _blocklist_client(args.endpoint)

    if args.list:
        do_list(client)
        return

    terms = load_terms(args.terms_file)
    existing = do_list(client)
    exists = args.name in existing

    print("\n=== Plan ===")
    print(f"  Blocklist        : {args.name}  ({'update existing' if exists else 'CREATE new'})")
    print(f"  Terms to add     : {len(terms)}")
    for t in terms[:20]:
        print(f"     + {t}")
    if len(terms) > 20:
        print(f"     ... and {len(terms) - 20} more")

    if not args.apply:
        print("\n*** PREVIEW — no changes made. Re-run with --apply to commit. ***")
        return

    # ---- APPLY (gated) -------------------------------------------------------
    from azure.ai.contentsafety.models import TextBlocklist, TextBlocklistItem, AddOrUpdateTextBlocklistItemsOptions
    client.create_or_update_text_blocklist(
        blocklist_name=args.name,
        options=TextBlocklist(blocklist_name=args.name, description=args.description),
    )
    print(f"[ok] blocklist ensured: {args.name}")
    if terms:
        items = [TextBlocklistItem(text=t) for t in terms]
        result = client.add_or_update_blocklist_items(
            blocklist_name=args.name,
            options=AddOrUpdateTextBlocklistItemsOptions(blocklist_items=items),
        )
        added = len(getattr(result, "blocklist_items", []) or [])
        print(f"[ok] terms added/updated: {added}")
    print("APPLY complete.")


if __name__ == "__main__":
    main()
