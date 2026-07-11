#!/usr/bin/env python3
"""build-seo-pages.py — generate public, SEO-indexable PREVIEW pages for every published solution.

Why: the full runbooks live on the GATED wiki (great for buyers, invisible to Google). These pages are
public teasers — the problem, what the solution is, what's inside — with JSON-LD and a strong CTA to buy
the full runbook (store) or describe a new one (/create). The gated implementation detail stays gated.

Output: marketing/growth/learn/<slug>.html + index.html (hub) + sitemap.xml
Deploy: the learn/ dir -> the store's public/learn/ (served directly by Apache, like /start and /create).
"""
import json, re, html
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REG = ROOT / "library" / "_index" / "registry.json"
OUT = ROOT / "marketing" / "growth" / "learn"
STORE = "https://workplace.phoenixtekk.com"
BASE = f"{STORE}/learn"

def teaser(rel_path, fallback):
    """First ~2 paragraphs of the solution overview, markdown stripped."""
    p = ROOT / Path(rel_path.replace("\\", "/")) / "source" / "01-solution-overview.md"
    if not p.is_file():
        return fallback
    txt = p.read_text(encoding="utf-8", errors="ignore")
    txt = re.sub(r"^#.*$", "", txt, flags=re.M)                 # drop headings
    txt = re.sub(r"[*_`>#|]", "", txt)                          # drop md marks
    txt = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", txt)          # links -> text
    paras = [ln.strip() for ln in re.split(r"\n\s*\n", txt) if len(ln.strip()) > 60]
    return " ".join(paras[:2])[:600] if paras else fallback

def meta_desc(t):
    s = re.split(r"(?<=[.!?])\s", t)[0]
    return (s[:152] + "…") if len(s) > 155 else s

def esc(s): return html.escape(s or "", quote=True)

PAGE = """<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} | Ready-to-Deploy Runbook — Workplace Marketplace</title>
<meta name="description" content="{desc}">
<link rel="canonical" href="{canonical}">
<link rel="icon" type="image/png" href="/create/logo.png">
<meta property="og:type" content="product"><meta property="og:title" content="{title}">
<meta property="og:description" content="{desc}"><meta property="og:url" content="{canonical}">
<script type="application/ld+json">{jsonld}</script>
<style>
:root{{--bg:#0b1220;--card:#141f36;--ink:#eaf0fb;--mut:#9fb0cd;--line:#243350;--brand:#3b82f6;--brand2:#22c55e;--accent:#38bdf8}}
*{{box-sizing:border-box}}body{{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;color:var(--ink);background:radial-gradient(1000px 500px at 15% -8%,#16233f,var(--bg) 60%) no-repeat,var(--bg);line-height:1.6}}
a{{color:var(--accent);text-decoration:none}}.wrap{{max-width:820px;margin:0 auto;padding:0 20px}}
header{{display:flex;align-items:center;gap:10px;padding:18px 0}}header img{{width:28px;height:28px;border-radius:8px}}header b{{font-weight:800}}header small{{display:block;font-size:11px;color:var(--mut);letter-spacing:.12em;text-transform:uppercase}}
.crumb{{font-size:12.5px;color:var(--mut);margin:8px 0 6px}}.cat{{color:var(--accent);font-weight:700;font-size:12.5px;text-transform:uppercase;letter-spacing:.05em}}
h1{{font-size:clamp(24px,4vw,36px);line-height:1.15;margin:6px 0 14px;letter-spacing:-.02em}}
.lede{{color:#cdd8ea;font-size:17px}}.card{{background:linear-gradient(180deg,var(--card),#18243f);border:1px solid var(--line);border-radius:16px;padding:20px;margin:22px 0}}
.card h2{{font-size:16px;margin:0 0 10px}}.card ul{{margin:0;padding-left:18px;color:var(--mut)}}.card li{{margin:5px 0}}
.cta{{display:flex;gap:12px;flex-wrap:wrap;margin:22px 0}}.btn{{display:inline-flex;align-items:center;gap:8px;font-weight:700;border-radius:12px;padding:13px 20px;font-size:15px}}
.btn.p{{background:linear-gradient(92deg,var(--brand),#2563eb);color:#fff}}.btn.g{{border:1px solid var(--line);color:var(--ink)}}
.price{{color:var(--mut);font-size:14px;margin-top:4px}}.rel{{margin:26px 0}}.rel a{{display:block;padding:10px 0;border-top:1px solid var(--line);color:var(--ink)}}.rel a:hover{{color:var(--accent)}}
footer{{border-top:1px solid var(--line);margin-top:30px;padding:22px 0;color:var(--mut);font-size:13px}}
</style></head><body><div class="wrap">
<header><img src="/create/logo.png" alt=""><span><b>PHOENIXTEKK</b><small>Workplace Marketplace</small></span></header>
<div class="crumb"><a href="/learn/">Catalog</a> › {category} › {title}</div>
<div class="cat">{category}</div>
<h1>{title}</h1>
<p class="lede">{teaser}</p>
<div class="cta">
  <a class="btn p" href="{buy}">Get the full runbook →</a>
  <a class="btn g" href="{createurl}">Need a variant? Ask →</a>
</div>
<div class="price">{pricetext}</div>
<div class="card"><h2>What's inside</h2><ul>
<li><b>Complete click-by-click implementation guide</b> (Word/PDF) — assess → configure → pilot → validate → expand, with pass/fail gates.</li>
<li><b>{scripts} tested PowerShell scripts</b> — discovery, validation, reporting, and safe remediation.</li>
<li>Requirements, testing, troubleshooting & best-practices — everything to deploy it yourself or hand to your team.</li>
<li>One flat price · unlimited devices · Commercial &amp; Government (GCC High).</li>
</ul></div>
<div class="card"><h2>Run it yourself — simpler, cheaper, proven</h2>
<p style="color:var(--mut);margin:0">No consultant, no open day-rate meter. Self-guided documentation a competent admin follows end to end, backed by tested scripts. Pilot-first, rollback-ready.</p></div>
{related}
<footer>Phoenixtekk Workplace Marketplace · <a href="{store}">workplace.phoenixtekk.com</a> · 400+ ready-to-deploy Microsoft &amp; IT solutions · Commercial &amp; Government (GCC High)</footer>
</div></body></html>"""

