#!/usr/bin/env python3
"""
build-hero.py — Phoenixtekk Workplace Marketplace factory hero-image generator.

Builds a templated product hero image (consistent house style) for a solution, driven by its
metadata + an optional listing/hero.json spec, then renders it to PNG via headless Edge/Chrome
(no native libs needed on Windows).

Outputs:
  deliverables/<SOL>-hero.svg   editable vector source
  deliverables/<SOL>-hero.png   1200x1200 store-ready raster (Bagisto base image)

The solution TITLE always appears on the image. Everything templatable (title color-split,
from/to flow, four benefit tiles, footer category) comes from listing/hero.json; if that's
missing, sensible defaults are derived from solution.meta.json.

Usage:
  python tools/build-hero.py --solution-dir "library/intune-solutions/windows-hello-for-business/v1.0.0"
"""
import argparse, json, os, subprocess, sys, tempfile, html, pathlib, hashlib, random, re

W = 1200
MARGIN = 15                      # required clear space between title text and the image border
COLORS = {"white": "#ffffff", "green": "#5cc24a", "blue": "#2f95d6"}

# Per-CATEGORY visual theme: solutions in the same category share a palette (cohesive),
# while a per-SOLUTION seed varies the background motif a little (distinct). Title colors
# (white/green/blue) and the green arrow stay constant for brand consistency.
CATEGORY_THEME = {
    "intune-solutions":      {"bg": ("#071226", "#0c2748", "#091a33"), "line": "#3a6ea5", "node": "#54a0e0", "glow": "#2f95d6"},
    "entra-id-solutions":    {"bg": ("#08111f", "#0a2a3a", "#08202c"), "line": "#2f8fa5", "node": "#3fd0d0", "glow": "#26c0c0"},
    "defender-solutions":    {"bg": ("#1a0a10", "#3a121c", "#220a10"), "line": "#a5455a", "node": "#e06a7a", "glow": "#c0392b"},
    "sentinel-solutions":    {"bg": ("#0d0a20", "#241a4a", "#120e2c"), "line": "#6a5fb0", "node": "#9b8ce0", "glow": "#6c5ce0"},
    "azure-solutions":       {"bg": ("#06101f", "#0a2447", "#08182f"), "line": "#3a78c0", "node": "#5aa0e6", "glow": "#0078d4"},
    "backup-dr-solutions":   {"bg": ("#07140f", "#0c3326", "#08231a"), "line": "#3a8f6a", "node": "#4fd0a0", "glow": "#1e8e5a"},
    "security-solutions":    {"bg": ("#130c06", "#3a240c", "#221608"), "line": "#a5783a", "node": "#e0a85a", "glow": "#c98a1b"},
    "infrastructure":        {"bg": ("#0a0f14", "#1c2c38", "#101820"), "line": "#5a7385", "node": "#8fb0c8", "glow": "#5b7a99"},
    "cloud":                 {"bg": ("#06101f", "#0a2447", "#08182f"), "line": "#3a78c0", "node": "#5aa0e6", "glow": "#2f95d6"},
    "memberships":           {"bg": ("#160a26", "#33174f", "#1d0e34"), "line": "#7a5aa5", "node": "#b88ce0", "glow": "#8a5cd0"},
}
DEFAULT_THEME = CATEGORY_THEME["intune-solutions"]

def category_slugify(name):
    return re.sub(r"[^a-z0-9]+", "-", str(name).lower()).strip("-")

def fit_size(text, base, *, min_size, factor):
    """Shrink a title font-size so the line fits within W minus a MARGIN each side.
    factor = average glyph-width / font-size for the (bold) font; conservative to avoid clipping."""
    usable = W - 2 * MARGIN
    est = max(1, len(text)) * base * factor
    if est <= usable:
        return base
    return max(min_size, int(usable / (max(1, len(text)) * factor)))

