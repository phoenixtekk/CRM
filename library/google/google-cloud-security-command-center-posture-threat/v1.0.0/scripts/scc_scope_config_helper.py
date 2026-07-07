#!/usr/bin/env python3
# scc_scope_config_helper.py — validate SCC scope + export wiring before the other tools run (read-only).
#
# PURPOSE: Resolves and validates the SCC deployment target — the Organization/SecOps project, the
#          required APIs, and the Pub/Sub export topic/subscription plus the SCC notification service
#          account's publish binding — so the notification/export setup has a correct, verified
#          target. READ-ONLY: it inspects and reports; it changes nothing.
# HOW TO RUN: python scc_scope_config_helper.py --organization ORG_ID --project SECOPS_PROJECT \
#              --topic finding-export-secops-v1 [--subscription finding-export-secops-v1-sub]
#            (Python 3.10+, gcloud auth / ADC; see --help)
# EXPECTED RESULTS: A checklist of PASS/WARN/FAIL for org access, enabled APIs, topic/subscription
#          existence, and the SCC publisher IAM binding. Exit non-zero if any FAIL.
#
# NOTE: The SCC notification service account address is per-org and edition-dependent; verify the
#       exact address in Console before relying on the binding check. Uses `gcloud` (ADC, no keys).

import argparse
import json
import subprocess
import sys

REQUIRED_APIS = ["securitycenter.googleapis.com", "pubsub.googleapis.com"]


def gcloud_json(args):
    cmd = ["gcloud"] + args + ["--format=json"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except FileNotFoundError:
        print("ERROR: gcloud not found on PATH.", file=sys.stderr)
        sys.exit(2)
    if proc.returncode != 0:
        return None
    try:
        return json.loads(proc.stdout or "null")
    except json.JSONDecodeError:
        return None


class Checks:
    def __init__(self):
        self.fail = 0
        self.warn = 0

    def report(self, level, name, detail=""):
        print(f"  [{level:<4}] {name}{(' — ' + detail) if detail else ''}")
        if level == "FAIL":
            self.fail += 1
        elif level == "WARN":
            self.warn += 1


def check_org(checks, org):
    orgs = gcloud_json(["organizations", "list"]) or []
    ids = {o.get("name", "").split("/")[-1] for o in orgs}
    if org in ids:
        checks.report("PASS", f"Organization {org} visible to caller")
    else:
        checks.report("FAIL", f"Organization {org} not listed",
                      "check auth / organizations.list permission")


def check_apis(checks, project):
    enabled = gcloud_json(["services", "list", "--enabled", f"--project={project}"]) or []
    ids = {s.get("config", {}).get("name") or s.get("name", "") for s in enabled}
    ids = {i.split("/")[-1] for i in ids}
    for api in REQUIRED_APIS:
        if api in ids:
            checks.report("PASS", f"API enabled: {api}")
        else:
            checks.report("FAIL", f"API not enabled: {api}",
                          f"gcloud services enable {api} --project={project}")


def check_topic(checks, project, topic):
    data = gcloud_json(["pubsub", "topics", "describe", topic, f"--project={project}"])
    if data:
        checks.report("PASS", f"Topic exists: {topic}")
        return f"projects/{project}/topics/{topic}"
    checks.report("FAIL", f"Topic missing: {topic}",
                  "create Finding Export Topic - SecOps - v1")
    return None


def check_subscription(checks, project, subscription):
    if not subscription:
        checks.report("WARN", "No --subscription given", "cannot verify consumer wiring")
        return
    data = gcloud_json(["pubsub", "subscriptions", "describe", subscription, f"--project={project}"])
    if data:
        checks.report("PASS", f"Subscription exists: {subscription}")
    else:
        checks.report("WARN", f"Subscription missing: {subscription}",
                      "SIEM/consumer will have nothing to pull")


def check_publisher_binding(checks, project, topic, org):
    policy = gcloud_json(["pubsub", "topics", "get-iam-policy", topic, f"--project={project}"])
    if not policy:
        checks.report("WARN", "Could not read topic IAM policy", "verify manually")
        return
    publishers = set()
    for binding in policy.get("bindings", []):
        if binding.get("role") == "roles/pubsub.publisher":
            publishers.update(binding.get("members", []))
    # Expected SCC notification service account (verify exact address for your org).
    expected = f"serviceAccount:service-org-{org}@gcp-sa-scc-notification.iam.gserviceaccount.com"
    if expected in publishers:
        checks.report("PASS", "SCC notification SA has publisher on topic")
    else:
        checks.report("WARN", "SCC notification SA publisher binding not found",
                      f"verify/add {expected} as roles/pubsub.publisher (address is per-org)")


def main():
    ap = argparse.ArgumentParser(description="Read-only SCC scope + export-wiring validator.")
    ap.add_argument("--organization", required=True, help="Organization ID (numeric).")
    ap.add_argument("--project", required=True, help="SecOps project hosting the export topic.")
    ap.add_argument("--topic", required=True, help="Pub/Sub export topic name.")
    ap.add_argument("--subscription", help="Pub/Sub subscription the SIEM/consumer pulls.")
    args = ap.parse_args()

    org = args.organization.split("/")[-1]
    print(f"SCC scope/config validation — org {org}, project {args.project} (read-only)\n")

    checks = Checks()
    check_org(checks, org)
    check_apis(checks, args.project)
    check_topic(checks, args.project, args.topic)
    check_subscription(checks, args.project, args.subscription)
    check_publisher_binding(checks, args.project, args.topic, org)

    print(f"\nSummary: {checks.fail} FAIL, {checks.warn} WARN")
    print("Note: SCC editions and the notification service-account address are version/tenant-"
          "dependent; verify in Console before relying on these checks.")
    sys.exit(1 if checks.fail else 0)


if __name__ == "__main__":
    main()