def main():
    reg = json.loads(REG.read_text(encoding="utf-8"))
    sols = [s for s in reg if isinstance(s, dict) and s.get("slug") and s.get("status") == "published"]
    OUT.mkdir(parents=True, exist_ok=True)
    by_cat = {}
    for s in sols:
        by_cat.setdefault(s.get("category", "Other"), []).append(s)

    written = []
    for s in sols:
        slug, title, cat = s["slug"], s.get("title", ""), s.get("category", "")
        t = teaser(s.get("rel_path", ""), f"A ready-to-deploy {cat} solution: {title}.")
        price = s.get("commercial")
        buy = f"{STORE}/{slug}-commercial?src=learn"
        canonical = f"{BASE}/{slug}.html"
        pricetext = f"From ${price:,.0f} — one flat price, unlimited devices." if price else "One flat price, unlimited devices."
        # related: up to 3 others in same category
        rel_items = [x for x in by_cat.get(cat, []) if x["slug"] != slug][:3]
        rel_html = ""
        if rel_items:
            rel_html = '<div class="rel"><h2 style="font-size:16px">Related solutions</h2>' + \
                "".join(f'<a href="/learn/{esc(r["slug"])}.html">{esc(r.get("title",""))}</a>' for r in rel_items) + "</div>"
        jsonld = json.dumps({
            "@context": "https://schema.org", "@type": "Product", "name": title,
            "description": meta_desc(t), "category": cat, "brand": {"@type": "Brand", "name": "Phoenixtekk Workplace Marketplace"},
            "offers": {"@type": "Offer", "price": price or 0, "priceCurrency": "USD", "url": buy, "availability": "https://schema.org/InStock"},
        }, ensure_ascii=False)
        page = PAGE.format(title=esc(title), desc=esc(meta_desc(t)), canonical=canonical, category=esc(cat),
                           teaser=esc(t), buy=esc(buy), createurl=f"{STORE}/create?src=learn", pricetext=esc(pricetext),
                           scripts=s.get("script_count", 5), related=rel_html, store=STORE, jsonld=jsonld)
        (OUT / f"{slug}.html").write_text(page, encoding="utf-8")
        written.append((slug, title, cat))

    # hub index grouped by category
    hub = ['<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">',
           '<title>Solution Catalog — Ready-to-Deploy Microsoft &amp; IT Runbooks | Workplace Marketplace</title>',
           '<meta name="description" content="Browse 400+ ready-to-deploy Microsoft Intune, Entra, Purview, Defender, Azure &amp; networking runbooks — click-by-click docs plus tested scripts.">',
           f'<link rel="canonical" href="{BASE}/"><link rel="icon" type="image/png" href="/create/logo.png">',
           '<style>body{font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;background:#0b1220;color:#eaf0fb;line-height:1.6;margin:0}.wrap{max-width:960px;margin:0 auto;padding:0 20px}h1{font-size:32px;margin:24px 0 6px}h2{color:#38bdf8;margin:28px 0 8px;font-size:18px}a{color:#eaf0fb;text-decoration:none}a:hover{color:#38bdf8}.g{display:grid;grid-template-columns:1fr 1fr;gap:6px}li{list-style:none}ul{padding:0;margin:0}.mut{color:#9fb0cd}</style></head><body><div class="wrap">',
           '<h1>Ready-to-Deploy Solution Catalog</h1>',
           '<p class="mut">400+ click-to-implement Microsoft &amp; cloud runbooks — documentation plus tested scripts. One flat price each, unlimited devices. <a href="/create">Can\'t find it? Ask →</a></p>']
    for cat in sorted(by_cat):
        items = sorted(by_cat[cat], key=lambda x: x.get("title", ""))
        hub.append(f'<h2>{esc(cat)} ({len(items)})</h2><ul class="g">')
        hub += [f'<li><a href="/learn/{esc(s["slug"])}.html">{esc(s.get("title",""))}</a></li>' for s in items]
        hub.append("</ul>")
    hub.append("</div></body></html>")
    (OUT / "index.html").write_text("\n".join(hub), encoding="utf-8")

    # sitemap
    sm = ['<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemap.org/schemas/sitemap/0.9">'.replace("sitemap.org","sitemaps.org")]
    sm.append(f"<url><loc>{BASE}/</loc></url>")
    for slug, _, _ in written:
        sm.append(f"<url><loc>{BASE}/{slug}.html</loc></url>")
    sm.append("</urlset>")
    (OUT / "sitemap.xml").write_text("\n".join(sm), encoding="utf-8")

    print(f"Generated {len(written)} SEO pages + index.html + sitemap.xml -> {OUT}")

if __name__ == "__main__":
    main()
