#!/usr/bin/env python3
# sso_readiness_assessment.py — read-only SSO/provisioning readiness baseline for the SaaS estate
#
# PURPOSE: Read an app inventory (CSV) and, optionally, verify the assignment groups exist via the
#          Admin SDK Directory API, then report each app's declared auth method, SSO/SCIM readiness,
#          owner, and whether its assignment group is present. Read-only: it changes no configuration.
# HOW TO RUN: python sso_readiness_assessment.py --apps apps.csv [--check-groups] [--out readiness.json]
#             (Python 3.10+, gcloud auth / ADC; see --help)
# EXPECTED RESULTS: A per-app readiness table on stdout (and optional JSON) classifying each app as
#          READY / PARTIAL / NOT-READY for the factory. Non-zero exit only on input/auth errors.
#
# Inventory CSV columns (header row required; extra columns ignored):
#   app,owner,auth_method,supports_saml,supports_oidc,supports_scim,assignment_group
#   - auth_method: one of local | saml | oidc | other | unknown
#   - supports_*:  true/false/unknown
#   - assignment_group: the Google Group email that should grant the app (may be blank)
#
# SAFETY: read-only. Group existence is checked with the read-only Directory scope only. No writes,
#         no credentials in code — authentication is via Application Default Credentials (ADC).

import argparse
import csv
import json
import sys

DIRECTORY_RO_SCOPE = "https://www.googleapis.com/auth/admin.directory.group.readonly"


def parse_bool(value):
    v = (value or "").strip().lower()
    if v in ("true", "yes", "y", "1"):
        return True
    if v in ("false", "no", "n", "0"):
        return False
    return None  # unknown


def load_inventory(path):
    rows = []
    with open(path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        required = {"app"}
        if not required.issubset({(c or "").strip() for c in (reader.fieldnames or [])}):
            raise ValueError("inventory CSV must have at least an 'app' column")
        for raw in reader:
            rows.append({
                "app": (raw.get("app") or "").strip(),
                "owner": (raw.get("owner") or "").strip(),
                "auth_method": (raw.get("auth_method") or "unknown").strip().lower(),
                "supports_saml": parse_bool(raw.get("supports_saml")),
                "supports_oidc": parse_bool(raw.get("supports_oidc")),
                "supports_scim": parse_bool(raw.get("supports_scim")),
                "assignment_group": (raw.get("assignment_group") or "").strip(),
            })
    return [r for r in rows if r["app"]]


def build_directory_service():
    """Build a read-only Admin SDK Directory client using ADC. Imported lazily so the tool
    still runs (inventory-only) without the client libraries installed."""
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("[!] --check-groups needs: pip install google-api-python-client google-auth",
              file=sys.stderr)
        return None
    try:
        creds, _ = google.auth.default(scopes=[DIRECTORY_RO_SCOPE])
        return build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    except Exception as exc:  # noqa: BLE001 - surface any auth/discovery problem, keep running
        print(f"[!] could not initialize Directory API ({exc}); continuing without group checks.",
              file=sys.stderr)
        return None


def group_exists(service, group_email):
    if not group_email:
        return None
    try:
        service.groups().get(groupKey=group_email).execute()
        return True
    except Exception:  # noqa: BLE001 - 404 or permission -> treat as "not found/unknown"
        return False


def classify(app):
    """Return (status, notes) for the factory readiness of one app."""
    notes = []
    can_federate = app["supports_saml"] is True or app["supports_oidc"] is True \
        or app["auth_method"] in ("saml", "oidc")
    if not app["owner"]:
        notes.append("no owner")
    if not app["assignment_group"]:
        notes.append("no assignment group")
    if app["supports_scim"] is not True:
        notes.append("provisioning=manual/unknown")

    if not can_federate:
        return "NOT-READY", notes + ["no SAML/OIDC support declared"]
    if notes:
        return "PARTIAL", notes
    return "READY", ["federates + owner + group + provisioning"]


def main(argv=None):
    ap = argparse.ArgumentParser(description="Read-only SSO/provisioning readiness baseline.")
    ap.add_argument("--apps", required=True, help="path to the app inventory CSV")
    ap.add_argument("--check-groups", action="store_true",
                    help="verify each assignment_group exists via the Admin SDK (read-only)")
    ap.add_argument("--out", help="optional path to write the readiness JSON")
    args = ap.parse_args(argv)

    try:
        inventory = load_inventory(args.apps)
    except (OSError, ValueError) as exc:
        print(f"[x] cannot read inventory: {exc}", file=sys.stderr)
        return 2
    if not inventory:
        print("[x] inventory is empty.", file=sys.stderr)
        return 2

    service = build_directory_service() if args.check_groups else None

    results = []
    for app in inventory:
        grp_present = group_exists(service, app["assignment_group"]) if service else None
        status, notes = classify(app)
        if grp_present is False and app["assignment_group"]:
            status = "PARTIAL" if status == "READY" else status
            notes = notes + [f"group '{app['assignment_group']}' NOT found in directory"]
        results.append({**app, "group_present": grp_present, "status": status, "notes": notes})

    counts = {"READY": 0, "PARTIAL": 0, "NOT-READY": 0}
    print("\nSSO Readiness Assessment (read-only)\n" + "=" * 60)
    for r in results:
        counts[r["status"]] += 1
        print(f"[{r['status']:<9}] {r['app']}")
        print(f"            auth={r['auth_method']} saml={r['supports_saml']} "
              f"oidc={r['supports_oidc']} scim={r['supports_scim']}")
        print(f"            group={r['assignment_group'] or '(none)'} "
              f"present={r['group_present']} owner={r['owner'] or '(none)'}")
        print(f"            notes: {', '.join(r['notes'])}")
    print("=" * 60)
    print(f"Totals: READY={counts['READY']}  PARTIAL={counts['PARTIAL']}  "
          f"NOT-READY={counts['NOT-READY']}  (of {len(results)} apps)")
    print("This is a read-only baseline; no configuration was changed.")

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump({"apps": results, "totals": counts}, fh, indent=2)
        print(f"[i] wrote {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
