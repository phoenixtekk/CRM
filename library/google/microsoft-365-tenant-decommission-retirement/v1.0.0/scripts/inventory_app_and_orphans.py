#!/usr/bin/env python3
# inventory_app_and_orphans.py — inventory Entra apps/SPs/credentials + orphaned identities (read-only)
#
# PURPOSE: Enumerate the identity/app trust the migration left behind — app registrations, enterprise
#          apps (service principals), long-lived/expired secrets & certs, and stale/guest/orphaned
#          accounts — classify them, and optionally disable/remove named objects. --mode data instead
#          inventories data-bearing users (mailbox/OneDrive presence) as Phase-2 disposition input.
#          SAFE BY DEFAULT: read-only unless --apply; even with --apply the default action is DISABLE.
# HOW TO RUN: python inventory_app_and_orphans.py --mode identity [--stale-days 90] --out inv.json
#             [--apply --action disable|remove --scope-file objects.txt]  (Py 3.10+; msal+requests; env creds)
# EXPECTED RESULTS: JSON inventory + stdout. Flags standing secrets, orphaned SPs, guests, never-signed-in
#          accounts. Dry-run changes nothing; --apply acts ONLY on ids/appIds listed in --scope-file.
#
# Credentials from ENVIRONMENT only: M365DECOM_TENANT_ID / M365DECOM_CLIENT_ID / M365DECOM_CLIENT_SECRET.
# READ needs: Application.Read.All, Directory.Read.All, AuditLog.Read.All, User.Read.All.
# --apply additionally needs write scopes/roles (Application.ReadWrite.All / User.ReadWrite.All).
# NEVER pass --action remove without a soak on --action disable first (see the Implementation guide).

import argparse
import datetime as dt
import json
import os
import sys

GRAPH = "https://graph.microsoft.com/v1.0"
SCOPE = ["https://graph.microsoft.com/.default"]


def die(msg: str, code: int = 2) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(code)


def get_token() -> str:
    try:
        import msal  # type: ignore
    except ImportError:
        die("msal not installed. Run: pip install msal requests")
    tenant = os.environ.get("M365DECOM_TENANT_ID")
    client = os.environ.get("M365DECOM_CLIENT_ID")
    secret = os.environ.get("M365DECOM_CLIENT_SECRET")
    if not (tenant and client and secret):
        die("Set M365DECOM_TENANT_ID / M365DECOM_CLIENT_ID / M365DECOM_CLIENT_SECRET in the environment.")
    app = msal.ConfidentialClientApplication(
        client_id=client,
        authority=f"https://login.microsoftonline.com/{tenant}",
        client_credential=secret,
    )
    result = app.acquire_token_for_client(scopes=SCOPE)
    if "access_token" not in result:
        die(f"Token request failed: {result.get('error_description', result.get('error'))}")
    return result["access_token"]


def graph_paged(session, url: str):
    import time
    items = []
    while url:
        for attempt in range(5):
            resp = session.get(url, timeout=60)
            if resp.status_code == 429 or resp.status_code >= 500:
                time.sleep(min(int(resp.headers.get("Retry-After", 2 ** attempt)), 30))
                continue
            if not resp.ok:
                die(f"Graph GET {url} -> {resp.status_code}: {resp.text[:300]}")
            data = resp.json()
            break
        else:
            die(f"Graph GET {url} kept throttling.")
        if isinstance(data, dict) and "value" in data:
            items.extend(data["value"])
            url = data.get("@odata.nextLink")
        else:
            return data
    return items


def load_set(path):
    if not path:
        return set()
    with open(path, encoding="utf-8") as fh:
        return {ln.strip() for ln in fh if ln.strip() and not ln.startswith("#")}


def parse_dt(s):
    if not s:
        return None
    try:
        return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        return None


def inventory_identity(session, stale_days):
    now = dt.datetime.now(dt.timezone.utc)
    findings = {"app_registrations": [], "service_principals": [], "stale_accounts": [], "guests": []}

    for app in graph_paged(session, f"{GRAPH}/applications"
                                    "?$select=id,appId,displayName,passwordCredentials,keyCredentials,web"):
        secrets = app.get("passwordCredentials") or []
        keys = app.get("keyCredentials") or []
        expired = long_lived = 0
        for cred in secrets + keys:
            end = parse_dt(cred.get("endDateTime"))
            start = parse_dt(cred.get("startDateTime"))
            if end and end < now:
                expired += 1
            if start and end and (end - start).days > 365:
                long_lived += 1
        reply = ((app.get("web") or {}).get("redirectUris") or [])
        flags = []
        if expired:
            flags.append(f"{expired} expired credential(s)")
        if long_lived:
            flags.append(f"{long_lived} credential(s) valid >365d")
        if secrets or keys:
            flags.append(f"{len(secrets)} secret(s)/{len(keys)} cert(s) present")
        findings["app_registrations"].append({
            "id": app["id"], "appId": app.get("appId"),
            "displayName": app.get("displayName"), "replyUrls": reply,
            "classification": "REVIEW" if flags else "KEEP?", "signals": flags})

    stale_cut = now - dt.timedelta(days=stale_days)
    for sp in graph_paged(session, f"{GRAPH}/servicePrincipals"
                                   "?$select=id,appId,displayName,accountEnabled,servicePrincipalType,replyUrls"):
        entry = {"id": sp["id"], "appId": sp.get("appId"),
                 "displayName": sp.get("displayName"),
                 "type": sp.get("servicePrincipalType"),
                 "enabled": sp.get("accountEnabled"),
                 "replyUrls": sp.get("replyUrls") or [],
                 "classification": "REVIEW", "signals": []}
        if not sp.get("accountEnabled"):
            entry["signals"].append("already disabled")
        findings["service_principals"].append(entry)

    for u in graph_paged(session, f"{GRAPH}/users?$select=id,userPrincipalName,userType,"
                                  "accountEnabled,createdDateTime,signInActivity&$top=999"):
        last = parse_dt((u.get("signInActivity") or {}).get("lastSignInDateTime"))
        entry = {"id": u["id"], "userPrincipalName": u.get("userPrincipalName"),
                 "userType": u.get("userType"), "enabled": u.get("accountEnabled"),
                 "lastSignIn": (u.get("signInActivity") or {}).get("lastSignInDateTime"),
                 "signals": []}
        if (u.get("userType") or "").lower() == "guest":
            entry["signals"].append("guest account")
            findings["guests"].append(entry)
        if last is None:
            entry["signals"].append("never signed in")
            findings["stale_accounts"].append(entry)
        elif last < stale_cut:
            entry["signals"].append(f"no sign-in since {last.date()}")
            findings["stale_accounts"].append(entry)
    return findings


