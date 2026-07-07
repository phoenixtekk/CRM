#!/usr/bin/env python3
# wave-batcher.py — build dependency-aware, size-limited migration waves from a discovery user-set.
#
# PURPOSE: Read-only planning. Batches the M365 user set into ordered migration waves that keep
#          delegate and shared-mailbox CLUSTERS together and honor a max wave size, carving a small
#          pilot wave first. Writes ONLY the plan files (waves.csv + JSON report); it never touches a
#          directory or migration engine. This is safe-by-default: nothing is applied to production.
# HOW TO RUN: python wave-batcher.py --input discovery-users.csv --max-users 500 --pilot-size 25
#             --keep-clusters --out waves.csv --report Wave-Plan.json      (Python 3.10+)
# EXPECTED RESULTS: waves.csv (upn,wave,stage) + a JSON report. report.split_clusters MUST be empty —
#                   a non-empty split_clusters means a delegate/shared-mailbox group was split across
#                   waves and someone would lose access at cutover (fix before accepting the plan).
#
# No external services or credentials are used; this reads a file and writes plan files only.

import argparse
import csv
import json
import sys
from collections import defaultdict


def load_rows(path):
    if path.lower().endswith(".json"):
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        return data if isinstance(data, list) else data.get("users", [])
    with open(path, newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def split_list(value):
    if not value:
        return []
    if isinstance(value, list):
        return [str(v).strip() for v in value if str(v).strip()]
    return [p.strip() for p in str(value).replace(";", ",").split(",") if p.strip()]


def build_clusters(users, keep_clusters):
    """Union-find so a manager, their delegates, and shared-mailbox members share one cluster id."""
    parent = {}

    def find(x):
        parent.setdefault(x, x)
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    upns = [u["upn"] for u in users]
    for u in upns:
        find(u)
    if keep_clusters:
        for u in users:
            for d in split_list(u.get("delegates")):
                if d in parent:
                    union(u["upn"], d)
            for other in users:
                shared = set(split_list(u.get("shared_mailboxes"))) & \
                         set(split_list(other.get("shared_mailboxes")))
                if shared and other["upn"] != u["upn"]:
                    union(u["upn"], other["upn"])

    groups = defaultdict(list)
    for u in upns:
        groups[find(u)].append(u)
    return list(groups.values())


def size_of(user):
    for key in ("mailbox_bytes", "drive_bytes", "data_bytes"):
        try:
            v = int(user.get(key) or 0)
            if v:
                return v
        except (TypeError, ValueError):
            pass
    return 1  # fall back to headcount weighting when volumes are unknown


def batch(users, max_users, pilot_size, keep_clusters):
    by_upn = {}
    for u in users:
        low = {k.lower().strip(): v for k, v in u.items()}
        low["upn"] = (low.get("upn") or low.get("userprincipalname")
                      or low.get("primary_smtp") or "").strip()
        if low["upn"]:
            by_upn[low["upn"]] = low

    clusters = build_clusters(list(by_upn.values()), keep_clusters)
    # sort clusters: singletons and small first so the pilot can be small & representative
    clusters.sort(key=lambda c: (len(c), sum(size_of(by_upn[m]) for m in c)))

    assignments = []          # (upn, wave_label, stage)
    split_check = defaultdict(set)

    # pilot wave: fill up to pilot_size from smallest clusters, never splitting a cluster
    pilot, remaining = [], []
    count = 0
    for c in clusters:
        if count + len(c) <= pilot_size:
            pilot.extend(c)
            count += len(c)
        else:
            remaining.append(c)
    for m in pilot:
        assignments.append((m, "Migration Wave - Pilot - Pilot", "Pilot"))
        split_check[m].add("Migration Wave - Pilot - Pilot")

    # remaining waves, size-capped, clusters kept whole
    wave_no, cur, cur_count = 2, [], 0

    def flush(n, members):
        label = f"Migration Wave - Wave{n} - Wave{n}"
        for m in members:
            assignments.append((m, label, f"Wave{n}"))
            split_check[m].add(label)

    for c in remaining:
        if cur_count + len(c) > max_users and cur:
            flush(wave_no, cur)
            wave_no += 1
            cur, cur_count = [], 0
        cur.extend(c)
        cur_count += len(c)
    if cur:
        flush(wave_no, cur)

    # a cluster is "split" if its members landed in more than one wave label
    split_clusters = []
    if keep_clusters:
        for c in clusters:
            labels = set()
            for m in c:
                labels |= split_check.get(m, set())
            if len(labels) > 1:
                split_clusters.append({"members": sorted(c), "waves": sorted(labels)})

    return assignments, split_clusters


def main():
    ap = argparse.ArgumentParser(description="Build dependency-aware migration waves (read-only plan).")
    ap.add_argument("--input", required=True)
    ap.add_argument("--max-users", type=int, default=500, help="max users per non-pilot wave")
    ap.add_argument("--pilot-size", type=int, default=25, help="target size of the first pilot wave")
    ap.add_argument("--keep-clusters", action="store_true",
                    help="keep delegate & shared-mailbox groups in the same wave (recommended)")
    ap.add_argument("--out", default="waves.csv", help="output wave assignment CSV")
    ap.add_argument("--report", help="output JSON plan report")
    args = ap.parse_args()

    users = load_rows(args.input)
    assignments, split_clusters = batch(users, args.max_users, args.pilot_size, args.keep_clusters)

    with open(args.out, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["upn", "wave", "stage"])
        w.writerows(assignments)

    waves = defaultdict(int)
    for _, wave, _ in assignments:
        waves[wave] += 1

    report = {
        "user_count": len(assignments),
        "wave_count": len(waves),
        "waves": [{"wave": k, "users": v} for k, v in sorted(waves.items())],
        "split_clusters": split_clusters,
        "clusters_intact": len(split_clusters) == 0,
    }
    print(f"Users batched:  {report['user_count']}")
    print(f"Waves:          {report['wave_count']}")
    for w in report["waves"]:
        print(f"  {w['wave']}: {w['users']}")
    print(f"Split clusters: {len(split_clusters)} (must be 0)")
    print(f"Assignments written: {args.out}")

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"Report written: {args.report}")

    return 0 if report["clusters_intact"] else 2


if __name__ == "__main__":
    sys.exit(main())
