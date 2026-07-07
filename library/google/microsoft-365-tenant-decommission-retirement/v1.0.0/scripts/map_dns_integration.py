#!/usr/bin/env python3
# map_dns_integration.py — map & classify each domain's DNS + integration ties to the M365 tenant (read-only)
#
# PURPOSE: Plan the Phase-5 DNS/integration cutover. For each domain it resolves MX, SPF, DKIM, DMARC,
#          autodiscover, enterpriseregistration/enrollment, Teams/Lync SRV, and Microsoft verification
#          records and classifies each as RE-POINT-TO-GOOGLE / REMOVE / KEEP. Optionally cross-checks
#          Entra verified domains + app reply URLs via Graph as integration signals. READ-ONLY: it only
#          resolves DNS and reads the directory — it makes no DNS or tenant changes.
# HOW TO RUN: python map_dns_integration.py --domains-file domains.txt [--graph] --out dns-map.json
#             (Python 3.10+; DNS via dnspython if installed else `nslookup`; --graph needs msal+requests+env creds)
# EXPECTED RESULTS: A per-domain plan (JSON + stdout) showing current records, the Google target where a
#          record must be re-pointed, and which Microsoft-only records to remove. It PLANS only; edits are
#          made in the authoritative zone under change control (see the Implementation guide).
#
# --graph credentials (optional) from ENVIRONMENT only:
#   M365DECOM_TENANT_ID / M365DECOM_CLIENT_ID / M365DECOM_CLIENT_SECRET  (Domain.Read.All, Application.Read.All)

import argparse
import datetime as dt
import json
import os
import subprocess
import sys

GRAPH = "https://graph.microsoft.com/v1.0"
SCOPE = ["https://graph.microsoft.com/.default"]

# Google Workspace target records to re-point survivors to (confirm in Google Admin console at change time).
GOOGLE_TARGETS = {
    "MX": ["smtp.google.com", "aspmx.l.google.com"],
    "SPF_include": "include:_spf.google.com",
    "DKIM_selector": "google._domainkey",
}
# Substrings that mark a record as Microsoft-side (candidate for REMOVE once the domain leaves the tenant).
MS_MARKERS = ("outlook.com", "protection.outlook.com", "office365.com", "microsoft.com",
              "lync.com", "sipfed", "enterpriseregistration", "enterpriseenrollment", "msoid")


def die(msg: str, code: int = 2) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(code)


def resolve(name, rtype):
    """Resolve a DNS record type. Prefer dnspython; fall back to the OS resolver. Returns list[str]."""
    try:
        import dns.resolver  # type: ignore
        try:
            answers = dns.resolver.resolve(name, rtype, lifetime=10)
            return [r.to_text().strip('"') for r in answers]
        except Exception:
            return []
    except ImportError:
        # Fallback: parse nslookup output (best-effort; note dnspython gives cleaner results).
        try:
            out = subprocess.run(["nslookup", "-type=" + rtype, name],
                                 capture_output=True, text=True, timeout=15).stdout
            hits = []
            for line in out.splitlines():
                low = line.lower()
                if rtype.lower() in low or "mail exchanger" in low or "text =" in low:
                    hits.append(line.strip())
            return hits
        except Exception:
            return []


def classify(values):
    joined = " ".join(values).lower()
    if any(m in joined for m in MS_MARKERS):
        return "REMOVE (Microsoft-side)"
    if "google.com" in joined or "_spf.google.com" in joined:
        return "KEEP (already Google)"
    return "REVIEW"


def graph_signals(session):
    import time
    def paged(url):
        items = []
        while url:
            for attempt in range(5):
                r = session.get(url, timeout=60)
                if r.status_code == 429 or r.status_code >= 500:
                    time.sleep(min(int(r.headers.get("Retry-After", 2 ** attempt)), 30))
                    continue
                if not r.ok:
                    die(f"Graph GET {url} -> {r.status_code}: {r.text[:200]}")
                data = r.json()
                break
            else:
                die("Graph throttled.")
            items.extend(data.get("value", []))
            url = data.get("@odata.nextLink")
        return items
    domains = [{"id": d.get("id"), "isVerified": d.get("isVerified"),
                "isDefault": d.get("isDefault")} for d in paged(f"{GRAPH}/domains")]
    apps = [{"displayName": a.get("displayName"),
             "replyUrls": (a.get("web") or {}).get("redirectUris") or []}
            for a in paged(f"{GRAPH}/applications?$select=displayName,web")]
    return {"verified_domains": domains, "app_reply_urls": apps}


