#!/usr/bin/env python3
"""dolibarr-sync.py — Phase 1: push the marketplace catalog into Dolibarr as Services.

Reads the SAME source of truth as the store (library/_index/registry.json) and upserts one
Dolibarr **Service** per solution, idempotent by `ref` (the base SKU `PTK-<SOL>`). The three
audience tiers map to Dolibarr **multiprice levels**:

    level 1 = Commercial   level 2 = Non-Profit (x0.60)   level 3 = Government (x0.85)

so a third party assigned a price level automatically gets the right price on quotes/invoices.
(Enable PRODUIT_MULTIPRICES in Dolibarr and set 3 price levels first — see the enablement runbook.)

Usage:
    python tools/dolibarr-sync.py --dry-run          # offline: show exactly what would sync (no key)
    python tools/dolibarr-sync.py                    # live upsert (needs ~/.claude/.dolibarr.env)
    python tools/dolibarr-sync.py --separate-products  # fallback: 3 products per solution (per-SKU)
    python tools/dolibarr-sync.py --limit 5          # first N (smoke test)

Safe: writes only to Dolibarr (separate DB); never touches the store or wiki. Idempotent.
"""
import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REGISTRY = REPO / "library" / "_index" / "registry.json"
STORE = "https://workplace.phoenixtekk.com"
VAT = 0.0  # solutions are digital services; set your applicable VAT/tax rate here if needed


def gov_price(commercial):
    return round(float(commercial) * 0.85, 2)


def load_solutions():
    data = json.loads(REGISTRY.read_text(encoding="utf-8"))
    items = data if isinstance(data, list) else data.get("solutions", [])
    return [s for s in items if s.get("status") == "published"]


def base_ref(sol):
    return f"PTK-{sol['sol_code']}"


def description(sol):
    return (f"{sol['title']} — {sol['category']} solution package "
            f"(implementation guide + PowerShell scripts). "
            f"Store: {STORE}/{sol['slug']}-commercial")


def multiprice_payload(sol):
    comm = float(sol["commercial"])
    npo = float(sol.get("nonprofit") or round(comm * 0.60, 2))
    gov = gov_price(comm)
    return {
        "label": sol["title"][:250],
        "type": 1,                      # 1 = service
        "description": description(sol),
        "price": comm,                  # base price = commercial (level 1)
        "price_base_type": "HT",
        "tva_tx": VAT,
        "status": 1,                    # on sale
        "status_buy": 0,
        "multiprices": {"1": comm, "2": npo, "3": gov},
        "multiprices_base_type": {"1": "HT", "2": "HT", "3": "HT"},
        "array_options": {"options_store_url": f"{STORE}/{sol['slug']}-commercial"},
    }


def separate_payloads(sol):
    """Fallback: one product per audience SKU."""
    comm = float(sol["commercial"])
    npo = float(sol.get("nonprofit") or round(comm * 0.60, 2))
    gov = gov_price(comm)
    tiers = [("COMM", "Commercial", comm), ("NPO", "Non-Profit", npo), ("GOV", "Government", gov)]
    out = []
    for code, label, price in tiers:
        ref = f"PTK-{sol['sol_code']}-{code}-001"
        out.append((ref, {
            "label": f"{sol['title']} — {label}"[:250],
            "type": 1, "description": description(sol),
            "price": price, "price_base_type": "HT", "tva_tx": VAT,
            "status": 1, "status_buy": 0,
        }))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="offline: print the plan, no API calls")
    ap.add_argument("--separate-products", action="store_true",
                    help="3 products/solution (per-SKU) instead of multiprice levels")
    ap.add_argument("--limit", type=int, default=0, help="only the first N solutions")
    args = ap.parse_args()

    sols = load_solutions()
    if args.limit:
        sols = sols[:args.limit]
    print(f"Solutions to sync: {len(sols)}  mode: "
          f"{'separate-products' if args.separate_products else 'multiprice-levels'}")

    if args.dry_run:
        total = 0
        for s in sols:
            if args.separate_products:
                for ref, p in separate_payloads(s):
                    print(f"  {ref:<28} {p['price']:>8.2f}  {p['label'][:60]}")
                    total += 1
            else:
                ref = base_ref(s)
                comm = float(s["commercial"]); npo = float(s.get('nonprofit') or round(comm*0.6,2))
                print(f"  {ref:<20} L1={comm:>8.2f} L2={npo:>8.2f} L3={gov_price(comm):>8.2f}  {s['title'][:52]}")
                total += 1
        print(f"\nDRY RUN — would upsert {total} Dolibarr "
              f"{'products' if args.separate_products else 'services'}. No changes made.")
        return

    # live mode
    try:
        from dolibarr_client import DolibarrClient, DolibarrError
    except ImportError:
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        from dolibarr_client import DolibarrClient, DolibarrError
    try:
        client = DolibarrClient()
        client.ping()  # fail fast if key/url wrong
    except DolibarrError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(2)

    created = updated = failed = 0
    for s in sols:
        try:
            if args.separate_products:
                for ref, payload in separate_payloads(s):
                    action, pid = client.upsert_product(ref, payload)
                    print(f"  {action.upper():7} {ref} (id {pid})")
                    created += action == "created"; updated += action == "updated"
            else:
                ref = base_ref(s)
                action, pid = client.upsert_product(ref, multiprice_payload(s))
                print(f"  {action.upper():7} {ref} (id {pid})  {s['title'][:50]}")
                created += action == "created"; updated += action == "updated"
        except DolibarrError as e:
            failed += 1
            print(f"  FAIL    {base_ref(s)}: {e}", file=sys.stderr)
    print(f"\nDone. created={created} updated={updated} failed={failed}")


if __name__ == "__main__":
    main()
