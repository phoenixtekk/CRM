#!/usr/bin/env python3
"""
build-support-heroes.py — product images for the 3 paid SUPPORT add-on products.

DELIBERATELY DISTINCT from the solution hero images (tools/build-hero.py): the solution
heroes are dark navy "tech circuit + from→to transformation" banners. These support images
use a LIGHT, warm "services" language — a soft card, a big friendly emblem per tier, the
price, and the terms — so a shopper instantly reads them as human support, not a technical
product. Each tier also has its own accent color + emblem so the three are distinct from
each other too.

Renders each bespoke SVG to a 1200x1200 PNG via headless Edge/Chrome (same method as
build-hero.py, no native libs).

Output: support/deliverables/<key>-support.svg + <key>-support.png
Usage:  python support/build-support-heroes.py
"""
import html, os, pathlib, subprocess, sys, tempfile, time, shutil

W = 1200
HERE = pathlib.Path(__file__).resolve().parent
DELIV = HERE / "deliverables"; DELIV.mkdir(exist_ok=True)


def esc(t): return html.escape(str(t), quote=False)


# Each tier: accent color family, emblem glyph, title lines, big price, terms, 3 feature ticks.
TIERS = [
    {
        "key": "chat30", "sku": "PTK-SUPPORT-CHAT30-001",
        "accent": "#12a594", "accent2": "#0d8276", "wash": "#e6f7f4", "badge": "CHAT SUPPORT",
        "emblem": "chat",
        "title": [("30-Day Chat", 96), ("Support", 96)],
        "price": "$500", "terms": "30 days · your preferred messaging app",
        "ticks": ["SMS · WhatsApp · Teams", "Slack · Telegram · Web", "Unblock your rollout"],
    },
    {
        "key": "call60", "sku": "PTK-SUPPORT-CALL60-001",
        "accent": "#2f6fe0", "accent2": "#1e50b0", "wash": "#e7effc", "badge": "LIVE CALL",
        "emblem": "call",
        "title": [("Live Implementation", 70), ("Call · 60 min", 88)],
        "price": "$200", "terms": "per hour · one scheduled session",
        "ticks": ["1-on-1 with an engineer", "Plan or troubleshoot", "Book a time that suits you"],
    },
    {
        "key": "priority", "sku": "PTK-SUPPORT-PRIORITY-001",
        "accent": "#e08a1e", "accent2": "#b86a10", "wash": "#fdf1de", "badge": "PRIORITY",
        "emblem": "star",
        "title": [("Priority", 104), ("Implementation Support", 60)],
        "price": "$1,000", "terms": "per week · up to 3 working meetings",
        "ticks": ["Front-of-queue response", "3 meetings / week", "Hands-on guidance"],
    },
]


