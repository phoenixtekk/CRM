#!/usr/bin/env python3
# synfid_profile.py — build an aggregate-only Reference Profile from governed reference data
#
# PURPOSE: Reference Profile builder. Reads a read-only, minimized reference dataset and emits an
#          AGGREGATE-ONLY statistical fingerprint (per-field summary stats, histograms, category
#          frequencies, pairwise correlations, missingness). By design it writes NO row-level real
#          data. Safe by default: prints to stdout unless --write is given.
# HOW TO RUN: python synfid_profile.py --data reference.csv --manifest manifest.json [--out ref_profile.json] [--write]
#             (Python 3.10+, standard library only; see --help)
# EXPECTED RESULTS: An aggregate JSON profile (no raw rows) with a content hash, ready to be the
#                   reusable reference for fidelity measurement. Refuses to emit if it would leak rows.

import argparse
import csv
import hashlib
import json
import math
import sys
from collections import Counter, defaultdict


def load_manifest(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def read_columns(path):
    with open(path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        header = reader.fieldnames or []
        cols = defaultdict(list)
        n = 0
        for row in reader:
            n += 1
            for h in header:
                cols[h].append(row.get(h, ""))
    return header, cols, n


def _floats(values):
    out = []
    for v in values:
        if v in ("", None):
            continue
        try:
            out.append(float(v))
        except ValueError:
            continue
    return out


def numeric_summary(values, bins=10):
    nums = _floats(values)
    missing = sum(1 for v in values if v in ("", None))
    if not nums:
        return {"count": 0, "missing": missing}
    nums_sorted = sorted(nums)
    n = len(nums_sorted)
    mean = sum(nums_sorted) / n
    var = sum((x - mean) ** 2 for x in nums_sorted) / n if n > 1 else 0.0
    lo, hi = nums_sorted[0], nums_sorted[-1]
    # aggregate histogram (counts only, no raw values)
    hist = [0] * bins
    width = (hi - lo) / bins if hi > lo else 1.0
    for x in nums_sorted:
        idx = min(int((x - lo) / width), bins - 1) if hi > lo else 0
        hist[idx] += 1

    def pct(p):
        k = min(int(p * (n - 1)), n - 1)
        return nums_sorted[k]

    return {
        "count": n,
        "missing": missing,
        "mean": round(mean, 6),
        "std": round(math.sqrt(var), 6),
        "min": lo,
        "p25": pct(0.25),
        "p50": pct(0.50),
        "p75": pct(0.75),
        "max": hi,
        "hist_bins": bins,
        "hist_range": [lo, hi],
        "hist_counts": hist,
    }


def categorical_summary(values, top=50):
    missing = sum(1 for v in values if v in ("", None))
    present = [v for v in values if v not in ("", None)]
    counts = Counter(present)
    total = sum(counts.values()) or 1
    freqs = {k: round(c / total, 6) for k, c in counts.most_common(top)}
    return {
        "count": len(present),
        "missing": missing,
        "distinct": len(counts),
        "frequencies": freqs,   # aggregate proportions only
    }


def pearson(xs, ys):
    n = len(xs)
    if n < 2:
        return None
    mx, my = sum(xs) / n, sum(ys) / n
    num = sum((a - mx) * (b - my) for a, b in zip(xs, ys))
    dx = math.sqrt(sum((a - mx) ** 2 for a in xs))
    dy = math.sqrt(sum((b - my) ** 2 for b in ys))
    if dx == 0 or dy == 0:
        return None
    return round(num / (dx * dy), 6)


def build_profile(header, cols, n, manifest):
    fields = {f["name"]: f for f in manifest.get("fields", [])}
    profile = {"n_rows": n, "fields": {}, "correlations": {}}
    numeric_cache = {}
    for name in header:
        spec = fields.get(name, {})
        role = spec.get("role", "fidelity")
        ftype = spec.get("type", "categorical")
        if role in ("identifier", "free-text") or ftype in ("identifier", "free-text"):
            profile["fields"][name] = {"type": ftype, "role": role, "excluded": True}
            continue
        if ftype == "numeric":
            profile["fields"][name] = {"type": "numeric", "role": role, **numeric_summary(cols[name])}
            paired = _floats(cols[name])
            numeric_cache[name] = paired
        else:
            profile["fields"][name] = {"type": ftype, "role": role, **categorical_summary(cols[name])}
    # pairwise correlations over aligned numeric rows
    num_names = list(numeric_cache.keys())
    for i in range(len(num_names)):
        for j in range(i + 1, len(num_names)):
            a, b = num_names[i], num_names[j]
            xs, ys = [], []
            for va, vb in zip(cols[a], cols[b]):
                if va in ("", None) or vb in ("", None):
                    continue
                try:
                    xs.append(float(va))
                    ys.append(float(vb))
                except ValueError:
                    continue
            r = pearson(xs, ys)
            if r is not None:
                profile["correlations"][f"{a}|{b}"] = r
    return profile


def assert_no_rows(profile):
    """Defensive check: the profile must not embed row-level real values."""
    for name, f in profile["fields"].items():
        if "raw" in f or "values" in f or "rows" in f:
            raise ValueError(f"profile field '{name}' contains row-level data; refusing to emit")


def main(argv=None):
    p = argparse.ArgumentParser(description="Build an aggregate-only Reference Profile.")
    p.add_argument("--data", required=True, help="Governed reference CSV (read-only, minimized).")
    p.add_argument("--manifest", required=True, help="Field Manifest JSON (types/roles).")
    p.add_argument("--out", help="Output path for the aggregate profile (used with --write).")
    p.add_argument("--write", action="store_true", help="Write to --out (default: print only).")
    p.add_argument("--bins", type=int, default=10, help="Histogram bins for numeric fields.")
    args = p.parse_args(argv)

    manifest = load_manifest(args.manifest)
    header, cols, n = read_columns(args.data)
    profile = build_profile(header, cols, n, manifest)
    assert_no_rows(profile)

    payload = json.dumps(profile, indent=2, sort_keys=True)
    profile["_hash"] = hashlib.sha256(payload.encode("utf-8")).hexdigest()[:16]
    profile["_note"] = "AGGREGATE-ONLY. Contains no row-level real data. Export permitted per governance."
    out = json.dumps(profile, indent=2, sort_keys=True)

    if args.write and args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(out + "\n")
        print(f"[written] Reference Profile (aggregate-only) -> {args.out}  hash={profile['_hash']}")
    else:
        print("# dry-run: aggregate-only Reference Profile (pass --write --out <file> to save):")
        print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
