#!/usr/bin/env python3
# generate-ssp-poam.py — draft the SSP and POA&M from the NIST 800-171 control map.
#
# PURPOSE: Generate DRAFT `SSP – CUI Boundary – Org` (one implementation statement per requirement) and
#          `POA&M – CUI Boundary – Org` (one row per partial/not-configured/verify-edition requirement)
#          from the control-map CSV produced by assess-nist-controls.py. It reads a local CSV and writes
#          local files only — it touches no tenant and holds no credentials.
# HOW TO RUN: python generate-ssp-poam.py --control-map control-map.csv \
#                    --out-ssp "SSP – CUI Boundary – Org.md" --out-poam "POA&M – CUI Boundary – Org.csv"
#             (Python 3.10+, standard library only)
# EXPECTED RESULTS: A Markdown SSP draft + a CSV POA&M draft. Both are DRAFTS for the compliance owner to
#                   review, correct, and own — the tool never attests conformance.
#
# BOUNDARY: This drafts documentation from measured configuration. It does NOT assert that any control is
# "satisfied" and does NOT produce a CMMC assessment result. Implementation statements are worded as
# "configured to support ... (pending assessor determination)". A human compliance owner is authoritative.

import argparse
import csv
import sys
from datetime import datetime, timezone

# statuses that become POA&M items (something remains to do or confirm)
OPEN_STATUSES = {"partial", "not-configured", "verify-edition"}


def read_control_map(path):
    with open(path, newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def write_ssp(rows, out_path, boundary):
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    lines = [
        "# SSP – CUI Boundary – Org (DRAFT)",
        "",
        f"System Security Plan draft generated {now} from `NIST 800-171 – Control Map – Org`.",
        f"CUI boundary: **{boundary}**.",
        "",
        "> DRAFT for compliance-owner review. Implementation statements describe how the Google Workspace",
        "> tenant is *configured to support* each NIST SP 800-171 family, **pending assessor determination**.",
        "> This document does not assert conformance and is not a CMMC assessment result. NIST 800-171",
        "> applicability/scoping and any ITAR/DFARS interpretation remain with compliance/legal/the assessor.",
        "",
        "## Control-family implementation statements",
        "",
    ]
    for r in rows:
        fam = r.get("family", "")
        name = r.get("family_name", "")
        mech = r.get("workspace_mechanism", "")
        status = r.get("status", "")
        val = r.get("configured_value", "") or r.get("planned_setting", "")
        evidence = r.get("evidence_pointer", "")
        lines += [
            f"### {fam} — {name}",
            f"- **Workspace mechanism:** {mech}",
            f"- **Status:** {status}",
            f"- **Configured value:** {val or '(record from control map)'}",
            f"- **Evidence:** {evidence or '(see Evidence – CUI Boundary package)'}",
            f"- **Implementation statement:** The tenant is configured to support the {name} ({fam})",
            f"  requirements of NIST SP 800-171 via {mech}, applied to the {boundary} boundary and evidenced",
            "  as noted above. Conformance is subject to the assessor's determination.",
            "",
        ]
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


def write_poam(rows, out_path, boundary):
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    open_rows = [r for r in rows if r.get("status") in OPEN_STATUSES]
    with open(out_path, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["control_family", "family_name", "status", "weakness/gap",
                    "planned_remediation", "owner", "milestone_date", "notes"])
        for r in open_rows:
            fam = r.get("family", "")
            status = r.get("status", "")
            if status == "verify-edition":
                gap = "Edition/rollout-dependent capability not confirmed in tenant"
                rem = "Confirm edition/Assured Controls availability; enable or document compensating control"
            elif status == "not-configured":
                gap = "Control mechanism not configured on boundary OU"
                rem = "Configure per implementation guide; pilot then enforce; evidence"
            else:  # partial
                gap = "Control partially configured / incomplete coverage"
                rem = "Complete configuration across boundary OU; re-evidence"
            w.writerow([fam, r.get("family_name", ""), status, gap, rem,
                        "<assign owner>", "<set milestone>",
                        r.get("evidence_pointer", "")])
    print(f"POA&M draft: {out_path} ({len(open_rows)} open item(s)) — assign owners + milestones.")
    return len(open_rows)


def main():
    p = argparse.ArgumentParser(description="Draft SSP + POA&M from the NIST 800-171 control map.")
    p.add_argument("--control-map", required=True, help="control-map CSV from assess-nist-controls.py")
    p.add_argument("--out-ssp", default="SSP – CUI Boundary – Org.md", help="output SSP markdown")
    p.add_argument("--out-poam", default="POA&M – CUI Boundary – Org.csv", help="output POA&M CSV")
    p.add_argument("--boundary", default="CUI – Boundary – Org", help="boundary name for the documents")
    args = p.parse_args()

    try:
        rows = read_control_map(args.control_map)
    except FileNotFoundError:
        print(f"ERROR: control map not found: {args.control_map} "
              "(run assess-nist-controls.py first)", file=sys.stderr)
        sys.exit(2)
    if not rows:
        print("ERROR: control map is empty.", file=sys.stderr)
        sys.exit(2)

    write_ssp(rows, args.out_ssp, args.boundary)
    print(f"SSP draft: {args.out_ssp} ({len(rows)} families).")
    open_n = write_poam(rows, args.out_poam, args.boundary)
    print("\nBoth are DRAFTS. The compliance owner reviews, corrects, and owns them; the tool does not")
    print("attest conformance and does not produce a CMMC assessment result.")
    if open_n == 0:
        print("No open POA&M items from status — confirm nothing is over-stated as 'configured'.")


if __name__ == "__main__":
    main()
