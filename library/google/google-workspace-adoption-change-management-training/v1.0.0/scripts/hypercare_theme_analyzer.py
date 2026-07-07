#!/usr/bin/env python3
# hypercare_theme_analyzer.py — rank hypercare ticket themes and check floorwalker staffing.
#
# PURPOSE: Analyze a hypercare TICKET export into ranked themes (by keyword taxonomy over subject/body)
#          so the top user pain points are visible and can feed back into comms/training, and check
#          floorwalker STAFFING against the "Hypercare Model - <Wave/Region> - Golive" plan. Safe
#          default: read-only over inputs; writes only a themes report CSV.
# HOW TO RUN: python hypercare_theme_analyzer.py --tickets tickets.csv
#             [--expected-floorwalkers N --actual-floorwalkers M] [--out themes.csv]
#             (Python 3.10+; standard library only)
# EXPECTED RESULTS: A ranked theme table + STAFFING: OK/SHORT, and a CSV of themes with counts/shares.
#                   Non-zero exit if staffing is SHORT (so it can gate/flag a wave).
#
# Input format (CSV headers): tickets.csv : id,subject[,description][,app]
# Themes are matched by a transparent, editable keyword taxonomy below — tune for your environment.
# No credentials, no API calls, no secrets.

import argparse
import csv
import sys
from collections import Counter

# Editable taxonomy: theme -> keywords. First matching theme wins; unmatched -> "Other".
THEMES = {
    "Mail migration / missing mail": ["missing email", "old mail", "forward", "outlook", "mailbox",
                                      "not received", "where is my mail"],
    "Drive / files & sharing": ["drive", "file", "share", "permission", "shared drive", "folder",
                                "onedrive", "sync"],
    "Docs / Sheets / Slides": ["docs", "sheet", "slide", "format", "template", "office", "word",
                               "excel", "powerpoint"],
    "Meet / meetings & calendar": ["meet", "meeting", "calendar", "invite", "join", "camera",
                                   "microphone", "recording"],
    "Chat / Spaces": ["chat", "space", "message", "teams", "im "],
    "Sign-in / SSO / access": ["sign in", "login", "log in", "password", "sso", "mfa", "2-step",
                               "locked", "access"],
    "Mobile / device setup": ["mobile", "phone", "android", "ios", "app install", "device"],
    "Gemini / AI features": ["gemini", "help me write", "ai ", "side panel", "gem "],
}


def classify(text: str) -> str:
    t = text.lower()
    for theme, kws in THEMES.items():
        if any(kw in t for kw in kws):
            return theme
    return "Other"


def main() -> int:
    ap = argparse.ArgumentParser(description="Rank hypercare ticket themes and check staffing.")
    ap.add_argument("--tickets", required=True, help="Tickets CSV: id,subject[,description][,app]")
    ap.add_argument("--expected-floorwalkers", type=int, default=None,
                    help="Planned floorwalkers per the Hypercare Model.")
    ap.add_argument("--actual-floorwalkers", type=int, default=None,
                    help="Actual floorwalkers staffed.")
    ap.add_argument("--out", default="hypercare_themes.csv", help="Output CSV path.")
    args = ap.parse_args()

    try:
        with open(args.tickets, newline="", encoding="utf-8") as fh:
            tickets = list(csv.DictReader(fh))
    except FileNotFoundError:
        sys.exit(f"ERROR: file not found: {args.tickets}")

    counts = Counter()
    for r in tickets:
        blob = " ".join(str(r.get(k) or "") for k in ("subject", "description", "app"))
        counts[classify(blob)] += 1
    total = sum(counts.values())

    print(f"Hypercare theme analysis  ({total} tickets)")
    print(f"{'Theme':34} {'Count':>7} {'Share':>7}")
    rows = []
    for theme, n in counts.most_common():
        share = (n / total) if total else 0.0
        print(f"{theme:34} {n:7d} {share:6.0%}")
        rows.append({"theme": theme, "count": n, "share": f"{share:.4f}"})

    with open(args.out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["theme", "count", "share"])
        w.writeheader()
        w.writerows(rows)
    print(f"\nWrote {args.out} (read-only over inputs).")

    rc = 0
    if args.expected_floorwalkers is not None and args.actual_floorwalkers is not None:
        if args.actual_floorwalkers >= args.expected_floorwalkers:
            print(f"STAFFING: OK — {args.actual_floorwalkers}/{args.expected_floorwalkers} floorwalkers.")
        else:
            print(f"STAFFING: SHORT — {args.actual_floorwalkers}/{args.expected_floorwalkers} "
                  f"floorwalkers; add coverage or draw on champions.")
            rc = 1
    else:
        print("STAFFING: not evaluated (pass --expected-floorwalkers and --actual-floorwalkers).")
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
