#!/usr/bin/env python3
# mailplane_dns_audit.py — Audit MX / SPF / DKIM / DMARC DNS posture for a set of domains (read-only).
#
# PURPOSE: Read-only DNS assessment of the Gmail mail plane. For each domain it resolves MX, SPF
#          (with an approximate SPF DNS-lookup count vs the RFC 7208 limit of 10), the Google DKIM
#          selector, and the DMARC record + policy level. Discovery only — it changes nothing.
# HOW TO RUN: python mailplane_dns_audit.py --domains-file domains.txt [--out baseline]   (Python 3.10+)
#             (uses dnspython if installed: pip install dnspython; else falls back to `nslookup`)
# EXPECTED RESULTS: A per-domain table + JSON/CSV report; PASS/WARN/FAIL flags for missing SPF,
#                   SPF>10 lookups, DKIM not resolving, and DMARC policy level. Non-zero exit on FAIL.

import argparse
import csv
import json
import subprocess
import sys
from datetime import datetime, timezone

try:
    import dns.resolver  # type: ignore
    _HAVE_DNSPYTHON = True
except Exception:  # pragma: no cover - optional dependency
    _HAVE_DNSPYTHON = False

SPF_LOOKUP_MECHANISMS = ("include:", "a", "mx", "ptr", "exists:", "redirect=")
SPF_MAX_LOOKUPS = 10


def _txt_records(name: str) -> list[str]:
    """Return TXT record strings for a name, or [] if none/lookup fails."""
    if _HAVE_DNSPYTHON:
        try:
            answers = dns.resolver.resolve(name, "TXT", lifetime=8)
            out = []
            for r in answers:
                out.append(b"".join(getattr(r, "strings", []) or []).decode() or r.to_text().strip('"'))
            return out
        except Exception:
            return []
    # Fallback: nslookup (best-effort, read-only)
    try:
        res = subprocess.run(["nslookup", "-type=TXT", name], capture_output=True, text=True, timeout=10)
        return [ln.split("text =")[-1].strip().strip('"') for ln in res.stdout.splitlines() if "text =" in ln]
    except Exception:
        return []


def _mx_records(name: str) -> list[str]:
    if _HAVE_DNSPYTHON:
        try:
            return sorted(r.to_text() for r in dns.resolver.resolve(name, "MX", lifetime=8))
        except Exception:
            return []
    try:
        res = subprocess.run(["nslookup", "-type=MX", name], capture_output=True, text=True, timeout=10)
        return [ln.strip() for ln in res.stdout.splitlines() if "mail exchanger" in ln]
    except Exception:
        return []


def _count_spf_lookups(spf: str) -> int:
    """Approximate the number of DNS-lookup-costing mechanisms in an SPF record."""
    tokens = spf.split()
    count = 0
    for t in tokens:
        low = t.lower().lstrip("+-~?")
        if any(low.startswith(m) for m in SPF_LOOKUP_MECHANISMS):
            count += 1
    return count


def audit_domain(domain: str) -> dict:
    result: dict = {"domain": domain, "flags": []}

    # MX
    mx = _mx_records(domain)
    result["mx"] = mx
    if not mx:
        result["flags"].append(("WARN", "no MX records found"))

    # SPF
    spf = next((t for t in _txt_records(domain) if t.lower().startswith("v=spf1")), None)
    result["spf"] = spf
    if not spf:
        result["flags"].append(("FAIL", "no SPF record"))
    else:
        lookups = _count_spf_lookups(spf)
        result["spf_lookups"] = lookups
        if lookups > SPF_MAX_LOOKUPS:
            result["flags"].append(("FAIL", f"SPF lookups {lookups} > {SPF_MAX_LOOKUPS} (permerror risk)"))
        if "include:_spf.google.com" not in spf:
            result["flags"].append(("WARN", "SPF does not include _spf.google.com"))

    # DKIM (Google default selector)
    dkim = next((t for t in _txt_records(f"google._domainkey.{domain}") if "v=DKIM1" in t or "p=" in t), None)
    result["dkim_google_selector"] = bool(dkim)
    if not dkim:
        result["flags"].append(("WARN", "google._domainkey DKIM not resolving"))

    # DMARC
    dmarc = next((t for t in _txt_records(f"_dmarc.{domain}") if t.lower().startswith("v=dmarc1")), None)
    result["dmarc"] = dmarc
    if not dmarc:
        result["flags"].append(("FAIL", "no DMARC record"))
    else:
        policy = "none"
        for tag in dmarc.split(";"):
            tag = tag.strip()
            if tag.lower().startswith("p="):
                policy = tag.split("=", 1)[1].strip().lower()
        result["dmarc_policy"] = policy
        if policy == "none":
            result["flags"].append(("INFO", "DMARC at p=none (monitor) — enforcement pending"))
        if "rua=" not in dmarc.lower():
            result["flags"].append(("WARN", "DMARC has no rua= aggregate-report address"))

    result["worst"] = _worst(result["flags"])
    return result


def _worst(flags: list[tuple[str, str]]) -> str:
    order = {"FAIL": 3, "WARN": 2, "INFO": 1, "PASS": 0}
    return max((f[0] for f in flags), key=lambda s: order.get(s, 0), default="PASS")


def main() -> int:
    ap = argparse.ArgumentParser(description="Read-only MX/SPF/DKIM/DMARC posture audit for the Gmail mail plane.")
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--domains-file", help="Path to a text file, one domain per line.")
    src.add_argument("--domain", help="A single domain to audit.")
    ap.add_argument("--out", help="Output basename; writes <out>.json and <out>.csv if set.")
    args = ap.parse_args()

    if args.domain:
        domains = [args.domain.strip()]
    else:
        with open(args.domains_file, encoding="utf-8") as fh:
            domains = [ln.strip() for ln in fh if ln.strip() and not ln.startswith("#")]

    if not _HAVE_DNSPYTHON:
        print("[note] dnspython not installed; using nslookup fallback (install: pip install dnspython)\n")

    report = {"generated": datetime.now(timezone.utc).isoformat(), "domains": []}
    any_fail = False
    for d in domains:
        r = audit_domain(d)
        report["domains"].append(r)
        any_fail = any_fail or r["worst"] == "FAIL"
        print(f"=== {d}  [{r['worst']}] ===")
        print(f"  MX:    {', '.join(r['mx']) or '(none)'}")
        print(f"  SPF:   {r.get('spf') or '(none)'}"
              + (f"   [~{r.get('spf_lookups')} lookups]" if r.get('spf') else ""))
        print(f"  DKIM:  {'google selector present' if r['dkim_google_selector'] else '(not resolving)'}")
        print(f"  DMARC: {r.get('dmarc') or '(none)'}")
        for level, msg in r["flags"]:
            print(f"    - [{level}] {msg}")
        print()

    if args.out:
        with open(f"{args.out}.json", "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        with open(f"{args.out}.csv", "w", newline="", encoding="utf-8") as fh:
            w = csv.writer(fh)
            w.writerow(["domain", "worst", "mx_count", "spf", "spf_lookups", "dkim", "dmarc_policy", "flags"])
            for r in report["domains"]:
                w.writerow([r["domain"], r["worst"], len(r["mx"]), r.get("spf"),
                            r.get("spf_lookups"), r["dkim_google_selector"], r.get("dmarc_policy"),
                            "; ".join(f"{l}:{m}" for l, m in r["flags"])])
        print(f"[written] {args.out}.json / {args.out}.csv")

    return 2 if any_fail else 0


if __name__ == "__main__":
    sys.exit(main())
