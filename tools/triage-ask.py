#!/usr/bin/env python3
"""triage-ask.py — match a free-text solution ask against the published catalog.

Two jobs:
  1. --build-index  : regenerate library/_index/catalog-index.json (a lightweight,
                      keyword-tokenized index the /create + /start endpoints search server-side).
  2. --ask "<text>" : score the ask against the catalog and print the top matches as JSON
                      (used by the human/worker triage step and for local testing).

The catalog index is PUBLIC product info (title/slug/category/price/link) — safe to ship to the
server. Actual solution generation is NEVER fired from here; this only decides
"already covered (send link)" vs "buildable (queue for /generate-solution)".
"""
import json, re, sys, argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "library" / "_index" / "registry.json"
INDEX = ROOT / "library" / "_index" / "catalog-index.json"
STORE = "https://workplace.phoenixtekk.com"

STOP = set("a an the of for to in on with and or via using use your you our we i want need "
           "implement implementation deploy deployment setup configure configuration solution "
           "solutions manage management enable enabling how do get make build please can it that "
           "this these those at as is are be with without into across per etc".split())

# light synonym expansion so "iphone" matches "ios", "vpn" matches "globalprotect", etc.
SYN = {
    "iphone": ["ios", "ipad", "apple"], "ios": ["iphone", "apple", "ipados"],
    "mac": ["macos", "apple"], "macos": ["mac", "apple"],
    "android": ["googleplay"], "vpn": ["globalprotect", "anyconnect", "tunnel", "aovpn", "plap"],
    "mfa": ["conditional", "authentication", "2fa"], "dlp": ["purview", "loss"],
    "label": ["labeling", "sensitivity", "purview"], "enroll": ["enrollment", "ade", "autopilot"],
    "byod": ["personal"], "cod": ["corporate"], "defender": ["security"], "sentinel": ["siem"],
    "bitlocker": ["encryption"], "autopilot": ["provisioning", "hybrid"], "pim": ["privileged"],
}

def tok(s):
    words = re.findall(r"[a-z0-9]+", (s or "").lower())
    return [w for w in words if w not in STOP and len(w) > 1]

def load_registry():
    r = json.loads(REGISTRY.read_text(encoding="utf-8"))
    return r if isinstance(r, list) else (r.get("solutions") or list(r.values()))

def build_index():
    rows = []
    for s in load_registry():
        if not isinstance(s, dict):
            continue
        slug = s.get("slug")
        if not slug or s.get("status") != "published":
            continue
        title, cat = s.get("title", ""), s.get("category", "")
        kw = sorted(set(tok(title) + tok(cat) + tok((s.get("sol_code") or ""))))
        rows.append({
            "slug": slug, "title": title, "category": cat,
            "price": s.get("commercial"),
            "link": f"{STORE}/{slug}-commercial",
            "keywords": kw,
        })
    INDEX.write_text(json.dumps(rows, ensure_ascii=False, indent=0), encoding="utf-8")
    print(f"catalog-index.json written: {len(rows)} published solutions -> {INDEX}")
    return rows

def expand(tokens):
    out = set(tokens)
    for t in tokens:
        out.update(SYN.get(t, []))
    return out

def score(ask, rows, top=5):
    q = expand(tok(ask))
    if not q:
        return []
    scored = []
    for r in rows:
        kw = set(r["keywords"])
        hits = q & kw
        if not hits:
            continue
        # coverage of the ask + a small boost for category hits
        s = len(hits) / max(4, len(q)) + 0.15 * len([h for h in hits if h in tok(r["category"])])
        scored.append((round(s, 3), sorted(hits), r))
    scored.sort(key=lambda x: x[0], reverse=True)
    out = []
    for s, hits, r in scored[:top]:
        out.append({"score": s, "matched": hits, "title": r["title"],
                    "category": r["category"], "price": r["price"], "link": r["link"]})
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--build-index", action="store_true")
    ap.add_argument("--ask", type=str, default="")
    ap.add_argument("--top", type=int, default=5)
    a = ap.parse_args()
    if a.build_index or not INDEX.exists():
        rows = build_index()
    else:
        rows = json.loads(INDEX.read_text(encoding="utf-8"))
    if a.ask:
        matches = score(a.ask, rows, a.top)
        verdict = "covered" if (matches and matches[0]["score"] >= 0.5) else ("partial" if matches else "new")
        print(json.dumps({"ask": a.ask, "verdict": verdict, "matches": matches}, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
