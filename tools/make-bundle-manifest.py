#!/usr/bin/env python3
"""
Build the manifest + stage the bundle files for swap-downloads-to-bundle.php.

For each solution (from registry.json) that has a built <SOL>-Complete-Solution.zip, copy the
zip into dist/bundles/ and add a manifest entry { sol_code, file_name, skus }. Writes
dist/bundle-manifest.json (bundles_dir is the server staging dir the zips get scp'd to).

Usage:
  python tools/make-bundle-manifest.py [--only SOL] [--bundles-dir /tmp/ptk-bundles]
Run from CRM repo root, then scp dist/bundles/* -> <bundles-dir> on linuxg5 and run the swap.
"""
import argparse, json, shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REG = ROOT / "library" / "_index" / "registry.json"
TITLE = "Complete Solution Package (PDF, Word Doc & Scripts)"


def solutions():
    reg = json.loads(REG.read_text(encoding="utf-8"))
    items = reg if isinstance(reg, list) else (reg.get("solutions") or reg.get("entries") or list(reg.values()))
    if isinstance(items, dict):
        items = list(items.values())
    return [s for s in items if isinstance(s, dict) and s.get("sol_code") and s.get("rel_path")]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only")
    ap.add_argument("--bundles-dir", default="/tmp/ptk-bundles")
    args = ap.parse_args()

    out_dir = ROOT / "dist" / "bundles"
    out_dir.mkdir(parents=True, exist_ok=True)
    # clean stale staged bundles
    for f in out_dir.glob("*.zip"):
        f.unlink()

    entries = []
    missing = []
    for s in solutions():
        sol = s["sol_code"]
        if args.only and sol != args.only:
            continue
        vdir = (ROOT / s["rel_path"].replace("\\", "/")).resolve()
        bundle = vdir / "deliverables" / f"{sol}-Complete-Solution.zip"
        skus = s.get("skus") or []
        if not bundle.exists():
            missing.append(sol); continue
        if not skus:
            missing.append(f"{sol}(no skus)"); continue
        shutil.copyfile(bundle, out_dir / bundle.name)
        entries.append({"sol_code": sol, "file_name": bundle.name, "skus": skus})

    manifest = {"bundles_dir": args.bundles_dir, "title": TITLE, "entries": entries}
    (ROOT / "dist" / "bundle-manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    total_skus = sum(len(e["skus"]) for e in entries)
    print(f"manifest: {len(entries)} solution(s), {total_skus} sku(s) -> dist/bundle-manifest.json")
    print(f"staged bundles -> dist/bundles/  (scp these to {args.bundles_dir} on linuxg5)")
    if missing:
        print(f"NOTE: {len(missing)} solution(s) had no built bundle yet: {', '.join(missing[:10])}{' ...' if len(missing)>10 else ''}")


if __name__ == "__main__":
    main()
