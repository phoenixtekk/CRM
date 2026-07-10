#!/usr/bin/env python3
"""
scaffold-listing.py — from a small per-solution spec (JSON), generate the non-source artifacts a
solution needs before build/publish: solution.meta.json, listing/bagisto-products.json (3-tier,
white-label), listing/hero.json, listing/sales-content.md, and README.md.

The source/*.md + scripts/*.ps1 are authored separately (by hand or subagents). This tool only
assembles the metadata/listing wrapper so 3-tier pricing + white-label sales copy stay consistent.

Usage:
  python tools/scaffold-listing.py --spec path/to/spec.json --solution-dir library/<cat>/<slug>/v1.0.0
Pricing: Non-Profit = round(commercial*0.60,2); Government = round(commercial*0.85,2).
"""
import argparse, json
from pathlib import Path

RUN_IT = ("<h4>Run it yourself — simpler, cheaper, and proven</h4>"
          "<p>You do <strong>not</strong> need a consultant. The package hands you the field-tested "
          "method as <strong>self-guided, click-by-click documentation</strong> a competent admin can "
          "follow end to end &mdash; backed by ready-to-run PowerShell.</p>"
          "<ul><li><strong>Simpler</strong> &mdash; exact, ordered steps with full navigation paths; "
          "every object you create is named and reused through testing and troubleshooting.</li>"
          "<li><strong>Cheaper</strong> &mdash; one fixed price instead of an open meter; a comparable "
          "consulting engagement runs well into the thousands per day. Reusable on every rollout.</li>"
          "<li><strong>Tested</strong> &mdash; a pilot-first method (<strong>Assess &rarr; Configure "
          "&rarr; Pilot &rarr; Validate &rarr; Expand</strong>) with explicit pass/fail gates.</li></ul>")
REPEATABLE = ("<h4>The repeatable way</h4><p>Every solution follows the same repeatable shape, so each "
              "deployment feels familiar and low-risk — buy once, reuse the playbook for the next wave "
              "and the next project.</p>")
DELIVERY = ("<p><em>Delivered as a Word document and PDF, plus all five PowerShell scripts in a single "
            "ZIP — yours to keep and reuse.</em></p>")


def whats_inside(items):
    lis = "".join(f"<li>{x}</li>" for x in items)
    return f"<h4>What's inside</h4><ul>{lis}</ul>"


def commercial_desc(s):
    return (f"<h3>{s['hook']}</h3><p>{s['problem']}</p>" + RUN_IT +
            whats_inside(s['whats_inside']) + REPEATABLE +
            f"<h4>The bottom line</h4><p>{s['bottom_line']}</p>" + DELIVERY)


def npo_desc(s):
    return (f"<h3>{s['hook']}</h3><p>{s['problem']}</p>"
            "<h4>Run it yourself — and stretch every dollar</h4>"
            "<p>The complete commercial package at <strong>40% below</strong> the standard price — the "
            "same self-guided documentation and tested scripts, simpler and cheaper than consulting. "
            "<strong>Eligibility:</strong> verification of qualifying non-profit status (e.g. 501(c)(3)) "
            "is completed before the discount applies.</p>" + whats_inside(s['whats_inside']) + DELIVERY)


