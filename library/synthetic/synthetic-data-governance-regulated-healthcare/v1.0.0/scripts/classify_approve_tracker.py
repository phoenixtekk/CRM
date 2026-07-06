#!/usr/bin/env python3
# classify_approve_tracker.py — record stewarded classifications and drive the approval workflow
#
# PURPOSE: Maintain the JSON-backed classification & approval log for governed synthetic/test assets.
#          `classify` records a stewarded classification (validated against the scheme, with who/when/
#          why). `request` opens an approval request (requester, purpose, target env). `decide` records
#          the reviewer's approve/reject decision, enforcing requester != approver (separation of
#          duties). Safe by default: DRY-RUN unless --commit; log is metadata only, never real PHI.
# HOW TO RUN: python classify_approve_tracker.py classify --id A --value synthetic-only --scheme scheme.json --log log.json --steward NAME --reason "..." [--commit]   (Python 3.10+; see --help)
# EXPECTED RESULTS: Dry-run previews the record and prints "(dry-run)". With --commit the log is
#          updated. A self-approval (requester == approver) is REJECTED. Classifying with a value not
#          in the scheme is REJECTED.

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

LOG_NAME = "Classification & Approval Log - Enterprise - v1"


def now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_json(path, what, default=None):
    p = Path(path)
    if not p.exists():
        if default is not None:
            return default
        sys.exit(f"ERROR: {what} not found: {path}")
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        sys.exit(f"ERROR: {what} is not valid JSON ({path}): {e}")


def load_log(path):
    data = load_json(path, "log", default={"log_name": LOG_NAME, "classifications": {}, "approvals": []})
    data.setdefault("classifications", {})
    data.setdefault("approvals", [])
    return data


def save_log(path, data):
    Path(path).write_text(json.dumps(data, indent=2), encoding="utf-8")


def scheme_values(scheme):
    # Scheme JSON: {"values": [{"name": "synthetic-only", ...}, ...]} or a plain list of names.
    if isinstance(scheme, list):
        return {v if isinstance(v, str) else v.get("name") for v in scheme}
    vals = scheme.get("values", [])
    return {v if isinstance(v, str) else v.get("name") for v in vals}


def cmd_classify(args):
    scheme = load_json(args.scheme, "classification scheme")
    allowed = scheme_values(scheme)
    if args.value not in allowed:
        sys.exit(f"ERROR: '{args.value}' is not in the classification scheme {sorted(allowed)}. "
                 f"Classification is a stewarded decision within the agreed scheme.")
    log = load_log(args.log)
    record = {
        "value": args.value,
        "steward": args.steward,
        "reason": args.reason,
        "classified_at": now_iso(),
    }
    print(f"[CLASSIFY] asset '{args.id}' -> '{args.value}'")
    print(json.dumps(record, indent=2))
    if not args.commit:
        print("\n(dry-run) not written. Re-run with --commit to save.")
        return 0
    log["classifications"][args.id] = record
    save_log(args.log, log)
    print(f"\nCommitted classification for '{args.id}': {args.log}")
    return 0


def cmd_request(args):
    log = load_log(args.log)
    req = {
        "asset_id": args.id,
        "requester": args.requester,
        "purpose": args.purpose,
        "target_env": args.target_env,
        "status": "requested",
        "requested_at": now_iso(),
        "reviewer": None,
        "decided_at": None,
    }
    print(f"[REQUEST] approval for asset '{args.id}' by '{args.requester}' -> env '{args.target_env}'")
    print(json.dumps(req, indent=2))
    if not args.commit:
        print("\n(dry-run) not written. Re-run with --commit to save.")
        return 0
    log["approvals"].append(req)
    save_log(args.log, log)
    print(f"\nCommitted request (index {len(log['approvals']) - 1}): {args.log}")
    return 0


def latest_open_request(log, asset_id):
    for i in range(len(log["approvals"]) - 1, -1, -1):
        r = log["approvals"][i]
        if r.get("asset_id") == asset_id and r.get("status") == "requested":
            return i, r
    return None, None


def cmd_decide(args):
    if args.decision not in ("approve", "reject"):
        sys.exit("ERROR: --decision must be 'approve' or 'reject'.")
    log = load_log(args.log)
    idx, req = latest_open_request(log, args.id)
    if req is None:
        sys.exit(f"ERROR: no open approval request for asset '{args.id}'. Run `request` first.")
    if args.reviewer.strip().lower() == req["requester"].strip().lower():
        sys.exit("ERROR: requester and approver must differ (separation of duties). "
                 f"'{args.reviewer}' requested this asset and cannot approve it.")
    req["status"] = "approved" if args.decision == "approve" else "rejected"
    req["reviewer"] = args.reviewer
    req["decided_at"] = now_iso()
    print(f"[DECIDE] asset '{args.id}' -> {req['status']} by '{args.reviewer}'")
    print(json.dumps(req, indent=2))
    if not args.commit:
        print("\n(dry-run) not written. Re-run with --commit to save.")
        return 0
    log["approvals"][idx] = req
    save_log(args.log, log)
    print(f"\nCommitted decision: {args.log}")
    return 0


def cmd_status(args):
    log = load_log(args.log)
    cls = log["classifications"].get(args.id)
    print(f"Asset '{args.id}':")
    print(f"  classification: {cls['value'] if cls else '(none)'}"
          + (f" (by {cls['steward']})" if cls else ""))
    apps = [a for a in log["approvals"] if a.get("asset_id") == args.id]
    if not apps:
        print("  approvals: (none)")
    for a in apps:
        print(f"  approval: {a['status']:<9} requester={a['requester']} reviewer={a.get('reviewer') or '-'} "
              f"env={a['target_env']}")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Classification & approval tracker (metadata only).")
    sub = ap.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("classify", help="Record a stewarded classification.")
    c.add_argument("--id", required=True)
    c.add_argument("--value", required=True, help="A value from the classification scheme.")
    c.add_argument("--scheme", required=True, help="Path to Classification Scheme JSON.")
    c.add_argument("--log", required=True, help="Path to the classification/approval log JSON.")
    c.add_argument("--steward", required=True)
    c.add_argument("--reason", required=True, help="Why this classification (recorded).")
    c.add_argument("--commit", action="store_true")
    c.set_defaults(func=cmd_classify)

    rq = sub.add_parser("request", help="Open an approval request.")
    rq.add_argument("--id", required=True)
    rq.add_argument("--log", required=True)
    rq.add_argument("--requester", required=True)
    rq.add_argument("--purpose", required=True)
    rq.add_argument("--target-env", required=True)
    rq.add_argument("--commit", action="store_true")
    rq.set_defaults(func=cmd_request)

    d = sub.add_parser("decide", help="Record an approve/reject decision.")
    d.add_argument("--id", required=True)
    d.add_argument("--log", required=True)
    d.add_argument("--decision", required=True, help="'approve' or 'reject'.")
    d.add_argument("--reviewer", required=True, help="Must differ from the requester.")
    d.add_argument("--commit", action="store_true")
    d.set_defaults(func=cmd_decide)

    st = sub.add_parser("status", help="Show classification + approvals for an asset.")
    st.add_argument("--id", required=True)
    st.add_argument("--log", required=True)
    st.set_defaults(func=cmd_status)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