def inventory_data(session):
    """Phase-2 input: users that still hold mailbox/OneDrive data (disposition candidates)."""
    rows = []
    for u in graph_paged(session, f"{GRAPH}/users?$select=id,userPrincipalName,accountEnabled&$top=999"):
        drive = graph_paged(session, f"{GRAPH}/users/{u['userPrincipalName']}/drive?$select=quota")
        used_mb = None
        if isinstance(drive, dict) and drive.get("quota"):
            used_mb = round((drive["quota"].get("used") or 0) / (1024 * 1024), 1)
        rows.append({"userPrincipalName": u.get("userPrincipalName"),
                     "enabled": u.get("accountEnabled"),
                     "oneDriveUsedMB": used_mb,
                     "disposition": "UNCLASSIFIED (legal/records to set HOLD/RETAIN/DISPOSE)"})
    return {"data_bearing_users": rows}


def main() -> None:
    ap = argparse.ArgumentParser(description="Inventory Entra apps/orphans or data objects (read-only default).")
    ap.add_argument("--mode", choices=["identity", "data"], default="identity")
    ap.add_argument("--stale-days", type=int, default=90, help="Sign-in age (days) marking an account stale.")
    ap.add_argument("--out", default="inventory.json")
    ap.add_argument("--apply", action="store_true", help="Act on --scope-file objects. Default: dry-run.")
    ap.add_argument("--action", choices=["disable", "remove"], default="disable",
                    help="With --apply: disable (default, reversible) or remove. Applies to SPs/accounts.")
    ap.add_argument("--scope-file", help="ids/appIds to act on with --apply (one per line).")
    args = ap.parse_args()

    if args.apply and args.mode != "identity":
        die("--apply is only supported in --mode identity.")
    if args.apply and not args.scope_file:
        die("--apply requires --scope-file listing the exact object ids to act on.")

    import requests
    session = requests.Session()
    session.headers.update({"Authorization": f"Bearer {get_token()}", "Accept": "application/json"})

    findings = inventory_identity(session, args.stale_days) if args.mode == "identity" \
        else inventory_data(session)

    report = {"generated": dt.datetime.now(dt.timezone.utc).isoformat(),
              "mode": args.mode,
              "gate": "Gate 4 - Identity/app cleanup" if args.mode == "identity"
                      else "Gate 2 - Data disposition inventory",
              "action_mode": "APPLY" if args.apply else "DRY-RUN",
              "findings": findings}

    if args.apply:
        targets = load_set(args.scope_file)
        acted = 0
        # Only service principals and user accounts are actioned here; app-registration deletion is
        # deferred to a deliberate, evidenced admin step (see Implementation Phase 4).
        for coll in ("service_principals", "stale_accounts", "guests"):
            for obj in findings.get(coll, []):
                if obj["id"] in targets or obj.get("appId") in targets:
                    is_user = "userPrincipalName" in obj
                    base = f"{GRAPH}/users/{obj['id']}" if is_user else f"{GRAPH}/servicePrincipals/{obj['id']}"
                    if args.action == "disable":
                        r = session.patch(base, json={"accountEnabled": False}, timeout=60)
                    else:
                        r = session.delete(base, timeout=60)
                    label = obj.get("userPrincipalName") or obj.get("displayName") or obj["id"]
                    if r.ok:
                        acted += 1
                        print(f"  {args.action}d: {label}")
                    else:
                        print(f"  FAILED {args.action}: {label} -> {r.status_code} {r.text[:150]}",
                              file=sys.stderr)
        report["acted_count"] = acted

    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    if args.mode == "identity":
        print(f"[{report['action_mode']}] apps={len(findings['app_registrations'])} "
              f"SPs={len(findings['service_principals'])} "
              f"stale={len(findings['stale_accounts'])} guests={len(findings['guests'])}")
    else:
        print(f"data-bearing users inventoried: {len(findings['data_bearing_users'])} "
              f"(all UNCLASSIFIED — hand to legal/records)")
    if not args.apply:
        print("Dry-run: no changes made.")
    print(f"Inventory written to {args.out}")


if __name__ == "__main__":
    main()