def gen_motif(rnd, line, node):
    """Seeded circuit motif (lines + nodes) anchored near the top and bottom edges.
    Deterministic per seed so re-running produces the same image; varies between solutions."""
    segs, nodes = [], []
    for _ in range(rnd.randint(4, 6)):
        left = rnd.random() < 0.5
        x = rnd.choice([40, 70, 120]) if left else rnd.choice([1160, 1110, 1060])
        top = rnd.random() < 0.5
        y = rnd.randint(120, 320) if top else rnd.randint(900, 1060)
        dx = rnd.choice([100, 140, 180]) * (1 if left else -1)
        dy = rnd.choice([30, 40, 50]) * (1 if top else -1)
        run = rnd.choice([80, 120, 150])
        segs.append(f'<path d="M{x} {y} H{x+dx} L{x+dx+30} {y+dy} H{x+dx+30+(run if left else -run)}"/>')
        nodes += [(x + dx, y), (x + dx + 30, y + dy)]
    g = '<g stroke="' + line + '" stroke-width="2" opacity="0.16" fill="none">' + "".join(segs) + '</g>'
    g += '<g fill="' + node + '" opacity="0.5">' + "".join(f'<circle cx="{nx}" cy="{ny}" r="5"/>' for nx, ny in nodes) + '</g>'
    return g

# ----------------------------- icon library (centered at 0,0) -----------------------------
def _icon(name):
    s = '<circle r="46" fill="#10294a" stroke="#2f95d6" stroke-width="2.5"/>'
    g = '#5cc24a'; b = '#56b0e6'; w = '#9fc4e6'
    if name == "shield":
        s += (f'<path d="M0 -26 L24 -16 V8 C24 26 13 38 0 44 C-13 38 -24 26 -24 8 V-16 Z" fill="none" stroke="{g}" stroke-width="4"/>'
              f'<path d="M-12 4 L-2 16 L14 -8" fill="none" stroke="{g}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>')
    elif name == "fingerprint":
        s += (f'<g fill="none" stroke="{b}" stroke-width="4" stroke-linecap="round">'
              '<path d="M-22 6 a22 26 0 0 1 44 0"/><path d="M-13 8 a13 17 0 0 1 26 0 v14"/>'
              '<path d="M-4 9 a4 8 0 0 1 8 0 v18"/><path d="M-22 20 v6"/><path d="M22 18 v10"/></g>')
    elif name == "chip":
        s += (f'<rect x="-18" y="-18" width="36" height="36" rx="5" fill="none" stroke="{w}" stroke-width="4"/>'
              f'<g stroke="{w}" stroke-width="4"><path d="M-8 -28 v8 M8 -28 v8 M-8 28 v-8 M8 28 v-8 M-28 -8 h8 M-28 8 h8 M28 -8 h-8 M28 8 h-8"/></g>')
    elif name == "cloud":
        s += f'<path d="M-20 12 a16 16 0 0 1 4 -31 a19 19 0 0 1 36 -4 a15 15 0 0 1 6 35 z" fill="none" stroke="{b}" stroke-width="4"/>'
    elif name == "lock":
        s += (f'<rect x="-18" y="-2" width="36" height="28" rx="5" fill="none" stroke="{w}" stroke-width="4"/>'
              f'<path d="M-10 -2 v-10 a10 10 0 0 1 20 0 v10" fill="none" stroke="{w}" stroke-width="4"/>')
    elif name == "key":
        s += (f'<circle cx="-10" cy="-2" r="12" fill="none" stroke="{w}" stroke-width="4"/>'
              f'<path d="M-1 4 L22 27 M14 19 l6 -6 M20 25 l6 -6" stroke="{w}" stroke-width="4" fill="none"/>')
    elif name == "chart":
        s += f'<g stroke="{g}" stroke-width="5" stroke-linecap="round"><path d="M-22 20 v-8 M-7 20 v-20 M8 20 v-12 M23 20 v-28"/></g>'
    elif name == "gear":
        s += (f'<circle r="10" fill="none" stroke="{w}" stroke-width="4"/>'
              f'<g stroke="{w}" stroke-width="4"><path d="M0 -26 v10 M0 26 v-10 M-26 0 h10 M26 0 h-10 M-18 -18 l7 7 M18 18 l-7 -7 M18 -18 l-7 7 M-18 18 l7 -7"/></g>')
    elif name == "device":
        s += (f'<rect x="-24" y="-18" width="48" height="32" rx="3" fill="none" stroke="{w}" stroke-width="4"/>'
              f'<path d="M-30 22 h60" stroke="{w}" stroke-width="4"/>')
    elif name == "users":
        s += (f'<g fill="none" stroke="{b}" stroke-width="4"><circle cx="-10" cy="-6" r="9"/>'
              '<path d="M-26 22 a16 16 0 0 1 32 0"/><circle cx="16" cy="-2" r="7"/><path d="M8 22 a12 12 0 0 1 24 0"/></g>')
    else:  # check fallback
        s += f'<path d="M-16 0 L-4 14 L18 -14" fill="none" stroke="{g}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>'
    return s

