#!/usr/bin/env python3
"""
publish-wiki-page.py — publish ANY single Markdown file to the self-hosted Wiki.js
(docs.phoenixtekk.com) at an arbitrary path. General-purpose companion to publish-wiki.py
(which is solution-specific). Use this to satisfy the global "mirror all durable docs to the
Wiki.js KB" rule from any repo/session.

Auth & target come from the environment (never commit these):
  WIKIJS_URL    e.g. https://docs.phoenixtekk.com
  WIKIJS_TOKEN  a Wiki.js API token with page read/write (Administration -> API Access)
Load from the gitignored env file before running:
  set -a; . ./.wikijs.env; set +a     (or /home/workplace/.wikijs.env on linuxg5)

Usage:
  python tools/publish-wiki-page.py --file PATH --path SECTION/slug --title "Human Title" \
         [--tags a,b,c] [--description "one-liner"] [--dry-run] [--draft]

Notes:
- Page path = wiki URL path (no extension, no leading/trailing slash). Match the existing
  taxonomy/casing (e.g. SystemDocs/, runbooks/, solutions/, security/).
- Pages are PUBLISHED by default; gate who can read them with the group access rules
  (Guests denied on internal sections like SystemDocs/). --draft stages without publishing.
- Idempotent: creates the page if absent, updates it if present (never duplicates).
- Do NOT publish secrets (tokens, credentials, private keys).
"""
import argparse, json, os, sys
from pathlib import Path
from urllib import request as urlrequest, error as urlerror

BROWSER_UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

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


def load_wiki_env():
    """Populate WIKIJS_URL / WIKIJS_TOKEN from env, else from a .wikijs.env file.
    Search order: current env -> ./.wikijs.env (repo-local) -> ~/.claude/.wikijs.env (global).
    Lets this tool run from ANY repo without manually sourcing the env."""
    if os.environ.get("WIKIJS_URL") and os.environ.get("WIKIJS_TOKEN"):
        return
    candidates = [Path.cwd() / ".wikijs.env", Path.home() / ".claude" / ".wikijs.env"]
    for f in candidates:
        if not f.is_file():
            continue
        for line in f.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip().removeprefix("export ").strip()
            v = v.strip().strip('"').strip("'")
            if k in ("WIKIJS_URL", "WIKIJS_TOKEN") and not os.environ.get(k):
                os.environ[k] = v
        if os.environ.get("WIKIJS_URL") and os.environ.get("WIKIJS_TOKEN"):
            return


def gql(url, token, query, variables, tolerate=None):
    body = json.dumps({"query": query, "variables": variables}).encode("utf-8")
    req = urlrequest.Request(url.rstrip("/") + "/graphql", data=body, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("User-Agent", BROWSER_UA)  # Cloudflare blocks the default urllib UA (1010)
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", required=True, help="path to the Markdown file to publish")
    ap.add_argument("--path", required=True, help="Wiki.js page path, e.g. SystemDocs/my-doc")
    ap.add_argument("--title", required=True)
    ap.add_argument("--tags", default="", help="comma-separated")
    ap.add_argument("--description", default="")
    ap.add_argument("--dry-run", action="store_true", help="print, no network")
    ap.add_argument("--draft", action="store_true", help="publish as unpublished draft")
    args = ap.parse_args()

    content = Path(args.file).read_text(encoding="utf-8")
    path = args.path.strip("/")
    tags = [t.strip() for t in args.tags.split(",") if t.strip()]
    desc = args.description or f"{args.title}"
    is_published = not args.draft

    print(f"Wiki.js target path : {path}")
    print(f"Title               : {args.title}")
    print(f"Tags                : {', '.join(tags) or '(none)'}")
    print(f"isPublished         : {is_published}")
    print(f"Content length      : {len(content):,} chars")
    if args.dry_run:
        print("[DRY-RUN] not sending.")
        return

    load_wiki_env()  # auto-load ./.wikijs.env or ~/.claude/.wikijs.env if not already in env
    url, token = os.environ.get("WIKIJS_URL"), os.environ.get("WIKIJS_TOKEN")
    if not url or not token:
        sys.exit("Set WIKIJS_URL/WIKIJS_TOKEN, or create ~/.claude/.wikijs.env "
                 "(WIKIJS_URL=... and WIKIJS_TOKEN=...).")

    # PageNotFound surfaces as code 6003 wrapped in INTERNAL_SERVER_ERROR -> tolerate both = create
    found = gql(url, token, FIND_QUERY, {"path": path, "locale": "en"},
                tolerate={6003, "INTERNAL_SERVER_ERROR"})
    existing = (found or {}).get("pages", {}).get("singleByPath") if found else None

    if existing:
        data = gql(url, token, UPDATE_MUTATION, {
            "id": int(existing["id"]), "content": content, "description": desc,
            "title": args.title, "tags": tags, "isPublished": is_published})
        rr = data["pages"]["update"]["responseResult"]
        action = "UPDATE"
    else:
        data = gql(url, token, CREATE_MUTATION, {
            "content": content, "description": desc, "path": path,
            "title": args.title, "tags": tags, "isPublished": is_published})
        rr = data["pages"]["create"]["responseResult"]
        action = "CREATE"

    if not rr["succeeded"]:
        sys.exit(f"{action} FAILED: {rr.get('errorCode')} {rr.get('message')}")
    print(f"{action} OK -> {url.rstrip('/')}/{path}")


if __name__ == "__main__":
    main()
