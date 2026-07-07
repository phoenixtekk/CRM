#!/usr/bin/env python3
# gwsdk_schedule_config_helper.py — scheduling & config helper for the toolkit (read-only, generates config)
#
# PURPOSE: Read-only / generative. Emit "Schedule Definition – Reports – Expand": the exact command
#          lines and cron / Cloud Scheduler / Windows Task Scheduler entries to run the toolkit's
#          reports on a cadence, plus the least-scope service-identity requirements each needs.
#          Also validates a scope->task inventory. Makes NO Google API calls and NO changes.
# HOW TO RUN: python gwsdk_schedule_config_helper.py --subject reports-admin@corp.example \
#             --out ./reports --format cron              (Python 3.10+; no Google auth needed)
# EXPECTED RESULTS: Printed + written scheduler snippets and the required minimal scope per job.
#                   Exit 0 on success.
#
# No secrets in code: this tool only renders config; it never reads or embeds credentials.

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone

ARTIFACT = "Schedule Definition – Reports – Expand"

# Each toolkit job: the command, its cadence, and the MINIMAL scope it requires (least scope).
JOBS = [
    {"name": "Discovery Report – Tenant – Assess", "script": "gwsdk_tenant_discovery.py",
     "args": "--subject {subject} --out {out}", "cron": "0 6 * * 1",
     "scope": "admin.directory.user.readonly"},
    {"name": "Sharing Report – External – Validate", "script": "gwsdk_sharing_audit_report.py",
     "args": "--subject {subject} --report sharing --domain {domain} --out {out}", "cron": "0 5 * * *",
     "scope": "drive.readonly"},
    {"name": "Audit Report – Login – Validate", "script": "gwsdk_sharing_audit_report.py",
     "args": "--subject {subject} --report login --days 1 --out {out}", "cron": "30 5 * * *",
     "scope": "admin.reports.audit.readonly"},
]


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Render scheduler config for the toolkit's reports.")
    p.add_argument("--subject", required=True, help="Impersonation subject the scheduled jobs use.")
    p.add_argument("--domain", default="corp.example", help="Primary domain (for the sharing report).")
    p.add_argument("--python", default="python", help="Python executable name/path in the scheduled context.")
    p.add_argument("--scripts-dir", default=".", help="Directory holding the toolkit scripts.")
    p.add_argument("--out", default="./reports", help="Output directory the scheduled reports write to.")
    p.add_argument("--format", choices=["cron", "cloud-scheduler", "task-scheduler", "all"],
                   default="all", help="Which scheduler format(s) to emit.")
    p.add_argument("--write", action="store_true", help="Also write the definition JSON to --out.")
    return p.parse_args()


def command_for(job: dict, args) -> str:
    script_path = os.path.join(args.scripts_dir, job["script"])
    filled = job["args"].format(subject=args.subject, domain=args.domain, out=args.out)
    return f"{args.python} {script_path} {filled}"


def render_cron(job: dict, cmd: str) -> str:
    return f"{job['cron']}  {cmd}"


def render_cloud_scheduler(job: dict, cmd: str) -> str:
    # Illustrative gcloud invocation; the target runtime (Cloud Run job / Function) uses ADC / Workload
    # Identity — no key material. Verify exact flags for your gcloud version.
    slug = job["name"].lower().replace(" – ", "-").replace(" ", "-")
    return (f"gcloud scheduler jobs create http {slug} \\\n"
            f"  --schedule=\"{job['cron']}\" --uri=\"<your-runner-endpoint>\" \\\n"
            f"  --oidc-service-account-email=\"<runner-sa>\"   # runs: {cmd}")


def render_task_scheduler(job: dict, cmd: str) -> str:
    slug = job["name"].replace(" – ", "-").replace(" ", "-")
    # /RU with an attached identity / gMSA; credentials via ADC, never stored in the task.
    return (f'schtasks /Create /TN "{slug}" /TR "{cmd}" /SC DAILY /ST 05:00 '
            f'/RL LIMITED   # ensure ADC is available to this account')


def main() -> int:
    args = parse_args()
    print(f"# {ARTIFACT} — subject {args.subject}\n")
    definition = {"artifact": ARTIFACT,
                  "generated": datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"),
                  "jobs": []}

    for job in JOBS:
        cmd = command_for(job, args)
        print(f"## {job['name']}")
        print(f"   required minimal scope: {job['scope']}  (least scope)")
        if args.format in ("cron", "all"):
            print("   [cron]\n     " + render_cron(job, cmd))
        if args.format in ("cloud-scheduler", "all"):
            print("   [cloud-scheduler]\n     " + render_cloud_scheduler(job, cmd).replace("\n", "\n     "))
        if args.format in ("task-scheduler", "all"):
            print("   [task-scheduler]\n     " + render_task_scheduler(job, cmd))
        print()
        definition["jobs"].append({"name": job["name"], "scope": job["scope"],
                                   "cron": job["cron"], "command": cmd})

    print("# Service-identity requirement: DWD Grant – AdminSDK – LeastScope must include exactly the "
          "scopes listed above and no more. Credentials must resolve from ADC / a secrets manager in "
          "the scheduled context — never a committed key.")

    if args.write:
        os.makedirs(args.out, exist_ok=True)
        path = os.path.join(args.out, "schedule-definition-reports-expand.json")
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(definition, fh, indent=2)
        print(f"\nWrote: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
