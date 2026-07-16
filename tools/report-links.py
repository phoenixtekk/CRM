#!/usr/bin/env python3
"""report-links.py — emit the review URLs for factory-produced product solutions.

The factory's mandatory FINAL step (publish-solution SKILL §9): after any run that creates or
republishes products, report a clickable Store + Wiki link per product so the owner can review
immediately. Links are DERIVED from registry.json + each solution's meta/listing — never typed
by hand, never guessed (a wrong link is worse than none).

Usage
  python tools/report-links.py --slug <slug> [--slug <slug> ...]
  python tools/report-links.py --since 2026-07-16          # everything published/updated on/after
  python tools/report-links.py --last 12                   # N most recently published
  ... add --verify to check each URL and flag dead ones (slower; hits the live sites)

Output: a markdown table (many) or inline pairs (1-3), ready to paste into the Shipped report.

Exit codes: 0 ok · 1 nothing matched · 2 a link failed verification (--verify only)
"""
import argparse, io, json, sys, urllib.request, urllib.error
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
REGISTRY = REPO / "library" / "_index" / "registry.json"
STORE = "https://workplace.phoenixtekk.com"
WIKI = "https://docs.phoenixtekk.com"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36"


def load_registry():
    data = json.loads(REGISTRY.read_text(encoding="utf-8"))
    return data["solutions"] if isinstance(data, dict) and "solutions" in data else data


def version_dir(entry):
    """Resolve the solution's current version folder from LATEST.txt (fall back to registry)."""
    base = REPO / "library" / entry["category_slug"] / entry["slug"]
    latest = base / "LATEST.txt"
    if latest.exists():
        v = latest.read_text(encoding="utf-8").strip().replace("\r", "")
        if v:
            return base / v
    return base / f"v{entry.get('version', '1.0.0')}"


def solution_links(entry):
    """Return (title, [(audience, store_url)], wiki_url, gated, notes)."""
    vdir = version_dir(entry)
    meta, listing = {}, {}
    mp, lp = vdir / "solution.meta.json", vdir / "listing" / "bagisto-products.json"
    if mp.exists():
        meta = json.loads(mp.read_text(encoding="utf-8"))
    if lp.exists():
        listing = json.loads(lp.read_text(encoding="utf-8"))

    # Store: url_key straight from the listing — that IS the live route. No guessing.
    store = []
    for p in listing.get("products", []):
        key = p.get("url_key")
        if key:
            store.append((p.get("audience", "?"), f"{STORE}/{key}"))
    # Commercial first (it's the review link); free products only have the one.
    order = {"commercial": 0, "free": 0, "nonprofit": 1, "government": 2}
    store.sort(key=lambda x: order.get(x[0], 9))

    # Wiki: meta.wiki_path overrides the default solutions/<category_slug>/<slug>.
    wpath = meta.get("wiki_path") or f"solutions/{entry['category_slug']}/{entry['slug']}"
    gated = meta.get("wiki_gated", True)

    notes = []
    if not store:
        notes.append("NO STORE LISTING (no url_key found)")
    if entry.get("status") != "published":
        notes.append(f"status={entry.get('status')}")
    return meta.get("title") or entry["title"], store, f"{WIKI}/en/{wpath}", gated, notes


def http_status(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA}, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception as e:
        return f"ERR({type(e).__name__})"


def main():
    ap = argparse.ArgumentParser(description="Report Store + Wiki review links for solutions.")
    ap.add_argument("--slug", action="append", default=[], help="slug (repeatable)")
    ap.add_argument("--since", help="YYYY-MM-DD — published_at/updated on or after")
    ap.add_argument("--last", type=int, help="N most recently published")
    ap.add_argument("--verify", action="store_true", help="check each URL (store 200; wiki 403=gated / 200=public)")
    ap.add_argument("--out", help="write markdown here as well as stdout")
    a = ap.parse_args()

    reg = load_registry()
    if a.slug:
        want = set(a.slug)
        sols = [e for e in reg if e["slug"] in want]
        missing = want - {e["slug"] for e in sols}
        for m in sorted(missing):
            print(f"WARN: slug not in registry: {m}", file=sys.stderr)
    elif a.since:
        sols = [e for e in reg if (e.get("published_at") or e.get("updated") or "") >= a.since]
    elif a.last:
        sols = sorted(reg, key=lambda e: (e.get("published_at") or e.get("updated") or ""), reverse=True)[: a.last]
    else:
        ap.error("give one of --slug / --since / --last")

    if not sols:
        print("No solutions matched.", file=sys.stderr)
        return 1

    sols.sort(key=lambda e: e["title"])
    rows, bad = [], False
    for e in sols:
        title, store, wiki, gated, notes = solution_links(e)
        s_url = store[0][1] if store else None
        s_txt, w_txt = "—", None

        if a.verify:
            if s_url:
                sc = http_status(s_url)
                ok = sc == 200
                bad |= not ok
                s_txt = f"[review in store]({s_url}) — {sc}{'' if ok else ' ⚠ DEAD'}"
            wc = http_status(wiki)
            expect = 403 if gated else 200
            ok = wc == expect
            bad |= not ok
            label = "gated" if gated else "public"
            w_txt = f"[wiki guide]({wiki}) — {wc} ({label})" + ("" if ok else f" ⚠ expected {expect}")
        else:
            if s_url:
                s_txt = f"[review in store]({s_url})"
            w_txt = f"[wiki guide]({wiki})" + (" (gated)" if gated else " (public)")

        if notes:
            s_txt += f" _({'; '.join(notes)})_"
        rows.append((title, s_txt, w_txt))

    lines = []
    if len(rows) <= 3:
        for t, s, w in rows:
            lines += [f"- **{t}**", f"  - Store: {s}", f"  - Wiki: {w}"]
    else:
        lines += ["| Product | Store (Marketplace) | Wiki (KB) |", "|---|---|---|"]
        lines += [f"| **{t}** | {s} | {w} |" for t, s, w in rows]
    md = "\n".join(lines)
    print(md)
    if a.out:
        io.open(a.out, "w", encoding="utf-8", newline="\n").write(md + "\n")
    if a.verify and bad:
        print("\nWARN: at least one link did not verify — fix or say so; never report a dead URL.", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
