#!/usr/bin/env python3
# assignment_guardrail_check.py — enforce group-only assignment + NameID standard (read-only guardrail)
#
# PURPOSE: Flag policy violations in `App Catalog - Federated SaaS - v1`: apps assigned to All-users
#          or an OU instead of a group, apps with no assignment group, over-broad assignment (a group
#          whose membership exceeds a threshold), and NameID not matching the standard. Read-only;
#          returns a non-zero exit on any violation so it can gate CI / change approval.
# HOW TO RUN: python assignment_guardrail_check.py --catalog catalog.csv [--check-membership] \
#               [--max-members 5000] [--nameid-standard "Basic Information > Primary email"]
#             (Python 3.10+, gcloud auth / ADC for --check-membership; see --help)
# EXPECTED RESULTS: A list of PASS/VIOLATION lines per app and a summary; exit 0 = clean,
#          exit 1 = one or more guardrail violations.
#
# Catalog CSV columns used (header required; extras ignored):
#   app,assignment_target,assignment_group,name_id
#     - assignment_target: how the app is turned on -> group | ou | all-users  (required)
#     - assignment_group:  the Google Group email when assignment_target == group
#     - name_id:           the configured NameID source (compared to the standard)
#
# SAFETY: read-only. Membership size (optional) uses the read-only Directory scope. No writes, no
#         secrets in code (ADC).

import argparse
import csv
import sys

DIRECTORY_RO_SCOPE = "https://www.googleapis.com/auth/admin.directory.group.member.readonly"
DEFAULT_NAMEID = "Basic Information > Primary email"


def load_catalog(path):
    with open(path, newline="", encoding="utf-8") as fh:
        rows = [dict(r) for r in csv.DictReader(fh)]
    return [{k: (v or "").strip() for k, v in r.items()} for r in rows if (r.get("app") or "").strip()]


def build_directory_service():
    try:
        import google.auth
        from googleapiclient.discovery import build
        creds, _ = google.auth.default(scopes=[DIRECTORY_RO_SCOPE])
        return build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    except ImportError:
        print("[!] --check-membership needs: pip install google-api-python-client google-auth",
              file=sys.stderr)
    except Exception as exc:  # noqa: BLE001
        print(f"[!] Directory API unavailable ({exc}); skipping membership sizing.", file=sys.stderr)
    return None


def count_members(service, group_email):
    """Count members via paginated Directory API (read-only). Returns None on error/absent."""
    if not (service and group_email):
        return None
    try:
        total, token = 0, None
        while True:
            resp = service.members().list(groupKey=group_email, maxResults=200,
                                          pageToken=token).execute()
            total += len(resp.get("members", []))
            token = resp.get("nextPageToken")
            if not token:
                return total
    except Exception:  # noqa: BLE001
        return None


def check_app(app, service, max_members, nameid_standard):
    violations = []
    target = app.get("assignment_target", "").lower()

    if target in ("all-users", "all", "everyone"):
        violations.append("assigned to ALL USERS — must be group-driven")
    elif target == "ou":
        violations.append("assigned to an OU — must be a group, not an OU")
    elif target == "group":
        if not app.get("assignment_group"):
            violations.append("assignment_target=group but no assignment_group set")
        elif service is not None:
            n = count_members(service, app["assignment_group"])
            if n is not None and n > max_members:
                violations.append(f"over-broad group: {n} members > {max_members} threshold")
    else:
        violations.append(f"unknown assignment_target '{target or '(blank)'}' "
                          "(expected group|ou|all-users)")

    nameid = app.get("name_id", "")
    if nameid and nameid_standard and nameid.strip().lower() != nameid_standard.strip().lower():
        violations.append(f"NameID '{nameid}' != standard '{nameid_standard}'")
    return violations


def main(argv=None):
    ap = argparse.ArgumentParser(description="Read-only guardrail: group-only assignment + NameID.")
    ap.add_argument("--catalog", required=True, help="path to the app catalog CSV")
    ap.add_argument("--check-membership", action="store_true",
                    help="size each assignment group via the Admin SDK (read-only)")
    ap.add_argument("--max-members", type=int, default=5000,
                    help="flag groups larger than this as over-broad")
    ap.add_argument("--nameid-standard", default=DEFAULT_NAMEID,
                    help="expected NameID source; set empty to skip the NameID check")
    args = ap.parse_args(argv)

    try:
        catalog = load_catalog(args.catalog)
    except OSError as exc:
        print(f"[x] cannot read catalog: {exc}", file=sys.stderr)
        return 2
    if not catalog:
        print("[x] catalog is empty.", file=sys.stderr)
        return 2

    service = build_directory_service() if args.check_membership else None

    total_violations = 0
    print("\nAssignment Guardrail Check (read-only)\n" + "=" * 60)
    for app in catalog:
        v = check_app(app, service, args.max_members, args.nameid_standard)
        if v:
            total_violations += len(v)
            print(f"[VIOLATION] {app['app']}")
            for item in v:
                print(f"            - {item}")
        else:
            print(f"[PASS]      {app['app']}")
    print("=" * 60)
    print(f"{total_violations} violation(s) across {len(catalog)} app(s).")
    if total_violations:
        print("Guardrail FAILED — remediate before turn-on / change approval.")
    else:
        print("Guardrail clean — assignment is group-driven and NameID matches the standard.")
    return 1 if total_violations else 0


if __name__ == "__main__":
    sys.exit(main())