# ----------------------------- SVG builder -----------------------------
def esc(t): return html.escape(str(t), quote=False)

def build_svg(title, category, hero, slug="", branded=False):
    lines = hero.get("title_lines") or [{"text": title, "color": "white", "size": "main"}]
    frm = hero.get("from", {"label": "BEFORE", "items": []})
    to = hero.get("to", {"label": "Microsoft Intune", "stat": ""})
    tagline = hero.get("tagline", "SECURE.  MODERN.  EFFICIENT.")
    benefits = (hero.get("benefits") or [])[:4]

    # category palette (cohesive) + per-solution seed (distinct)
    theme = CATEGORY_THEME.get(category_slugify(category), DEFAULT_THEME)
    seed = int(hashlib.md5((slug or title).encode("utf-8")).hexdigest()[:8], 16)
    rnd = random.Random(seed)
    g0, g1, g2 = theme["bg"]
    glow_cx = rnd.choice([430, 520, 600, 680, 770])
    glow_cy = rnd.choice([480, 540, 600])
    glow_rx = rnd.choice([560, 600, 640]); glow_ry = rnd.choice([320, 360, 400])

    parts = []
    parts.append(f'<svg viewBox="0 0 {W} {W}" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="t d">')
    _desc = (f'Phoenixtekk {esc(category)} marketing banner.' if branded else f'{esc(category)} marketing banner.')
    parts.append(f'<title id="t">{esc(title)} — product hero</title><desc id="d">{_desc}</desc>')
    parts.append('<defs>'
                 f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{g0}"/><stop offset="0.55" stop-color="{g1}"/><stop offset="1" stop-color="{g2}"/></linearGradient>'
                 '<linearGradient id="arrow" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2f9e3a"/><stop offset="1" stop-color="#74d84c"/></linearGradient>'
                 f'<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{theme["glow"]}" stop-opacity="0.33"/><stop offset="1" stop-color="{theme["glow"]}" stop-opacity="0"/></radialGradient>'
                 '</defs>')
    parts.append(f'<rect width="{W}" height="{W}" fill="url(#bg)"/><ellipse cx="{glow_cx}" cy="{glow_cy}" rx="{glow_rx}" ry="{glow_ry}" fill="url(#glow)"/>')
    # seeded circuit motif (cohesive palette, per-solution layout)
    parts.append(gen_motif(rnd, theme["line"], theme["node"]))
    # title — auto-fit each line so it always clears the border by >= MARGIN px
    parts.append('<g text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-weight="800">')
    y = 170
    for ln in lines:
        sub = ln.get("size") == "sub"
        base = 58 if sub else 112
        size = fit_size(esc(ln["text"]), base, min_size=(34 if sub else 46), factor=(0.56 if sub else 0.58))
        color = COLORS.get(ln.get("color", "white"), "#ffffff")
        wt = '700' if sub else '800'
        parts.append(f'<text x="600" y="{y}" font-size="{size}" fill="{color}" font-weight="{wt}">{esc(ln["text"])}</text>')
        y += 77 if sub else 115
    parts.append('</g>')
    # from card
    parts.append('<g font-family="Segoe UI, Arial, sans-serif">'
                 '<rect x="70" y="430" width="370" height="300" rx="18" fill="#ffffff" opacity="0.05"/>'
                 '<rect x="70" y="430" width="370" height="300" rx="18" fill="none" stroke="#1f4a7a" stroke-width="2"/>'
                 f'<text x="255" y="478" text-anchor="middle" font-size="30" font-weight="700" fill="#cfe0f2" letter-spacing="2">{esc(frm.get("label","BEFORE"))}</text>'
                 '<g font-size="26" fill="#d7e3f1">')
    iy = 540
    for item in (frm.get("items") or [])[:4]:
        parts.append(f'<g><circle cx="120" cy="{iy}" r="14" fill="#c0392b"/>'
                     f'<path d="M114 {iy-6} l12 12 M126 {iy-6} l-12 12" stroke="#fff" stroke-width="3"/>'
                     f'<text x="150" y="{iy+9}">{esc(item)}</text></g>')
        iy += 55
    parts.append('</g></g>')
    # arrow
    parts.append('<polygon points="460,545 560,545 560,515 620,580 560,645 560,615 460,615" fill="url(#arrow)"/>')
    # to card
    parts.append('<g font-family="Segoe UI, Arial, sans-serif">'
                 '<rect x="660" y="430" width="470" height="300" rx="18" fill="#ffffff" opacity="0.06"/>'
                 '<rect x="660" y="430" width="470" height="300" rx="18" fill="none" stroke="#2f95d6" stroke-width="2"/>'
                 '<g transform="translate(700,470)"><path d="M14 34 a22 22 0 0 1 6 -43 a26 26 0 0 1 49 -6 a20 20 0 0 1 8 49 z" fill="#eaf3fc"/></g>'
                 f'<text x="800" y="500" font-size="30" font-weight="700" fill="#ffffff">{esc(to.get("label","Microsoft Intune"))}</text>'
                 '<g transform="translate(820,540)"><path d="M75 6 L130 26 V70 C130 110 105 138 75 150 C45 138 20 110 20 70 V26 Z" fill="#13355c" stroke="#54c14a" stroke-width="4"/>'
                 '<path d="M50 78 L70 100 L104 56" fill="none" stroke="#5cc24a" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/></g>'
                 f'<text x="690" y="700" font-size="27" font-weight="700" fill="#9fe39a">{esc(to.get("stat",""))}</text></g>')
    # tagline
    parts.append(f'<text x="600" y="800" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="34" font-weight="800" fill="#9fc4e6" letter-spacing="8">{esc(tagline)}</text>')
    # benefit tiles
    xs = [165, 455, 745, 1035]
    parts.append('<g font-family="Segoe UI, Arial, sans-serif" text-anchor="middle">')
    for i, bn in enumerate(benefits):
        parts.append(f'<g transform="translate({xs[i]},905)">{_icon(bn.get("icon","check"))}</g>')
    parts.append('<g font-size="29" font-weight="700" fill="#ffffff">')
    for i, bn in enumerate(benefits):
        parts.append(f'<text x="{xs[i]}" y="995">{esc(bn.get("title",""))}</text>')
    parts.append('</g><g font-size="23" fill="#9fb6cf">')
    for i, bn in enumerate(benefits):
        parts.append(f'<text x="{xs[i]}" y="1030">{esc(bn.get("sub",""))}</text>')
    parts.append('</g></g>')
    # footer — company name/URL only when branded; white-label shows the category alone
    footer_txt = (f'PHOENIXTEKK&#160;&#160;·&#160;&#160;{esc(category)}&#160;&#160;·&#160;&#160;workplace.phoenixtekk.com'
                  if branded else f'{esc(category)}')
    parts.append('<line x1="120" y1="1105" x2="1080" y2="1105" stroke="#1f4a7a" stroke-width="2"/>'
                 f'<text x="600" y="1150" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="26" font-weight="700" fill="#7f9cba" letter-spacing="1">{footer_txt}</text>')
    parts.append('</svg>')
    return "\n".join(parts)

