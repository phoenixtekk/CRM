#!/usr/bin/env python3
# license_winddown_helper.py — model and reclaim M365 license assignments (dry-run by default)
#
# PURPOSE: Wind down duplicate spend after the Google move. Reports assigned SKUs per user, computes
#          reclaimable vs retained seats and a projected monthly saving, and — only with --apply —
#          REMOVES license assignments (never cancels subscriptions) for a named scope. Accounts on the
#          legal-hold register (--hold-file) and any --retain users are always excluded from reclaim.
# HOW TO RUN: python license_winddown_helper.py [--scope-file users.txt] [--hold-file holds.txt]
#             [--price-file skus.csv] [--apply]   (Python 3.10+; pip install msal requests; env creds)
# EXPECTED RESULTS: A plan (JSON + stdout). Dry-run (default) changes NOTHING. With --apply it removes
#          assignments only for reclaimable users and prints each action; held/retained users are skipped.
#
# Credentials from the ENVIRONMENT only: M365DECOM_TENANT_ID / M365DECOM_CLIENT_ID / M365DECOM_CLIENT_SECRET.
# READ needs: User.Read.All, Directory.Read.All. --apply additionally needs a role/scope permitted to
# manage license assignments (e.g. User.ReadWrite.All / Directory.ReadWrite.All + License Administrator).
# WRITE IS OFF unless --apply is passed. No credentials or keys are stored in this file.

import argparse
import csv
import datetime as dt
import json
import os
import sys

GRAPH = "https://graph.microsoft.com/v1.0"
SCOPE = ["https://graph.microsoft.com/.default"]


def die(msg: str, code: int = 2) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(code)


def get_token() -> str:
    try:
        import msal  # type: ignore
    except ImportError:
        die("msal not installed. Run: pip install msal requests")
    tenant = os.environ.get("M365DECOM_TENANT_ID")
    client = os.environ.get("M365DECOM_CLIENT_ID")
    secret = os.environ.get("M365DECOM_CLIENT_SECRET")
    if not (tenant and client and secret):
        die("Set M365DECOM_TENANT_ID / M365DECOM_CLIENT_ID / M365DECOM_CLIENT_SECRET in the environment.")
    app = msal.ConfidentialClientApplication(
        client_id=client,
        authority=f"https://login.microsoftonline.com/{tenant}",
        client_credential=secret,
    )
    result = app.acquire_token_for_client(scopes=SCOPE)
    if "access_token" not in result:
        die(f"Token request failed: {result.get('error_description', result.get('error'))}")
    return result["access_token"]


def graph_paged(session, url: str):
    import time
    items = []
    while url:
        for attempt in range(5):
            resp = session.get(url, timeout=60)
            if resp.status_code == 429 or resp.status_code >= 500:
                time.sleep(min(int(resp.headers.get("Retry-After", 2 ** attempt)), 30))
                continue
            if not resp.ok:
                die(f"Graph GET {url} -> {resp.status_code}: {resp.text[:300]}")
            data = resp.json()
            break
        else:
            die(f"Graph GET {url} kept throttling.")
        items.extend(data.get("value", []))
        url = data.get("@odata.nextLink")
    return items


def load_set(path):
    if not path:
        return set()
    with open(path, encoding="utf-8") as fh:
        return {ln.strip().lower() for ln in fh if ln.strip() and not ln.startswith("#")}


def load_prices(path):
    """CSV: skuId,skuPartNumber,monthly_price. Missing price -> 0 (saving unknown for that SKU)."""
    prices = {}
    if not path:
        return prices
    with open(path, newline="", encoding="utf-8") as fh:
        for row in csv.DictReader(fh):
            sku = (row.get("skuId") or "").strip()
            if sku:
                try:
                    prices[sku] = float(row.get("monthly_price") or 0)
                except ValueError:
                    prices[sku] = 0.0
    return prices


