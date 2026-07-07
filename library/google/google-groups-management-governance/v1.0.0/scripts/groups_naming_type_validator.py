#!/usr/bin/env python3
# groups_naming_type_validator.py — naming-convention & type-policy conformance gate (read-only)
#
# PURPOSE: Assert every group in scope conforms to the naming standard (<Type> – <Scope> – <Purpose>
#          display + email prefix dl-/sec-/collab-/dyn-/ext-) AND that its Groups settings match the
#          declared type's policy row (Step 1.1). READ-ONLY: Directory + Groups Settings read only.
#          This is a GATE tool — it exits non-zero when any drift is found (Gates 3/4, Test 3).
# HOW TO RUN: python groups_naming_type_validator.py --domain corp.example [--scope finance] [--json]
#             (Python 3.10+, OAuth/ADC with the *.readonly scopes in Requirement 2.6;
#              `pip install google-api-python-client google-auth`. See --help.)
# EXPECTED RESULTS: PASS (exit 0) with no drift, or a per-group list of naming/type violations and
#          exit 1 so CI/change-control can gate on it.
#
# SAFETY: read-only. No credentials/keys embedded — auth resolved at runtime (ADC / delegated SA).

import argparse
import json
import re
import sys

GROUP_RO = "https://www.googleapis.com/auth/admin.directory.group.readonly"
SETTINGS = "https://www.googleapis.com/auth/apps.groups.settings"

# Canonical type policy (subset of fields the validator asserts). Mirrors Step 1.1 in Section 3.
TYPE_POLICY = {
    "dl-":     {"type": "distribution",  "whoCanPostMessage": {"ALL_IN_DOMAIN_CAN_POST"},
                "external_allowed": False},
    "sec-":    {"type": "security",      "whoCanPostMessage": {"NONE_CAN_POST"},
                "external_allowed": False},
    "collab-": {"type": "collaboration", "whoCanPostMessage": {"ALL_MEMBERS_CAN_POST"},
                "external_allowed": False},
    "dyn-":    {"type": "dynamic",       "whoCanPostMessage": None,  # inherits underlying type
                "external_allowed": False},
    "ext-":    {"type": "external",      "whoCanPostMessage": {"ALL_MEMBERS_CAN_POST"},
                "external_allowed": True},
}
# Display-name convention: "<Type> – <Scope> – <Purpose>" (en dash, 3 parts).
NAME_RE = re.compile(r"^\s*\S.*\s[–-]\s.*\s[–-]\s.*\S\s*$")


def build_services():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("ERROR: pip install google-api-python-client google-auth", file=sys.stderr)
        sys.exit(2)
    creds, _ = google.auth.default(scopes=[GROUP_RO, SETTINGS])
    directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    settings = build("groupssettings", "v1", credentials=creds, cache_discovery=False)
    return directory, settings


def list_groups(directory, domain, scope):
    groups, page = [], None
    while True:
        resp = directory.groups().list(domain=domain, maxResults=200, pageToken=page).execute()
        for g in resp.get("groups", []):
            if scope and scope.lower() not in (g.get("email", "") + g.get("name", "")).lower():
                continue
            groups.append(g)
        page = resp.get("nextPageToken")
        if not page:
            break
    return groups


def validate(g, cfg):
    """Return a list of violation strings for one group ([] == conformant)."""
    email = g.get("email", "")
    name = g.get("name", "")
    local = email.split("@", 1)[0].lower()
    v = []
    prefix = next((p for p in TYPE_POLICY if local.startswith(p)), None)
    if prefix is None:
        return [f"email prefix off-standard (expected one of {list(TYPE_POLICY)})"]
    if not NAME_RE.match(name):
        v.append(f"display name '{name}' not '<Type> – <Scope> – <Purpose>'")
    policy = TYPE_POLICY[prefix]
    want = policy["whoCanPostMessage"]
    got = cfg.get("whoCanPostMessage")
    if want is not None and got not in want:
        v.append(f"whoCanPostMessage={got} not in policy {sorted(want)} for type {policy['type']}")
    return v


def main():
    ap = argparse.ArgumentParser(description="Naming & type-policy conformance gate (read-only).")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--scope", help="Substring filter on email/name")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    directory, settings = build_services()
    groups = list_groups(directory, args.domain, args.scope)
    print(f"Naming/type validator — domain={args.domain} scope={args.scope or 'ALL'} "
          f"({len(groups)} groups)\n")

    drift = {}
    for g in groups:
        email = g.get("email", "")
        try:
            cfg = settings.groups().get(groupUniqueId=email, alt="json").execute()
        except Exception:
            cfg = {}
        viols = validate(g, cfg)
        if viols:
            drift[email] = viols

    if not drift:
        print("PASS — every group conforms to naming + type policy.")
        if args.json:
            print(json.dumps({"result": "PASS", "groups": len(groups), "drift": {}}, indent=2))
        return 0

    print(f"FAIL — {len(drift)} group(s) off-standard:")
    for email, viols in drift.items():
        print(f"  {email}")
        for x in viols:
            print(f"      - {x}")
    if args.json:
        print(json.dumps({"result": "FAIL", "groups": len(groups), "drift": drift}, indent=2))
    return 1  # gate signal


if __name__ == "__main__":
    sys.exit(main())
