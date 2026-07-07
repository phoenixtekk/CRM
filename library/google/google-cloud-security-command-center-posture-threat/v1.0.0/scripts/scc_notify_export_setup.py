#!/usr/bin/env python3
# scc_notify_export_setup.py — set up SCC finding notification/export and posture mute rules (dry-run default).
#
# PURPOSE: Configures the notification/export plumbing — creates the SCC notification config
#          (Finding Notification - Org - v1) that publishes findings to the Pub/Sub export topic
#          (Finding Export Topic - SecOps - v1), and optionally applies posture MUTE rules for
#          approved exceptions. SAFE BY DEFAULT: prints the plan and makes NO changes unless --apply.
# HOW TO RUN: python scc_notify_export_setup.py --organization ORG_ID --project SECOPS_PROJECT \
#              --topic finding-export-secops-v1 --config-id finding-notification-org-v1 \
#              [--filter 'state="ACTIVE"'] [--mute-config mutes.yaml] [--apply]
#            (Python 3.10+, gcloud auth / ADC; see --help)
# EXPECTED RESULTS: A printed plan of the exact gcloud commands. With --apply, they are executed and
#          results reported. Without --apply, nothing is changed.
#
# NOTE: SCC notification/mute command surfaces are edition-dependent — verify subcommands/flags
#       against your edition's gcloud SCC docs. No credentials/keys in code; uses ADC.

import argparse
import subprocess
import sys

try:
    import yaml  # optional; only needed when --mute-config is used
except ImportError:
    yaml = None


def planned(cmd):
    print("  $ " + " ".join(cmd))


def execute(cmd, apply):
    planned(cmd)
    if not apply:
        return True
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    except FileNotFoundError:
        print("ERROR: gcloud not found on PATH.", file=sys.stderr)
        sys.exit(2)
    if proc.returncode != 0:
        print(f"    FAILED ({proc.returncode}): {proc.stderr.strip()}", file=sys.stderr)
        return False
    print("    OK")
    if proc.stdout.strip():
        print("    " + proc.stdout.strip().replace("\n", "\n    "))
    return True


def build_notification_cmd(org, project, topic, config_id, filt):
    topic_path = f"projects/{project}/topics/{topic}"
    cmd = [
        "gcloud", "scc", "notifications", "create", config_id,
        f"--organization={org}",
        f"--pubsub-topic={topic_path}",
        f"--filter={filt}",
        "--description=Finding Notification - Org - v1",
    ]
    return cmd


def load_mutes(path):
    if yaml is None:
        print("ERROR: PyYAML required for --mute-config (pip install pyyaml).", file=sys.stderr)
        sys.exit(2)
    with open(path, encoding="utf-8") as fh:
        data = yaml.safe_load(fh) or {}
    return data.get("mutes", [])


def build_mute_cmd(org, mute):
    # Each mute entry: {id, filter, description}. Verify mute-config subcommand for your edition.
    return [
        "gcloud", "scc", "muteconfigs", "create", mute["id"],
        f"--organization={org}",
        f"--filter={mute['filter']}",
        f"--description={mute.get('description', 'Posture Baseline - Corp - v1 exception')}",
    ]


def main():
    ap = argparse.ArgumentParser(
        description="Set up SCC notification/export and posture mute rules (dry-run by default).")
    ap.add_argument("--organization", required=True, help="Organization ID (numeric).")
    ap.add_argument("--project", help="SecOps project hosting the export topic.")
    ap.add_argument("--topic", help="Pub/Sub topic name (Finding Export Topic - SecOps - v1).")
    ap.add_argument("--config-id", default="finding-notification-org-v1",
                    help="Notification config ID.")
    ap.add_argument("--filter", default='state="ACTIVE"',
                    help="SCC finding filter for the notification config.")
    ap.add_argument("--mute-config", help="YAML file of posture mute rules to create.")
    ap.add_argument("--apply", action="store_true",
                    help="Actually create the resources. Omit for a dry-run (default).")
    args = ap.parse_args()

    org = args.organization.split("/")[-1]
    mode = "APPLY" if args.apply else "DRY-RUN (no changes)"
    print(f"SCC notify/export setup — organization {org} — mode: {mode}")
    print("NOTE: verify gcloud SCC subcommands against your edition before applying.\n")

    ok = True

    if args.topic:
        if not args.project:
            print("ERROR: --project is required with --topic.", file=sys.stderr)
            sys.exit(2)
        print("Plan: create/ensure notification config -> Pub/Sub topic")
        cmd = build_notification_cmd(org, args.project, args.topic, args.config_id, args.filter)
        ok = execute(cmd, args.apply) and ok
        print()

    if args.mute_config:
        mutes = load_mutes(args.mute_config)
        print(f"Plan: create {len(mutes)} posture mute rule(s) (approved exceptions):")
        for mute in mutes:
            ok = execute(build_mute_cmd(org, mute), args.apply) and ok
        print()

    if not args.topic and not args.mute_config:
        print("Nothing to do: supply --topic (with --project) and/or --mute-config.")

    if not args.apply:
        print("Dry-run complete. Re-run with --apply (under change control) to make changes.")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
