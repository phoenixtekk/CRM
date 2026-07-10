#!/usr/bin/env python3
"""leadgen-digest.py — weekly per-board conversion digest for the job-board lead-gen engine.

Reads the landing-page logs (pageviews.jsonl + leads.jsonl) and prints a per-source report:
arrivals, leads, and conversion rate, plus a recent-leads tail. Group key = `src` (the ?src=<board>
tag), so you see which job board actually converts.

Run ON linuxg5 (data lives at /home/workplace/leaddata), e.g. via weekly cron:
    0 8 * * 1  cd /home/workplace && python3 leadgen-digest.py --days 7 | mail -s "Weekly lead digest" admin@phoenixtekk.io
Or over SSH from anywhere:
    ssh linuxg5 'sudo -u workplace python3 - --days 7' < tools/leadgen-digest.py   # (or scp it first)

No secrets, read-only.
"""
import json, argparse, collections, datetime as dt
from pathlib import Path

def load(p):
    rows = []
    if Path(p).is_file():
        for ln in Path(p).read_text(encoding="utf-8", errors="ignore").splitlines():
            ln = ln.strip()
            if ln:
                try: rows.append(json.loads(ln))
                except Exception: pass
    return rows

def within(ts, cutoff):
    try:
        return dt.datetime.fromisoformat(ts.replace("Z", "+00:00")) >= cutoff
    except Exception:
        return True  # keep undated rows

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data-dir", default="/home/workplace/leaddata")
    ap.add_argument("--days", type=int, default=7)
    ap.add_argument("--tail", type=int, default=10)
    a = ap.parse_args()
    d = Path(a.data_dir)
    cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=a.days)

    pvs = [r for r in load(d / "pageviews.jsonl") if within(r.get("ts", ""), cutoff)]
    lds = [r for r in load(d / "leads.jsonl") if within(r.get("ts", ""), cutoff)]

    def keyed(rows, k="src"):
        c = collections.Counter()
        for r in rows: c[(r.get(k) or "direct")] += 1
        return c
    pv_by = keyed(pvs); ld_by = keyed(lds)
    sources = sorted(set(pv_by) | set(ld_by), key=lambda s: (ld_by[s], pv_by[s]), reverse=True)

    line = "=" * 66
    print(line)
    print(f" Workplace Marketplace — Lead-gen digest (last {a.days} days)")
    print(f" {dt.datetime.now(dt.timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}")
    print(line)
    print(f" Totals: {len(pvs)} arrivals · {len(lds)} leads · "
          f"{(100.0*len(lds)/len(pvs)):.1f}% conversion" if pvs else " Totals: 0 arrivals · 0 leads")
    print("-" * 66)
    print(f" {'SOURCE':<18}{'ARRIVALS':>10}{'LEADS':>8}{'CONV%':>9}")
    print("-" * 66)
    for s in sources:
        pv, ld = pv_by[s], ld_by[s]
        conv = f"{(100.0*ld/pv):.1f}" if pv else ("—" if ld == 0 else "∞")
        print(f" {s[:18]:<18}{pv:>10}{ld:>8}{conv:>9}")
    print("-" * 66)
    if lds:
        print(f"\n Recent leads (last {a.tail}):")
        for r in lds[-a.tail:]:
            desc = (r.get("desc") or "")[:70]
            print(f"  [{r.get('src','?'):<10}] {r.get('email','?'):<32} {desc}")
    print(line)

if __name__ == "__main__":
    main()
