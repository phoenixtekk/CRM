#!/usr/bin/env python3
# gemini_adoption_report.py — Gemini adoption/usage report via Admin SDK Reports API (read-only)
#
# PURPOSE: Read-only adoption measurement. Captures a pre-rollout baseline and per-cohort usage from
#          the Admin SDK Reports API, and evaluates the adoption gate (Gate G3) against a target
#          relative to the baseline. Reads reports only; never changes the tenant.
# HOW TO RUN: python gemini_adoption_report.py --baseline --out adoption-baseline.json
#             python gemini_adoption_report.py --cohort "Pilot-Wave0" --since 2026-07-20 --out pilot.json
#             python gemini_adoption_report.py --cohort "Pilot-Wave0" --against adoption-baseline.json --gate 40
#             (Python 3.10+, gcloud auth / ADC; Admin SDK Reports read-only scope; see --help)
# EXPECTED RESULTS: Usage figures for the window, and with --gate a 'GATE G3: PASS/FAIL' line.
#          Non-zero exit when the gate fails.
#
# NOTES:
#   - SAFE BY DEFAULT: read-only. No --apply; this tool cannot mutate anything.
#   - NO hardcoded credentials/keys — ADC / gcloud auth or an authorized service account (domain-wide
#     delegation for the Reports READ scope only) discovered from the environment. No key in code.
#   - IMPORTANT: the exact Gemini usage metrics / activity events exposed by the Reports API are
#     VERSION-DEPENDENT and evolving. This tool queries the Reports API generically and reports what
#     it finds; where a specific Gemini counter is not present, it says so rather than inventing it.
#     VERIFY IN YOUR TENANT which applications/parameters carry Gemini usage.

import argparse
import json
import sys
from datetime import datetime, timezone, timedelta


REPORTS_SCOPE = "https://www.googleapis.com/auth/admin.reports.usage.readonly"
ACTIVITY_SCOPE = "https://www.googleapis.com/auth/admin.reports.audit.readonly"


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _reports_client():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        return None
    creds, _ = google.auth.default(scopes=[REPORTS_SCOPE, ACTIVITY_SCOPE])
    return build("admin", "reports_v1", credentials=creds, cache_discovery=False)


def _default_date(days_back: int) -> str:
    return (datetime.now(timezone.utc) - timedelta(days=days_back)).strftime("%Y-%m-%d")


def _fetch_customer_usage(client, date: str) -> dict:
    """Fetch customer-level usage for a date. Returns {parameter_name: value} best-effort."""
    params: dict[str, str] = {}
    try:
        resp = client.customerUsageReports().get(date=date).execute()
    except Exception as exc:  # noqa: BLE001 — surface API errors as a note, do not fabricate data
        return {"_error": str(exc)}
    for rec in resp.get("usageReports", []):
        for p in rec.get("parameters", []):
            name = p.get("name", "")
            val = p.get("intValue") or p.get("stringValue") or p.get("boolValue")
            if val is not None:
                params[name] = val
    return params


def _gemini_params(params: dict) -> dict:
    """Filter to parameters that look Gemini/AI-related. Names are version-dependent — verify."""
    hits = {k: v for k, v in params.items()
            if any(tok in k.lower() for tok in ("gemini", "gen_ai", "genai", "duet"))}
    return hits


def cmd_baseline(args) -> int:
    client = _reports_client()
    date = args.since or _default_date(2)  # Reports data lags ~2 days
    print(f"[assess] adoption baseline for {date}")
    if client is None:
        print("  google-api-python-client not installed — install to query the Reports API:")
        print("    pip install google-api-python-client google-auth")
        print("  VERIFY IN YOUR TENANT which Reports API parameters carry Gemini usage.")
        data = {"generated": _iso_now(), "date": date, "mode": "manual", "gemini_params": {}}
    else:
        allp = _fetch_customer_usage(client, date)
        if "_error" in allp:
            print(f"  Reports API error: {allp['_error']} (check scope/date; data lags ~2 days).")
        gp = _gemini_params(allp)
        if not gp:
            print("  No obviously-Gemini usage parameters found at customer level.")
            print("  VERIFY IN YOUR TENANT: Gemini usage may be under app-specific reports/parameters.")
        else:
            for k, v in gp.items():
                print(f"    {k} = {v}")
        data = {"generated": _iso_now(), "date": date, "gemini_params": gp}
    out = args.out or "adoption-baseline.json"
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)
    print(f"[assess] baseline written -> {out}")
    return 0


