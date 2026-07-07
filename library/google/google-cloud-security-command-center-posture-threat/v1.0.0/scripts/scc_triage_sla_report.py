#!/usr/bin/env python3
# scc_triage_sla_report.py — generate a finding triage + remediation-SLA report (read-only).
#
# PURPOSE: Pulls ACTIVE SCC findings, maps each to its owner and a severity->SLA target from
#          Triage Runbook - SecOps - v1, computes due dates and at-risk/breached flags, and emits an
#          HTML triage report. READ-ONLY: it never changes findings or configuration.
# HOW TO RUN: python scc_triage_sla_report.py --organization ORG_ID --runbook runbook.yaml \
#              [--out triage-sla.html]   (Python 3.10+, gcloud auth / ADC; see --help)
# EXPECTED RESULTS: An HTML report listing active findings with severity, age, owner, SLA due date,
#          and an OK / AT-RISK / BREACHED status. Prints a summary to stdout.
#
# NOTE: Finding shape/fields are edition-dependent; the tool reads common fields defensively and
#       falls back to UNSPECIFIED. Uses `gcloud` via subprocess (no keys in code, uses ADC).

import argparse
import datetime as dt
import html
import json
import subprocess
import sys

try:
    import yaml
except ImportError:
    yaml = None

# Fallback severity->remediation-SLA (hours) if the runbook omits one. Starting point, not a mandate.
DEFAULT_SLA_HOURS = {"CRITICAL": 24, "HIGH": 72, "MEDIUM": 336, "LOW": 720}


def run_gcloud_json(args):
    cmd = ["gcloud"] + args + ["--format=json"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    except FileNotFoundError:
        print("ERROR: gcloud not found on PATH.", file=sys.stderr)
        sys.exit(2)
    if proc.returncode != 0:
        print(f"WARN: gcloud returned {proc.returncode}: {proc.stderr.strip()}", file=sys.stderr)
        return []
    try:
        return json.loads(proc.stdout or "[]")
    except json.JSONDecodeError:
        return []


def load_runbook(path):
    if not path:
        return {"sla_hours": {}, "owners": []}
    if yaml is None:
        print("ERROR: PyYAML required for --runbook (pip install pyyaml).", file=sys.stderr)
        sys.exit(2)
    with open(path, encoding="utf-8") as fh:
        data = yaml.safe_load(fh) or {}
    return {"sla_hours": data.get("sla_hours", {}), "owners": data.get("owners", [])}


def parse_time(value):
    if not value:
        return None
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (ValueError, AttributeError):
        return None


def owner_for(finding, owners):
    """Match a finding to an owner rule by resource/category substring; first match wins."""
    resource = (finding.get("resourceName") or "")
    category = (finding.get("category") or "")
    for rule in owners:
        match = rule.get("match", "")
        if match and (match in resource or match in category):
            return rule.get("owner", "unassigned")
    return "unassigned"


def status_for(due, now):
    if due is None:
        return "UNKNOWN"
    remaining = (due - now).total_seconds() / 3600.0
    if remaining < 0:
        return "BREACHED"
    if remaining < 24:
        return "AT-RISK"
    return "OK"


def main():
    ap = argparse.ArgumentParser(description="Read-only SCC triage + SLA report generator.")
    ap.add_argument("--organization", required=True, help="Organization ID (numeric).")
    ap.add_argument("--runbook", help="YAML runbook: sla_hours + owners (Triage Runbook - SecOps - v1).")
    ap.add_argument("--out", default="triage-sla.html", help="Output HTML path.")
    args = ap.parse_args()

    org = args.organization.split("/")[-1]
    runbook = load_runbook(args.runbook)
    sla_hours = {**DEFAULT_SLA_HOURS, **{k.upper(): v for k, v in runbook["sla_hours"].items()}}
    now = dt.datetime.now(dt.timezone.utc)

    raw = run_gcloud_json(["scc", "findings", "list", org, "--filter", 'state="ACTIVE"'])
    rows = []
    counts = {"OK": 0, "AT-RISK": 0, "BREACHED": 0, "UNKNOWN": 0}
    for item in raw:
        finding = item.get("finding", item) if isinstance(item, dict) else {}
        sev = (finding.get("severity") or "UNSPECIFIED").upper()
        created = parse_time(finding.get("createTime") or finding.get("eventTime"))
        hours = sla_hours.get(sev)
        due = created + dt.timedelta(hours=hours) if (created and hours) else None
        status = status_for(due, now)
        counts[status] = counts.get(status, 0) + 1
        rows.append({
            "category": finding.get("category", "UNSPECIFIED"),
            "severity": sev,
            "resource": finding.get("resourceName", ""),
            "created": created.isoformat() if created else "",
            "due": due.isoformat() if due else "",
            "owner": owner_for(finding, runbook["owners"]),
            "status": status,
        })

    # Sort worst-first: BREACHED, AT-RISK, then by severity.
    sev_rank = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}
    status_rank = {"BREACHED": 0, "AT-RISK": 1, "OK": 2, "UNKNOWN": 3}
    rows.sort(key=lambda r: (status_rank.get(r["status"], 9), sev_rank.get(r["severity"], 9)))

    write_html(args.out, org, rows, counts, now)
    print(f"Triage/SLA report — org {org}: {len(rows)} active findings")
    print(f"  BREACHED={counts.get('BREACHED',0)}  AT-RISK={counts.get('AT-RISK',0)}  "
          f"OK={counts.get('OK',0)}  UNKNOWN={counts.get('UNKNOWN',0)}")
    print(f"  Wrote {args.out}")
    # Non-zero exit if anything is breached — useful for scheduled runs.
    sys.exit(1 if counts.get("BREACHED", 0) else 0)


def write_html(path, org, rows, counts, now):
    def esc(v):
        return html.escape(str(v))
    color = {"BREACHED": "#c0392b", "AT-RISK": "#e67e22", "OK": "#27ae60", "UNKNOWN": "#7f8c8d"}
    body = [
        "<h1>SCC Triage &amp; Remediation-SLA Report</h1>",
        f"<p>Organization {esc(org)} — generated {esc(now.isoformat())} (UTC)</p>",
        "<p>Findings mapped to owners and severity-based SLAs per "
        "<em>Triage Runbook - SecOps - v1</em>. SCC editions/detectors are version-dependent.</p>",
        "<p><strong>Summary:</strong> "
        + " · ".join(f"{k}: {counts.get(k, 0)}" for k in ["BREACHED", "AT-RISK", "OK", "UNKNOWN"])
        + "</p>",
        "<table border='1' cellpadding='6' cellspacing='0' style='border-collapse:collapse'>",
        "<tr><th>Status</th><th>Severity</th><th>Category</th><th>Owner</th>"
        "<th>Created</th><th>SLA due</th><th>Resource</th></tr>",
    ]
    for r in rows:
        body.append(
            f"<tr><td style='color:{color.get(r['status'], '#000')};font-weight:bold'>"
            f"{esc(r['status'])}</td><td>{esc(r['severity'])}</td><td>{esc(r['category'])}</td>"
            f"<td>{esc(r['owner'])}</td><td>{esc(r['created'])}</td><td>{esc(r['due'])}</td>"
            f"<td>{esc(r['resource'])}</td></tr>")
    body.append("</table>")
    doc = ("<!doctype html><html><head><meta charset='utf-8'>"
           "<title>SCC Triage/SLA Report</title>"
           "<style>body{font-family:sans-serif;margin:2rem}th{background:#f0f0f0}</style>"
           "</head><body>" + "".join(body) + "</body></html>")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(doc)


if __name__ == "__main__":
    main()
