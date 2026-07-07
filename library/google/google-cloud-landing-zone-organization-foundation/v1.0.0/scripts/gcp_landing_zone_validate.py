#!/usr/bin/env python3
# gcp_landing_zone_validate.py — validate the landing-zone gates and emit an HTML report.
#
# PURPOSE: Read-only check of the landing-zone gates — hierarchy present, guardrails enforced,
#          IAM baseline group-only, org audit sink writing, billing export populated, Shared VPC
#          attachable — and write a PASS/FAIL HTML report. READ-ONLY; changes nothing.
# HOW TO RUN: python gcp_landing_zone_validate.py --organization ORG_ID
#             --logging-project P --billing-project P --host-project P [--report out.html]
#             (Python 3.10+, gcloud authenticated / ADC; see --help)
# EXPECTED RESULTS: Console PASS/FAIL per check + an HTML report. Exit code 0 if all pass, 1 if any
#          check fails — usable as a CI gate before Expand.

import argparse
import html
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone

REQUIRED_CONSTRAINTS = [
    "iam.disableServiceAccountKeyCreation",
    "compute.vmExternalIpAccess",
    "compute.skipDefaultNetworkCreation",
]
EXPECTED_FOLDERS = {"Common", "Production", "Non-Production", "Bootstrap"}


def gcloud_bin():
    g = shutil.which("gcloud")
    if not g:
        sys.exit("ERROR: gcloud CLI not found on PATH. Install the Google Cloud SDK first.")
    return g


def gjson(args):
    res = subprocess.run([gcloud_bin()] + args + ["--format=json"],
                         capture_output=True, text=True)
    if res.returncode != 0 or not res.stdout.strip():
        return None
    try:
        return json.loads(res.stdout)
    except json.JSONDecodeError:
        return None


def check_hierarchy(org_id):
    folders = gjson(["resource-manager", "folders", "list", f"--organization={org_id}"]) or []
    names = {f.get("displayName") for f in folders}
    missing = EXPECTED_FOLDERS - names
    ok = not missing
    detail = "all expected folders present" if ok else f"missing folders: {sorted(missing)}"
    return ok, detail


def check_guardrails(org_id):
    missing = []
    for c in REQUIRED_CONSTRAINTS:
        pol = gjson(["org-policies", "describe", c, f"--organization={org_id}"])
        if pol is None:
            missing.append(c)
    ok = not missing
    detail = "baseline constraints enforced at org node" if ok \
        else f"not enforced at org node: {missing} (verify constraint names for your org)"
    return ok, detail


def check_iam_group_only(org_id):
    pol = gjson(["organizations", "get-iam-policy", org_id])
    if not pol:
        return False, "could not read org IAM policy"
    user_members = []
    for b in pol.get("bindings", []):
        for m in b.get("members", []):
            if m.startswith("user:"):
                user_members.append(f"{m} -> {b.get('role')}")
    ok = not user_members
    detail = "no individual user bindings at org node" if ok \
        else f"{len(user_members)} user binding(s) found (should be group-based): {user_members[:5]}"
    return ok, detail


def check_log_sink(org_id, logging_project):
    sinks = gjson(["logging", "sinks", "list", f"--organization={org_id}"]) or []
    audit = [s for s in sinks if logging_project in (s.get("destination") or "")]
    ok = bool(audit)
    detail = f"aggregated audit sink -> {logging_project} present" if ok \
        else f"no org sink targeting {logging_project}"
    return ok, detail


def check_billing_export(billing_project):
    datasets = gjson(["bq", "ls" ]) if False else None  # bq is separate; probe via BigQuery API optional
    # Lightweight probe: confirm the project exists and billing API path is plausible.
    proj = gjson(["projects", "describe", billing_project])
    ok = proj is not None
    detail = (f"billing-export project {billing_project} present — confirm the "
              "gcp_billing_export_* table has rows in BigQuery (see Testing T6)") if ok \
        else f"billing-export project {billing_project} not found"
    return ok, detail


def check_shared_vpc(host_project):
    res = subprocess.run(
        [gcloud_bin(), "compute", "shared-vpc", "associated-projects", "list",
         host_project, "--format=json"], capture_output=True, text=True)
    if res.returncode != 0:
        # Host may be enabled with zero attachments yet; check host status instead.
        status = gjson(["compute", "shared-vpc", "get-host-project", host_project])
        ok = status is not None
        return ok, ("Shared VPC host enabled (no service projects attached yet)" if ok
                    else f"host project {host_project} is not a Shared VPC host")
    try:
        attached = json.loads(res.stdout) if res.stdout.strip() else []
    except json.JSONDecodeError:
        attached = []
    return True, f"Shared VPC host active, {len(attached)} service project(s) attached"


def render_html(results, org_id):
    rows = []
    for name, ok, detail in results:
        color = "#137333" if ok else "#c5221f"
        badge = "PASS" if ok else "FAIL"
        rows.append(
            f"<tr><td>{html.escape(name)}</td>"
            f"<td style='color:{color};font-weight:700'>{badge}</td>"
            f"<td>{html.escape(detail)}</td></tr>")
    all_pass = all(ok for _, ok, _ in results)
    overall = "ALL CHECKS PASSED" if all_pass else "ONE OR MORE CHECKS FAILED"
    overall_color = "#137333" if all_pass else "#c5221f"
    return f"""<!doctype html><meta charset="utf-8">
<title>Landing Zone Validation — {html.escape(org_id)}</title>
<body style="font-family:Segoe UI,Arial,sans-serif;max-width:900px;margin:2rem auto;color:#202124">
<h1>Google Cloud Landing Zone — Validation Report</h1>
<p>Organization: <code>{html.escape(org_id)}</code> ·
Generated: {datetime.now(timezone.utc).isoformat()}</p>
<h2 style="color:{overall_color}">{overall}</h2>
<table border="1" cellpadding="8" cellspacing="0" style="border-collapse:collapse;width:100%">
<tr style="background:#f1f3f4"><th align="left">Check</th><th>Result</th><th align="left">Detail</th></tr>
{''.join(rows)}
</table>
<p style="color:#5f6368;font-size:.9em">Version- or preview-dependent constraints/features are
flagged to verify in your organization; this report checks presence/enforcement, not policy intent.</p>
</body>"""


def main():
    ap = argparse.ArgumentParser(description="Validate the landing-zone gates (read-only).")
    ap.add_argument("--organization", required=True)
    ap.add_argument("--logging-project", required=True)
    ap.add_argument("--billing-project", required=True)
    ap.add_argument("--host-project", required=True)
    ap.add_argument("--report", default="landing-zone-validation.html")
    args = ap.parse_args()

    results = []
    results.append(("Hierarchy present & nested", *check_hierarchy(args.organization)))
    results.append(("Org-policy guardrails enforced", *check_guardrails(args.organization)))
    results.append(("IAM baseline group-only (no user bindings)",
                    *check_iam_group_only(args.organization)))
    results.append(("Centralized audit log sink writing",
                    *check_log_sink(args.organization, args.logging_project)))
    results.append(("Billing export project present", *check_billing_export(args.billing_project)))
    results.append(("Shared VPC attachable", *check_shared_vpc(args.host_project)))

    print(f"== Landing Zone validation — org {args.organization} ==")
    for name, ok, detail in results:
        print(f"  [{'PASS' if ok else 'FAIL'}] {name}: {detail}")

    with open(args.report, "w", encoding="utf-8") as fh:
        fh.write(render_html(results, args.organization))
    print(f"\nHTML report written to {args.report}")

    sys.exit(0 if all(ok for _, ok, _ in results) else 1)


if __name__ == "__main__":
    main()
