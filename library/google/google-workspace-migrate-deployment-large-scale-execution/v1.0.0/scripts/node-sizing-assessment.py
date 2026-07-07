#!/usr/bin/env python3
# node-sizing-assessment.py — inventory the Microsoft 365 source and recommend Google Workspace Migrate node count.
#
# PURPOSE: Read-only discovery of the source (mailboxes, OneDrive, SharePoint) via Microsoft Graph to
#          produce a quantified baseline and a recommended worker-node count for a target throughput/window.
#          Read-only by default: it never writes to Microsoft 365 or Google.
# HOW TO RUN: python node-sizing-assessment.py --graph --out baseline-source.json   (Python 3.10+, OAuth/ADC; see --help)
#             (pip install msgraph-core azure-identity  — or use --sample to run with bundled sample data)
# EXPECTED RESULTS: Prints an inventory summary + recommended node count; writes baseline-source.json used
#                   by wave-batch-builder.py and post-migration-validation.py. Non-zero exit if inputs are invalid.

import argparse
import json
import math
import sys
from datetime import datetime, timezone

# Planning defaults — conservative starting points. Confirm real per-node throughput against
# Google Workspace Migrate guidance FOR YOUR VERSION and calibrate from the pilot.
DEFAULT_PER_NODE_GBPH = 40.0   # GB/hour effective per worker node (planning estimate; verify for your version)
DEFAULT_WINDOW_HOURS = 72.0    # migration window for the bulk pre-stage pass
DELTA_HEADROOM = 1.3           # multiply node count for delta passes + headroom


def parse_args():
    p = argparse.ArgumentParser(description="Assess M365 source and recommend GWSMigrate worker-node count (read-only).")
    src = p.add_mutually_exclusive_group(required=True)
    src.add_argument("--graph", action="store_true", help="Read the live source via Microsoft Graph (read-only).")
    src.add_argument("--sample", action="store_true", help="Run against bundled sample inventory (no network).")
    p.add_argument("--per-node-gbph", type=float, default=DEFAULT_PER_NODE_GBPH,
                   help="Planning throughput per worker node in GB/hour (verify for your version).")
    p.add_argument("--window-hours", type=float, default=DEFAULT_WINDOW_HOURS,
                   help="Bulk pre-stage window in hours.")
    p.add_argument("--out", default="baseline-source.json", help="Output baseline JSON path.")
    return p.parse_args()


def read_graph_inventory():
    """Read a read-only source inventory from Microsoft Graph.

    Uses OAuth via azure-identity (DefaultAzureCredential / interactive) — NO hardcoded secrets.
    Graph reports endpoints used (all read-only):
      GET /users                                   -> mailbox list
      /reports getMailboxUsageDetail               -> mailbox sizes/item counts
      /reports getOneDriveUsageAccountDetail       -> OneDrive sizes/file counts
      /reports getSharePointSiteUsageDetail        -> SharePoint site sizes/file counts
    """
    try:
        from azure.identity import DefaultAzureCredential  # noqa: F401
        # from msgraph import GraphServiceClient  # wire your Graph client here
    except ImportError:
        sys.exit("Missing dependency: pip install msgraph-core azure-identity (or run with --sample).")
    # Intentionally not fabricating live calls here. Wire DefaultAzureCredential + the Graph reports
    # endpoints above, aggregate to the same schema as sample_inventory(), and return it.
    sys.exit("Live --graph read not wired in this template. Provide a Graph client, or use --sample. "
             "See the docstring for the exact read-only report endpoints to call.")


def sample_inventory():
    return {
        "mailboxes": {"count": 8200, "total_gb": 41000.0, "largest_gb": 92.0, "total_items": 61000000},
        "onedrive":  {"count": 8200, "total_gb": 58000.0, "largest_gb": 210.0, "total_files": 39000000},
        "sharepoint": {"sites": 640, "libraries": 2100, "total_gb": 74000.0, "total_files": 51000000},
        "sharing": {"externally_shared_items": 220000, "unique_permission_items": 1800000},
    }


def recommend_nodes(inv, per_node_gbph, window_hours):
    total_gb = (inv["mailboxes"]["total_gb"] + inv["onedrive"]["total_gb"] + inv["sharepoint"]["total_gb"])
    required_gbph = total_gb / max(window_hours, 1.0)
    base_nodes = math.ceil(required_gbph / max(per_node_gbph, 0.1))
    recommended = max(1, math.ceil(base_nodes * DELTA_HEADROOM))
    return total_gb, required_gbph, base_nodes, recommended


def main():
    args = parse_args()
    inv = sample_inventory() if args.sample else read_graph_inventory()

    total_gb, required_gbph, base_nodes, recommended = recommend_nodes(
        inv, args.per_node_gbph, args.window_hours)
    total_items = (inv["mailboxes"]["total_items"] + inv["onedrive"]["total_files"]
                   + inv["sharepoint"]["total_files"])

    baseline = {
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "source": "sample" if args.sample else "microsoft-graph",
        "inventory": inv,
        "totals": {"total_gb": round(total_gb, 1), "total_items": total_items},
        "sizing": {
            "per_node_gbph": args.per_node_gbph,
            "window_hours": args.window_hours,
            "required_gbph": round(required_gbph, 1),
            "base_worker_nodes": base_nodes,
            "recommended_worker_nodes": recommended,
            "delta_headroom": DELTA_HEADROOM,
            "note": "Planning estimate. Verify per-node throughput for your Google Workspace Migrate version "
                    "and calibrate from the pilot wave.",
        },
    }

    print("=== Source baseline (read-only) ===")
    print(f"  Mailboxes : {inv['mailboxes']['count']:>8,}  {inv['mailboxes']['total_gb']:>10,.0f} GB")
    print(f"  OneDrive  : {inv['onedrive']['count']:>8,}  {inv['onedrive']['total_gb']:>10,.0f} GB")
    print(f"  SharePoint: {inv['sharepoint']['sites']:>8,} sites  {inv['sharepoint']['total_gb']:>10,.0f} GB")
    print(f"  TOTAL     : {total_gb:>12,.0f} GB   {total_items:>14,} items")
    print("=== Node sizing ===")
    print(f"  Window {args.window_hours:.0f}h @ {args.per_node_gbph:.0f} GB/h/node "
          f"-> required {required_gbph:,.0f} GB/h")
    print(f"  Base nodes {base_nodes}  ->  RECOMMENDED worker nodes: {recommended}  (incl. delta headroom)")
    print("  Reminder: verify per-node throughput for your version; calibrate from the pilot.")

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(baseline, f, indent=2)
    print(f"\nWrote baseline -> {args.out}")


if __name__ == "__main__":
    main()
