#!/usr/bin/env python3
# dmarc_policy_planner.py — Plan the next safe DMARC record (monitor->quarantine->reject) as a dry-run.
#
# PURPOSE: Config helper that computes the NEXT DMARC record string for a domain given the current
#          stage and the measured alignment %, honoring a pct= ramp. DRY-RUN BY DEFAULT: it PRINTS the
#          exact TXT record to publish in DNS and whether advancement is safe — it never touches DNS or
#          the tenant. Advancement requires --apply purely to acknowledge intent; it still only prints.
# HOW TO RUN: python dmarc_policy_planner.py --domain corp.example --rua dmarc@corp.example
#             --current {none,quarantine,reject} --alignment 99.1 [--pct 25] [--apply]   (Python 3.10+)
# EXPECTED RESULTS: The proposed _dmarc TXT record + a SAFE/HOLD decision vs the alignment threshold,
#                   and the recommended pct ramp. Non-zero exit if advancement is not yet safe.

import argparse
import sys

STAGES = ["none", "quarantine", "reject"]
DEFAULT_MIN_ALIGN = {"quarantine": 95.0, "reject": 98.0}  # stricter to reach reject


def next_stage(current: str) -> str | None:
    i = STAGES.index(current)
    return STAGES[i + 1] if i + 1 < len(STAGES) else None


def build_record(domain: str, policy: str, rua: str, pct: int,
                 adkim: str, aspf: str, sp: str | None) -> str:
    rec = f"v=DMARC1; p={policy}; rua=mailto:{rua}"
    if policy != "none" and pct < 100:
        rec += f"; pct={pct}"
    rec += f"; adkim={adkim}; aspf={aspf}"
    if sp:
        rec += f"; sp={sp}"
    return rec


def main() -> int:
    ap = argparse.ArgumentParser(description="Dry-run DMARC advancement planner (prints the next TXT record).")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--rua", required=True, help="Aggregate-report mailbox (rua=mailto:...).")
    ap.add_argument("--current", choices=STAGES, required=True, help="Current DMARC policy stage.")
    ap.add_argument("--alignment", type=float, required=True,
                    help="Measured %% of legitimate volume DMARC-aligned (from dmarc_rua_analyzer.py).")
    ap.add_argument("--pct", type=int, default=100, help="pct ramp for the next stage (25/50/100).")
    ap.add_argument("--adkim", default="r", choices=["r", "s"], help="DKIM alignment (relaxed/strict).")
    ap.add_argument("--aspf", default="r", choices=["r", "s"], help="SPF alignment (relaxed/strict).")
    ap.add_argument("--sp", choices=["none", "quarantine", "reject"], help="Optional subdomain policy.")
    ap.add_argument("--min-align", type=float, help="Override the min alignment %% for the next stage.")
    ap.add_argument("--apply", action="store_true",
                    help="Acknowledge intent to advance (still DRY-RUN — prints record; does not publish).")
    args = ap.parse_args()

    nxt = next_stage(args.current)
    print(f"Domain: {args.domain}   current p={args.current}   measured alignment={args.alignment:.2f}%\n")

    if nxt is None:
        rec = build_record(args.domain, "reject", args.rua, 100, args.adkim, args.aspf, args.sp)
        print("Already at the strongest policy (p=reject). Steady-state record:")
        print(f"  _dmarc.{args.domain}  IN TXT  \"{rec}\"")
        return 0

    threshold = args.min_align if args.min_align is not None else DEFAULT_MIN_ALIGN[nxt]
    safe = args.alignment >= threshold
    rec = build_record(args.domain, nxt, args.rua, args.pct, args.adkim, args.aspf, args.sp)

    print(f"Proposed next stage: p={args.current} -> p={nxt}  (threshold {threshold:.0f}%)")
    print(f"Proposed record:\n  _dmarc.{args.domain}  IN TXT  \"{rec}\"\n")

    if not safe:
        print(f"[HOLD] Alignment {args.alignment:.2f}% < {threshold:.0f}%. Do NOT advance yet — "
              "reconcile failing/unknown senders (dmarc_rua_analyzer.py) first.")
        return 2

    if args.pct < 100:
        print(f"[SAFE] Advancement meets threshold. Ramp with pct={args.pct}, watch reports, then raise pct.")
    else:
        print("[SAFE] Advancement meets threshold at pct=100.")
    print("\nDRY-RUN: this tool never publishes DNS. Publish the record above under change control "
          "(TTL pre-lowered), then re-run dmarc_rua_analyzer.py to confirm.")
    if not args.apply:
        print("(Run again with --apply once approved — output is identical; --apply only records intent.)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
