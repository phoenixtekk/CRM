#!/usr/bin/env python3
# finops-savings-analyzer.py — read rightsizing / idle / CUD recommendations into a savings backlog.
#
# PURPOSE: Optimization analysis. Reads the Recommender API (via gcloud) for machine-type
#          rightsizing, idle-resource, and committed-use-discount (CUD) recommendations across the
#          given projects/regions and produces a savings backlog with an estimated monthly saving and
#          an owner (project) per item. STRICTLY READ-ONLY — it never acts on a recommendation and
#          never purchases a commitment.
# HOW TO RUN: python finops-savings-analyzer.py --projects a,b --regions us-central1,us-east1
#             [--recommenders ...] [--json OUT.json]
#             (Python 3.10+, gcloud installed + authenticated / ADC; recommender.googleapis.com
#              enabled + roles/recommender.viewer; see --help)
# EXPECTED RESULTS: A printed backlog (and optional JSON) of recommendations with estimated monthly
#             savings, sorted by saving. Changes nothing. A CUD purchase is a human, approved action.
#
# No credentials or keys are embedded; auth comes from gcloud/ADC. Recommender IDs are
# version-dependent — verify current IDs in the Google Cloud Recommender docs for your org.

import argparse
import json
import shutil
import subprocess
import sys

# Default recommenders (verify current IDs for your org — these are the widely-documented ones).
DEFAULT_RECOMMENDERS = [
    "google.compute.instance.MachineTypeRecommender",   # VM rightsizing
    "google.compute.instance.IdleResourceRecommender",  # idle VMs
    "google.compute.disk.IdleResourceRecommender",      # unattached/idle disks
    "google.compute.commitment.UsageCommitmentRecommender",  # CUD opportunities
]


def require_gcloud():
    if shutil.which("gcloud") is None:
        sys.exit("ERROR: gcloud CLI not found on PATH. Install the Google Cloud SDK.")


def list_recs(project, location, recommender):
    """Read-only recommender list; returns [] on any error (e.g. API off / no perms / none)."""
    res = subprocess.run(
        ["gcloud", "recommender", "recommendations", "list",
         f"--project={project}", f"--location={location}",
         f"--recommender={recommender}", "--format=json"],
        capture_output=True, text=True)
    if res.returncode != 0:
        sys.stderr.write(f"  (skip) {project}/{location}/{recommender}: {res.stderr.strip()[:160]}\n")
        return []
    try:
        return json.loads(res.stdout or "[]")
    except json.JSONDecodeError:
        return []


def monthly_saving(rec):
    """Extract estimated monthly cost saving from a recommendation's primaryImpact (USD)."""
    impact = rec.get("primaryImpact", {}) or {}
    cost = (impact.get("costProjection", {}) or {}).get("cost", {}) or {}
    units = cost.get("units")
    nanos = cost.get("nanos", 0) or 0
    if units is None and not nanos:
        return None
    # Recommender reports the projected cost delta (negative units = a saving) over the impact window.
    val = float(units or 0) + float(nanos) / 1e9
    return round(-val, 2)  # positive number = monthly saving


def main():
    ap = argparse.ArgumentParser(description="Read cost recommendations into a savings backlog (read-only).")
    ap.add_argument("--projects", required=True, help="Comma list of project ids to analyze.")
    ap.add_argument("--regions", required=True, help="Comma list of locations/regions, e.g. us-central1")
    ap.add_argument("--recommenders", help="Comma list of recommender IDs (default: common set).")
    ap.add_argument("--json", help="Write the backlog to this JSON file.")
    a = ap.parse_args()
    require_gcloud()

    projects = [p.strip() for p in a.projects.split(",") if p.strip()]
    regions = [r.strip() for r in a.regions.split(",") if r.strip()]
    recommenders = ([r.strip() for r in a.recommenders.split(",")]
                    if a.recommenders else DEFAULT_RECOMMENDERS)

    backlog = []
    for project in projects:
        for location in regions:
            for recommender in recommenders:
                for rec in list_recs(project, location, recommender):
                    saving = monthly_saving(rec)
                    backlog.append({
                        "owner_project": project,
                        "location": location,
                        "recommender": recommender,
                        "description": (rec.get("description") or "")[:200],
                        "state": (rec.get("stateInfo", {}) or {}).get("state"),
                        "estimated_monthly_saving_usd": saving,
                        "recommendation_id": rec.get("name"),
                    })

    backlog.sort(key=lambda x: (x["estimated_monthly_saving_usd"] or 0), reverse=True)
    total = round(sum(b["estimated_monthly_saving_usd"] or 0 for b in backlog), 2)

    print("=== FinOps – Savings Backlog – v1 (read-only) ===")
    print(f"Items: {len(backlog)}   Estimated total monthly saving: ${total}")
    for b in backlog[:40]:
        print(f"  ${str(b['estimated_monthly_saving_usd']):>10}  {b['owner_project']:<20} "
              f"{b['recommender'].split('.')[-1]:<32} {b['description'][:60]}")
    if any(r["recommender"].endswith("UsageCommitmentRecommender") for r in backlog):
        print("\nNOTE: CUD/commitment items are OPPORTUNITIES only. A purchase is a commitment and "
              "money movement — approve and execute it as a human action, never via this tool.")

    if a.json:
        with open(a.json, "w", encoding="utf-8") as fh:
            json.dump({"total_monthly_saving_usd": total, "items": backlog}, fh, indent=2)
        print(f"\nWrote backlog -> {a.json}")


if __name__ == "__main__":
    main()
