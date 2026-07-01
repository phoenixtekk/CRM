#!/usr/bin/env python3
"""
wiki-learning-sync.py — detect human validation edits to published solution docs on Wiki.js.

This is the DETERMINISTIC signal generator for the "Documentation Validation Learning Loop"
(CLAUDE.md §6). It does NOT change anything by itself — it finds, per published solution:
  - the current Wiki.js page content, its last-edit time, and last author,
  - the factory's "as-generated" render of the local source (the same render publish-wiki.py uses),
  - the per-source-file diff between them = the human's corrections,
and emits a human-readable summary + a machine-readable JSON report. A scheduled Claude run
consumes the report to learn (sync source, rebuild/republish, append AUTHORING_LESSONS, etc.).

Read-only. Auth from env / ~/.claude/.wikijs.env (WIKIJS_URL, WIKIJS_TOKEN).

Usage:
  python tools/wiki-learning-sync.py --registry library/_index/registry.json
  python tools/wiki-learning-sync.py --registry ... --human-author "lacy" --json learning-report.json
  python tools/wiki-learning-sync.py --registry ... --all     # ignore the checkpoint, scan everything

A change is reported when the current wiki content differs from the factory baseline
(library/_index/wiki-baselines/<slug>.md, written at publish time) — optionally filtered by
--human-author. The baseline diff is the sole gate: an edit keeps surfacing until it's applied
(applying republishes -> baseline refreshes -> diff clears), so a read-only check never consumes it.
"""
import argparse, json, os, sys, glob, re, difflib
from pathlib import Path
from urllib import request as urlrequest, error as urlerror

SOURCE_ORDER = [
    "executive-summary.md", "01-solution-overview.md", "02-requirements.md",
    "__global__", "03-implementation.md", "05-testing.md", "06-troubleshooting.md",
    "07-best-practices.md", "08-deliverables-summary.md",
]
BROWSER_UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
SINGLE_BY_PATH = """query($path:String!,$locale:String!){ pages{ singleByPath(path:$path,locale:$locale){ id } } }"""
SINGLE = """query($id:Int!){ pages{ single(id:$id){ id path title updatedAt authorName authorId content } } }"""


def load_wiki_env():
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