def emblem(name, accent):
    """A large white glyph on an accent disc, centered at (0,0). Distinct per tier."""
    s = f'<circle r="150" fill="{accent}"/><circle r="150" fill="none" stroke="#ffffff" stroke-width="6" opacity="0.35"/>'
    w = "#ffffff"
    if name == "chat":
        # two overlapping speech bubbles + typing dots
        s += (f'<g fill="{w}">'
              f'<path d="M-118 -70 h150 a26 26 0 0 1 26 26 v72 a26 26 0 0 1 -26 26 h-96 l-40 34 v-34 h-14 a26 26 0 0 1 -26 -26 v-72 a26 26 0 0 1 26 -26 z"/>'
              f'</g>'
              f'<g fill="{accent}"><circle cx="-58" cy="-8" r="9"/><circle cx="-20" cy="-8" r="9"/><circle cx="18" cy="-8" r="9"/></g>'
              f'<path d="M40 20 h96 a24 24 0 0 1 24 24 v58 a24 24 0 0 1 -24 24 h-70 l-34 28 v-28 h8 a1 1 0 0 1 0 0" '
              f'fill="{w}" opacity="0.55"/>')
    elif name == "call":
        # headset (arc + ear cups) with a small clock badge
        s += (f'<g fill="none" stroke="{w}" stroke-width="16" stroke-linecap="round">'
              f'<path d="M-92 6 a92 92 0 0 1 184 0"/></g>'
              f'<g fill="{w}"><rect x="-112" y="0" width="44" height="78" rx="18"/>'
              f'<rect x="68" y="0" width="44" height="78" rx="18"/></g>'
              # mic boom
              f'<path d="M90 78 q0 46 -46 52" fill="none" stroke="{w}" stroke-width="12" stroke-linecap="round"/>'
              # clock badge
              f'<circle cx="46" cy="120" r="40" fill="{w}"/>'
              f'<g stroke="{accent}" stroke-width="8" stroke-linecap="round"><path d="M46 120 v-22 M46 120 l16 12"/></g>')
    else:  # star — priority
        s += (f'<path d="M0 -118 L34 -38 L120 -30 L56 26 L74 112 L0 68 L-74 112 L-56 26 L-120 -30 L-34 -38 Z" '
              f'fill="{w}"/>'
              f'<path d="M0 -70 L20 -22 L72 -18 L34 14 L46 66 L0 40 L-46 66 L-34 14 L-72 -18 L-20 -22 Z" '
              f'fill="{accent}"/>')
    return s


