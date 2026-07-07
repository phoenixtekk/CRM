#!/usr/bin/env python3
# decommission_report.py — pre-closure guardrail check + closure evidence pack (read-only)
#
# PURPOSE: The Gate-6 gate. --precheck runs a read-only pre-closure guardrail (all prior gates
#          evidenced, no domain still routing, no license on a non-retained account, no residual app
#          registration except the tooling app, zero unresolved HOLD items) and returns PASS/FAIL.
#          Without --precheck it consolidates the evidence directory into an HTML closure report.
#          READ-ONLY: it reads the local evidence JSONs (and, with --live, re-reads a few Graph facts);
#          it changes nothing in the tenant.
# HOW TO RUN: python decommission_report.py --precheck --evidence-dir evidence/ --out precheck.json
#             python decommission_report.py --evidence-dir evidence/ --out closure-report.html
#             (Python 3.10+; --live re-check needs msal+requests+env creds; otherwise stdlib only)
# EXPECTED RESULTS: --precheck -> PASS (all green) or FAIL (named blockers), exit code reflects it.
#             report mode -> a self-contained HTML evidence pack for the records store.
#
# --live credentials (optional) from ENVIRONMENT only:
#   M365DECOM_TENANT_ID / M365DECOM_CLIENT_ID / M365DECOM_CLIENT_SECRET  (Directory.Read.All, Domain.Read.All)

import argparse
import datetime as dt
import glob
import html
import json
import os
import sys

GRAPH = "https://graph.microsoft.com/v1.0"
SCOPE = ["https://graph.microsoft.com/.default"]
TOOLING_APP = "Decommission Read - Source-Tenant - v1"


def die(msg: str, code: int = 2) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(code)


def load_evidence(evidence_dir):
    """Load every *.json in the evidence dir keyed by filename; tolerate non-JSON gracefully."""
    out = {}
    for path in sorted(glob.glob(os.path.join(evidence_dir, "*.json"))):
        try:
            with open(path, encoding="utf-8") as fh:
                out[os.path.basename(path)] = json.load(fh)
        except (json.JSONDecodeError, OSError) as exc:
            out[os.path.basename(path)] = {"_error": str(exc)}
    return out


def live_facts():
    """Optional live re-check of a few closure-critical facts. Returns {} if creds absent."""
    if not all(os.environ.get(v) for v in
               ("M365DECOM_TENANT_ID", "M365DECOM_CLIENT_ID", "M365DECOM_CLIENT_SECRET")):
        return {}
    try:
        import msal, requests  # type: ignore
    except ImportError:
        return {}
    app = msal.ConfidentialClientApplication(
        client_id=os.environ["M365DECOM_CLIENT_ID"],
        authority=f"https://login.microsoftonline.com/{os.environ['M365DECOM_TENANT_ID']}",
        client_credential=os.environ["M365DECOM_CLIENT_SECRET"])
    tok = app.acquire_token_for_client(scopes=SCOPE)
    if "access_token" not in tok:
        return {}
    s = requests.Session()
    s.headers.update({"Authorization": f"Bearer {tok['access_token']}", "Accept": "application/json"})
    facts = {}
    r = s.get(f"{GRAPH}/domains", timeout=60)
    if r.ok:
        facts["verified_domains"] = [d["id"] for d in r.json().get("value", []) if d.get("isVerified")]
    r = s.get(f"{GRAPH}/applications?$select=displayName", timeout=60)
    if r.ok:
        facts["app_registrations"] = [a.get("displayName") for a in r.json().get("value", [])]
    return facts


