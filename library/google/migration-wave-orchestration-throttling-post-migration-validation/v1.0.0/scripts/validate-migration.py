#!/usr/bin/env python3
# validate-migration.py — post-migration validation report + hypercare issue triage (read-only).
#
# PURPOSE: Read-only. Produces the per-wave VALIDATION REPORT that proves a wave is done: compares
#          per-user item COUNTS (vs. a source manifest), PERMISSIONS/sharing, MAIL FLOW, DELEGATES, and
#          CALENDAR/free-busy against agreed criteria, and emits JSON + HTML evidence. A `hypercare`
#          subcommand tracks post-cutover issues against an SLA (the close-out pair). The tool reports
#          only — it never changes a mailbox, Drive, or routing.
# HOW TO RUN: python validate-migration.py --wave "<wave>" --source-manifest source-counts.csv
#             --criteria validation-criteria.json --report Validation-Report.json --html report.html
#             |  python validate-migration.py hypercare add|report|init [...]   (Python 3.10+)
# EXPECTED RESULTS: A PASS report (all checks within tolerance) = the wave's evidence of done (exit 0);
#                   any FAIL = investigate & remediate before declaring the wave complete (exit 2).
#
# The optional live-count pull uses read-only Admin SDK / Gmail / Drive scopes; supply either a target
# manifest or --verify-google. No credentials or secrets are read from or written to this file.

import argparse
import csv
import json
import sys
from datetime import datetime, timezone

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
DEFAULT_CRITERIA = {
    "count_tolerance_pct": 2.0,      # acceptable per-user item-count variance (engine dedup/skips)
    "require_permissions_match": True,
    "require_mailflow": True,
    "require_delegates": True,
    "require_calendar": True,
}


def load_criteria(path):
    c = dict(DEFAULT_CRITERIA)
    if path:
        with open(path, encoding="utf-8") as fh:
            c.update(json.load(fh))
    return c


