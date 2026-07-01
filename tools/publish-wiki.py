#!/usr/bin/env python3
"""
publish-wiki.py — Phoenixtekk Workplace Marketplace factory: publish a solution's
documentation to the self-hosted Wiki.js at docs.phoenixtekk.com.

Renders the solution's source markdown (the same SOURCE_ORDER the deliverables compiler uses)
into a single Wiki.js page at  solutions/<category_slug>/<slug>  and creates or updates it
through the Wiki.js GraphQL API. The page is the "living, always-current" copy of the guide;
gating (who may read it) and update alerts are handled by the sync/alert tooling (#3/#4).

Auth & target come from the environment (never committed):
  WIKIJS_URL    e.g. https://docs.phoenixtekk.com
  WIKIJS_TOKEN  a Wiki.js API token with page read/write (Administration -> API Access)

Usage:
  # local preview — no network, no token needed:
  python tools/publish-wiki.py --solution-dir "library/intune-solutions/<slug>/v1.0.0" --dry-run
  # live (reads WIKIJS_URL / WIKIJS_TOKEN):
  python tools/publish-wiki.py --solution-dir "library/intune-solutions/<slug>/v1.0.0"
  # live + leave the page as an unpublished draft (override the default):
  python tools/publish-wiki.py --solution-dir "library/.../v1.0.0" --draft

Default: pages are PUBLISHED (isPublished=true) so docs are live on the wiki. Gate who can read
them with the #3 group access rules (deny Guests/Public Users on solutions/**); a published but
ungated page is publicly readable. Use --draft to stage a page without publishing it.
"""
import argparse, json, os, sys, glob
from pathlib import Path
from urllib import request as urlrequest, error as urlerror

SOURCE_ORDER = [
    "executive-summary.md",
    "01-solution-overview.md",
    "02-requirements.md",
    "__global__",            # resolved to source/global-requirements-<category_slug>.md
    "03-implementation.md",
    "05-testing.md",
    "06-troubleshooting.md",
    "07-best-practices.md",
    "08-deliverables-summary.md",
]


def load_meta(sol_dir: Path) -> dict:
    meta = json.loads((sol_dir / "solution.meta.json").read_text(encoding="utf-8"))
    for k in ("slug", "title", "category_slug", "version"):
        if not meta.get(k):
            sys.exit(f"solution.meta.json missing required field: {k}")
    return meta


def render_markdown(sol_dir: Path, meta: dict) -> str:
    src = sol_dir / "source"
    parts = [f"# {meta['title']}\n",
             f"> **Version {meta['version']}** · Category: {meta.get('category','')} · "
             f"Solution code: {meta.get('sol_code','')}\n",
             "> This is the online, maintained copy of the implementation guide. When this "
             "solution is updated, eligible customers are alerted and can return here for the "
             "current content. Downloadable PDF + scripts are attached on the store listing.\n"]
    for name in SOURCE_ORDER:
        if name == "__global__":
            hits = sorted(glob.glob(str(src / "global-requirements-*.md")))
            files = [Path(hits[0])] if hits else []
        else:
            f = src / name
            files = [f] if f.exists() else []
        for f in files:
            parts.append("\n\n---\n\n")
            parts.append(f.read_text(encoding="utf-8").strip())
    return "\n".join(parts).strip() + "\n"


def load_wiki_env():
    """Populate WIKIJS_URL/WIKIJS_TOKEN from ./.wikijs.env or ~/.claude/.wikijs.env if not set."""
    if os.environ.get("WIKIJS_URL") and os.environ.get("WIKIJS_TOKEN"):
        return
    for f in (Path.cwd() / ".wikijs.env", Path.home() / ".claude" / ".wikijs.env"):
        if f.is_file():
            for line in f.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    k = k.strip().removeprefix("export ").strip()
                    if k in ("WIKIJS_URL", "WIKIJS_TOKEN") and not os.environ.get(k):
                        os.environ[k] = v.strip().strip('"').strip("'")
        if os.environ.get("WIKIJS_URL") and os.environ.get("WIKIJS_TOKEN"):
            return


def gql(url: str, token: str, query: str, variables: dict, tolerate=None):
    """Run a GraphQL op. If every returned error's code is in `tolerate`, return None
    instead of exiting (used so a missing page on lookup means 'create', not 'abort')."""
    body = json.dumps({"query": query, "variables": variables}).encode("utf-8")
    req = urlrequest.Request(url.rstrip("/") + "/graphql", data=body, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {token}")
    # Cloudflare fronts docs.phoenixtekk.com and blocks the default urllib UA (error 1010).
    req.add_header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                                 "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36")
    try:
        with urlrequest.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urlerror.HTTPError as e:
        sys.exit(f"Wiki.js HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:500]}")
    except urlerror.URLError as e:
        sys.exit(f"Wiki.js connection error: {e}")
    if data.get("errors"):
        tolerate = tolerate or set()
        codes = {(err.get("extensions") or {}).get("code") for err in data["errors"]}
        if codes and codes <= tolerate:
            return None
        sys.exit("Wiki.js GraphQL errors: " + json.dumps(data["errors"])[:800])
    return data["data"]


