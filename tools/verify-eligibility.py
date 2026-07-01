#!/usr/bin/env python3
"""
verify-eligibility.py — verify a customer's Non-Profit or Government status before granting a
discounted store tier (Non-Profit -40% / Government -15%). Returns a verdict + the exact Bagisto
customer-group assignment to apply on approval.

Verification layers (each independent; the tool uses whatever is available):
  GOVERNMENT
    - keyless: email domain check (.gov / .mil / .fed.us / *.state.<st>.us patterns)  [always on]
    - automated: SAM.gov Entity Management API  [needs env SAM_GOV_API_KEY]
  NON-PROFIT
    - keyless: IRS Pub78 / Exempt-Org dataset lookup by EIN  [needs data/irs_pub78.csv present]
    - automated: TechSoup validation  [needs env TECHSOUP_API_KEY (+ partner onboarding)]

Verdict: "eligible" (auto-approve), "review" (manual review needed), or "ineligible".
On approval, assign the customer to the matching group on linuxg5:
  Non-Profit (Verified) = customer_groups.code 'non-profit' (id 4)
  Government (Verified)  = customer_groups.code 'government' (id 5)
This tool NEVER changes the store by itself — it prints the verdict + the apply command.

Usage:
  python tools/verify-eligibility.py --type government --email jdoe@agency.gov [--uei ABC123...]
  python tools/verify-eligibility.py --type nonprofit  --email x@org.org --ein 12-3456789
Env (optional, enable the automated layers): SAM_GOV_API_KEY, TECHSOUP_API_KEY
"""
import argparse, csv, json, os, re, sys
from pathlib import Path
from urllib import request as urlreq, parse as urlparse, error as urlerr

GOV_TLDS = (".gov", ".mil", ".fed.us")
GOV_STATE_RE = re.compile(r"\.state\.[a-z]{2}\.us$|\.[a-z]{2}\.us$", re.I)
UA = "Mozilla/5.0 (eligibility-verifier) AppleWebKit/537.36 Chrome/124 Safari/537.36"


def gov_email_signal(email: str):
    dom = (email or "").split("@")[-1].lower().strip()
    if not dom:
        return None, "no email domain"
    if dom.endswith(GOV_TLDS) or GOV_STATE_RE.search(dom):
        return True, f"government email domain ({dom})"
    return False, f"non-government email domain ({dom})"


def samgov_lookup(uei=None, name=None):
    key = os.environ.get("SAM_GOV_API_KEY")
    if not key:
        return None, "SAM_GOV_API_KEY not set (automated gov check skipped)"
    q = {"api_key": key, "registrationStatus": "A"}
    if uei: q["ueiSAM"] = uei
    elif name: q["legalBusinessName"] = name
    else: return None, "no UEI or legal name to query SAM.gov"
    url = "https://api.sam.gov/entity-information/v3/entities?" + urlparse.urlencode(q)
    try:
        req = urlreq.Request(url, headers={"User-Agent": UA})
        data = json.loads(urlreq.urlopen(req, timeout=30).read())
        total = data.get("totalRecords", 0)
        if total and total > 0:
            ent = data["entityData"][0]["entityRegistration"]
            return True, f"SAM.gov active registration: {ent.get('legalBusinessName')} (UEI {ent.get('ueiSAM')})"
        return False, "no active SAM.gov entity matched"
    except urlerr.HTTPError as e:
        return None, f"SAM.gov HTTP {e.code} (check key/quota)"
    except Exception as e:
        return None, f"SAM.gov error: {e}"


def irs_pub78_lookup(ein: str):
    # Keyless: lookup the EIN in the locally-staged IRS exempt-org dataset (data/irs_pub78.csv).
    # Download from IRS Tax Exempt Organization Search bulk data; expected columns include EIN + deductibility.
    ds = Path(__file__).resolve().parent.parent / "data" / "irs_pub78.csv"
    digits = re.sub(r"\D", "", ein or "")
    if not digits:
        return None, "no EIN provided"
    if not ds.exists():
        return None, "IRS Pub78 dataset not staged (data/irs_pub78.csv) — automated NPO check skipped"
    try:
        with ds.open(encoding="utf-8", errors="ignore") as f:
            for row in csv.reader(f):
                if row and re.sub(r"\D", "", row[0]) == digits:
                    return True, f"EIN {ein} found in IRS exempt-org list ({row[1] if len(row)>1 else 'listed'})"
        return False, f"EIN {ein} not in IRS exempt-org list"
    except Exception as e:
        return None, f"IRS dataset error: {e}"


def techsoup_lookup(ein: str):
    key = os.environ.get("TECHSOUP_API_KEY")
    if not key:
        return None, "TECHSOUP_API_KEY not set (automated NPO validation skipped)"
    # TechSoup's validation (NGOsource/365 Connect) is partner-gated; wire the partner endpoint here
    # once onboarded. Structured as a layer so it activates without touching the rest of the tool.
    return None, "TechSoup endpoint not configured (partner onboarding required)"


def decide(signals):
    """signals: list of (bool|None, reason). True=pass, False=fail, None=unavailable."""
    passes = [r for ok, r in signals if ok is True]
    fails = [r for ok, r in signals if ok is False]
    if passes:
        return "eligible", passes, fails
    if fails and not any(ok is None for ok, _ in signals):
        return "ineligible", passes, fails
    return "review", passes, fails


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--type", required=True, choices=["government", "nonprofit"])
    ap.add_argument("--email", required=True)
    ap.add_argument("--ein", help="non-profit EIN (e.g. 12-3456789)")
    ap.add_argument("--uei", help="government SAM.gov UEI")
    ap.add_argument("--name", help="legal entity name (SAM.gov fallback)")
    ap.add_argument("--json", action="store_true", help="emit JSON only")
    args = ap.parse_args()

    signals = []
    if args.type == "government":
        signals.append(gov_email_signal(args.email))
        signals.append(samgov_lookup(uei=args.uei, name=args.name))
        group_code, group_id = "government", 5
    else:
        signals.append(irs_pub78_lookup(args.ein))
        signals.append(techsoup_lookup(args.ein))
        # an .org domain is a weak hint only — never decisive
        group_code, group_id = "non-profit", 4

    verdict, passes, fails = decide(signals)
    out = {
        "email": args.email, "type": args.type, "verdict": verdict,
        "passed": passes, "failed": fails,
        "unavailable": [r for ok, r in signals if ok is None],
        "group_code": group_code, "group_id": group_id,
        "apply_hint": (f"On approval, set this customer's group to '{group_code}' (id {group_id}): "
                       f"UPDATE customers SET customer_group_id={group_id} WHERE email='{args.email}';"),
    }
    if args.json:
        print(json.dumps(out, indent=2)); return
    print(f"Customer : {args.email}")
    print(f"Tier     : {args.type}  ->  group '{group_code}' (id {group_id})")
    print(f"VERDICT  : {verdict.upper()}")
    for r in passes: print(f"  [pass] {r}")
    for r in fails: print(f"  [fail] {r}")
    for ok, r in signals:
        if ok is None: print(f"  [n/a ] {r}")
    print(f"\n{out['apply_hint']}")
    if verdict == "review":
        print("-> Manual review required (collect 501(c)(3) letter / gov entity proof), then apply the group.")


if __name__ == "__main__":
    main()
