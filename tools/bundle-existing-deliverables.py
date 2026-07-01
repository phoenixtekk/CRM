#!/usr/bin/env python3
"""
One-time migration: for every solution in library/_index/registry.json, build a single
"<SOL>-Complete-Solution.zip" (the existing PDF + Word doc + scripts) and rewrite that
solution's listing/bagisto-products.json so every product carries exactly ONE download —
the bundle — instead of the separate PDF + Scripts links.

This closes the Bagisto "optional downloadable-link checkbox" footgun (a buyer could check
out without selecting their files). Re-attach to the live store afterward with the loader's
non-destructive --update-content.

Usage:
  python tools/bundle-existing-deliverables.py [--dry-run] [--only SOL_CODE]
Run from the CRM repo root.
"""
import argparse, json, sys, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REG = ROOT / "library" / "_index" / "registry.json"
BUNDLE_TITLE = "Complete Solution Package (PDF, Word Doc & Scripts)"


def solutions():
    reg = json.loads(REG.read_text(encoding="utf-8"))
    items = reg if isinstance(reg, list) else (reg.get("solutions") or reg.get("entries") or list(reg.values()))
    if isinstance(items, dict):
        items = list(items.values())
    return [s for s in items if isinstance(s, dict) and s.get("sol_code") and s.get("rel_path")]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--only", help="limit to one SOL_CODE")
    args = ap.parse_args()

    ok = skipped = 0
    problems = []
    for s in solutions():
        sol = s["sol_code"]
        if args.only and sol != args.only:
            continue
        vdir = (ROOT / s["rel_path"].replace("\\", "/")).resolve()
        deliv = vdir / "deliverables"
        scr = vdir / "scripts"
        listing = vdir / "listing" / "bagisto-products.json"

        pdf = deliv / f"{sol}-Solution.pdf"
        docx = deliv / f"{sol}-Solution.docx"
        bundle = deliv / f"{sol}-Complete-Solution.zip"

        missing = [p.name for p in (pdf, docx) if not p.exists()]
        if missing or not listing.exists():
            problems.append(f"{sol}: missing {missing or ''} {'(no listing json)' if not listing.exists() else ''}".strip())
            skipped += 1
            continue

        ps1s = sorted(scr.glob("*.ps1")) if scr.exists() else []

        if args.dry_run:
            print(f"  [dry] {sol}: bundle {pdf.name}+{docx.name}+{len(ps1s)} script(s) -> {bundle.name}; patch {listing.name}")
            ok += 1
            continue

        # 1) build the bundle from existing deliverables
        with zipfile.ZipFile(bundle, "w", zipfile.ZIP_DEFLATED) as b:
            b.write(pdf, arcname=pdf.name)
            b.write(docx, arcname=docx.name)
            for p in ps1s:
                b.write(p, arcname=f"Scripts/{p.name}")

        # 2) rewrite the listing so every product has the single bundle download
        data = json.loads(listing.read_text(encoding="utf-8"))
        dl = [{"title": BUNDLE_TITLE, "source_type": "file", "source": bundle.name}]
        for p in data.get("products", []):
            if p.get("type") == "downloadable" or "downloads" in p:
                p["downloads"] = [dict(d) for d in dl]
        listing.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

        print(f"  {sol}: bundle={bundle.stat().st_size:>9,}B ({len(ps1s)} scripts); listing patched ({len(data.get('products', []))} products)")
        ok += 1

    print(f"\n{'DRY-RUN ' if args.dry_run else ''}done: {ok} ok, {skipped} skipped")
    if problems:
        print("PROBLEMS:\n  " + "\n  ".join(problems))
        sys.exit(1 if not args.dry_run else 0)


if __name__ == "__main__":
    main()
