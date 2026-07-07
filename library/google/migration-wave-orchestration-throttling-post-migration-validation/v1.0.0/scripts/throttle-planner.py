#!/usr/bin/env python3
# throttle-planner.py — budget migration concurrency/pacing against Microsoft Graph + Google API limits.
#
# PURPOSE: Read-only. For each wave, compute a THROTTLE BUDGET (concurrent workers + request pacing)
#          that keeps the projected request rate under BOTH the Microsoft Graph throttling model (source
#          read side) and the Google Workspace API quotas (target write side) for the wave's data volume
#          and change window, with headroom. `--observe` compares a sampled rate file to the budget. This
#          tool computes and reports only — it changes nothing in any engine or tenant.
# HOW TO RUN: python throttle-planner.py --waves waves.csv --limits limits.json --window-hours 8
#             --report Throttle-Budget.json  [--observe rate-samples.csv]        (Python 3.10+)
# EXPECTED RESULTS: Per-wave recommended workers + pacing and fits_window / headroom_pct. A wave with
#                   fits_window=false or negative headroom does NOT fit the window under the limits —
#                   split it, widen the window, or request a quota increase (never exceed the budget).
#
# limits.json is operator-supplied CURRENT numbers (they change per tenant/license/API version and MUST
# be re-confirmed — see the Requirements Guide). No credentials or secrets are used or stored.

import argparse
import csv
import json
import sys
from collections import defaultdict

# Illustrative DEFAULTS only — override every value from your own limits.json after confirming current
# figures in Google Cloud console -> Quotas and Microsoft Graph throttling guidance for your tenant.
DEFAULT_LIMITS = {
    # requests/second ceilings (per app/tenant) — VERIFY current values for your tenant & engine version
    "graph_read_rps": 20.0,        # Microsoft Graph read side (source)
    "google_write_rps": 20.0,      # Google Admin SDK / Drive / Gmail write side (target)
    "requests_per_item": 3.0,      # approx API calls the engine issues per migrated item (verify)
    "avg_items_per_gib": 8000.0,   # approx mail items per GiB (verify against your estate)
    "headroom": 0.30,              # keep 30% below the ceiling for backoff/variance
    "per_worker_rps": 2.0,         # sustainable request rate one migration worker drives (verify)
}


def load_limits(path):
    limits = dict(DEFAULT_LIMITS)
    if path:
        with open(path, encoding="utf-8") as fh:
            limits.update(json.load(fh))
    return limits


def wave_volumes(waves_csv, sizes_csv):
    """Sum data volume per wave. If per-user sizes aren't supplied, weight by headcount."""
    sizes = {}
    if sizes_csv:
        with open(sizes_csv, newline="", encoding="utf-8") as fh:
            for r in csv.DictReader(fh):
                low = {k.lower(): v for k, v in r.items()}
                upn = low.get("upn", "")
                try:
                    sizes[upn] = int(low.get("data_bytes") or low.get("mailbox_bytes") or 0)
                except ValueError:
                    sizes[upn] = 0
    vols = defaultdict(lambda: {"users": 0, "bytes": 0})
    with open(waves_csv, newline="", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            low = {k.lower(): v for k, v in r.items()}
            wave = low.get("wave", "")
            vols[wave]["users"] += 1
            vols[wave]["bytes"] += sizes.get(low.get("upn", ""), 0)
    return vols


def plan_wave(users, data_bytes, window_hours, limits):
    gib = data_bytes / (1024 ** 3) if data_bytes else users  # fall back to headcount
    est_items = gib * limits["avg_items_per_gib"] if data_bytes else users * 2000
    est_requests = est_items * limits["requests_per_item"]
    window_secs = max(window_hours * 3600, 1)

    required_rps = est_requests / window_secs
    # the binding ceiling is the lower of the two vendors' throttling limits, minus headroom
    ceiling = min(limits["graph_read_rps"], limits["google_write_rps"]) * (1 - limits["headroom"])
    workers = max(1, int(ceiling // limits["per_worker_rps"]))
    achievable_rps = min(ceiling, workers * limits["per_worker_rps"])

    fits = required_rps <= achievable_rps
    headroom_pct = round((achievable_rps - required_rps) / achievable_rps * 100, 1) if achievable_rps else -100.0
    # pacing: min delay per request per worker to stay at/under the per-worker rate
    pace_ms = round(1000.0 / limits["per_worker_rps"], 1)

    return {
        "users": users,
        "data_gib": round(gib, 2),
        "est_items": int(est_items),
        "est_requests": int(est_requests),
        "required_rps": round(required_rps, 2),
        "ceiling_rps": round(ceiling, 2),
        "recommended_workers": workers,
        "pace_ms_per_request_per_worker": pace_ms,
        "achievable_rps": round(achievable_rps, 2),
        "fits_window": fits,
        "headroom_pct": headroom_pct,
    }


def observe(rate_csv, budget):
    """Compare sampled observed rps against the budgeted ceiling — pass if never sustained-over."""
    breaches = 0
    with open(rate_csv, newline="", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            low = {k.lower(): v for k, v in r.items()}
            wave = low.get("wave", "")
            try:
                rps = float(low.get("observed_rps") or 0)
            except ValueError:
                continue
            ceiling = budget.get(wave, {}).get("ceiling_rps", 0)
            if ceiling and rps > ceiling:
                breaches += 1
    return breaches


def main():
    ap = argparse.ArgumentParser(description="Budget migration throttling against both vendors' limits.")
    ap.add_argument("--waves", required=True, help="waves.csv from wave-batcher.py")
    ap.add_argument("--sizes", help="optional per-user data sizes CSV (upn,data_bytes)")
    ap.add_argument("--limits", help="limits.json (CURRENT tenant/API numbers) — override defaults")
    ap.add_argument("--window-hours", type=float, default=8.0, help="change/migration window per wave")
    ap.add_argument("--report", help="output JSON throttle budget")
    ap.add_argument("--observe", help="sampled rate CSV (wave,observed_rps) to compare to budget")
    args = ap.parse_args()

    limits = load_limits(args.limits)
    if not args.limits:
        print("[warn] using ILLUSTRATIVE default limits — confirm current tenant/API numbers "
              "and pass --limits limits.json before committing a schedule.", file=sys.stderr)

    vols = wave_volumes(args.waves, args.sizes)
    budget = {}
    any_fail = False
    for wave, v in sorted(vols.items()):
        p = plan_wave(v["users"], v["bytes"], args.window_hours, limits)
        budget[wave] = p
        flag = "OK " if p["fits_window"] else "!! "
        if not p["fits_window"]:
            any_fail = True
        print(f"{flag}{wave}: {p['users']}u/{p['data_gib']}GiB -> "
              f"{p['recommended_workers']} workers, pace {p['pace_ms_per_request_per_worker']}ms, "
              f"req {p['required_rps']}rps vs {p['achievable_rps']}rps, headroom {p['headroom_pct']}%")

    if args.observe:
        breaches = observe(args.observe, budget)
        print(f"\nObserved-rate breaches over budget: {breaches} (target 0)")
        any_fail = any_fail or breaches > 0

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump({"window_hours": args.window_hours, "limits": limits, "waves": budget},
                      fh, indent=2)
        print(f"Report written: {args.report}")

    return 0 if not any_fail else 2


if __name__ == "__main__":
    sys.exit(main())