def cmd_cohort(args) -> int:
    client = _reports_client()
    since = args.since or _default_date(9)
    print(f"[measure] cohort '{args.cohort}' usage since {since}")
    if client is None:
        print("  google-api-python-client not installed — install to query the Reports API.")
        cohort_metric = None
    else:
        # Customer-level counters approximate cohort activity where per-user filtering is applied via
        # activities().list(userKey=...) in a fuller wiring. We report customer-level Gemini params and
        # flag that per-cohort attribution needs the activities feed. VERIFY IN YOUR TENANT.
        allp = _fetch_customer_usage(client, args.since or _default_date(2))
        gp = _gemini_params(allp) if "_error" not in allp else {}
        for k, v in gp.items():
            print(f"    {k} = {v}")
        cohort_metric = gp
        print("  NOTE: per-cohort attribution uses the activities feed (userKey filter); customer-level")
        print("        counters shown here approximate org usage. VERIFY IN YOUR TENANT.")

    report = {"generated": _iso_now(), "cohort": args.cohort, "since": since, "metrics": cohort_metric}
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"[measure] report written -> {args.out}")

    if args.gate is not None:
        return _evaluate_gate(args, report)
    return 0


def _evaluate_gate(args, report: dict) -> int:
    print(f"[gate G3] adoption target: {args.gate}%")
    baseline = None
    if args.against:
        try:
            with open(args.against, "r", encoding="utf-8") as fh:
                baseline = json.load(fh)
        except OSError as exc:
            print(f"  cannot read baseline {args.against}: {exc}")
    metrics = report.get("metrics") or {}
    if not metrics:
        print("  No adoption metric available to evaluate. GATE G3: INDETERMINATE —")
        print("  VERIFY IN YOUR TENANT which Reports parameter represents active Gemini users, then")
        print("  re-run with a concrete --metric. Not treating an unknown metric as PASS.")
        return 2
    # If an active-user count and a cohort size are available, compute a percentage; otherwise report
    # the raw metric and defer the pass/fail to a concrete, tenant-verified metric.
    if args.active_metric and args.cohort_size:
        active = int(metrics.get(args.active_metric, 0))
        pct = (active / args.cohort_size) * 100 if args.cohort_size else 0
        print(f"  active={active}  cohort_size={args.cohort_size}  adoption={pct:.1f}%")
        if pct >= args.gate:
            print("GATE G3: PASS")
            return 0
        print("GATE G3: FAIL — adoption below target; remediate readiness/training before expanding.")
        return 1
    print("  Provide --active-metric <param> and --cohort-size <n> for a computed gate.")
    print("GATE G3: INDETERMINATE — VERIFY IN YOUR TENANT and supply a concrete active-user metric.")
    return 2


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Gemini adoption/usage report via Reports API (read-only).")
    p.add_argument("--baseline", action="store_true", help="Capture the pre-rollout adoption baseline.")
    p.add_argument("--cohort", default=None, help="Cohort name to report on.")
    p.add_argument("--since", default=None, help="Start date YYYY-MM-DD (Reports data lags ~2 days).")
    p.add_argument("--against", default=None, help="Baseline JSON to compare against (for --gate).")
    p.add_argument("--gate", type=float, default=None, help="Adoption target %% (Gate G3).")
    p.add_argument("--active-metric", default=None, help="Reports parameter representing active users.")
    p.add_argument("--cohort-size", type=int, default=None, help="Cohort size for the adoption percentage.")
    p.add_argument("--out", default=None, help="Write the report/baseline JSON here.")
    return p


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    if args.baseline:
        return cmd_baseline(args)
    if args.cohort:
        return cmd_cohort(args)
    print("Nothing to do. Pass --baseline or --cohort <name>.")
    return 2


if __name__ == "__main__":
    sys.exit(main())