def main() -> None:
    ap = argparse.ArgumentParser(description="Model/reclaim M365 license assignments (dry-run default).")
    ap.add_argument("--scope-file", help="Optional: limit to these UPNs (one per line). Default: all.")
    ap.add_argument("--hold-file", help="UPNs on legal hold — NEVER reclaimed (one per line).")
    ap.add_argument("--retain-file", help="UPNs to retain for now (still needed) — not reclaimed.")
    ap.add_argument("--price-file", help="CSV skuId,skuPartNumber,monthly_price for saving estimate.")
    ap.add_argument("--out", default="license-plan.json", help="Output plan JSON path.")
    ap.add_argument("--apply", action="store_true",
                    help="ACTUALLY remove license assignments for reclaimable users. Default: dry-run.")
    args = ap.parse_args()

    scope = load_set(args.scope_file)
    holds = load_set(args.hold_file)
    retain = load_set(args.retain_file)
    prices = load_prices(args.price_file)

    import requests
    session = requests.Session()
    session.headers.update({"Authorization": f"Bearer {get_token()}", "Accept": "application/json"})

    # Map subscribed SKUs for readable part numbers.
    sku_names = {s["skuId"]: s.get("skuPartNumber", s["skuId"])
                 for s in graph_paged(session, f"{GRAPH}/subscribedSkus")}

    users = graph_paged(
        session,
        f"{GRAPH}/users?$select=id,userPrincipalName,accountEnabled,assignedLicenses"
        "&$top=999")

    plan = {"reclaimable": [], "retained": [], "held": [], "no_license": []}
    projected_saving = 0.0

    for u in users:
        upn = (u.get("userPrincipalName") or "").lower()
        if scope and upn not in scope:
            continue
        licenses = [lic.get("skuId") for lic in (u.get("assignedLicenses") or []) if lic.get("skuId")]
        entry = {"userPrincipalName": u.get("userPrincipalName"),
                 "skus": [sku_names.get(s, s) for s in licenses],
                 "skuIds": licenses}
        if not licenses:
            plan["no_license"].append(entry)
            continue
        if upn in holds:
            entry["reason"] = "on legal-hold register"
            plan["held"].append(entry)
            continue
        if upn in retain:
            entry["reason"] = "explicitly retained (still needed)"
            plan["retained"].append(entry)
            continue
        entry["monthly_value"] = round(sum(prices.get(s, 0.0) for s in licenses), 2)
        projected_saving += entry["monthly_value"]
        plan["reclaimable"].append(entry)

    report = {
        "generated": dt.datetime.now(dt.timezone.utc).isoformat(),
        "mode": "APPLY" if args.apply else "DRY-RUN",
        "gate": "Gate 3 - Licensing wind-down",
        "counts": {k: len(v) for k, v in plan.items()},
        "projected_monthly_saving": round(projected_saving, 2),
        "plan": plan,
    }

    # Apply: remove all assigned licenses for reclaimable users only.
    if args.apply:
        applied = 0
        for entry in plan["reclaimable"]:
            body = {"addLicenses": [], "removeLicenses": entry["skuIds"]}
            resp = session.post(f"{GRAPH}/users/{entry['userPrincipalName']}/assignLicense",
                                json=body, timeout=60)
            if resp.ok:
                applied += 1
                print(f"  reclaimed: {entry['userPrincipalName']} "
                      f"({', '.join(entry['skus'])})")
            else:
                print(f"  FAILED:   {entry['userPrincipalName']} -> "
                      f"{resp.status_code}: {resp.text[:200]}", file=sys.stderr)
        report["applied_count"] = applied

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    print(f"[{report['mode']}] reclaimable={report['counts']['reclaimable']} "
          f"retained={report['counts']['retained']} held={report['counts']['held']} "
          f"projected monthly saving={report['projected_monthly_saving']}")
    if not args.apply:
        print("Dry-run: no changes made. Re-run with --apply (pilot scope first) to reclaim.")
    print(f"Plan written to {args.out}")


if __name__ == "__main__":
    main()
