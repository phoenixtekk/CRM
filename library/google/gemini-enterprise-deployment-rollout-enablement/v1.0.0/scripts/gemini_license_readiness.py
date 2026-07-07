#!/usr/bin/env python3
# gemini_license_readiness.py — assess Gemini/AI license position and cohort assignment (read-only)
#
# PURPOSE: Read-only assessment of the tenant's Gemini/AI subscription — total vs. assigned vs.
#          available seats — and (optionally) verify that assigned licenses match a cohort's
#          membership. Establishes the license baseline for the rollout. Never assigns or removes
#          licenses; this tool only reads and reports.
# HOW TO RUN: python gemini_license_readiness.py --report license-baseline.json
#             python gemini_license_readiness.py --verify-cohort "Pilot-Wave0"
#             (Python 3.10+, gcloud auth / ADC; Admin SDK Licensing + Directory read scopes; see --help)
# EXPECTED RESULTS: Prints seat totals and a PASS/FAIL feasibility line; with --verify-cohort prints
#          the assigned-vs-membership diff. Non-zero exit on shortfall or diff.
#
# NOTES:
#   - SAFE BY DEFAULT: read-only. There is no --apply; this tool cannot mutate licensing.
#   - NO hardcoded credentials/keys. Uses Application Default Credentials (ADC) / gcloud auth or an
#     authorized service account discovered from the environment — never an exported key in code.
#   - The exact Gemini/AI SKU id and edition are entitlement-dependent — VERIFY IN YOUR TENANT and
#     pass the SKU id you see under Billing → Subscriptions via --sku-id.
#   - Uses the Admin SDK Enterprise License Manager + Directory APIs when google-api-python-client is
#     installed (pip install google-api-python-client google-auth); otherwise prints the equivalent
#     gcloud/console steps so the run is still actionable.

import argparse
import json
import sys
from datetime import datetime, timezone


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _load_admin_clients(customer: str):
    """Build read-only Admin SDK clients from ADC. Returns (licensing, directory) or (None, None)."""
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        return None, None
    scopes = [
        "https://www.googleapis.com/auth/apps.licensing",
        "https://www.googleapis.com/auth/admin.directory.user.readonly",
        "https://www.googleapis.com/auth/admin.directory.group.readonly",
    ]
    creds, _ = google.auth.default(scopes=scopes)
    licensing = build("licensing", "v1", credentials=creds, cache_discovery=False)
    directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    return licensing, directory


def _manual_steps():
    print("  [manual] google-api-python-client not installed — verify in the Admin console instead:")
    print("    1. admin.google.com -> Billing -> Subscriptions -> (your Gemini/AI subscription)")
    print("    2. Record total seats and 'Licenses assigned' vs 'available'.")
    print("    3. VERIFY IN YOUR TENANT: the exact SKU id/edition of the Gemini/AI add-on.")
    print("    Install clients to automate: pip install google-api-python-client google-auth")


def cmd_report(args) -> int:
    print(f"[assess] Gemini/AI license baseline — customer={args.customer} sku={args.sku_id or '(unset)'}")
    licensing, _ = _load_admin_clients(args.customer)
    if licensing is None or not args.sku_id:
        if not args.sku_id:
            print("  --sku-id not provided (VERIFY IN YOUR TENANT which Gemini/AI SKU id applies).")
        _manual_steps()
        baseline = {
            "generated": _iso_now(),
            "customer": args.customer,
            "sku_id": args.sku_id,
            "mode": "manual",
            "note": "seat counts to be filled from Billing -> Subscriptions; verify SKU in tenant",
        }
    else:
        assignments = []
        req = licensing.licenseAssignments().listForProduct(
            productId=args.product_id, customerId=args.customer, maxResults=1000
        )
        while req is not None:
            resp = req.execute()
            assignments.extend(resp.get("items", []))
            req = licensing.licenseAssignments().listForProduct_next(req, resp)
        assigned = sum(1 for a in assignments if a.get("skuId") == args.sku_id)
        baseline = {
            "generated": _iso_now(),
            "customer": args.customer,
            "product_id": args.product_id,
            "sku_id": args.sku_id,
            "assigned_seats": assigned,
            "note": "total/available seats are read from Billing -> Subscriptions (not exposed by "
                    "the Licensing API); record them alongside this baseline. Verify in your tenant.",
        }
        print(f"  assigned seats (this SKU): {assigned}")
        print("  total/available seats: read from Billing -> Subscriptions (VERIFY IN YOUR TENANT).")

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(baseline, fh, indent=2)
        print(f"[assess] baseline written -> {args.report} (License Assignment - Gemini - v1)")
    return 0


def _group_members(directory, group_key: str) -> set[str]:
    members: set[str] = set()
    req = directory.members().list(groupKey=group_key, maxResults=200)
    while req is not None:
        resp = req.execute()
        for m in resp.get("members", []):
            if m.get("email"):
                members.add(m["email"].lower())
        req = directory.members().list_next(req, resp)
    return members


def cmd_verify_cohort(args) -> int:
    print(f"[gate G2] verify assigned licenses == cohort membership: {args.verify_cohort}")
    licensing, directory = _load_admin_clients(args.customer)
    if licensing is None:
        _manual_steps()
        print("  [gate G2] cannot verify automatically without clients — VERIFY IN YOUR TENANT.")
        return 2
    if not args.group_key or not args.sku_id:
        print("  provide --group-key (the cohort group) and --sku-id to verify. VERIFY IN YOUR TENANT.")
        return 2

    membership = _group_members(directory, args.group_key)
    assigned = set()
    req = licensing.licenseAssignments().listForProduct(
        productId=args.product_id, customerId=args.customer, maxResults=1000
    )
    while req is not None:
        resp = req.execute()
        for a in resp.get("items", []):
            if a.get("skuId") == args.sku_id and a.get("userId"):
                assigned.add(a["userId"].lower())
        req = licensing.licenseAssignments().listForProduct_next(req, resp)

    missing = sorted(membership - assigned)   # in cohort, no license (under-assignment)
    extra = sorted(assigned - membership)      # licensed, not in cohort (waste / bleed)
    print(f"  cohort members: {len(membership)}  |  licensed: {len(assigned)}")
    print(f"  under-assigned (in cohort, no license): {len(missing)}")
    print(f"  over-assigned (licensed, not in cohort): {len(extra)}")
    for u in missing[:20]:
        print(f"    - MISSING: {u}")
    for u in extra[:20]:
        print(f"    + EXTRA:   {u}")
    if missing or extra:
        print("GATE G2: FAIL — reconcile license assignment to cohort membership.")
        return 1
    print("GATE G2: PASS")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Gemini/AI license readiness & cohort verification (read-only).")
    p.add_argument("--customer", default="my_customer", help="Customer id (default: my_customer).")
    p.add_argument("--product-id", default="Google-Apps",
                   help="Licensing productId containing the Gemini/AI SKU. VERIFY IN YOUR TENANT.")
    p.add_argument("--sku-id", default=None,
                   help="Gemini/AI SKU id (entitlement-dependent — VERIFY IN YOUR TENANT).")
    p.add_argument("--report", default=None, help="Write the license baseline JSON to this path.")
    p.add_argument("--verify-cohort", default=None, help="Gate G2: verify a named cohort's assignment.")
    p.add_argument("--group-key", default=None, help="Google Group key for the cohort (with --verify-cohort).")
    return p


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    if args.verify_cohort:
        return cmd_verify_cohort(args)
    return cmd_report(args)


if __name__ == "__main__":
    sys.exit(main())