# ----------------------------- PNG render via headless Edge/Chrome -----------------------------
def find_browser():
    pf = os.environ.get("ProgramFiles", r"C:\Program Files")
    pf86 = os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")
    for p in [rf"{pf}\Microsoft\Edge\Application\msedge.exe",
              rf"{pf86}\Microsoft\Edge\Application\msedge.exe",
              rf"{pf}\Google\Chrome\Application\chrome.exe",
              rf"{pf86}\Google\Chrome\Application\chrome.exe"]:
        if os.path.exists(p):
            return p
    return None

def render_png(svg_path, png_path, size=W):
    browser = find_browser()
    if not browser:
        print("WARN: no Edge/Chrome found — PNG not rendered (SVG written). Install a Chromium browser or render manually.", file=sys.stderr)
        return False
    svg = pathlib.Path(svg_path).read_text(encoding="utf-8")
    # wrapper lives beside the output; a fresh --user-data-dir forces a standalone headless
    # instance so it doesn't hand off to a running Edge/Chrome (which renders an error page).
    wrap = pathlib.Path(png_path).parent / "_hero_wrap.html"
    wrap.write_text(f"<!doctype html><html><head><meta charset='utf-8'>"
                    f"<style>html,body{{margin:0;padding:0;width:{size}px;height:{size}px}}svg{{display:block;width:{size}px;height:{size}px}}</style>"
                    f"</head><body>{svg}</body></html>", encoding="utf-8")
    uri = wrap.as_uri()
    profile = tempfile.mkdtemp(prefix="phoenix_hero_")
    if os.path.exists(png_path):
        try: os.remove(png_path)
        except OSError: pass
    import time, shutil
    try:
        # classic --headless is synchronous for --screenshot (no child-process fork race).
        subprocess.run([browser, "--headless", "--disable-gpu", "--hide-scrollbars",
                        "--no-first-run", "--no-default-browser-check", f"--user-data-dir={profile}",
                        "--force-device-scale-factor=1", f"--window-size={size},{size}",
                        "--virtual-time-budget=3000", f"--screenshot={png_path}", uri],
                       check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=90)
        # keep the wrapper readable until the PNG actually lands (covers any async fork)
        for _ in range(30):
            if os.path.exists(png_path) and os.path.getsize(png_path) > 0:
                break
            time.sleep(0.3)
    finally:
        try: wrap.unlink()
        except OSError: pass
        shutil.rmtree(profile, ignore_errors=True)
    return os.path.exists(png_path)

