#!/usr/bin/env python3
# dmarc_rua_analyzer.py — Parse DMARC aggregate (RUA) reports and summarize sender alignment (read-only).
#
# PURPOSE: Read-only analysis of DMARC aggregate XML reports (the evidence gate for advancing DMARC).
#          Parses .xml / .xml.gz / .zip reports, aggregates volume by sending source IP + header-from,
#          and computes the % of volume passing DMARC (SPF or DKIM aligned) so you can decide whether
#          it is safe to move p=none -> quarantine -> reject. Never sends mail or changes DNS.
# HOW TO RUN: python dmarc_rua_analyzer.py --input reports/ [--out rua-summary] [--min-align 98]
#             (Python 3.10+, standard library only)
# EXPECTED RESULTS: A per-source table (volume, SPF/DKIM/DMARC pass), an overall alignment %, and a
#                   PASS/FAIL vs --min-align. Non-zero exit if alignment below threshold (not yet safe).

import argparse
import glob
import gzip
import io
import os
import sys
import zipfile
import xml.etree.ElementTree as ET
from collections import defaultdict


def _iter_report_bytes(path: str):
    """Yield (name, xml_bytes) for every DMARC report found under path."""
    files = [path] if os.path.isfile(path) else sorted(
        glob.glob(os.path.join(path, "**", "*"), recursive=True))
    for f in files:
        if os.path.isdir(f):
            continue
        low = f.lower()
        try:
            if low.endswith(".gz"):
                with gzip.open(f, "rb") as fh:
                    yield f, fh.read()
            elif low.endswith(".zip"):
                with zipfile.ZipFile(f) as zf:
                    for n in zf.namelist():
                        if n.lower().endswith(".xml"):
                            yield f"{f}:{n}", zf.read(n)
            elif low.endswith(".xml"):
                with open(f, "rb") as fh:
                    yield f, fh.read()
        except Exception as e:  # skip unreadable/corrupt report, keep going
            print(f"[warn] could not read {f}: {e}", file=sys.stderr)


def parse_report(xml_bytes: bytes, agg: dict) -> None:
    """Accumulate per-source counts into agg keyed by (source_ip, header_from)."""
    root = ET.parse(io.BytesIO(xml_bytes)).getroot()
    for rec in root.findall(".//record"):
        row = rec.find("row")
        if row is None:
            continue
        src = (row.findtext("source_ip") or "?").strip()
        count = int(row.findtext("count") or "0")
        pol = row.find("policy_evaluated")
        dkim = (pol.findtext("dkim") if pol is not None else None) or "fail"
        spf = (pol.findtext("spf") if pol is not None else None) or "fail"
        ident = rec.find("identifiers")
        hfrom = (ident.findtext("header_from") if ident is not None else None) or "?"
        key = (src, hfrom.lower().strip())
        a = agg[key]
        a["volume"] += count
        if dkim.lower() == "pass":
            a["dkim_pass"] += count
        if spf.lower() == "pass":
            a["spf_pass"] += count
        # DMARC passes if EITHER aligned mechanism passes
        if dkim.lower() == "pass" or spf.lower() == "pass":
            a["dmarc_pass"] += count


def main() -> int:
    ap = argparse.ArgumentParser(description="Read-only DMARC aggregate (RUA) report analyzer.")
    ap.add_argument("--input", required=True, help="A report file or a directory of reports (.xml/.gz/.zip).")
    ap.add_argument("--out", help="Output basename for a CSV summary.")
    ap.add_argument("--min-align", type=float, default=98.0,
                    help="Minimum overall DMARC alignment %% to consider enforcement-safe (default 98).")
    args = ap.parse_args()

    agg: dict = defaultdict(lambda: {"volume": 0, "dkim_pass": 0, "spf_pass": 0, "dmarc_pass": 0})
    n_reports = 0
    for name, data in _iter_report_bytes(args.input):
        try:
            parse_report(data, agg)
            n_reports += 1
        except Exception as e:
            print(f"[warn] parse failed for {name}: {e}", file=sys.stderr)

    if n_reports == 0:
        print("No DMARC reports found. Point --input at a file or directory of RUA reports.", file=sys.stderr)
        return 1

    total = sum(a["volume"] for a in agg.values())
    aligned = sum(a["dmarc_pass"] for a in agg.values())
    overall = (aligned / total * 100.0) if total else 0.0

    rows = sorted(agg.items(), key=lambda kv: kv[1]["volume"], reverse=True)
    print(f"Parsed {n_reports} report(s); {total} messages across {len(agg)} source(s).\n")
    print(f"{'source_ip':<20}{'header_from':<28}{'vol':>8}{'spf%':>7}{'dkim%':>7}{'dmarc%':>8}")
    print("-" * 78)
    for (src, hfrom), a in rows:
        v = a["volume"] or 1
        print(f"{src:<20}{hfrom[:27]:<28}{a['volume']:>8}"
              f"{a['spf_pass']/v*100:>6.0f}%{a['dkim_pass']/v*100:>6.0f}%{a['dmarc_pass']/v*100:>7.0f}%")

    print("\n" + "=" * 60)
    verdict = "PASS" if overall >= args.min_align else "FAIL"
    print(f"Overall DMARC-aligned volume: {overall:.2f}%  (threshold {args.min_align:.0f}%)  -> {verdict}")
    if verdict == "FAIL":
        print("Not yet safe to advance DMARC enforcement. Reconcile failing/unknown sources first.")
    else:
        print("Alignment meets threshold. Confirm every source above is a KNOWN legitimate sender before advancing.")

    if args.out:
        import csv
        with open(f"{args.out}.csv", "w", newline="", encoding="utf-8") as fh:
            w = csv.writer(fh)
            w.writerow(["source_ip", "header_from", "volume", "spf_pass", "dkim_pass", "dmarc_pass"])
            for (src, hfrom), a in rows:
                w.writerow([src, hfrom, a["volume"], a["spf_pass"], a["dkim_pass"], a["dmarc_pass"]])
        print(f"[written] {args.out}.csv")

    return 0 if verdict == "PASS" else 2


if __name__ == "__main__":
    sys.exit(main())
