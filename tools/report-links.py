#!/usr/bin/env python3
"""report-links.py — emit the review URLs for factory-produced product solutions.

The factory's mandatory FINAL step (publish-solution SKILL §9): after any run that TOUCHES a live
product, report a clickable Store link + Wiki link + LOCAL DELIVERABLES PATH per product, so the
owner can review the listing, the guide, and the actual files without hunting for any of them. All
three are DERIVED from registry.json + each solution's meta/listing — never typed by hand, never
guessed (a wrong link is worse than none).

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


def local_deliverables(entry, vdir, meta, absolute=False):
    """Return (display_path, notes) for the run's local deliverables.

    Reports the VERSION dir — that is the source of truth a rebuild writes to; library/_deliverables/
    is a publish-time copy. If the two disagree, say so: a stale shelf means the store may have
    shipped a different file than the one sitting in the version dir.
    """
    d = vdir / "deliverables"
    notes = []
    if not d.is_dir():
        return None, ["NO LOCAL DELIVERABLES DIR"]

    files = sorted(p.name for p in d.iterdir() if p.is_file())
    if not files:
        notes.append("EMPTY — nothing built")

    # The bundle named in meta is what the listing hands the buyer; its absence is worth flagging.
    for want in meta.get("deliverables", []):
        if want not in files:
            notes.append(f"MISSING {want}")

    shelf = REPO / "library" / "_deliverables" / entry["slug"]
    if shelf.is_dir():
        shelf_files = sorted(p.name for p in shelf.iterdir() if p.is_file())
        if shelf_files != files:
            notes.append("shelf differs from version dir — re-publish to refresh")
    elif files:
        notes.append("not on the _deliverables shelf (not published yet?)")

    if absolute:
        return str(d), notes
    return d.relative_to(REPO).as_posix(), notes


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
    return meta.get("title") or entry["title"], store, f"{WIKI}/en/{wpath}", gated, notes, vdir, meta


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
    ap.add_argument("--retired", action="append", default=[],
                    help="slug that was retired/purged in this run: reported as removed, never as a live link (repeatable)")
    ap.add_argument("--abs-paths", action="store_true", dest="abs_paths",
                    help="print absolute local deliverable paths instead of repo-relative clickable links")
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
    elif a.retired:
        sols = []  # a retire-only run: every slug is reported via --retired below
    else:
        ap.error("give one of --slug / --since / --last / --retired")

    if not sols and not a.retired:
        print("No solutions matched.", file=sys.stderr)
        return 1

    sols.sort(key=lambda e: e["title"])
    retired = set(a.retired)
    rows, bad = [], False
    for e in sols:
        title, store, wiki, gated, notes, vdir, meta = solution_links(e)
        s_url = store[0][1] if store else None
        s_txt, w_txt = "—", None

        # Retired/purged: the store URL 404s and the wiki page — even when deleted — still answers
        # 403 (the Guests deny rule fires before the 404), so --verify CANNOT tell "gated" from
        # "gone". Never emit a link that would dead-end the owner; state the removal instead.
        if e["slug"] in retired:
            rows.append((title, "_retired — listing removed from the store_",
                         "_retired — wiki page deleted_", "_retired_"))
            retired.discard(e["slug"])
            continue

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

        # Local deliverables — where the actual files sit on this machine.
        dpath, dnotes = local_deliverables(e, vdir, meta, absolute=a.abs_paths)
        if dpath is None:
            d_txt = f"⚠ _{'; '.join(dnotes)}_"
            bad = True
        else:
            d_txt = f"[`{dpath}`]({dpath})" if not a.abs_paths else f"`{dpath}`"
            if dnotes:
                d_txt += f" ⚠ _({'; '.join(dnotes)})_"
                bad = True
        rows.append((title, s_txt, w_txt, d_txt))

    # A retired solution is usually git-rm'd from the registry in the same run, so it never matched
    # above — report it anyway rather than let it disappear silently from the summary.
    for slug in sorted(retired):
        rows.append((f"{slug} (retired)", "_retired — listing removed from the store_",
                     "_retired — wiki page deleted_", "_retired_"))

    lines = []
    if len(rows) <= 3:
        for t, s, w, d in rows:
            lines += [f"- **{t}**", f"  - Store: {s}", f"  - Wiki: {w}", f"  - Deliverables (local): {d}"]
    else:
        lines += ["| Product | Store (Marketplace) | Wiki (KB) | Deliverables (local) |", "|---|---|---|---|"]
        lines += [f"| **{t}** | {s} | {w} | {d} |" for t, s, w, d in rows]
    md = "\n".join(lines)
    print(md)
    if a.out:
        io.open(a.out, "w", encoding="utf-8", newline="\n").write(md + "\n")
    # Deliverable problems are found locally and must fail the check with or without --verify.
    if bad:
        print("\nWARN: something above did not check out (⚠) — a link that did not verify, or missing/"
              "stale local deliverables. Fix it or say so plainly; never report a dead URL or point at "
              "files that aren't what the store shipped.", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
