#!/usr/bin/env python3
"""
.SYNOPSIS
    AISAFETY-Discovery.py — read-only inventory of custom AI apps and their current safety posture.

.DESCRIPTION
    PURPOSE
        Assess (Step 1) which AI apps are in scope for guardrails, whether an Azure AI Content Safety
        resource already exists in the subscription, and whether each app calls any safety layer
        (pre/post-generation) today. Produces the worklist and helps pick the pilot app. READ-ONLY —
        it inspects an app-inventory file and lists Azure Cognitive Services accounts; it changes
        nothing.

    HOW TO RUN
        pip install azure-identity azure-mgmt-cognitiveservices
        # Optional: describe your apps in a JSON file (see --apps-file schema below).
        python AISAFETY-Discovery.py --subscription <sub-id> --apps-file apps.json --out discovery.json

        apps.json schema (one object per AI app you own):
        [
          {
            "name": "SupportBot",
            "owner": "jane@contoso.com",
            "accepts_user_text": true,
            "accepts_images": false,
            "generates_content": true,
            "rag": true,
            "current_safety_layer": "none"     // none | pre | post | pre+post
          }
        ]

    EXPECTED RESULTS
        A console summary + JSON report listing: existing Content Safety resources found, and per app
        whether it needs a pre-filter, a post-filter, and groundedness checks. Apps with
        current_safety_layer == "none" are flagged as the highest-priority worklist; one is suggested
        as the pilot.

.NOTES
    White-label. Read-only (no resource is created or modified). Preview capabilities (groundedness,
    protected material, Prompt Shields specifics) evolve — verify current availability in your tenant.
"""
import argparse
import json
import sys


def load_apps(path):
    if not path:
        return []
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError) as exc:
        print(f"[warn] could not read apps file '{path}': {exc}", file=sys.stderr)
        return []


def list_content_safety_resources(subscription_id):
    """Read-only: list Cognitive Services accounts of kind ContentSafety / AIServices."""
    resources = []
    if not subscription_id:
        print("[info] no --subscription given; skipping Azure resource discovery.")
        return resources
    try:
        from azure.identity import DefaultAzureCredential
        from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient

        client = CognitiveServicesManagementClient(DefaultAzureCredential(), subscription_id)
        for acct in client.accounts.list():
            kind = (acct.kind or "").lower()
            if kind in ("contentsafety", "aiservices"):
                resources.append({
                    "name": acct.name,
                    "kind": acct.kind,
                    "location": acct.location,
                    "endpoint": (acct.properties.endpoint if acct.properties else None),
                })
    except Exception as exc:  # noqa: BLE001 - discovery must not hard-fail
        print(f"[warn] Azure resource discovery skipped: {exc}", file=sys.stderr)
    return resources


def assess_app(app):
    needs = {
        "needs_pre_filter": bool(app.get("accepts_user_text") or app.get("accepts_images")),
        "needs_post_filter": bool(app.get("generates_content")),
        "needs_groundedness": bool(app.get("rag")),
        "has_safety_today": (app.get("current_safety_layer", "none") != "none"),
    }
    needs["priority"] = "HIGH" if not needs["has_safety_today"] else "review"
    return needs


def main():
    ap = argparse.ArgumentParser(description="Read-only AI-app + Content-Safety discovery.")
    ap.add_argument("--subscription", help="Azure subscription id (optional; enables resource scan).")
    ap.add_argument("--apps-file", help="JSON file describing your AI apps (see docstring).")
    ap.add_argument("--out", default="discovery.json", help="Output JSON report path.")
    args = ap.parse_args()

    resources = list_content_safety_resources(args.subscription)
    apps = load_apps(args.apps_file)

    assessed = []
    for app in apps:
        a = dict(app)
        a["assessment"] = assess_app(app)
        assessed.append(a)

    high = [a for a in assessed if a["assessment"]["priority"] == "HIGH"]
    pilot_suggestion = high[0]["name"] if high else (assessed[0]["name"] if assessed else None)

    report = {
        "content_safety_resources_found": resources,
        "apps": assessed,
        "worklist_high_priority": [a["name"] for a in high],
        "suggested_pilot_app": pilot_suggestion,
    }

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    print("=== AISAFETY Discovery (read-only) ===")
    print(f"Content Safety resources found : {len(resources)}")
    for r in resources:
        print(f"  - {r['name']} ({r['kind']}, {r['location']})")
    print(f"AI apps assessed               : {len(assessed)}")
    for a in assessed:
        s = a["assessment"]
        print(f"  - {a.get('name')}: pre={s['needs_pre_filter']} post={s['needs_post_filter']} "
              f"groundedness={s['needs_groundedness']} priority={s['priority']}")
    print(f"Suggested pilot app            : {pilot_suggestion}")
    print(f"Report written                 : {args.out}")


if __name__ == "__main__":
    main()
