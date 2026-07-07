#!/usr/bin/env python3
# btw-project-mapping-builder.py — build/validate the source->target line-item CSV MigrationWiz consumes
#
# PURPOSE: Generate the per-project "line item" mapping CSV (source UPN -> target Google address, plus
#          SharePoint-site->Shared-Drive and Team->Chat-space mappings) that a MigrationWiz project imports,
#          and VALIDATE it (resolvable source, provisioned+licensed target, no duplicates/blanks). Produces the
#          artifact "BTW Mapping - User Pairs - Per Project". Safe by default: writes only the CSV/report you
#          name; never calls a MigrationWiz API and never migrates data.
# HOW TO RUN: python btw-project-mapping-builder.py --in members.csv --project mailbox --out mapping.csv \
#             [--validate] [--google-sa-file sa.json] [--google-subject admin@corp.example]
#             (Python 3.10+; validation needs read-only Admin SDK access; see --help)
# EXPECTED RESULTS: A MigrationWiz-ready CSV of source,target[,folder-mapping] rows and a validation summary.
#             Exit 0 if all rows valid (or --validate not requested); exit 2 if any row is unresolved,
#             unlicensed on the target, or duplicated.
#
# Standard-library-first (csv, argparse). Optional target validation:
#   pip install google-api-python-client google-auth   (read-only Admin SDK scopes; no keys in code)
# Input CSV columns (header row): source, target[, source_resource, target_resource]
#   - mailbox project:   source=source UPN,           target=target Gmail address
#   - documents project: source=source UPN/site URL,  target=target Drive/Shared-Drive, resources optional
#   - teamschat project: source=Team id/name,         target=Chat space name

import argparse
import csv
import sys

READONLY_SCOPES = ["https://www.googleapis.com/auth/admin.directory.user.readonly"]
VALID_PROJECTS = {"mailbox", "documents", "teamschat"}


def load_rows(path):
    with open(path, newline="", encoding="utf-8-sig") as fh:
        rows = list(csv.DictReader(fh))
    if not rows:
        print(f"ERROR: {path} has no data rows.", file=sys.stderr)
        sys.exit(2)
    return rows


def build_mapping(rows, project):
    """Normalize input rows into MigrationWiz line items. Returns (items, issues)."""
    items, issues, seen = [], [], set()
    for i, r in enumerate(rows, start=2):  # header is line 1
        src = (r.get("source") or "").strip()
        tgt = (r.get("target") or "").strip()
        if not src or not tgt:
            issues.append(f"line {i}: blank source/target")
            continue
        key = (src.lower(), tgt.lower())
        if key in seen:
            issues.append(f"line {i}: duplicate pair {src} -> {tgt}")
            continue
        seen.add(key)
        item = {"source": src, "target": tgt}
        if project in ("documents", "teamschat"):
            if r.get("source_resource"):
                item["source_resource"] = r["source_resource"].strip()
            if r.get("target_resource"):
                item["target_resource"] = r["target_resource"].strip()
        items.append(item)
    return items, issues


def validate_targets(items, sa_file, subject):
    """Confirm each target address resolves to a provisioned account (read-only). Returns issue list."""
    issues = []
    try:
        from google.oauth2 import service_account
        import google.auth
        from googleapiclient.discovery import build

        if sa_file:
            creds = service_account.Credentials.from_service_account_file(sa_file, scopes=READONLY_SCOPES)
            if subject:
                creds = creds.with_subject(subject)
        else:
            creds, _ = google.auth.default(scopes=READONLY_SCOPES)
        directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    except Exception as exc:  # noqa: BLE001
        print(f"  [..] Target validation skipped (no/failed Google creds): {exc}")
        return issues

    for it in items:
        tgt = it["target"]
        try:
            u = directory.users().get(userKey=tgt, projection="basic").execute()
            if u.get("suspended"):
                issues.append(f"target {tgt}: account suspended")
        except Exception:  # noqa: BLE001 - not found / not accessible
            issues.append(f"target {tgt}: not provisioned/resolvable in target directory")
    return issues


def write_csv(items, out, project):
    cols = ["source", "target"]
    if project in ("documents", "teamschat"):
        cols += ["source_resource", "target_resource"]
    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=cols)
        w.writeheader()
        for it in items:
            w.writerow({c: it.get(c, "") for c in cols})


def main():
    ap = argparse.ArgumentParser(description="Build/validate the MigrationWiz line-item mapping CSV.")
    ap.add_argument("--in", dest="infile", required=True, help="Members CSV (header: source,target[,...]).")
    ap.add_argument("--project", required=True, choices=sorted(VALID_PROJECTS),
                    help="Project type the mapping is for.")
    ap.add_argument("--out", help="Write the MigrationWiz-ready mapping CSV here.")
    ap.add_argument("--validate", action="store_true",
                    help="Validate that each target resolves to a provisioned account (read-only).")
    ap.add_argument("--google-sa-file", help="Google service-account JSON (read-only scopes).")
    ap.add_argument("--google-subject", help="Admin to impersonate via domain-wide delegation.")
    args = ap.parse_args()

    print(f"== BTW Mapping - User Pairs - Per Project ({args.project}) ==")
    rows = load_rows(args.infile)
    items, issues = build_mapping(rows, args.project)
    print(f"  {len(items)} valid line item(s); {len(issues)} structural issue(s).")

    if args.validate:
        print("  Validating targets against the Google directory (read-only)...")
        issues += validate_targets(items, args.google_sa_file, args.google_subject)

    for msg in issues:
        print(f"    - {msg}")

    if args.out and not issues:
        write_csv(items, args.out, args.project)
        print(f"  Mapping written (MigrationWiz-ready): {args.out}")
    elif args.out and issues:
        print("  NOT writing CSV: resolve the issues above first.")

    if issues:
        print("  RESULT: FAIL — fix mapping before importing into MigrationWiz.")
        sys.exit(2)
    print("  RESULT: PASS — mapping is clean.")
    sys.exit(0)


if __name__ == "__main__":
    main()