def build_svg(t):
    a, a2, wash = t["accent"], t["accent2"], t["wash"]
    p = []
    p.append(f'<svg viewBox="0 0 {W} {W}" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="ti de">')
    p.append(f'<title id="ti">{esc(t["title"][0][0])} — support product image</title>'
             f'<desc id="de">Phoenixtekk Support &amp; Services product image.</desc>')
    p.append('<defs>'
             f'<linearGradient id="bg" x1="0" y1="0" x2="0.4" y2="1">'
             f'<stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="{wash}"/></linearGradient>'
             f'<linearGradient id="acc" x1="0" y1="0" x2="1" y2="1">'
             f'<stop offset="0" stop-color="{a}"/><stop offset="1" stop-color="{a2}"/></linearGradient>'
             '</defs>')
    # light card background + warm accent blobs (top-right, bottom-left) — NOT the dark tech look
    p.append(f'<rect width="{W}" height="{W}" fill="url(#bg)"/>')
    p.append(f'<circle cx="1200" cy="0" r="360" fill="{a}" opacity="0.10"/>'
             f'<circle cx="0" cy="1200" r="420" fill="{a}" opacity="0.08"/>')
    # inner rounded panel border for a "card" feel
    p.append(f'<rect x="40" y="40" width="1120" height="1120" rx="48" fill="none" stroke="{a}" stroke-width="3" opacity="0.30"/>')
    # top badge pill
    bw = 34 + len(t["badge"]) * 17
    p.append(f'<g font-family="Segoe UI, Arial, sans-serif">'
             f'<rect x="{600-bw//2}" y="96" width="{bw}" height="54" rx="27" fill="url(#acc)"/>'
             f'<text x="600" y="132" text-anchor="middle" font-size="26" font-weight="800" '
             f'fill="#ffffff" letter-spacing="3">{esc(t["badge"])}</text></g>')
    # emblem
    p.append(f'<g transform="translate(600,340)">{emblem(t["emblem"], a)}</g>')
    # title (dark ink, friendly) — FIXED anchors so price/terms/ticks never collide.
    # Two lines, bottom-anchored so the last baseline sits at y=770 regardless of font sizes.
    GAP = 16
    (t1, s1), (t2, s2) = t["title"][0], t["title"][1]
    y2 = 770                       # second-line baseline (fixed)
    y1 = y2 - s2 - GAP             # first-line baseline stacks above it
    p.append('<g font-family="Segoe UI, Arial, sans-serif" text-anchor="middle" fill="#1f2a37" font-weight="800">')
    p.append(f'<text x="600" y="{y1}" font-size="{s1}">{esc(t1)}</text>')
    p.append(f'<text x="600" y="{y2}" font-size="{s2}">{esc(t2)}</text>')
    p.append('</g>')
    # big price + terms — FIXED positions, clear of the title above and the ticks below
    p.append(f'<text x="600" y="900" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" '
             f'font-size="132" font-weight="800" fill="{a}">{esc(t["price"])}</text>')
    p.append(f'<text x="600" y="948" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" '
             f'font-size="32" font-weight="600" fill="#5a6b7b">{esc(t["terms"])}</text>')
    # three feature ticks in a row (fixed band, well below the terms line)
    xs = [300, 600, 900]
    p.append('<g font-family="Segoe UI, Arial, sans-serif" text-anchor="middle">')
    for i, tick in enumerate(t["ticks"]):
        cx = xs[i]
        p.append(f'<g transform="translate({cx},1024)">'
                 f'<circle r="26" fill="{wash}" stroke="{a}" stroke-width="3"/>'
                 f'<path d="M-11 0 L-3 9 L12 -9" fill="none" stroke="{a}" stroke-width="6" '
                 f'stroke-linecap="round" stroke-linejoin="round"/></g>')
        p.append(f'<text x="{cx}" y="1082" font-size="24" font-weight="600" fill="#3d4b59">{esc(tick)}</text>')
    p.append('</g>')
    # footer — this IS a branded service product (Phoenixtekk Support), so name it
    p.append(f'<line x1="120" y1="1112" x2="1080" y2="1112" stroke="{a}" stroke-width="2" opacity="0.4"/>'
             f'<text x="600" y="1152" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" '
             f'font-size="26" font-weight="700" fill="{a2}" letter-spacing="2">'
             f'PHOENIXTEKK&#160;&#160;·&#160;&#160;SUPPORT &amp; SERVICES</text>')
    p.append('</svg>')
    return "\n".join(p)


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
        print("WARN: no Edge/Chrome found — PNG not rendered (SVG written).", file=sys.stderr)
        return False
    svg = pathlib.Path(svg_path).read_text(encoding="utf-8")
    wrap = pathlib.Path(png_path).parent / "_sup_wrap.html"
    wrap.write_text(f"<!doctype html><html><head><meta charset='utf-8'>"
                    f"<style>html,body{{margin:0;padding:0;width:{size}px;height:{size}px}}"
                    f"svg{{display:block;width:{size}px;height:{size}px}}</style>"
                    f"</head><body>{svg}</body></html>", encoding="utf-8")
    uri = wrap.as_uri()
    profile = tempfile.mkdtemp(prefix="phoenix_sup_")
    if os.path.exists(png_path):
        try: os.remove(png_path)
        except OSError: pass
    try:
        subprocess.run([browser, "--headless", "--disable-gpu", "--hide-scrollbars",
                        "--no-first-run", "--no-default-browser-check", f"--user-data-dir={profile}",
                        "--force-device-scale-factor=1", f"--window-size={size},{size}",
                        "--virtual-time-budget=3000", f"--screenshot={png_path}", uri],
                       check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=90)
        for _ in range(30):
            if os.path.exists(png_path) and os.path.getsize(png_path) > 0:
                break
            time.sleep(0.3)
    finally:
        try: wrap.unlink()
        except OSError: pass
        shutil.rmtree(profile, ignore_errors=True)
    return os.path.exists(png_path)


def main():
    for t in TIERS:
        svg_path = DELIV / f"{t['key']}-support.svg"
        png_path = DELIV / f"{t['key']}-support.png"
        svg_path.write_text(build_svg(t), encoding="utf-8")
        ok = render_png(str(svg_path), str(png_path))
        size = png_path.stat().st_size if ok else 0
        print(f"  {t['sku']:26} {svg_path.name:22} PNG={'ok' if ok else 'SKIPPED'} ({size:,} bytes)")


if __name__ == "__main__":
    main()
