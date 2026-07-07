#!/usr/bin/env python3
# validate-migration-report.py — post-migration validation report (item counts + permissions)
#
# PURPOSE: Read-only validation. For each migrated user, compares destination Gmail message counts
#          and Drive file counts against the pre-migration Scan baseline, and (optionally) spot-checks
#          Drive/Shared-Drive sharing for over-exposure. Emits per-user PASS/FAIL vs the agreed
#          tolerance. Writes nothing to Google.
# HOW TO RUN: python validate-migration-report.py --baseline scan.csv [--check-permissions]
#             [--tolerance 0.5] [--out report.csv]  (Python 3.10+, OAuth/ADC; see --help).
#             pip install google-api-python-client google-auth
# EXPECTED RESULTS: A per-user table (baseline vs migrated counts, variance %, PASS/FAIL) and an
#          overall gate result. Non-zero exit if any user fails.
#
# SAFETY: read-only (Gmail/Drive readonly + Directory readonly scopes). No writes. OAuth/ADC; no
#          credentials or secrets in code.

import argparse
import csv
import sys

SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/drive.metadata.readonly",
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
]


def build_clients(user_email, delegated_admin=None):
    """Build read-only Gmail + Drive clients impersonating a target user via DWD/OAuth."""
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        sys.exit("Missing deps. Run: pip install google-api-python-client google-auth")

    creds, _ = google.auth.default(scopes=SCOPES)
    subject = user_email
    if hasattr(creds, "with_subject"):
        creds = creds.with_subject(subject)
    gmail = build("gmail", "v1", credentials=creds, cache_discovery=False)
    drive = build("drive", "v3", credentials=creds, cache_discovery=False)
    return gmail, drive


def count_gmail_messages(gmail):
    """Approximate total messages via the profile's messagesTotal (read-only, cheap)."""
    prof = gmail.users().getProfile(userId="me").execute()
    return int(prof.get("messagesTotal", 0))


def count_drive_files(drive):
    """Count Drive files owned by / accessible to the user (read-only, paged)."""
    count, page_token = 0, None
    while True:
        resp = drive.files().list(
            q="trashed = false",
            spaces="drive",
            fields="nextPageToken, files(id)",
            pageSize=1000,
            pageToken=page_token,
        ).execute()
        count += len(resp.get("files", []))
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return count


def check_oversharing(drive, sample_limit=50):
    """Return count of sampled files shared to 'anyone' (potential over-exposure)."""
    exposed, checked, page_token = 0, 0, None
    while checked < sample_limit:
        resp = drive.files().list(
            q="trashed = false",
            spaces="drive",
            fields="nextPageToken, files(id, permissions(type))",
            pageSize=min(100, sample_limit - checked),
            pageToken=page_token,
        ).execute()
        for f in resp.get("files", []):
            checked += 1
            for perm in f.get("permissions", []) or []:
                if perm.get("type") == "anyone":
                    exposed += 1
                    break
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return exposed, checked


def load_baseline(path):
    """Scan baseline CSV: columns user, mail_items, drive_items (extras ignored)."""
    base = {}
    with open(path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.DictReader(fh)
        norm = {c: (c or "").strip().lower() for c in (reader.fieldnames or [])}
        for raw in reader:
            r = {norm.get(k, k): v for k, v in raw.items()}
            user = (r.get("user") or r.get("email") or r.get("destinationemail") or "").strip().lower()
            if user:
                base[user] = {
                    "mail": _to_int(r.get("mail_items")),
                    "drive": _to_int(r.get("drive_items")),
                }
    return base


def _to_int(v):
    try:
        return int(float(str(v).replace(",", "").strip()))
    except (TypeError, ValueError):
        return 0


def variance_pct(expected, actual):
    if expected <= 0:
        return 0.0 if actual == 0 else 100.0
    return round(abs(expected - actual) / expected * 100.0, 2)


def main():
    p = argparse.ArgumentParser(description="Post-migration validation report (read-only).")
    p.add_argument("--baseline", required=True, help="Scan baseline CSV (user, mail_items, drive_items).")
    p.add_argument("--tolerance", type=float, default=0.5, help="Max acceptable variance %% (default 0.5).")
    p.add_argument("--check-permissions", action="store_true", help="Spot-check Drive over-sharing.")
    p.add_argument("--delegated-admin", help="Super-admin for DWD context (optional).")
    p.add_argument("--out", help="Optional CSV report path.")
    args = p.parse_args()

    baseline = load_baseline(args.baseline)
    if not baseline:
        sys.exit("No users in --baseline. Nothing to validate.")

    print("== Post-Migration Validation Report (read-only) ==")
    print(f"{'User':38s} {'MailB/M':>14s} {'DriveB/M':>14s} {'Var%':>6s} {'Result':>7s}")

    results, failures = [], 0
    for user, exp in sorted(baseline.items()):
        try:
            gmail, drive = build_clients(user, args.delegated_admin)
            mail_actual = count_gmail_messages(gmail)
            drive_actual = count_drive_files(drive)
        except Exception as exc:  # noqa: BLE001
            print(f"{user:38s}  ERROR: {exc}")
            failures += 1
            results.append({"user": user, "result": "ERROR", "detail": str(exc)})
            continue

        v_mail = variance_pct(exp["mail"], mail_actual)
        v_drive = variance_pct(exp["drive"], drive_actual)
        worst = max(v_mail, v_drive)
        ok = worst <= args.tolerance
        over = ""
        if args.check_permissions:
            exposed, checked = check_oversharing(drive)
            if exposed:
                over = f" over-shared={exposed}/{checked}"
                ok = False
        if not ok:
            failures += 1
        print(f"{user:38s} {exp['mail']:>6d}/{mail_actual:<6d} "
              f"{exp['drive']:>6d}/{drive_actual:<6d} {worst:>6.2f} "
              f"{'PASS' if ok else 'FAIL':>7s}{over}")
        results.append({
            "user": user, "mail_baseline": exp["mail"], "mail_actual": mail_actual,
            "drive_baseline": exp["drive"], "drive_actual": drive_actual,
            "variance_pct": worst, "result": "PASS" if ok else "FAIL",
        })

    if args.out:
        with open(args.out, "w", newline="", encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=[
                "user", "mail_baseline", "mail_actual", "drive_baseline",
                "drive_actual", "variance_pct", "result"])
            w.writeheader()
            for r in results:
                w.writerow({k: r.get(k, "") for k in w.fieldnames})
        print(f"\nWrote report to {args.out}.")

    total = len(baseline)
    print(f"\nGATE: {total - failures}/{total} users within {args.tolerance}% tolerance.")
    print("RESULT:", "PASS — wave may close" if failures == 0
          else f"FAIL — {failures} user(s) need triage/re-delta")
    sys.exit(0 if failures == 0 else 2)


if __name__ == "__main__":
    main()
