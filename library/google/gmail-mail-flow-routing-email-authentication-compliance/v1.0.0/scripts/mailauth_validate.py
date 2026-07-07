#!/usr/bin/env python3
# mailauth_validate.py — Validate SPF / DKIM / DMARC records for a domain and produce a pass/fail report.
#
# PURPOSE: Read-only validation of a single domain's email authentication posture at a target stage.
#          Checks SPF syntax + lookup budget, resolves the Google DKIM selector, and parses the DMARC
#          record to confirm it matches the intended enforcement stage (monitor/quarantine/reject).
#          It does NOT send mail — pair with a real test message + header inspection (see 05-testing.md).
# HOW TO RUN: python mailauth_validate.py --domain corp.example --check {spf,dkim,dmarc,all}
#             [--expect-policy {none,quarantine,reject}] [--selector google]   (Python 3.10+)
#             (uses dnspython if installed: pip install dnspython; else `nslookup` fallback)
# EXPECTED RESULTS: A PASS/FAIL line per check and an overall verdict; non-zero exit on any FAIL.

import argparse
import subprocess
import sys

try:
    import dns.resolver  # type: ignore
    _HAVE_DNSPYTHON = True
except Exception:  # pragma: no cover
    _HAVE_DNSPYTHON = False

SPF_LOOKUP_MECHANISMS = ("include:", "a", "mx", "ptr", "exists:", "redirect=")
SPF_MAX_LOOKUPS = 10


def _txt(name: str) -> list[str]:
    if _HAVE_DNSPYTHON:
        try:
            ans = dns.resolver.resolve(name, "TXT", lifetime=8)
            return [b"".join(getattr(r, "strings", []) or []).decode() or r.to_text().strip('"') for r in ans]
        except Exception:
            return []
    try:
        res = subprocess.run(["nslookup", "-type=TXT", name], capture_output=True, text=True, timeout=10)
        return [ln.split("text =")[-1].strip().strip('"') for ln in res.stdout.splitlines() if "text =" in ln]
    except Exception:
        return []


def check_spf(domain: str) -> tuple[bool, str]:
    recs = [t for t in _txt(domain) if t.lower().startswith("v=spf1")]
    if not recs:
        return False, "no SPF record (v=spf1) found"
    if len(recs) > 1:
        return False, f"multiple SPF records ({len(recs)}) — only one is permitted (permerror)"
    spf = recs[0]
    lookups = sum(1 for tok in spf.split()
                  if any(tok.lower().lstrip("+-~?").startswith(m) for m in SPF_LOOKUP_MECHANISMS))
    if lookups > SPF_MAX_LOOKUPS:
        return False, f"SPF exceeds {SPF_MAX_LOOKUPS} DNS lookups (~{lookups}) — permerror risk"
    if not spf.rstrip().endswith(("~all", "-all")):
        return True, f"SPF present (~{lookups} lookups) but no ~all/-all terminator — review: {spf}"
    return True, f"SPF valid (~{lookups} lookups): {spf}"


def check_dkim(domain: str, selector: str) -> tuple[bool, str]:
    recs = _txt(f"{selector}._domainkey.{domain}")
    hit = next((t for t in recs if "v=DKIM1" in t or "p=" in t), None)
    if not hit:
        return False, f"DKIM selector '{selector}' not resolving — generate/publish in Admin console"
    if "p=" in hit and hit.split("p=", 1)[1].strip().strip(';').strip() == "":
        return False, f"DKIM selector '{selector}' present but public key empty (revoked?)"
    return True, f"DKIM selector '{selector}' resolves with a public key"


def check_dmarc(domain: str, expect_policy: str | None) -> tuple[bool, str]:
    recs = [t for t in _txt(f"_dmarc.{domain}") if t.lower().startswith("v=dmarc1")]
    if not recs:
        return False, "no DMARC record found at _dmarc"
    dmarc = recs[0]
    tags = {}
    for part in dmarc.split(";"):
        if "=" in part:
            k, v = part.split("=", 1)
            tags[k.strip().lower()] = v.strip()
    policy = tags.get("p", "none").lower()
    has_rua = "rua" in tags
    msg = f"DMARC p={policy}" + (f", rua set" if has_rua else ", NO rua (no aggregate reports!)")
    ok = True
    if not has_rua:
        ok = False
    if expect_policy and policy != expect_policy.lower():
        return False, f"{msg} — expected p={expect_policy}"
    return ok, msg


def main() -> int:
    ap = argparse.ArgumentParser(description="Read-only SPF/DKIM/DMARC record validation for a domain.")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--check", choices=["spf", "dkim", "dmarc", "all"], default="all")
    ap.add_argument("--selector", default="google", help="DKIM selector (Google default: google).")
    ap.add_argument("--expect-policy", choices=["none", "quarantine", "reject"],
                    help="Assert the DMARC policy matches this stage (for gating enforcement).")
    args = ap.parse_args()

    if not _HAVE_DNSPYTHON:
        print("[note] dnspython not installed; using nslookup fallback (pip install dnspython)\n")

    checks = []
    if args.check in ("spf", "all"):
        checks.append(("SPF", *check_spf(args.domain)))
    if args.check in ("dkim", "all"):
        checks.append(("DKIM", *check_dkim(args.domain, args.selector)))
    if args.check in ("dmarc", "all"):
        checks.append(("DMARC", *check_dmarc(args.domain, args.expect_policy)))

    print(f"Email-auth validation for {args.domain}\n" + "-" * 50)
    all_ok = True
    for name, ok, detail in checks:
        all_ok = all_ok and ok
        print(f"  [{'PASS' if ok else 'FAIL'}] {name}: {detail}")

    print("-" * 50)
    print(f"Overall: {'PASS' if all_ok else 'FAIL'}")
    print("Note: record validation only — confirm on real mail via Authentication-Results headers (T2).")
    return 0 if all_ok else 2


if __name__ == "__main__":
    sys.exit(main())
