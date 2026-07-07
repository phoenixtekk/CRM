#!/usr/bin/env python3
# discovery-profile.py — profile a migration discovery user-set and flag missing batching attributes.
#
# PURPOSE: Read-only. Profiles the discovery export (CSV/JSON) that describes the M365 users in scope
#          for an M365 -> Google Workspace migration, reporting user count, data distribution, delegate
#          and shared-mailbox CLUSTERS, and any rows missing the attributes the wave-batcher needs.
#          Optionally enriches from the live Google directory (Admin SDK Directory, read-only).
# HOW TO RUN: python discovery-profile.py --input discovery-users.csv --report Discovery-Profile.json
#             [--google-directory --delegated-admin admin@example.com]   (Python 3.10+, OAuth/ADC)
# EXPECTED RESULTS: A JSON profile + stdout summary. "missing_attributes" empty and clusters listed = a
#                   clean population ready to batch (Gate A pass); listed rows = fix the export first.
#
# This tool never writes to any directory or engine. `pip install google-api-python-client google-auth`
# only if using --google-directory. Credentials come from OAuth / Application Default Credentials — no
# keys are read from or written to this file.

import argparse
import csv
import json
import sys
from collections import defaultdict

# Attributes the wave-batcher relies on. Missing any of these breaks dependency-aware batching.
REQUIRED = ["upn", "department", "manager"]
CLUSTER_HINTS = ["delegates", "shared_mailboxes"]


def load_rows(path):
    """Load the discovery export as a list of dict rows (CSV or JSON)."""
    if path.lower().endswith(".json"):
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        return data if isinstance(data, list) else data.get("users", [])
    with open(path, newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def split_list(value):
    """A cell like 'a@x;b@x' or 'a@x,b@x' -> ['a@x','b@x']. Empty -> []."""
    if not value:
        return []
    if isinstance(value, list):
        return [str(v).strip() for v in value if str(v).strip()]
    return [p.strip() for p in str(value).replace(";", ",").split(",") if p.strip()]


def profile(rows, enrich=None):
    enrich = enrich or {}
    missing = []
    total_bytes = 0
    delegate_clusters = defaultdict(set)   # manager/owner -> set(members) that must stay together
    shared_clusters = defaultdict(set)

    for row in rows:
        low = {k.lower().strip(): v for k, v in row.items()}
        upn = (low.get("upn") or low.get("userprincipalname") or low.get("primary_smtp") or "").strip()

        # enrich missing fields from the live Google directory read (never overwrites source values)
        if upn in enrich:
            for k, v in enrich[upn].items():
                low.setdefault(k, v)

        miss = [a for a in REQUIRED if not str(low.get(a, "")).strip()]
        if miss:
            missing.append({"upn": upn or "<no-upn>", "missing": miss})

        # data volume (bytes) if present — used later for volume-based wave sizing
        for key in ("mailbox_bytes", "drive_bytes", "data_bytes"):
            try:
                total_bytes += int(low.get(key) or 0)
            except (TypeError, ValueError):
                pass

        # dependency clusters: a delegate must migrate in the same wave as the mailbox owner
        for d in split_list(low.get("delegates")):
            delegate_clusters[upn].add(d)
            delegate_clusters[upn].add(upn)
        for sm in split_list(low.get("shared_mailboxes")):
            shared_clusters[sm].add(upn)

    clusters = []
    for owner, members in delegate_clusters.items():
        if len(members) > 1:
            clusters.append({"type": "delegate", "anchor": owner, "members": sorted(members)})
    for sm, members in shared_clusters.items():
        if members:
            clusters.append({"type": "shared_mailbox", "anchor": sm, "members": sorted(members)})

    return {
        "user_count": len(rows),
        "total_data_bytes": total_bytes,
        "total_data_gib": round(total_bytes / (1024 ** 3), 2) if total_bytes else 0,
        "missing_attributes": missing,
        "clusters": clusters,
        "cluster_count": len(clusters),
        "ready_to_batch": len(missing) == 0,
    }


def google_enrich(delegated_admin):
    """Read-only Admin SDK Directory pull to confirm/enrich department & manager. Optional."""
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("[warn] google libraries not installed; skipping --google-directory enrichment",
              file=sys.stderr)
        return {}
    scopes = ["https://www.googleapis.com/auth/admin.directory.user.readonly"]
    creds, _ = google.auth.default(scopes=scopes)
    if delegated_admin and hasattr(creds, "with_subject"):
        creds = creds.with_subject(delegated_admin)
    svc = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    out, token = {}, None
    while True:
        resp = svc.users().list(customer="my_customer", maxResults=500, pageToken=token,
                                projection="full").execute()
        for u in resp.get("users", []):
            upn = u.get("primaryEmail", "")
            org = (u.get("organizations") or [{}])[0]
            rel = (u.get("relations") or [{}])
            mgr = next((r.get("value") for r in rel if r.get("type") == "manager"), "")
            out[upn] = {"department": org.get("department", ""), "manager": mgr}
        token = resp.get("nextPageToken")
        if not token:
            break
    return out


def main():
    ap = argparse.ArgumentParser(description="Profile a migration discovery user-set (read-only).")
    ap.add_argument("--input", required=True, help="discovery export CSV or JSON")
    ap.add_argument("--report", help="write the JSON profile to this path")
    ap.add_argument("--google-directory", action="store_true",
                    help="enrich from the live Google directory (read-only Admin SDK)")
    ap.add_argument("--delegated-admin", help="admin to impersonate for domain-wide delegation")
    args = ap.parse_args()

    rows = load_rows(args.input)
    enrich = google_enrich(args.delegated_admin) if args.google_directory else {}
    result = profile(rows, enrich)

    print(f"Users:            {result['user_count']}")
    print(f"Total data:       {result['total_data_gib']} GiB")
    print(f"Dependency clusters: {result['cluster_count']}")
    print(f"Rows missing batching attributes: {len(result['missing_attributes'])}")
    print(f"Ready to batch:   {result['ready_to_batch']}")
    if result["missing_attributes"][:10]:
        print("  e.g. " + ", ".join(f"{m['upn']}({'/'.join(m['missing'])})"
                                     for m in result["missing_attributes"][:10]))

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(result, fh, indent=2)
        print(f"\nReport written: {args.report}")

    # non-zero exit if not ready, so a pipeline can gate on it (Gate A)
    return 0 if result["ready_to_batch"] else 2


if __name__ == "__main__":
    sys.exit(main())