def main() -> None:
    ap = argparse.ArgumentParser(description="Map/classify DNS + integration ties to the M365 tenant (read-only).")
    ap.add_argument("--domains-file", required=True, help="Text file, one domain per line.")
    ap.add_argument("--graph", action="store_true",
                    help="Also read Entra verified domains + app reply URLs as integration signals.")
    ap.add_argument("--out", default="dns-map.json")
    args = ap.parse_args()

    with open(args.domains_file, encoding="utf-8") as fh:
        domains = [ln.strip() for ln in fh if ln.strip() and not ln.startswith("#")]
    if not domains:
        die("no domains in file")

    plan = []
    for d in domains:
        rec = {"domain": d, "records": {}, "actions": []}
        checks = {
            "MX": ("MX", d),
            "SPF": ("TXT", d),
            "DMARC": ("TXT", f"_dmarc.{d}"),
            "DKIM_google": ("CNAME", f"google._domainkey.{d}"),
            "autodiscover": ("CNAME", f"autodiscover.{d}"),
            "enterpriseregistration": ("CNAME", f"enterpriseregistration.{d}"),
            "enterpriseenrollment": ("CNAME", f"enterpriseenrollment.{d}"),
            "teams_sip_srv": ("SRV", f"_sip._tls.{d}"),
            "teams_federation_srv": ("SRV", f"_sipfederationtls._tcp.{d}"),
        }
        for label, (rtype, name) in checks.items():
            vals = resolve(name, rtype)
            rec["records"][label] = vals
            if not vals:
                continue
            cls = classify(vals)
            if label == "MX" and cls != "KEEP (already Google)":
                rec["actions"].append(f"RE-POINT-TO-GOOGLE: MX -> {GOOGLE_TARGETS['MX']}")
            elif label == "SPF":
                joined = " ".join(vals).lower()
                if "spf.protection.outlook.com" in joined:
                    rec["actions"].append(
                        "RE-POINT-TO-GOOGLE: SPF — drop include:spf.protection.outlook.com, "
                        f"ensure {GOOGLE_TARGETS['SPF_include']}")
            elif label in ("autodiscover", "enterpriseregistration",
                           "enterpriseenrollment", "teams_sip_srv", "teams_federation_srv"):
                if cls.startswith("REMOVE"):
                    rec["actions"].append(f"REMOVE: {label} (Microsoft-only)")
            elif label == "DKIM_google" and vals:
                rec["actions"].append("KEEP: Google DKIM selector present")
        if not rec["actions"]:
            rec["actions"].append("REVIEW: no automatic action derived — inspect manually")
        plan.append(rec)

    signals = None
    if args.graph:
        try:
            import msal, requests  # type: ignore
        except ImportError:
            die("--graph needs: pip install msal requests")
        tenant = os.environ.get("M365DECOM_TENANT_ID")
        client = os.environ.get("M365DECOM_CLIENT_ID")
        secret = os.environ.get("M365DECOM_CLIENT_SECRET")
        if not (tenant and client and secret):
            die("--graph requires M365DECOM_TENANT_ID/CLIENT_ID/CLIENT_SECRET in the environment.")
        app = msal.ConfidentialClientApplication(
            client_id=client, authority=f"https://login.microsoftonline.com/{tenant}",
            client_credential=secret)
        tok = app.acquire_token_for_client(scopes=SCOPE)
        if "access_token" not in tok:
            die(f"Token failed: {tok.get('error_description', tok.get('error'))}")
        session = requests.Session()
        session.headers.update({"Authorization": f"Bearer {tok['access_token']}",
                                "Accept": "application/json"})
        signals = graph_signals(session)

    report = {"generated": dt.datetime.now(dt.timezone.utc).isoformat(),
              "gate": "Gate 5 - DNS / integration",
              "google_targets": GOOGLE_TARGETS,
              "domains": plan,
              "integration_signals": signals}
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    print(f"Mapped {len(plan)} domain(s). Plan written to {args.out}")
    for rec in plan:
        print(f"  {rec['domain']}:")
        for a in rec["actions"]:
            print(f"     - {a}")
    print("PLAN ONLY — apply DNS changes in the authoritative zone under change control "
          "(snapshot the zone first).")


if __name__ == "__main__":
    main()
