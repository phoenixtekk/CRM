#!/usr/bin/env python3
# build-migration-userlist.py — build the source->destination user-list CSV CloudM consumes
#
# PURPOSE: Reconciles an M365 source user export against the Google Workspace directory and emits
#          the source->destination mapping CSV CloudM Migrate imports. Dry-run by default (prints a
#          preview + validation); --apply writes the CSV. No CloudM private API is called.
# HOW TO RUN: python build-migration-userlist.py --source-export src.csv --out userlist.csv --apply
#             (Python 3.10+, OAuth/ADC; see --help). pip install google-api-python-client google-auth
# EXPECTED RESULTS: A validated mapping preview (matched / unmatched / duplicate rows). With --apply,
#          userlist.csv is written; without it, nothing is written (dry-run).
#
# SAFETY: dry-run by default; only --apply writes the local CSV (no remote writes ever). OAuth/ADC;
#          no credentials or secrets in code. Align final headers to CloudM's import template for
#          your version before importing.

import argparse
import csv
import sys

DIRECTORY_SCOPE = "https://www.googleapis.com/auth/admin.directory.user.readonly"

# Output columns. NOTE: CloudM's import template column names/order vary by version — map these to
# CloudM's expected headers before import ("verify for your version"). Kept connector-agnostic here.
OUTPUT_FIELDS = ["SourceEmail", "DestinationEmail", "MigrateMail", "MigrateDrive", "Notes"]


def get_directory_service(delegated_admin=None):
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        sys.exit("Missing deps. Run: pip install google-api-python-client google-auth")
    creds, _ = google.auth.default(scopes=[DIRECTORY_SCOPE])
    if delegated_admin and hasattr(creds, "with_subject"):
        creds = creds.with_subject(delegated_admin)
    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def fetch_dest_index(service, domain=None):
    """Return {email -> {aliases}} for destination users, for source matching (read-only)."""
    index, page_token = {}, None
    while True:
        resp = service.users().list(
            customer="my_customer", domain=domain, maxResults=500,
            orderBy="email", pageToken=page_token, projection="full",
        ).execute()
        for u in resp.get("users", []):
            primary = u.get("primaryEmail", "").lower()
            if not primary:
                continue
            aliases = {a.lower() for a in u.get("aliases", []) or []}
            index[primary] = {"primary": primary, "aliases": aliases}
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return index


def load_source_export(path):
    rows = []
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        norm = {c: (c or "").strip().lower() for c in (reader.fieldnames or [])}
        for raw in reader:
            r = {norm.get(k, k): v for k, v in raw.items()}
            src = (r.get("upn") or r.get("primary_smtp") or r.get("email") or "").strip().lower()
            hint = (r.get("destination") or r.get("dest_email") or "").strip().lower()
            if src:
                rows.append({"source": src, "dest_hint": hint})
    return rows


def match(source_rows, dest_index):
    """Match each source user to a destination address by hint, then primary, then alias."""
    alias_to_primary = {}
    for prim, meta in dest_index.items():
        for a in meta["aliases"]:
            alias_to_primary.setdefault(a, prim)

    mapped, unmatched = [], []
    seen_dest = {}
    for r in source_rows:
        src = r["source"]
        dest = None
        if r["dest_hint"] and r["dest_hint"] in dest_index:
            dest = r["dest_hint"]
        elif src in dest_index:
            dest = src
        elif src in alias_to_primary:
            dest = alias_to_primary[src]
        else:
            local = src.split("@", 1)[0]
            candidates = [p for p in dest_index if p.split("@", 1)[0] == local]
            if len(candidates) == 1:
                dest = candidates[0]

        if dest:
            note = "duplicate-destination" if dest in seen_dest else ""
            seen_dest.setdefault(dest, src)
            mapped.append({"source": src, "dest": dest, "note": note})
        else:
            unmatched.append(src)
    return mapped, unmatched


def write_csv(path, mapped):
    with open(path, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=OUTPUT_FIELDS)
        w.writeheader()
        for m in mapped:
            w.writerow({
                "SourceEmail": m["source"],
                "DestinationEmail": m["dest"],
                "MigrateMail": "true",
                "MigrateDrive": "true",
                "Notes": m["note"],
            })


def main():
    p = argparse.ArgumentParser(description="Build source->destination user-list CSV for CloudM import.")
    p.add_argument("--source-export", required=True, help="M365 source user export CSV.")
    p.add_argument("--out", default="userlist.csv", help="Output CSV path (default userlist.csv).")
    p.add_argument("--domain", help="Limit destination directory read to this domain.")
    p.add_argument("--delegated-admin", help="Super-admin to impersonate via DWD (optional).")
    p.add_argument("--apply", action="store_true", help="Write the CSV (default is dry-run).")
    args = p.parse_args()

    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"== Build Migration User List ({mode}) ==")

    try:
        svc = get_directory_service(args.delegated_admin)
        dest_index = fetch_dest_index(svc, args.domain)
    except Exception as exc:  # noqa: BLE001
        sys.exit(f"ERROR reading Google directory: {exc}")

    source_rows = load_source_export(args.source_export)
    mapped, unmatched = match(source_rows, dest_index)
    dups = [m for m in mapped if m["note"] == "duplicate-destination"]

    print(f"Source rows:            {len(source_rows)}")
    print(f"Matched to destination: {len(mapped)}")
    print(f"Unmatched (no dest):    {len(unmatched)}")
    print(f"Duplicate destinations: {len(dups)}")
    for m in mapped[:10]:
        print(f"    {m['source']:40s} -> {m['dest']}  {m['note']}")
    if unmatched:
        print("  Unmatched source users (fix before import):")
        for u in unmatched[:20]:
            print(f"    - {u}")

    if unmatched or dups:
        print("\nWARNING: unresolved mappings present — review before importing into CloudM.")

    if args.apply:
        write_csv(args.out, mapped)
        print(f"\nWrote {len(mapped)} rows to {args.out}. "
              f"Map headers to CloudM's import template for your version before importing.")
    else:
        print(f"\nDry-run only. Re-run with --apply to write {args.out}.")

    sys.exit(0 if not unmatched else 2)


if __name__ == "__main__":
    main()