def gov_desc(s):
    return (f"<h3>{s['hook']}</h3><p>{s['problem']}</p>"
            "<h4>Public-sector pricing</h4>"
            "<p>The complete commercial package at <strong>15% below</strong> the standard price for "
            "verified government / public-sector buyers. <strong>Eligibility:</strong> verification of "
            "public-sector status (e.g. a government email domain or SAM.gov entity) is completed before "
            "the discount applies.</p>" + whats_inside(s['whats_inside']) + DELIVERY)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec", required=True)
    ap.add_argument("--solution-dir", required=True)
    args = ap.parse_args()
    s = json.loads(Path(args.spec).read_text(encoding="utf-8"))
    vdir = Path(args.solution_dir)
    (vdir / "listing").mkdir(parents=True, exist_ok=True)
    sol, slug, title = s["sol"], s["slug"], s["title"]
    c = round(float(s["commercial_price"]), 2)
    n = round(c * 0.60, 2)
    g = round(c * 0.85, 2)
    # One always-included deliverable: the Complete Solution Package (PDF + Word doc + scripts in
    # a single zip). Avoids the Bagisto "optional downloadable-link checkbox" footgun where a buyer
    # could check out without selecting their files. (Was two separate PDF + Scripts links.)
    bundle, hero = f"{sol}-Complete-Solution.zip", f"{sol}-hero.png"
    dls = [{"title": "Complete Solution Package (PDF, Word Doc & Scripts)", "source_type": "file", "source": bundle}]

    def product(aud, sku_suf, price, name_suf, short, desc, mt, md, urlsuf):
        return {"sku": f"PTK-{sol}-{sku_suf}-001", "name": f"{title} — {name_suf}",
                "type": "downloadable", "audience": aud, "price": price,
                "short_description": short, "description": desc,
                "meta_title": mt, "meta_description": md,
                "url_key": f"{slug}-{urlsuf}", "image": hero, "downloads": dls}

    listing = {"solution": {"slug": slug, "title": title, "category_path": [s["category"]],
                            "version": "1.0.0"},
               "products": [
                   product("commercial", "COMM", c, "Commercial", s["short"], commercial_desc(s),
                           s["meta_title"], s["meta_description"], "commercial"),
                   product("nonprofit", "NPO", n, "Non-Profit",
                           f"<p>{s['short_plain']} <strong>Qualifying non-profits save 40%.</strong></p>",
                           npo_desc(s), s["meta_title"] + " — Non-Profit",
                           "Qualifying non-profits, 40% below commercial. " + s["meta_description"],
                           "nonprofit"),
                   product("government", "GOV", g, "Government",
                           f"<p>{s['short_plain']} <strong>Verified public sector saves 15%.</strong></p>",
                           gov_desc(s), s["meta_title"] + " — Government",
                           "Verified public-sector pricing, 15% below commercial. " + s["meta_description"],
                           "government"),
               ]}
    (vdir / "listing" / "bagisto-products.json").write_text(json.dumps(listing, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    meta = {"slug": slug, "title": title, "category": s["category"],
            "category_slug": s["category_slug"], "sol_code": sol, "version": "1.0.0",
            "status": "generated", "created": s["date"], "updated": s["date"], "published_at": None,
            "version_directive": "New", "branding": "off", "author_notes": s["author_notes"],
            "products": [{"sku": f"PTK-{sol}-COMM-001", "audience": "commercial", "price": c},
                         {"sku": f"PTK-{sol}-NPO-001", "audience": "nonprofit", "price": n},
                         {"sku": f"PTK-{sol}-GOV-001", "audience": "government", "price": g}],
            "deliverables": [bundle], "hero": hero}
    (vdir / "solution.meta.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (vdir / "listing" / "hero.json").write_text(json.dumps(s["hero"], indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (vdir.parent / "LATEST.txt").write_text("v1.0.0\n", encoding="utf-8")
    (vdir / "listing" / "sales-content.md").write_text(
        f"# Sales Content — {title}\n\n{s['short_plain']}\n\n"
        f"## Pricing\n- Commercial: ${c:,.2f} · Non-Profit: ${n:,.2f} (40% off) · Government: ${g:,.2f} (15% off)\n"
        f"- Discounted tiers require eligibility verification.\n", encoding="utf-8")
    (vdir / "README.md").write_text(
        f"# {title} — v1.0.0\n\n| | |\n|---|---|\n| Category | {s['category']} |\n| Solution code | {sol} |\n"
        f"| Commercial | ${c:,.2f} (`PTK-{sol}-COMM-001`) |\n| Non-Profit | ${n:,.2f} (`PTK-{sol}-NPO-001`) |\n"
        f"| Government | ${g:,.2f} (`PTK-{sol}-GOV-001`) |\n| Branding | off (white-label) |\n\n"
        f"{s['bottom_line']}\n\nNext: build deliverables + hero, then `/publish-solution {slug}`.\n",
        encoding="utf-8")
    print(f"scaffolded {slug}: comm ${c:,.2f} / npo ${n:,.2f} / gov ${g:,.2f}  -> {vdir}")


if __name__ == "__main__":
    main()