FIND_QUERY = """
query ($path: String!, $locale: String!) {
  pages { singleByPath(path: $path, locale: $locale) { id path title isPublished } }
}"""

CREATE_MUTATION = """
mutation ($content:String!,$description:String!,$path:String!,$title:String!,$tags:[String]!,$isPublished:Boolean!) {
  pages { create(content:$content, description:$description, editor:"markdown", isPublished:$isPublished,
    isPrivate:false, locale:"en", path:$path, tags:$tags, title:$title) {
    responseResult { succeeded errorCode message } page { id path } } }
}"""

UPDATE_MUTATION = """
mutation ($id:Int!,$content:String!,$description:String!,$title:String!,$tags:[String]!,$isPublished:Boolean!) {
  pages { update(id:$id, content:$content, description:$description, editor:"markdown",
    isPublished:$isPublished, isPrivate:false, locale:"en", tags:$tags, title:$title) {
    responseResult { succeeded errorCode message } page { id path } } }
}"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solution-dir", required=True)
    ap.add_argument("--dry-run", action="store_true", help="render + print, no network")
    ap.add_argument("--draft", action="store_true",
                    help="publish as an unpublished draft (default: published/live)")
    ap.add_argument("--path-prefix", default="solutions", help="Wiki.js base path (default 'solutions')")
    args = ap.parse_args()

    sol_dir = Path(args.solution_dir)
    meta = load_meta(sol_dir)
    content = render_markdown(sol_dir, meta)
    path = f"{args.path_prefix.strip('/')}/{meta['category_slug']}/{meta['slug']}"
    title = meta["title"]
    # Honor the branding toggle (default OFF / white-label): no company name in the page description.
    _branded = str(meta.get("branding", "off")).strip().lower() in ("on", "branded", "yes", "true", "1")
    description = (f"Phoenixtekk solution guide — {title} (v{meta['version']})" if _branded
                  else f"Solution guide — {title} (v{meta['version']})")
    tags = ["solution", meta["category_slug"], meta["slug"], f"v{meta['version']}"]
    is_published = not args.draft

    print(f"Wiki.js target path : {path}")
    print(f"Title               : {title}")
    print(f"Tags                : {', '.join(tags)}")
    print(f"isPublished         : {is_published}  ({'published/live' if is_published else 'draft (--draft)'})")
    print(f"Content length      : {len(content):,} chars")

    if args.dry_run:
        out = sol_dir / "deliverables" / f"{meta.get('sol_code','SOL')}-wiki.md"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(content, encoding="utf-8")
        print(f"DRY-RUN: wrote rendered page to {out} (no network call).")
        return

    load_wiki_env()  # auto-load ./.wikijs.env or ~/.claude/.wikijs.env if not already set
    url, token = os.environ.get("WIKIJS_URL"), os.environ.get("WIKIJS_TOKEN")
    if not url or not token:
        sys.exit("Set WIKIJS_URL and WIKIJS_TOKEN (or create ~/.claude/.wikijs.env), "
                 "or use --dry-run.")

    found = gql(url, token, FIND_QUERY, {"path": path, "locale": "en"}, tolerate={6003, "INTERNAL_SERVER_ERROR"})
    existing = found["pages"]["singleByPath"] if found else None
    if existing and existing.get("id"):
        data = gql(url, token, UPDATE_MUTATION, {
            "id": int(existing["id"]), "content": content, "description": description,
            "title": title, "tags": tags, "isPublished": is_published})
        rr = data["pages"]["update"]["responseResult"]
        action = "UPDATE"
    else:
        data = gql(url, token, CREATE_MUTATION, {
            "content": content, "description": description, "path": path,
            "title": title, "tags": tags, "isPublished": is_published})
        rr = data["pages"]["create"]["responseResult"]
        action = "CREATE"

    if not rr.get("succeeded"):
        sys.exit(f"{action} failed: {rr.get('errorCode')} {rr.get('message')}")
    print(f"{action} OK — {url.rstrip('/')}/{path}")

    # Record the exact published content as the learning baseline (clean, account-free attribution:
    # the daily learning loop compares future wiki content against THIS, so only the owner's
    # validation edits surface — see CLAUDE.md §6).
    try:
        base_dir = Path(__file__).resolve().parent.parent / "library" / "_index" / "wiki-baselines"
        base_dir.mkdir(parents=True, exist_ok=True)
        (base_dir / f"{meta['slug']}.md").write_text(content, encoding="utf-8")
    except Exception as e:
        print(f"(warning: could not write learning baseline: {e})")


if __name__ == "__main__":
    main()