def gql(url, token, query, variables, tolerate=None):
    body = json.dumps({"query": query, "variables": variables}).encode("utf-8")
    req = urlrequest.Request(url.rstrip("/") + "/graphql", data=body, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("User-Agent", BROWSER_UA)
    try:
        with urlrequest.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urlerror.HTTPError as e:
        sys.exit(f"Wiki.js HTTP {e.code}: {e.read().decode('utf-8','replace')[:400]}")
    if data.get("errors"):
        codes = {(e.get("extensions") or {}).get("code") for e in data["errors"]}
        if tolerate and codes and codes <= set(tolerate):
            return None
        sys.exit("Wiki.js GraphQL errors: " + json.dumps(data["errors"])[:600])
    return data["data"]


def factory_sections(sol_dir: Path, meta: dict):
    """Return (header, [(label, body)]) matching publish-wiki.py's render, per source file."""
    src = sol_dir / "source"
    header = (f"# {meta['title']}\n\n"
              f"> **Version {meta['version']}** · Category: {meta.get('category','')} · "
              f"Solution code: {meta.get('sol_code','')}\n\n"
              "> This is the online, maintained copy of the implementation guide.")
    sections = []
    for name in SOURCE_ORDER:
        if name == "__global__":
            hits = sorted(glob.glob(str(src / "global-requirements-*.md")))
            files = [(Path(hits[0]).name, Path(hits[0]))] if hits else []
        else:
            f = src / name
            files = [(name, f)] if f.exists() else []
        for label, f in files:
            sections.append((label, f.read_text(encoding="utf-8").strip()))
    return header, sections


def section_by_h1(content: str, h1: str):
    """Return the chunk of `content` under the given level-1 heading (up to the next '# ' line).
    Robust to '---' horizontal rules inside a section (which a separator-split would mis-handle)."""
    lines = content.splitlines()
    h1 = h1.strip()
    start = None
    for i, l in enumerate(lines):
        if l.strip() == h1:
            start = i
            break
    if start is None:
        return None
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if lines[j].startswith("# "):
            end = j
            break
    chunk = lines[start:end]
    # drop the inter-section '---' separator (+ surrounding blanks) the publisher inserts between
    # sections — it belongs to neither source file, so it must not count as a diff.
    while chunk and chunk[-1].strip() in ("", "---"):
        chunk.pop()
    return "\n".join(chunk).strip()


def norm(s: str) -> str:
    return "\n".join(l.rstrip() for l in s.strip().splitlines())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--registry", required=True)
    ap.add_argument("--human-author", default=None,
                    help="only report pages whose last author matches this (e.g. 'lacy'); "
                         "omit to report all diffs and annotate the author")
    ap.add_argument("--json", default=None, help="write the machine-readable report here")
    ap.add_argument("--all", action="store_true", help=argparse.SUPPRESS)  # deprecated no-op (kept for compat)
    ap.add_argument("--init-baselines", action="store_true",
                    help="snapshot current wiki content as the factory baseline per solution "
                         "(run once when wiki and source are in sync), then exit")
    args = ap.parse_args()

    load_wiki_env()
    url, token = os.environ.get("WIKIJS_URL"), os.environ.get("WIKIJS_TOKEN")
    if not url or not token:
        sys.exit("Set WIKIJS_URL/WIKIJS_TOKEN or create ~/.claude/.wikijs.env")

    reg = json.loads(Path(args.registry).read_text(encoding="utf-8"))
    solutions = reg.get("solutions", []) if isinstance(reg, dict) else reg
    reg_dir = Path(args.registry).resolve().parent
    repo_root = reg_dir.parent.parent  # library/_index -> repo root
    base_dir = reg_dir / "wiki-baselines"  # exact factory-published content per slug (clean attribution)

    report = []
    for s in solutions:
        slug = s.get("slug")
        if not slug:
            continue
        # resolve the version dir from rel_path (Windows-style backslashes) or fall back to glob
        rel = (s.get("rel_path") or s.get("dir") or "").replace("\\", "/")
        vdir = (repo_root / rel) if rel else None
        if not vdir or not (vdir / "solution.meta.json").exists():
            cands = glob.glob(str(repo_root / "library" / "*" / slug / "v*" / "solution.meta.json"))
            if not cands:
                continue
            vdir = Path(sorted(cands)[-1]).parent
        meta = json.loads((vdir / "solution.meta.json").read_text(encoding="utf-8"))
        if not meta.get("wiki_published"):
            continue  # only solutions whose docs are live on the wiki can be validated/learned from
        wiki_path = meta.get("wiki_path") or f"solutions/{meta['category_slug']}/{slug}"

        found = gql(url, token, SINGLE_BY_PATH, {"path": wiki_path, "locale": "en"},
                    tolerate={6003, "INTERNAL_SERVER_ERROR"})
        page_id = (found or {}).get("pages", {}).get("singleByPath", {}).get("id") if found else None
        if not page_id:
            continue
        page = gql(url, token, SINGLE, {"id": int(page_id)})["pages"]["single"]
        author, updated, content = page.get("authorName"), page.get("updatedAt"), page.get("content") or ""

        baseline_file = base_dir / f"{slug}.md"
        if args.init_baselines:
            # snapshot the current wiki content as the factory baseline (run once when in sync)
            base_dir.mkdir(parents=True, exist_ok=True)
            baseline_file.write_text(content, encoding="utf-8")
            print(f"  baseline written: {slug}")
            continue

        if args.human_author and (author or "").lower() != args.human_author.lower():
            continue
        # The baseline diff below IS the gate: an edit keeps being reported until it's applied
        # (apply republishes -> baseline updated -> diff clears). No timestamp checkpoint needed,
        # so a read-only check (--detect-only / peek) never "consumes" an unapplied edit.

        # Factory side = the exact published baseline when present (robust, account-free attribution:
        # only edits made AFTER the last factory publish show up). Fall back to the source render.
        baseline = baseline_file.read_text(encoding="utf-8") if baseline_file.exists() else None
        _, sections = factory_sections(vdir, meta)
        file_diffs = []
        for label, body in sections:
            h1 = body.splitlines()[0].strip() if body else ""
            fac = section_by_h1(baseline, h1) if baseline else body
            if fac is None:
                fac = body  # heading absent from baseline (older page) -> use source body
            wsec = section_by_h1(content, h1) if h1.startswith("# ") else None
            if wsec is None:
                file_diffs.append({"source_file": label, "note": "heading not found in wiki (renamed?)",
                                   "diff": f"factory heading: {h1}"})
            elif norm(fac) != norm(wsec):
                diff = "\n".join(difflib.unified_diff(
                    norm(fac).splitlines(), norm(wsec).splitlines(),
                    fromfile=f"factory:{label}", tofile=f"wiki:{label}", lineterm=""))
                file_diffs.append({"source_file": label, "diff": diff})

        if file_diffs:
            report.append({"slug": slug, "wiki_path": wiki_path, "version_dir": str(vdir),
                           "author": author, "updated_at": updated,
                           "baseline": "publish-snapshot" if baseline else "source-render(fallback)",
                           "changed_files": [d["source_file"] for d in file_diffs],
                           "diffs": file_diffs})

    if args.init_baselines:
        print("\nBaselines initialized from current wiki content.")
        return

    # output
    print(f"Scanned {len(solutions)} solution(s). Human-edited since last run: {len(report)}\n")
    for r in report:
        print(f"• {r['slug']}  (author: {r['author']}, updated: {r['updated_at']})")
        print(f"    changed: {', '.join(r['changed_files'])}")
    if not report:
        print("No new human corrections to learn from.")

    if args.json:
        Path(args.json).write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"\nJSON report -> {args.json}")


if __name__ == "__main__":
    main()