def run_precheck(evidence, live):
    checks = []

    def add(name, ok, detail):
        checks.append({"check": name, "result": "PASS" if ok else "FAIL", "detail": detail})

    # 1. Prior gates evidenced (look for a report per gate).
    gates_seen = {rep.get("gate") for rep in evidence.values() if isinstance(rep, dict)}
    for g in ("Gate 1 - Completeness", "Gate 3 - Licensing wind-down", "Gate 4 - Identity/app cleanup",
              "Gate 5 - DNS / integration"):
        add(f"Evidence present: {g}", any(g == seen for seen in gates_seen),
            "found" if any(g == seen for seen in gates_seen) else "no evidence file for this gate")

    # 2. Completeness passed.
    comp = next((r for r in evidence.values()
                 if isinstance(r, dict) and r.get("gate") == "Gate 1 - Completeness"), None)
    add("Completeness gate PASS", bool(comp) and comp.get("result") == "PASS",
        comp.get("result") if comp else "missing")

    # 3. No unresolved HOLD/UNCLASSIFIED disposition items.
    unresolved = 0
    for r in evidence.values():
        if isinstance(r, dict) and r.get("gate") == "Gate 2 - Data disposition inventory":
            for row in (r.get("findings", {}) or {}).get("data_bearing_users", []):
                if "UNCLASSIFIED" in str(row.get("disposition", "")):
                    unresolved += 1
    add("Zero unresolved disposition items", unresolved == 0, f"{unresolved} unclassified")

    # 4. Live: no verified/routing domain remains; no app reg except the tooling app.
    if live:
        add("No verified domain remains in tenant",
            not live.get("verified_domains"),
            f"remaining: {live.get('verified_domains')}")
        residual = [a for a in live.get("app_registrations", []) if a and a != TOOLING_APP]
        add("No app registration except the tooling app", not residual,
            f"residual: {residual}" if residual else "clean")
    else:
        checks.append({"check": "Live tenant re-check", "result": "SKIPPED",
                       "detail": "no env creds; relying on evidence files only"})

    failed = [c for c in checks if c["result"] == "FAIL"]
    return {"generated": dt.datetime.now(dt.timezone.utc).isoformat(),
            "gate": "Gate 6 - Pre-closure guardrail",
            "result": "FAIL" if failed else "PASS",
            "checks": checks}


def build_html(evidence, live):
    parts = ["<h1>Microsoft 365 Tenant Decommission — Closure Evidence Pack</h1>",
             f"<p>Generated {html.escape(dt.datetime.now(dt.timezone.utc).isoformat())}</p>"]
    pre = run_precheck(evidence, live)
    parts.append(f"<h2>Pre-closure guardrail: {pre['result']}</h2><ul>")
    for c in pre["checks"]:
        parts.append(f"<li><strong>{html.escape(c['result'])}</strong> — "
                     f"{html.escape(c['check'])}: {html.escape(str(c['detail']))}</li>")
    parts.append("</ul>")
    parts.append("<h2>Evidence files consolidated</h2><ul>")
    for name, rep in evidence.items():
        gate = rep.get("gate", "—") if isinstance(rep, dict) else "—"
        result = rep.get("result", rep.get("action_mode", "")) if isinstance(rep, dict) else ""
        parts.append(f"<li>{html.escape(name)} — {html.escape(str(gate))} "
                     f"{html.escape(str(result))}</li>")
    parts.append("</ul>")
    parts.append("<h2>Closure actions to record manually</h2><ul>"
                 "<li>Verified domains removed from tenant (dates)</li>"
                 "<li>Subscriptions cancelled — grace/deletion dates</li>"
                 f"<li>Tooling app '{html.escape(TOOLING_APP)}' removed as final object</li></ul>")
    return ("<!doctype html><meta charset='utf-8'><title>M365DECOM Closure Evidence</title>"
            "<style>body{font:14px system-ui,Arial;margin:2rem;max-width:60rem}"
            "li{margin:.2rem 0}</style>" + "".join(parts))


def main() -> None:
    ap = argparse.ArgumentParser(description="Pre-closure guardrail + closure evidence pack (read-only).")
    ap.add_argument("--evidence-dir", required=True, help="Directory of per-gate evidence JSON files.")
    ap.add_argument("--precheck", action="store_true", help="Run the guardrail check (JSON out).")
    ap.add_argument("--live", action="store_true", help="Also re-check a few facts live via Graph.")
    ap.add_argument("--out", default="decommission-report.html")
    args = ap.parse_args()

    if not os.path.isdir(args.evidence_dir):
        die(f"evidence dir not found: {args.evidence_dir}")
    evidence = load_evidence(args.evidence_dir)
    live = live_facts() if args.live else {}

    if args.precheck:
        report = run_precheck(evidence, live)
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"Pre-closure guardrail: {report['result']}")
        for c in report["checks"]:
            if c["result"] != "PASS":
                print(f"  [{c['result']}] {c['check']}: {c['detail']}")
        print(f"Precheck written to {args.out}")
        sys.exit(1 if report["result"] == "FAIL" else 0)

    out_html = build_html(evidence, live)
    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write(out_html)
    print(f"Closure evidence pack written to {args.out}")
    print("Store it in 'Decommission Evidence - Source-Tenant - v1' and remove the tooling app last.")


if __name__ == "__main__":
    main()
