#!/usr/bin/env python3
# sso_validation_report.py — validate the app catalog for completeness + cert expiry (read-only report)
#
# PURPOSE: Reconcile `App Catalog - Federated SaaS - v1` for governance completeness and emit an
#          HTML + JSON report flagging apps that are missing an owner, an assignment group, a
#          provisioning method, or whose IdP signing certificate is expiring within a warning window.
#          Optionally verifies each assignment group exists via the Admin SDK (read-only).
# HOW TO RUN: python sso_validation_report.py --catalog catalog.csv [--check-groups] \
#               [--warn-days 45] [--out validation.html] [--json validation.json]
#             (Python 3.10+, gcloud auth / ADC for --check-groups; see --help)
# EXPECTED RESULTS: A pass/warn/fail summary on stdout and an HTML report; exit code 0 when clean,
#          1 when any app has a FAIL finding (missing required governance fields).
#
# Catalog CSV columns (header required; extras ignored):
#   app,type,name_id,assignment_group,provisioning,owner,cert_expiry,status
#     - provisioning: auto | scim | jit | manual
#     - cert_expiry:  ISO date YYYY-MM-DD (Google IdP signing cert), may be blank
#
# SAFETY: read-only. Only the read-only Directory scope is used (group existence). No writes to the
#         tenant, no credentials in code (ADC).

import argparse
import csv
import datetime as dt
import html
import json
import sys

DIRECTORY_RO_SCOPE = "https://www.googleapis.com/auth/admin.directory.group.readonly"
VALID_PROVISIONING = {"auto", "scim", "jit", "manual"}


def load_catalog(path):
    with open(path, newline="", encoding="utf-8") as fh:
        rows = [dict(r) for r in csv.DictReader(fh)]
    return [{k: (v or "").strip() for k, v in r.items()} for r in rows if (r.get("app") or "").strip()]


def build_directory_service():
    try:
        import google.auth
        from googleapiclient.discovery import build
        creds, _ = google.auth.default(scopes=[DIRECTORY_RO_SCOPE])
        return build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    except ImportError:
        print("[!] --check-groups needs: pip install google-api-python-client google-auth",
              file=sys.stderr)
    except Exception as exc:  # noqa: BLE001
        print(f"[!] Directory API unavailable ({exc}); skipping group checks.", file=sys.stderr)
    return None


def group_exists(service, email):
    if not (service and email):
        return None
    try:
        service.groups().get(groupKey=email).execute()
        return True
    except Exception:  # noqa: BLE001
        return False


def evaluate(app, warn_days, today, group_present):
    findings = []  # (severity, message); severity in {FAIL, WARN}
    if not app.get("owner"):
        findings.append(("FAIL", "missing owner"))
    if not app.get("assignment_group"):
        findings.append(("FAIL", "no assignment group (access must be group-driven)"))
    elif group_present is False:
        findings.append(("FAIL", f"assignment group '{app['assignment_group']}' not found"))
    prov = app.get("provisioning", "").lower()
    if not prov:
        findings.append(("FAIL", "no provisioning method recorded"))
    elif prov not in VALID_PROVISIONING:
        findings.append(("WARN", f"unrecognized provisioning '{prov}'"))
    if not app.get("type"):
        findings.append(("WARN", "no federation type (saml/oidc) recorded"))

    ce = app.get("cert_expiry", "")
    if ce:
        try:
            expiry = dt.date.fromisoformat(ce)
            days = (expiry - today).days
            if days < 0:
                findings.append(("FAIL", f"IdP cert EXPIRED {abs(days)}d ago ({ce})"))
            elif days <= warn_days:
                findings.append(("WARN", f"IdP cert expires in {days}d ({ce})"))
        except ValueError:
            findings.append(("WARN", f"cert_expiry not ISO date: '{ce}'"))
    else:
        findings.append(("WARN", "no cert_expiry tracked"))
    return findings


def worst(findings):
    if any(s == "FAIL" for s, _ in findings):
        return "FAIL"
    if any(s == "WARN" for s, _ in findings):
        return "WARN"
    return "PASS"


def render_html(results, warn_days):
    color = {"PASS": "#137333", "WARN": "#b06000", "FAIL": "#b00020"}
    parts = ["<!doctype html><meta charset='utf-8'><title>SSO Validation Report</title>",
             "<h1>App Catalog - Federated SaaS - v1 — Validation Report</h1>",
             f"<p>Generated {dt.date.today().isoformat()} · cert warning window {warn_days}d</p>",
             "<table border='1' cellpadding='6' cellspacing='0'>",
             "<tr><th>App</th><th>Type</th><th>Group</th><th>Provisioning</th>"
             "<th>Owner</th><th>Cert expiry</th><th>Status</th><th>Findings</th></tr>"]
    for r in results:
        st = r["status"]
        notes = "<br>".join(f"{s}: {html.escape(m)}" for s, m in r["findings"]) or "ok"
        parts.append(
            "<tr>" + "".join(
                f"<td>{html.escape(str(r['app'].get(c, '')))}</td>"
                for c in ("app", "type", "assignment_group", "provisioning", "owner", "cert_expiry")
            ) + f"<td style='color:{color[st]};font-weight:bold'>{st}</td><td>{notes}</td></tr>")
    parts.append("</table>")
    return "\n".join(parts)


def main(argv=None):
    ap = argparse.ArgumentParser(description="Read-only catalog validation + cert-expiry report.")
    ap.add_argument("--catalog", required=True, help="path to the app catalog CSV")
    ap.add_argument("--check-groups", action="store_true", help="verify groups via Admin SDK (read-only)")
    ap.add_argument("--warn-days", type=int, default=45, help="cert-expiry warning window (days)")
    ap.add_argument("--out", help="path to write the HTML report")
    ap.add_argument("--json", dest="json_out", help="path to write the JSON report")
    args = ap.parse_args(argv)

    try:
        catalog = load_catalog(args.catalog)
    except OSError as exc:
        print(f"[x] cannot read catalog: {exc}", file=sys.stderr)
        return 2
    if not catalog:
        print("[x] catalog is empty.", file=sys.stderr)
        return 2

    service = build_directory_service() if args.check_groups else None
    today = dt.date.today()

    results, counts = [], {"PASS": 0, "WARN": 0, "FAIL": 0}
    for app in catalog:
        gp = group_exists(service, app.get("assignment_group")) if service else None
        findings = evaluate(app, args.warn_days, today, gp)
        status = worst(findings)
        counts[status] += 1
        results.append({"app": app, "findings": findings, "status": status})

    print("\nSSO Validation Report (read-only)\n" + "=" * 60)
    for r in results:
        print(f"[{r['status']:<4}] {r['app']['app']}")
        for sev, msg in r["findings"]:
            print(f"        - {sev}: {msg}")
    print("=" * 60)
    print(f"PASS={counts['PASS']}  WARN={counts['WARN']}  FAIL={counts['FAIL']}  "
          f"(of {len(results)} apps)")

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(render_html(results, args.warn_days))
        print(f"[i] wrote {args.out}")
    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as fh:
            json.dump({"results": results, "counts": counts}, fh, indent=2)
        print(f"[i] wrote {args.json_out}")

    return 1 if counts["FAIL"] else 0


if __name__ == "__main__":
    sys.exit(main())
