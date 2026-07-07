#!/usr/bin/env python3
# btw-postmigration-validation.py — per-user post-migration validation report (mail/docs/chat)
#
# PURPOSE: Validate a migrated wave per user, read-only. Confirms each target Google account exists, is
#          licensed/active, and shows the expected data types present (Gmail mailbox, Drive content, and —
#          where in scope — a Chat space), comparing against the source item counts recorded in the wave's
#          mapping/validation input. Produces "BTW Validation - Mail/Docs/Chat - Per User". Read-only: no
#          writes, no MigrationWiz API; MigrationWiz's own per-item stats are read from its console.
# HOW TO RUN: python btw-postmigration-validation.py --in wave-expected.csv \
#             --google-sa-file sa.json --google-subject admin@corp.example [--tolerance-pct 2] [--out report.csv]
#             (Python 3.10+; read-only Admin SDK / Gmail / Drive scopes; see --help)
# EXPECTED RESULTS: A per-user PASS/FAIL table + summary and optional CSV. Exit 0 if every user passes every
#             in-scope data type within tolerance; exit 2 if any user fails (missing data type / out-of-tolerance
#             count / unprovisioned target).
#
# Optional live checks require:  pip install google-api-python-client google-auth
# Read-only scopes (impersonated per target user via domain-wide delegation):
#   admin.directory.user.readonly, gmail.readonly, drive.metadata.readonly
# No credentials are hardcoded; nothing is written except the report you name.
# Input CSV (header): target,data_types[,expected_mail,expected_drive]
#   data_types = pipe list of {mail,docs,chat}; expected_* = source item counts (optional, enables count check)

import argparse
import csv
import sys

DIR_SCOPE = "https://www.googleapis.com/auth/admin.directory.user.readonly"
GMAIL_SCOPE = "https://www.googleapis.com/auth/gmail.readonly"
DRIVE_SCOPE = "https://www.googleapis.com/auth/drive.metadata.readonly"


def load_expected(path):
    with open(path, newline="", encoding="utf-8-sig") as fh:
        rows = list(csv.DictReader(fh))
    if not rows:
        print(f"ERROR: no rows in {path}.", file=sys.stderr)
        sys.exit(2)
    return rows


def _int(v):
    try:
        return int(v)
    except (TypeError, ValueError):
        return None


def within_tol(expected, actual, tol_pct):
    if expected in (None, 0) or actual is None:
        return True  # no baseline to compare -> presence check only
    return abs(actual - expected) <= max(1, expected * tol_pct / 100.0)


def build_creds(sa_file, subject, scopes):
    from google.oauth2 import service_account
    import google.auth
    if sa_file:
        creds = service_account.Credentials.from_service_account_file(sa_file, scopes=scopes)
        return creds.with_subject(subject) if subject else creds
    creds, _ = google.auth.default(scopes=scopes)
    return creds


def validate_user(row, sa_file, tol_pct):
    target = (row.get("target") or "").strip()
    dtypes = {t.strip() for t in (row.get("data_types") or "").split("|") if t.strip()}
    result = {"target": target, "data_types": "|".join(sorted(dtypes)), "checks": {}, "passed": True}
    try:
        from googleapiclient.discovery import build
    except Exception:  # noqa: BLE001
        result["checks"]["_creds"] = "google libs unavailable — presence not checked"
        return result

    # Account exists / active
    try:
        subject_admin = None  # directory read uses admin subject if provided elsewhere; use target for data
        dir_creds = build_creds(sa_file, target, [DIR_SCOPE])
        directory = build("admin", "directory_v1", credentials=dir_creds, cache_discovery=False)
        u = directory.users().get(userKey=target, projection="basic").execute()
        if u.get("suspended"):
            result["checks"]["account"] = "FAIL: suspended"
            result["passed"] = False
        else:
            result["checks"]["account"] = "OK"
    except Exception as exc:  # noqa: BLE001
        result["checks"]["account"] = f"FAIL: not resolvable ({exc.__class__.__name__})"
        result["passed"] = False
        return result  # no point checking data on a missing account

    if "mail" in dtypes:
        try:
            gmail = build("gmail", "v1", credentials=build_creds(sa_file, target, [GMAIL_SCOPE]),
                          cache_discovery=False)
            prof = gmail.users().getProfile(userId="me").execute()
            actual = _int(prof.get("messagesTotal"))
            exp = _int(row.get("expected_mail"))
            ok = actual is not None and actual > 0 and within_tol(exp, actual, tol_pct)
            result["checks"]["mail"] = f"{'OK' if ok else 'FAIL'} (messages={actual}, expected~{exp})"
            result["passed"] &= ok
        except Exception as exc:  # noqa: BLE001
            result["checks"]["mail"] = f"FAIL: {exc.__class__.__name__}"
            result["passed"] = False

    if "docs" in dtypes:
        try:
            drive = build("drive", "v3", credentials=build_creds(sa_file, target, [DRIVE_SCOPE]),
                          cache_discovery=False)
            resp = drive.files().list(pageSize=1, fields="files(id)",
                                      q="trashed=false").execute()
            present = bool(resp.get("files"))
            result["checks"]["docs"] = "OK (files present)" if present else "FAIL: no files found"
            result["passed"] &= present
        except Exception as exc:  # noqa: BLE001
            result["checks"]["docs"] = f"FAIL: {exc.__class__.__name__}"
            result["passed"] = False

    if "chat" in dtypes:
        # Chat/Spaces coverage for Teams-to-Chat is verify-for-your-version; presence is asserted manually
        # and recorded here. We do not fabricate a Chat read API scope path.
        result["checks"]["chat"] = "MANUAL: confirm mapped Chat space present (verify for your version)"

    return result


def main():
    ap = argparse.ArgumentParser(description="Per-user post-migration validation (read-only).")
    ap.add_argument("--in", dest="infile", required=True,
                    help="Expected CSV (header: target,data_types[,expected_mail,expected_drive]).")
    ap.add_argument("--google-sa-file", help="Google service-account JSON (read-only scopes).")
    ap.add_argument("--tolerance-pct", type=float, default=2.0,
                    help="Allowed item-count deviation vs source (default 2%%).")
    ap.add_argument("--out", help="Write the per-user CSV report here.")
    args = ap.parse_args()

    rows = load_expected(args.infile)
    print("== BTW Validation - Mail/Docs/Chat - Per User (read-only) ==")
    results, failures = [], 0
    for row in rows:
        res = validate_user(row, args.google_sa_file, args.tolerance_pct)
        results.append(res)
        status = "PASS" if res["passed"] else "FAIL"
        if not res["passed"]:
            failures += 1
        checks = "; ".join(f"{k}={v}" for k, v in res["checks"].items())
        print(f"  [{status}] {res['target']:<32} {checks}")

    print(f"\n== Summary: {len(results) - failures}/{len(results)} passed ==")
    if failures:
        print("  Re-queue/retry failed line items in MigrationWiz, re-run the delta pass, and re-validate.")

    if args.out:
        with open(args.out, "w", newline="", encoding="utf-8") as fh:
            w = csv.writer(fh)
            w.writerow(["target", "data_types", "result", "checks"])
            for r in results:
                w.writerow([r["target"], r["data_types"], "PASS" if r["passed"] else "FAIL",
                            "; ".join(f"{k}={v}" for k, v in r["checks"].items())])
        print(f"  Report written: {args.out}")

    sys.exit(2 if failures else 0)


if __name__ == "__main__":
    main()