# ----------------------------- main -----------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solution-dir", required=True)
    ap.add_argument("--brand", dest="brand", action="store_true", default=None,
                    help="force company branding ON (overrides solution.meta.json 'branding')")
    ap.add_argument("--no-brand", dest="brand", action="store_false",
                    help="force company branding OFF / white-label (overrides solution.meta.json)")
    args = ap.parse_args()
    vdir = pathlib.Path(args.solution_dir).resolve()
    meta = json.loads((vdir / "solution.meta.json").read_text(encoding="utf-8"))
    sol, title, cat = meta["sol_code"], meta["title"], meta["category"]
    branded = args.brand if args.brand is not None else \
        str(meta.get("branding", "off")).strip().lower() in ("on", "branded", "yes", "true", "1")

    hero_spec = vdir / "listing" / "hero.json"
    if hero_spec.exists():
        hero = json.loads(hero_spec.read_text(encoding="utf-8"))
    else:
        # minimal default: title on one line, generic benefits
        hero = {"title_lines": [{"text": title, "color": "white", "size": "main"}],
                "from": {"label": "BEFORE", "items": []},
                "to": {"label": "Microsoft Intune", "stat": ""},
                "tagline": "SECURE.  MODERN.  EFFICIENT.", "benefits": []}
        print("NOTE: no listing/hero.json — using minimal default (author hero.json for full design).", file=sys.stderr)

    deliv = vdir / "deliverables"; deliv.mkdir(exist_ok=True)
    svg_path = deliv / f"{sol}-hero.svg"
    png_path = deliv / f"{sol}-hero.png"
    svg_path.write_text(build_svg(title, cat, hero, slug=meta.get("slug", ""), branded=branded), encoding="utf-8")
    ok = render_png(str(svg_path), str(png_path))
    print(f"  {svg_path.name}  {svg_path.stat().st_size:,} bytes")
    if ok:
        print(f"  {png_path.name}  {png_path.stat().st_size:,} bytes")
    print("Hero built." if ok else "Hero SVG built (PNG render skipped).")


if __name__ == "__main__":
    main()
