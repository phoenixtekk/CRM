#!/usr/bin/env python3
# saml_app_onboarding_helper.py — generate the standardized onboarding checklist + attribute map for an app
#
# PURPOSE: Given an app's service-provider (SP) details, produce the exact Google-Admin onboarding
#          steps, the standardized `Attribute Map - <App> - v1`, and the assignment-group / naming
#          artifacts for `SSO Onboarding Pattern - SaaS - v1`. DRY-RUN by default: it prints the plan
#          and writes nothing unless --apply is given (then it writes the checklist/map files locally).
# HOW TO RUN: python saml_app_onboarding_helper.py --app "Salesforce" --type saml \
#               --acs-url https://... --sp-entity-id https://... [--apply] [--out-dir ./onboarding]
#             (Python 3.10+; no Google auth needed — this is a local generator. See --help.)
# EXPECTED RESULTS: A ready-to-run onboarding checklist + attribute map printed to stdout; with
#          --apply, the same written to <out-dir>/<app>-checklist.md and <app>-attribute-map.json.
#
# SAFETY: dry-run default; the only write action (--apply) creates LOCAL files. No Google API calls,
#         no credentials, no secrets. It never changes tenant configuration — a human runs the steps.

import argparse
import json
import os
import re
import sys

STANDARD_NAMEID = {"source": "Basic Information > Primary email", "format": "EMAIL", "persistent": True}


def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.strip().lower()).strip("-") or "app"


def assignment_group_name(app):
    return f"Assignment Group - {app} - Users"


def attribute_map(app, groups_claim):
    """The standardized attribute map. Groups claim is added only when the SP consumes it."""
    mapping = {
        "artifact_name": f"Attribute Map - {app} - v1",
        "name_id": STANDARD_NAMEID,
        "attributes": [
            {"app_attribute": "email", "google_source": "Basic Information > Primary email"},
            {"app_attribute": "firstName", "google_source": "Basic Information > First name"},
            {"app_attribute": "lastName", "google_source": "Basic Information > Last name"},
        ],
    }
    if groups_claim:
        mapping["attributes"].append(
            {"app_attribute": groups_claim,
             "google_source": "Group membership (scoped to the assignment group)",
             "note": "Only include if the app consumes a groups claim for in-app roles."})
    return mapping


def build_checklist(app, app_type, acs_url, sp_entity_id, redirect_uris, is_custom):
    grp = assignment_group_name(app)
    app_object = f"Custom SAML App - {app} - v1" if is_custom else f"{app} (prebuilt catalog app)"
    steps = [
        f"# Onboarding Checklist - {app}  ({app_type.upper()})",
        f"_Pattern: `SSO Onboarding Pattern - SaaS - v1`  |  App object: `{app_object}`_",
        "",
        "## 1. Collect SP details (done)",
    ]
    if app_type == "saml":
        steps += [
            f"- ACS / Reply URL: `{acs_url or '<REQUIRED - obtain from the app>'}`",
            f"- SP Entity ID / Audience: `{sp_entity_id or '<REQUIRED - obtain from the app>'}`",
        ]
    else:
        steps += [
            f"- Redirect URIs: `{redirect_uris or '<REQUIRED - obtain from the app>'}`",
            "- Required scopes: `<obtain from the app; request least privilege>`",
        ]
    steps += [
        "",
        "## 2. Create the app in Google Admin",
        "- admin.google.com -> Apps -> Web and mobile apps -> Add app.",
        ("- Add custom SAML app; name it EXACTLY: "
         f"`{app_object}`." if is_custom else
         f"- Search the prebuilt catalog for `{app}` and select it."),
        "",
        "## 3. Exchange metadata / certificate (both directions)",
        "- From Google: copy SSO URL, Entity ID, and download the signing Certificate (or IdP metadata).",
        "- Paste Google's IdP metadata into the app's SSO settings (app's own console - vendor docs).",
        "- Paste the app's ACS URL / Entity ID (or OIDC redirect URIs) back into Google.",
        "- Record Google's IdP-cert EXPIRY in the catalog for rotation tracking.",
        "",
        "## 4. Attribute map",
        f"- Apply `Attribute Map - {app} - v1` (see the attribute-map file).",
        f"- Name ID = {STANDARD_NAMEID['source']} (format {STANDARD_NAMEID['format']}), "
        "unless the app documents a different NameID.",
        "",
        "## 5. Provisioning (if supported)",
        "- If Google shows Auto-provisioning for this app: enable it and SCOPE it to "
        f"`{grp}`.",
        "- Else, if the app has its own SCIM endpoint: configure SCIM (vendor docs), scope to the "
        "same group. Else record method = manual/JIT in the catalog.",
        "",
        "## 6. Assign by GROUP only",
        f"- User access -> turn ON only for `{grp}`. NEVER assign to All users or a broad OU.",
        "",
        "## 7. Pilot test (Gate 3)",
        "- Validate against `Pilot Cohort - SSO Factory - Pilot`: SP- and IdP-initiated SSO, "
        "group-only access, provisioning create + deactivate. See the Testing guide.",
        "",
        "## 8. Record in the catalog",
        f"- Append `{app}` to `App Catalog - Federated SaaS - v1` "
        "(type, attribute map, group, provisioning method, owner, cert expiry, status).",
    ]
    return "\n".join(steps) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description="Generate the standardized app-onboarding checklist + map.")
    ap.add_argument("--app", required=True, help="app display name, e.g. 'Salesforce'")
    ap.add_argument("--type", choices=["saml", "oidc"], default="saml", help="federation type")
    ap.add_argument("--acs-url", help="SAML ACS/Reply URL (SAML apps)")
    ap.add_argument("--sp-entity-id", help="SAML SP Entity ID / audience (SAML apps)")
    ap.add_argument("--redirect-uris", help="comma-separated OIDC redirect URIs (OIDC apps)")
    ap.add_argument("--custom", action="store_true",
                    help="app is NOT in the prebuilt catalog (create a custom SAML app)")
    ap.add_argument("--groups-claim",
                    help="app attribute name for a groups claim, only if the app consumes one")
    ap.add_argument("--apply", action="store_true", help="write the checklist + map to --out-dir")
    ap.add_argument("--out-dir", default="./onboarding", help="output dir when --apply is set")
    args = ap.parse_args(argv)

    checklist = build_checklist(args.app, args.type, args.acs_url, args.sp_entity_id,
                                args.redirect_uris, args.custom)
    amap = attribute_map(args.app, args.groups_claim)

    print(checklist)
    print("\n----- Attribute Map (JSON) -----")
    print(json.dumps(amap, indent=2))
    print(f"\nAssignment group to create/use: {assignment_group_name(args.app)}")

    if not args.apply:
        print("\n[dry-run] Nothing written. Re-run with --apply to save these files locally.")
        return 0

    os.makedirs(args.out_dir, exist_ok=True)
    s = slug(args.app)
    cpath = os.path.join(args.out_dir, f"{s}-checklist.md")
    mpath = os.path.join(args.out_dir, f"{s}-attribute-map.json")
    with open(cpath, "w", encoding="utf-8") as fh:
        fh.write(checklist)
    with open(mpath, "w", encoding="utf-8") as fh:
        json.dump(amap, fh, indent=2)
    print(f"\n[applied] wrote {cpath} and {mpath} (local files only; tenant unchanged).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
