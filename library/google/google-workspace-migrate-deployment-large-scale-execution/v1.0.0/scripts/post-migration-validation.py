#!/usr/bin/env python3
# post-migration-validation.py — validate a migrated wave against the source baseline (counts, permissions, mail).
#
# PURPOSE: Read-only post-migration validation report for one wave. Compares TARGET item counts to the source
#          baseline (parity), checks ownership/permission fidelity (sharing preserved via Bridge - Identity - Corp),
#          and for mail waves checks per-mailbox message-count parity — reading the Google Admin SDK / Drive /
#          Gmail APIs. Read-only: it never writes to Microsoft 365 or Google.
# HOW TO RUN: python post-migration-validation.py --wave "Migration Wave - Finance - Pilot" \
#                 --baseline baseline-source.json --out validate-pilot/   (Python 3.10+, OAuth/ADC)
#             (pip install google-api-python-client google-auth  — or --sample for a demo report)
# EXPECTED RESULTS: Writes a validation report (JSON) to --out and prints PASS/FAIL per gate. Exit non-zero if
#                   any gate (item-count parity, permission fidelity, mail parity) fails.

import argparse
import json
import os
import sys

COUNT_PARITY_THRESHOLD = 0.01     # allow 1% divergence (documented unsupported items)
MAIL_PARITY_THRESHOLD = 0.01


def parse_args():
    p = argparse.ArgumentParser(description="Validate a migrated wave vs. baseline (read-only).")
    p.add_argument("--wave", required=True, help="Wave name (Migration Wave - <Scope> - <Stage>).")
    p.add_argument("--baseline", help="baseline-source.json from node-sizing-assessment.py.")
    p.add_argument("--sample", action="store_true", help="Produce a demo report from sample numbers (no network).")
    p.add_argument("--out", default="validate-out/", help="Output directory for the report.")
    return p.parse_args()


def read_target_counts(sample):
    """Return measured target-side counts for the wave. Read-only.

    Live mode: Admin SDK Directory (users in scope), Drive API files.list (Drive/Shared Drive item counts +
    permissions), Gmail API users.getProfile (messagesTotal). OAuth/ADC only — NO hardcoded credentials.
    """
    if sample:
        return {
            "drive_files": 385_000,          # migrated to target Drive/Shared Drives
            "mail_messages": 612_000,        # migrated to Gmail
            "permission_mismatches": 3,      # owners/sharing not matching intended mapping
            "public_sharing_introduced": 0,  # unexpected broad sharing (should be 0)
        }
    try:
        from googleapiclient.discovery import build  # noqa: F401
        from google.oauth2 import service_account  # noqa: F401
    except ImportError:
        sys.exit("Missing deps: pip install google-api-python-client google-auth (or use --sample).")
    sys.exit("Live target read not wired in this template. Add read-only Drive/Gmail/Admin SDK reads (OAuth/ADC), "
             "or use --sample. See the docstring for the exact endpoints.")


def source_expected(baseline, sample):
    if sample or not baseline:
        # Demo expected numbers for the pilot scope.
        return {"drive_files": 388_000, "mail_messages": 616_000}
    with open(baseline, encoding="utf-8") as f:
        b = json.load(f)
    # For a real run, scope these to the wave's users; here we surface the totals as the reference.
    return {
        "drive_files": b["inventory"]["onedrive"]["total_files"] + b["inventory"]["sharepoint"]["total_files"],
        "mail_messages": b["inventory"]["mailboxes"]["total_items"],
    }


def gate(name, expected, actual, threshold):
    if expected == 0:
        ok = actual == 0
        div = 0.0
    else:
        div = abs(expected - actual) / expected
        ok = div <= threshold
    print(f"  {name:<24} expected {expected:>12,} | target {actual:>12,} | "
          f"diff {div:.2%} -> {'PASS' if ok else 'FAIL'}")
    return ok, div


def main():
    args = parse_args()
    tgt = read_target_counts(args.sample)
    exp = source_expected(args.baseline, args.sample)
    os.makedirs(args.out, exist_ok=True)

    print(f"=== Post-migration validation: {args.wave} ===")
    ok_files, files_div = gate("Item-count parity", exp["drive_files"], tgt["drive_files"], COUNT_PARITY_THRESHOLD)
    ok_mail, mail_div = gate("Mail-count parity", exp["mail_messages"], tgt["mail_messages"], MAIL_PARITY_THRESHOLD)

    perms_ok = tgt["permission_mismatches"] == 0 and tgt["public_sharing_introduced"] == 0
    print(f"  Permission fidelity      mismatches {tgt['permission_mismatches']}, "
          f"unexpected-public {tgt['public_sharing_introduced']} -> {'PASS' if perms_ok else 'FAIL'}")

    passed = ok_files and ok_mail and perms_ok
    report = {
        "wave": args.wave,
        "gates": {
            "item_count_parity": {"pass": ok_files, "divergence": round(files_div, 4)},
            "mail_count_parity": {"pass": ok_mail, "divergence": round(mail_div, 4)},
            "permission_fidelity": {"pass": perms_ok,
                                    "mismatches": tgt["permission_mismatches"],
                                    "public_sharing_introduced": tgt["public_sharing_introduced"]},
        },
        "overall_pass": passed,
    }
    out_path = os.path.join(args.out, "validation-report.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    print(f"\nOVERALL: {'PASS — gate cleared, wave may close / expand' if passed else 'FAIL — do not expand; remediate and re-validate'}")
    print(f"Report -> {out_path}")
    sys.exit(0 if passed else 1)


if __name__ == "__main__":
    main()
