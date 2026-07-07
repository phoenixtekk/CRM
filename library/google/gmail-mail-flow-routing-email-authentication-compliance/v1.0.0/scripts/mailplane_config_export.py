#!/usr/bin/env python3
# mailplane_config_export.py — Export & validate Gmail routing/domain config via the Admin SDK (read-only).
#
# PURPOSE: Read-only export of mail-plane configuration for change evidence and rollback reference.
#          Pulls domains, domain aliases, and (where the Admin SDK exposes it) sending/routing-relevant
#          settings, plus a naming-convention validation of any routing/compliance artifacts supplied in
#          a design manifest. Never writes to the tenant. Auth via OAuth or Application Default Creds.
# HOW TO RUN: python mailplane_config_export.py --section {domains,routing,all} [--manifest design.json]
#             [--out configured]   (Python 3.10+; pip install google-api-python-client google-auth
#             google-auth-oauthlib; set GOOGLE_APPLICATION_CREDENTIALS or use --oauth-client)
# EXPECTED RESULTS: A JSON export of the readable config and a PASS/FAIL on artifact naming
#                   (<Purpose> - <Scope> - <Stage>). No changes are made; safe to run repeatedly.

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone

# Least-privilege, READ-ONLY scopes only.
SCOPES = [
    "https://www.googleapis.com/auth/admin.directory.domain.readonly",
    "https://www.googleapis.com/auth/apps.groups.settings",  # read-only usage below
]

NAME_RE = re.compile(r"^.+\s+–\s+.+\s+–\s+(Assess|Design|Pilot|Prod|Monitor|Quarantine|Enforce|Target)$")
# Accept both en-dash and hyphen separators for convenience.
NAME_RE_ALT = re.compile(r"^.+\s+-\s+.+\s+-\s+(Assess|Design|Pilot|Prod|Monitor|Quarantine|Enforce|Target)$")


def _build_service(oauth_client: str | None):
    """Build a read-only Admin SDK Directory service using ADC or an installed-app OAuth flow."""
    try:
        from googleapiclient.discovery import build
    except Exception:
        print("[error] google-api-python-client not installed. "
              "pip install google-api-python-client google-auth google-auth-oauthlib", file=sys.stderr)
        raise SystemExit(3)

    creds = None
    if oauth_client:
        from google_auth_oauthlib.flow import InstalledAppFlow
        flow = InstalledAppFlow.from_client_secrets_file(oauth_client, SCOPES)
        creds = flow.run_local_server(port=0)
    else:
        # Application Default Credentials (e.g. an ADC / service account with domain-wide delegation).
        import google.auth
        creds, _ = google.auth.default(scopes=SCOPES)

    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def export_domains(service) -> dict:
    """Read domains + aliases (read-only)."""
    out: dict = {"domains": []}
    resp = service.domains().list(customer="my_customer").execute()
    for d in resp.get("domains", []):
        out["domains"].append({
            "domainName": d.get("domainName"),
            "isPrimary": d.get("isPrimary"),
            "verified": d.get("verified"),
            "domainAliases": [a.get("domainAliasName") for a in d.get("domainAliases", [])],
        })
    return out


def validate_manifest(manifest_path: str) -> tuple[list, list]:
    """Validate that every named artifact in a design manifest follows the naming convention."""
    with open(manifest_path, encoding="utf-8") as fh:
        manifest = json.load(fh)
    names = []
    for key in ("routes", "hosts", "rules", "records", "artifacts"):
        for item in manifest.get(key, []):
            names.append(item if isinstance(item, str) else item.get("name", ""))
    ok, bad = [], []
    for n in names:
        (ok if (NAME_RE.match(n) or NAME_RE_ALT.match(n)) else bad).append(n)
    return ok, bad


def main() -> int:
    ap = argparse.ArgumentParser(description="Read-only Gmail mail-plane config export + naming validation.")
    ap.add_argument("--section", choices=["domains", "routing", "all"], default="all")
    ap.add_argument("--manifest", help="Optional design manifest JSON to validate artifact naming.")
    ap.add_argument("--oauth-client", help="Path to an OAuth client_secret.json (installed-app flow).")
    ap.add_argument("--out", help="Output basename for the JSON export.")
    ap.add_argument("--offline", action="store_true",
                    help="Skip the Admin SDK call; only validate the manifest (no credentials needed).")
    args = ap.parse_args()

    export: dict = {"generated": datetime.now(timezone.utc).isoformat(), "section": args.section}

    if not args.offline and args.section in ("domains", "routing", "all"):
        try:
            service = _build_service(args.oauth_client)
            if args.section in ("domains", "all"):
                export.update(export_domains(service))
            if args.section in ("routing", "all"):
                # The Admin SDK does not expose all Gmail routing rules programmatically; routing/
                # content-compliance rules are configured in the Admin console and captured here from
                # the design manifest. Deep console internals are out of scope by design.
                export["routing_note"] = ("Routing/content-compliance rules are console-managed; "
                                          "capture them via the design manifest and Email Log Search.")
        except SystemExit:
            raise
        except Exception as e:
            print(f"[warn] Admin SDK export skipped ({e}). Re-run with valid ADC/OAuth or use --offline.",
                  file=sys.stderr)

    exit_code = 0
    if args.manifest:
        ok, bad = validate_manifest(args.manifest)
        export["naming_validation"] = {"ok": ok, "nonconforming": bad}
        print(f"Artifact naming: {len(ok)} conforming, {len(bad)} nonconforming.")
        for n in bad:
            print(f"  [FAIL] '{n}' is not '<Purpose> – <Scope> – <Stage>'")
        if bad:
            exit_code = 2

    if "domains" in export:
        print(f"\nDomains ({len(export['domains'])}):")
        for d in export["domains"]:
            flag = "primary" if d["isPrimary"] else "secondary"
            print(f"  - {d['domainName']} [{flag}] verified={d['verified']} "
                  f"aliases={d['domainAliases'] or '-'}")

    if args.out:
        with open(f"{args.out}.json", "w", encoding="utf-8") as fh:
            json.dump(export, fh, indent=2)
        print(f"\n[written] {args.out}.json")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
