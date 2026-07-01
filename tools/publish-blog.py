#!/usr/bin/env python3
"""
publish-blog.py — publish (or draft) one solution's blog post to the phoenixtekk.com WordPress
blog on linuxg2, with the product hero as the WordPress featured image.

IDEMPOTENT: dedupes by the post meta `ptk_slug` (== solution slug). If a post already exists for
the slug it is UPDATED (content + featured image re-ensured); otherwise a new post is created.
Safe default status = draft (review before public). Category 411 = "Product Updates".

Runs from the repo (Windows/git-bash) over ssh/scp to linuxg2. WordPress there runs Object Cache
Pro (needs WP_REDIS_DISABLED=true in CLI); site user tekkcomadmin; docroot
/var/www/vhosts/phoenixtekk.com/httpdocs.

Usage:
  python tools/publish-blog.py --slug <solution-slug> [--status draft|publish] [--host linuxg2]
The slug is resolved from library/_index/registry.json (title, category, sol_code, rel_path);
blog body is built from the solution's commercial listing description + pricing + a store CTA.
Records the result in library/_index/blog-posts.json.
"""
import argparse, json, os, re, html, subprocess, tempfile, base64
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCROOT = "/var/www/vhosts/phoenixtekk.com/httpdocs"
CAT = "411"
STORE = "https://workplace.phoenixtekk.com/"


def sh(*args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def strip_tags(s):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", s or "")).strip()


def money(n):
    return "${:,.2f}".format(float(n))


def build_body(rec, listing):
    prods = {p["audience"]: p for p in listing["products"]}
    comm = prods.get("commercial") or listing["products"][0]
    npo, gov = prods.get("nonprofit"), prods.get("government")
    excerpt = strip_tags(comm.get("short_description", ""))[:300]
    store = STORE + rec["slug"] + "-commercial"
    price = ("<p><strong>Pricing:</strong> Commercial " + money(comm["price"])
             + (" &middot; Non-Profit " + money(npo["price"]) if npo else "")
             + (" &middot; Government " + money(gov["price"]) if gov else "") + "</p>")
    body = ("<p><em>" + html.escape(excerpt) + "</em></p>" + comm["description"] + price
            + '<p><a class="button" href="' + store + '" target="_blank" rel="noopener">'
            + 'View this solution &rarr;</a></p>')
    return body, excerpt


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--slug", required=True)
    ap.add_argument("--status", default="draft", choices=["draft", "publish"])
    ap.add_argument("--host", default="linuxg2")
    args = ap.parse_args()

    reg = json.loads((ROOT / "library/_index/registry.json").read_text(encoding="utf-8"))
    rec = next((r for r in reg if r["slug"] == args.slug), None)
    if not rec:
        raise SystemExit(f"slug not in registry: {args.slug}")
    rel = rec["rel_path"].replace("\\", "/")
    listing = json.loads((ROOT / rel / "listing" / "bagisto-products.json").read_text(encoding="utf-8"))
    body, excerpt = build_body(rec, listing)
    hero = ROOT / rel / "deliverables" / (rec["sol_code"] + "-hero.png")
    title = rec["title"]
    tags = rec["category"] + ",solution,Microsoft"

    # stage temp files, scp to linuxg2
    tmp = Path(tempfile.mkdtemp())
    (tmp / "post.html").write_text(body, encoding="utf-8")
    for f in ("post.html",):
        sh("scp", "-q", str(tmp / f), f"{args.host}:/tmp/ptkblog_{args.slug}.html")
    has_img = hero.exists()
    if has_img:
        sh("scp", "-q", str(hero), f"{args.host}:/tmp/ptkblog_{args.slug}.png")

    b64_title = base64.b64encode(title.encode()).decode()
    b64_excerpt = base64.b64encode(excerpt.encode()).decode()
    b64_tags = base64.b64encode(tags.encode()).decode()

    remote = f"""
set -e
DOCROOT={DOCROOT}
WP(){{ sudo -u tekkcomadmin env WP_REDIS_DISABLED=true wp --path="$DOCROOT" "$@"; }}
SLUG='{args.slug}'; STATUS='{args.status}'; CAT={CAT}; HTML=/tmp/ptkblog_{args.slug}.html; PNG=/tmp/ptkblog_{args.slug}.png
TITLE=$(echo '{b64_title}' | base64 -d); EXCERPT=$(echo '{b64_excerpt}' | base64 -d); TAGS=$(echo '{b64_tags}' | base64 -d)
chmod a+r "$HTML" "$PNG" 2>/dev/null || true
ID=$(WP post list --category=$CAT --post_status=any --meta_key=ptk_slug --meta_value="$SLUG" --field=ID --format=ids 2>/dev/null | awk '{{print $1}}')
if [ -n "$ID" ]; then
  WP post update "$ID" "$HTML" --post_title="$TITLE" --post_status="$STATUS" --post_excerpt="$EXCERPT" >/dev/null
  ACTION=updated
else
  ID=$(WP post create "$HTML" --post_title="$TITLE" --post_status="$STATUS" --post_author=1 --post_category=$CAT --tags_input="$TAGS" --post_excerpt="$EXCERPT" --porcelain)
  WP post meta update "$ID" ptk_slug "$SLUG" >/dev/null 2>&1 || true
  ACTION=created
fi
if [ -f "$PNG" ]; then
  TH=$(WP post meta get "$ID" _thumbnail_id 2>/dev/null || true)
  if [ -z "$TH" ] || [ "$TH" = "0" ]; then WP media import "$PNG" --post_id="$ID" --featured_image --porcelain >/dev/null 2>&1 || true; fi
fi
rm -f "$HTML" "$PNG"
echo "BLOG action=$ACTION id=$ID status=$STATUS slug=$SLUG"
"""
    # write the remote script with LF endings and scp it (avoids Windows CRLF-over-ssh breakage)
    runsh = tmp / "run.sh"
    runsh.write_bytes(remote.replace("\r\n", "\n").encode("utf-8"))
    sh("scp", "-q", str(runsh), f"{args.host}:/tmp/ptkblog_run_{args.slug}.sh")
    r = sh("ssh", args.host, f"bash /tmp/ptkblog_run_{args.slug}.sh; rm -f /tmp/ptkblog_run_{args.slug}.sh")
    out = (r.stdout or "") + (r.stderr or "")
    line = next((l for l in out.splitlines() if l.startswith("BLOG ")), None)
    print(line or out.strip()[-400:])
    if line:
        pid = int(re.search(r"id=(\d+)", line).group(1))
        lp = ROOT / "library/_index/blog-posts.json"
        led = json.loads(lp.read_text(encoding="utf-8")) if lp.exists() else {}
        led[args.slug] = {"post_id": pid, "status": args.status, "category_id": int(CAT)}
        lp.write_text(json.dumps(led, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
