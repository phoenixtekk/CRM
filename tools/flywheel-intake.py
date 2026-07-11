#!/usr/bin/env python3
"""flywheel-intake.py — turn real demand into a weekly build/answer list.

Reads captured asks (the /create queue and/or a text file of questions you collected from communities),
triages each against the published catalog, and prints a prioritized worklist:
  NEW      -> build candidate (run /generate-solution)
  PARTIAL  -> answer now; consider a gap-scoped product
  COVERED  -> you already have it; answer + link the product

Usage:
  # export the live queue first (on linuxg5):  sudo -u workplace cat /home/workplace/leaddata/create-queue.jsonl > queue.jsonl
  python tools/flywheel-intake.py --queue queue.jsonl
  python tools/flywheel-intake.py --asks questions.txt      # one question per line
Requires library/_index/catalog-index.json (built by tools/triage-ask.py --build-index).
"""
import json, re, argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "library" / "_index" / "catalog-index.json"
STOP = set("a an the of for to in on with and or via using use your you our we i want need implement "
           "implementation deploy deployment setup configure configuration solution solutions manage "
           "management enable how do get make build please can it that this at as is are be into across per".split())
SYN = {"iphone":["ios","apple"],"ios":["iphone","apple"],"vpn":["globalprotect","anyconnect","tunnel","aovpn","plap"],
       "mfa":["conditional","authentication"],"dlp":["purview","loss"],"label":["labeling","sensitivity","purview"],
       "enroll":["enrollment","ade","autopilot"],"sync":["cloudsync","connect"],"anchor":["consistencyguid","objectguid"]}

def tok(s):
    return [w for w in re.findall(r"[a-z0-9]+", (s or "").lower()) if w not in STOP and len(w) > 1]

def expand(ts):
    out = set(ts)
    for t in ts: out.update(SYN.get(t, []))
    return out

def score(ask, rows):
    q = expand(tok(ask))
    if not q: return []
    scored = []
    for r in rows:
        hits = q & set(r.get("keywords", []))
        if hits:
            scored.append((round(len(hits)/max(4, len(q)), 3), r))
    scored.sort(key=lambda x: x[0], reverse=True)
    return scored[:3]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--queue"); ap.add_argument("--asks")
    a = ap.parse_args()
    if not INDEX.exists():
        print("Run: python tools/triage-ask.py --build-index"); return
    rows = json.loads(INDEX.read_text(encoding="utf-8"))
    asks = []
    if a.queue and Path(a.queue).is_file():
        for ln in Path(a.queue).read_text(encoding="utf-8", errors="ignore").splitlines():
            ln = ln.strip()
            if ln:
                try: asks.append(json.loads(ln).get("ask", ""))
                except Exception: pass
    if a.asks and Path(a.asks).is_file():
        asks += [l.strip() for l in Path(a.asks).read_text(encoding="utf-8").splitlines() if l.strip()]
    # dedupe
    seen, uniq = set(), []
    for x in asks:
        k = x.lower().strip()
        if x and k not in seen: seen.add(k); uniq.append(x)

    buckets = {"NEW": [], "PARTIAL": [], "COVERED": []}
    for ask in uniq:
        m = score(ask, rows)
        top = m[0] if m else None
        verdict = "COVERED" if (top and top[0] >= 0.5) else ("PARTIAL" if top else "NEW")
        buckets[verdict].append((ask, top))

    print("=" * 70)
    print(f" Flywheel intake — {len(uniq)} unique asks")
    print("=" * 70)
    for v in ("NEW", "PARTIAL", "COVERED"):
        items = buckets[v]
        if not items: continue
        tag = {"NEW": "🚀 BUILD (run /generate-solution)", "PARTIAL": "🧩 ANSWER + consider gap product",
               "COVERED": "✅ ANSWER + link the product"}[v]
        print(f"\n## {v} — {tag}  ({len(items)})")
        for ask, top in items:
            print(f"  • {ask[:88]}")
            if top:
                print(f"      closest: {top[1]['title'][:70]}  ({top[0]})  {top[1]['link']}")
    print("\n" + "=" * 70)
    print(f" NEW={len(buckets['NEW'])}  PARTIAL={len(buckets['PARTIAL'])}  COVERED={len(buckets['COVERED'])}")

if __name__ == "__main__":
    main()
