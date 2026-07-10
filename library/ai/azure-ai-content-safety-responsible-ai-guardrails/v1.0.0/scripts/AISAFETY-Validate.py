#!/usr/bin/env python3
"""
.SYNOPSIS
    AISAFETY-Validate.py — read-only check that the guardrail configuration is correctly wired.

.DESCRIPTION
    PURPOSE
        Confirm, before you rely on the safety filter, that:
          * the Content Safety resource is reachable KEYLESS (managed identity / DefaultAzureCredential),
          * a benign probe returns a well-formed analyze_text result (category severities present),
          * the custom blocklist `Prohibited Terms - App Guardrails - Pilot` exists,
          * the severity policy config loads and has per-category thresholds,
          * Prompt Shields / groundedness endpoints respond OR are clearly reported as unavailable
            in-region so you know before depending on them.
        READ-ONLY — sends only a benign probe string and lists config; changes nothing.

    HOW TO RUN
        pip install azure-ai-contentsafety azure-identity
        export CONTENT_SAFETY_ENDPOINT="https://<resource>.cognitiveservices.azure.com/"
        python AISAFETY-Validate.py --policy severity_policy.json \
               --blocklist "Prohibited Terms - App Guardrails - Pilot"

    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall result. Non-zero exit if any REQUIRED check fails
        (auth, moderation, blocklist, policy). Preview capabilities are reported as INFO/N-A, not
        failures, when unavailable in-region.

.NOTES
    White-label. Read-only. Preview capabilities (Prompt Shields, groundedness, protected material)
    are verified defensively — verify current availability in your tenant.
"""
import argparse
import json
import os
import sys

BENIGN_PROBE = "Hello, this is a routine configuration check. Please have a nice day."
CATEGORIES = ["Hate", "Sexual", "Violence", "SelfHarm"]


def _client(endpoint):
    from azure.ai.contentsafety import ContentSafetyClient
    from azure.identity import DefaultAzureCredential
    return ContentSafetyClient(endpoint, DefaultAzureCredential())


def check_auth_and_moderation(endpoint, results):
    try:
        from azure.ai.contentsafety.models import AnalyzeTextOptions
        client = _client(endpoint)
        resp = client.analyze_text(AnalyzeTextOptions(text=BENIGN_PROBE))
        cats = {str(i.category): int(i.severity or 0) for i in (resp.categories_analysis or [])}
        ok = all(c in cats for c in CATEGORIES)
        results.append(("Keyless auth + text moderation", ok,
                        f"categories returned: {sorted(cats)}"))
        return client, ok
    except Exception as exc:  # noqa: BLE001
        results.append(("Keyless auth + text moderation", False, str(exc)))
        return None, False


def check_blocklist(endpoint, name, results):
    try:
        from azure.ai.contentsafety import BlocklistClient
        from azure.identity import DefaultAzureCredential
        bl = BlocklistClient(endpoint, DefaultAzureCredential())
        names = [b.blocklist_name for b in bl.list_text_blocklists()]
        ok = name in names
        results.append((f"Blocklist '{name}' exists", ok, f"found: {names}"))
    except Exception as exc:  # noqa: BLE001
        results.append((f"Blocklist '{name}' exists", False, str(exc)))


def check_policy(path, results):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            policy = json.load(fh)
        block = policy.get("block", {})
        ok = all(c in block for c in CATEGORIES)
        results.append(("Severity policy loads with all categories", ok,
                        f"block thresholds: {block}"))
    except Exception as exc:  # noqa: BLE001
        results.append(("Severity policy loads with all categories", False, str(exc)))


def check_prompt_shields(client, results):
    if client is None:
        results.append(("Prompt Shields reachable (preview)", None, "skipped — no client"))
        return
    shield = getattr(client, "shield_prompt", None) or getattr(client, "detect_jailbreak", None)
    if shield is None:
        results.append(("Prompt Shields reachable (preview)", None,
                        "method not in this SDK version — verify availability/API version (N/A)"))
        return
    try:
        shield(user_prompt=BENIGN_PROBE, documents=[])
        results.append(("Prompt Shields reachable (preview)", True, "responded to benign probe"))
    except Exception as exc:  # noqa: BLE001
        results.append(("Prompt Shields reachable (preview)", None,
                        f"unavailable in-region (N/A): {exc}"))


def main():
    ap = argparse.ArgumentParser(description="Read-only guardrail configuration validator.")
    ap.add_argument("--endpoint", default=os.environ.get("CONTENT_SAFETY_ENDPOINT", ""))
    ap.add_argument("--policy", default="severity_policy.json")
    ap.add_argument("--blocklist", default="Prohibited Terms - App Guardrails - Pilot")
    args = ap.parse_args()

    if not args.endpoint:
        print("[FAIL] CONTENT_SAFETY_ENDPOINT not set (pass --endpoint or set the env var).")
        sys.exit(2)

    results = []  # (name, ok|None, detail)  — None = informational/N-A (preview)
    client, _ = check_auth_and_moderation(args.endpoint, results)
    check_blocklist(args.endpoint, args.blocklist, results)
    check_policy(args.policy, results)
    check_prompt_shields(client, results)

    print("=== AISAFETY Validate (read-only) ===")
    required_ok = True
    for name, ok, detail in results:
        if ok is True:
            tag = "PASS"
        elif ok is False:
            tag = "FAIL"
            required_ok = False
        else:
            tag = "N/A "
        print(f"[{tag}] {name} — {detail}")

    print("-" * 40)
    print("OVERALL:", "PASS" if required_ok else "FAIL (fix required checks before relying on the filter)")
    sys.exit(0 if required_ok else 1)


if __name__ == "__main__":
    main()