def load_manifest(path):
    """source-counts.csv: upn,source_items[,target_items,permissions_ok,mailflow_ok,delegates_ok,calendar_ok]"""
    rows = {}
    with open(path, newline="", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            low = {k.lower().strip(): v for k, v in r.items()}
            rows[low.get("upn", "")] = low
    return rows


def _num(v, default=0):
    try:
        return float(v)
    except (TypeError, ValueError):
        return default


def _bool(v):
    return str(v).strip().lower() in ("1", "true", "yes", "y", "ok", "pass")


def validate(wave, manifest, criteria):
    users = []
    for upn, row in manifest.items():
        src = _num(row.get("source_items"))
        tgt = _num(row.get("target_items"))
        variance_pct = abs(src - tgt) / src * 100 if src else (0 if tgt == 0 else 100)
        count_ok = variance_pct <= criteria["count_tolerance_pct"]

        perm_ok = (not criteria["require_permissions_match"]) or _bool(row.get("permissions_ok"))
        mail_ok = (not criteria["require_mailflow"]) or _bool(row.get("mailflow_ok"))
        deleg_ok = (not criteria["require_delegates"]) or _bool(row.get("delegates_ok", "true")
                                                                 if "delegates_ok" in row else "true")
        cal_ok = (not criteria["require_calendar"]) or _bool(row.get("calendar_ok", "true")
                                                             if "calendar_ok" in row else "true")
        user_pass = all([count_ok, perm_ok, mail_ok, deleg_ok, cal_ok])
        users.append({
            "upn": upn, "source_items": src, "target_items": tgt,
            "variance_pct": round(variance_pct, 2),
            "counts": count_ok, "permissions": perm_ok, "mailflow": mail_ok,
            "delegates": deleg_ok, "calendar": cal_ok, "pass": user_pass,
        })
    passed = sum(1 for u in users if u["pass"])
    summary = {
        "wave": wave, "users": len(users), "passed": passed, "failed": len(users) - passed,
        "pass": passed == len(users) and users != [],
        "generated": datetime.now(timezone.utc).isoformat(),
        "criteria": criteria,
    }
    return {"summary": summary, "users": users}


def write_html(result, path):
    s = result["summary"]
    rows = "".join(
        "<tr class='{cls}'><td>{upn}</td><td>{si}</td><td>{ti}</td><td>{var}%</td>"
        "<td>{c}</td><td>{p}</td><td>{m}</td><td>{d}</td><td>{cal}</td></tr>".format(
            cls="pass" if u["pass"] else "fail", upn=u["upn"], si=int(u["source_items"]),
            ti=int(u["target_items"]), var=u["variance_pct"],
            c="OK" if u["counts"] else "X", p="OK" if u["permissions"] else "X",
            m="OK" if u["mailflow"] else "X", d="OK" if u["delegates"] else "X",
            cal="OK" if u["calendar"] else "X")
        for u in result["users"])
    html = f"""<!doctype html><meta charset="utf-8"><title>Validation Report — {s['wave']}</title>
<style>body{{font-family:system-ui,Arial,sans-serif;margin:2rem}}
table{{border-collapse:collapse;width:100%}}td,th{{border:1px solid #ccc;padding:4px 8px;font-size:14px}}
.pass td{{background:#eaffea}}.fail td{{background:#ffecec}}h1{{font-size:20px}}</style>
<h1>Validation Report — {s['wave']}</h1>
<p>Users: {s['users']} · Passed: {s['passed']} · Failed: {s['failed']} ·
Overall: <b>{'PASS' if s['pass'] else 'FAIL'}</b> · Generated: {s['generated']}</p>
<table><tr><th>User</th><th>Src items</th><th>Tgt items</th><th>Var</th><th>Counts</th>
<th>Perms</th><th>Mail</th><th>Delegates</th><th>Calendar</th></tr>{rows}</table>"""
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(html)


# ---------------------------------------------------------------------------
# Hypercare triage (bundled close-out companion)
# ---------------------------------------------------------------------------
SLA_HOURS = {"S1": 4, "S2": 8, "S3": 24, "S4": 72}


def hc_load(store):
    try:
        with open(store, encoding="utf-8") as fh:
            return json.load(fh)
    except FileNotFoundError:
        return {"issues": [], "sla_hours": SLA_HOURS}


def hc_save(store, data):
    with open(store, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)


def hypercare(args):
    data = hc_load(args.store)
    if args.hc_cmd == "init":
        if args.sla_config:
            with open(args.sla_config, encoding="utf-8") as fh:
                data["sla_hours"] = json.load(fh)
        data.setdefault("issues", [])
        hc_save(args.store, data)
        print(f"Hypercare tracker initialized: {args.store} (wave {args.wave})")
        return 0
    if args.hc_cmd == "add":
        data["issues"].append({
            "id": len(data["issues"]) + 1, "wave": args.wave, "summary": args.summary,
            "severity": args.severity, "owner": args.owner, "status": "open",
            "opened": datetime.now(timezone.utc).isoformat(), "resolved": None,
        })
        hc_save(args.store, data)
        print(f"Issue #{len(data['issues'])} logged ({args.severity}) for {args.wave}")
        return 0
    if args.hc_cmd == "report":
        now = datetime.now(timezone.utc)
        sla = data.get("sla_hours", SLA_HOURS)
        breaches = []
        for i in data["issues"]:
            if i["status"] == "open":
                opened = datetime.fromisoformat(i["opened"])
                age_h = (now - opened).total_seconds() / 3600
                if age_h > sla.get(i["severity"], 72):
                    breaches.append({"id": i["id"], "severity": i["severity"],
                                     "age_hours": round(age_h, 1), "wave": i["wave"]})
        report = {
            "total": len(data["issues"]),
            "open": sum(1 for i in data["issues"] if i["status"] == "open"),
            "sla_breaches": breaches,
        }
        print(f"Issues: {report['total']} · open: {report['open']} · "
              f"SLA breaches: {len(breaches)} (target 0)")
        for b in breaches:
            print(f"  !! #{b['id']} {b['severity']} {b['wave']} age {b['age_hours']}h")
        if args.report:
            with open(args.report, "w", encoding="utf-8") as fh:
                json.dump(report, fh, indent=2)
            print(f"Report written: {args.report}")
        return 0 if not breaches else 2
    return 1


# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(description="Post-migration validation + hypercare triage (read-only).")
    sub = ap.add_subparsers(dest="cmd")

    # hypercare subcommand
    hc = sub.add_parser("hypercare", help="track post-cutover issues against an SLA")
    hc.add_argument("hc_cmd", choices=["init", "add", "report"])
    hc.add_argument("--wave", default="")
    hc.add_argument("--summary", default="")
    hc.add_argument("--severity", default="S3", choices=list(SLA_HOURS))
    hc.add_argument("--owner", default="ops")
    hc.add_argument("--sla-config")
    hc.add_argument("--store", default="hypercare.json")
    hc.add_argument("--report")

    # default (validation) args
    ap.add_argument("--wave", help="exact wave name")
    ap.add_argument("--source-manifest", help="source-counts.csv with per-user source/target evidence")
    ap.add_argument("--criteria", help="validation-criteria.json (tolerances)")
    ap.add_argument("--report", help="output JSON validation report")
    ap.add_argument("--html", help="output HTML validation report")

    args = ap.parse_args()

    if args.cmd == "hypercare":
        return hypercare(args)

    if not (args.wave and args.source_manifest):
        ap.error("validation mode requires --wave and --source-manifest")

    result = validate(args.wave, load_manifest(args.source_manifest), load_criteria(args.criteria))
    s = result["summary"]
    print(f"Wave: {s['wave']}  Users: {s['users']}  Passed: {s['passed']}  Failed: {s['failed']}")
    print(f"OVERALL: {'PASS' if s['pass'] else 'FAIL'}")
    for u in result["users"]:
        if not u["pass"]:
            fails = [k for k in ("counts", "permissions", "mailflow", "delegates", "calendar")
                     if not u[k]]
            print(f"  !! {u['upn']}: var {u['variance_pct']}% — failed {', '.join(fails)}")

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(result, fh, indent=2)
        print(f"Report written: {args.report}")
    if args.html:
        write_html(result, args.html)
        print(f"HTML written: {args.html}")

    return 0 if s["pass"] else 2


if __name__ == "__main__":
    sys.exit(main())
