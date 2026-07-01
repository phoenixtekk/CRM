#!/usr/bin/env python3
"""
add-government-tier.py — backfill a Government product (PTK-<SOL>-GOV-001 @ round(commercial*0.85,2))
into every solution that currently has only Commercial + Non-Profit. Updates each solution's
listing/bagisto-products.json AND solution.meta.json. Idempotent: skips solutions that already have a
government product. Does NOT touch the live store (run the loader afterwards).

Usage:
  python tools/add-government-tier.py --registry library/_index/registry.json [--apply]
Without --apply: dry-run (reports what it would change). With --apply: writes the files.
"""
import argparse, json, re
from pathlib import Path

GOV_BLOCK = ("<h4>Government pricing</h4><p>Verified government and public-sector buyers receive "
             "<strong>15% off</strong> this solution. <strong>Eligibility:</strong> verification of "
             "public-sector status (e.g. a government email domain or SAM.gov entity) is completed "
             "before the discount applies.</p>")


def gov_from_commercial(comm, title, slug):
    price = round(float(comm["price"]) * 0.85, 2)
    sku = comm["sku"].replace("-COMM-", "-GOV-")
    name = comm["name"].replace("— Commercial", "— Government")
    if name == comm["name"]:
        name = comm["name"] + " — Government"
    url_key = (comm.get("url_key") or f"{slug}-commercial")
    url_key = re.sub(r"-commercial$", "-government", url_key)
    if not url_key.endswith("-government"):
        url_key = f"{slug}-government"
    short = (f"<p>The complete {title} solution at <strong>15% below</strong> commercial for verified "
             f"government / public-sector buyers. Same self-guided documentation and tested scripts. "
             f"<strong>Eligibility verification required.</strong></p>")
    desc = (comm.get("description") or "") + GOV_BLOCK
    meta_title = (comm.get("meta_title") or name)
    if "Government" not in meta_title:
        meta_title = meta_title + " — Government"
    meta_desc = ("Verified public-sector pricing, 15% below commercial. " +
                 (comm.get("meta_description") or ""))[:320]
    gov = {
        "sku": sku, "name": name, "type": comm.get("type", "downloadable"),
        "audience": "government", "price": price,
        "short_description": short, "description": desc,
        "meta_title": meta_title, "meta_description": meta_desc,
        "url_key": url_key,
    }
    if comm.get("image"): gov["image"] = comm["image"]
    if comm.get("downloads"): gov["downloads"] = comm["downloads"]
    return gov


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--registry", required=True)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    reg = json.loads(Path(args.registry).read_text(encoding="utf-8"))
    sols = reg if isinstance(reg, list) else reg.get("solutions", [])
    repo = Path(args.registry).resolve().parent.parent.parent

    changed, skipped = [], []
    for s in sols:
        slug = s.get("slug"); rel = (s.get("rel_path") or "").replace("\\", "/")
        vdir = repo / rel
        jpath = vdir / "listing" / "bagisto-products.json"
        mpath = vdir / "solution.meta.json"
        if not jpath.exists():
            continue
        data = json.loads(jpath.read_text(encoding="utf-8"))
        prods = data["products"]
        if any(p.get("audience") == "government" for p in prods):
            skipped.append(slug); continue
        comm = next((p for p in prods if p.get("audience") == "commercial"), None)
        if not comm:
            skipped.append(slug + " (no commercial)"); continue
        title = data.get("solution", {}).get("title", slug)
        gov = gov_from_commercial(comm, title, slug)
        prods.append(gov)
        # meta
        meta = json.loads(mpath.read_text(encoding="utf-8")) if mpath.exists() else None
        if meta and not any(p.get("audience") == "government" for p in meta.get("products", [])):
            meta["products"].append({"sku": gov["sku"], "audience": "government", "price": gov["price"]})
        changed.append((slug, comm["price"], gov["price"], gov["sku"]))
        if args.apply:
            jpath.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            if meta:
                mpath.write_text(json.dumps(meta, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"{'APPLIED' if args.apply else 'DRY-RUN'} — {len(changed)} solution(s) get a Government tier; "
          f"{len(skipped)} skipped (already 3-tier).")
    for slug, c, g, sku in changed:
        print(f"  + {sku:24} ${g:,.2f}  (comm ${c:,.2f})  {slug}")


if __name__ == "__main__":
    main()
