#!/usr/bin/env python3
"""
community-sync.py — Workplace Marketplace community glue (CLAUDE.md §6 sibling; Phase E).

Two jobs, both read-only against Discourse (discuss.phoenixtekk.com) via a global API key:

  1. TIPS MIRROR  — publishes each "Tips & Tricks" topic (category 16) into the Wiki.js KB under
                    Workplace/tips/<slug> using ~/.claude/tools/publish-wiki-page.py. Idempotent:
                    a state file skips topics whose content hasn't changed since last run.
  2. SIGNAL LOOP  — writes the most-active community questions (top/monthly) to the CRM factory at
                    library/_index/community-signals.json (+ .md), so /generate-solution can see
                    real demand and prioritise which Microsoft-tech solution docs to build next.

Credentials load from ~/.claude/.discourse.env (DISCOURSE_URL, DISCOURSE_API_KEY, DISCOURSE_API_USER),
falling back to real env vars. No secrets are printed. Runs daily via community-sync-run.ps1.
"""
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request
from datetime import datetime, timezone

HOME = os.path.expanduser("~")
ENV_FILE = os.path.join(HOME, ".claude", ".discourse.env")
PUBLISH_TOOL = os.path.join(HOME, ".claude", "tools", "publish-wiki-page.py")

INDEX_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "library", "_index"))
TIPS_STATE = os.path.join(INDEX_DIR, "tips-mirror-state.json")
SIGNALS_JSON = os.path.join(INDEX_DIR, "community-signals.json")
SIGNALS_MD = os.path.join(INDEX_DIR, "community-signals.md")

WIKI_TIPS_PREFIX = "Workplace/tips"


def load_env():
    if os.path.exists(ENV_FILE):
        with open(ENV_FILE, encoding="utf-8") as fh:
            for line in fh:
                m = re.match(r"^\s*([A-Za-z_]+)\s*=\s*(.*)$", line)
                if m:
                    os.environ.setdefault(m.group(1), m.group(2).strip().strip('"').strip("'"))
    url = os.environ.get("DISCOURSE_URL", "https://discuss.phoenixtekk.com").rstrip("/")
    key = os.environ.get("DISCOURSE_API_KEY", "")
    user = os.environ.get("DISCOURSE_API_USER", "system")
    tips = int(os.environ.get("DISCOURSE_TIPS_CATEGORY_ID", "16"))
    if not key:
        sys.exit("ERROR: DISCOURSE_API_KEY not set (create ~/.claude/.discourse.env)")
    return url, key, user, tips


def now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def slugify(text):
    s = re.sub(r"[^a-zA-Z0-9]+", "-", (text or "").lower()).strip("-")
    return s[:80] or "tip"


def load_json(path, default):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        return default


def save_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(obj, fh, indent=2)


class Discourse:
    def __init__(self, url, key, user):
        self.url, self.key, self.user = url, key, user

    def get(self, path, params=None):
        u = self.url + path
        if params:
            u += "?" + urllib.parse.urlencode(params)
        req = urllib.request.Request(u, headers={
            "Api-Key": self.key,
            "Api-Username": self.user,
            "User-Agent": "phoenixtekk-community-sync/1.0",
            "Accept": "application/json",
        })
        with urllib.request.urlopen(req, timeout=25) as r:
            return json.loads(r.read().decode("utf-8"))

    def category(self, cat_id):
        for c in self.get("/categories.json").get("category_list", {}).get("categories", []):
            if c.get("id") == cat_id:
                return c
        return None


# ---------------------------------------------------------------------------- tips mirror
def mirror_tips(dc, tips_cat_id):
    cat = dc.category(tips_cat_id)
    if not cat:
        return {"error": f"tips category id {tips_cat_id} not found"}
    slug = cat.get("slug")
    # the "About this category" definition topic — skip it (id may come via topic_id or topic_url)
    about_topic_id = cat.get("topic_id")
    if not about_topic_id and cat.get("topic_url"):
        m = re.search(r"/t/[^/]+/(\d+)", cat["topic_url"])
        if m:
            about_topic_id = int(m.group(1))
    listing = dc.get(f"/c/{slug}/{tips_cat_id}.json")
    topics = listing.get("topic_list", {}).get("topics", [])

    state = load_json(TIPS_STATE, {})
    published, skipped, failed = 0, 0, 0
    for t in topics:
        tid = t.get("id")
        title_l = (t.get("title") or "").strip().lower()
        tslug_l = (t.get("slug") or "").lower()
        if tid == about_topic_id or tslug_l.startswith("about-the-") or title_l.startswith("about the "):
            continue
        marker = t.get("last_posted_at") or t.get("bumped_at") or t.get("created_at")
        if state.get(str(tid), {}).get("updated") == marker:
            skipped += 1
            continue
        try:
            topic = dc.get(f"/t/{tid}.json")
            posts = topic.get("post_stream", {}).get("posts", [])
            if not posts:
                continue
            raw = dc.get(f"/posts/{posts[0]['id']}.json").get("raw", "").strip()
            if not raw:
                continue
            title = topic.get("title") or t.get("title") or f"Tip {tid}"
            tslug = topic.get("slug") or slugify(title)
            if _publish_tip(dc.url, title, tslug, tid, raw):
                state[str(tid)] = {"updated": marker, "wiki": f"{WIKI_TIPS_PREFIX}/{tslug}", "title": title}
                published += 1
            else:
                failed += 1
        except Exception as e:
            failed += 1
            print(f"  tip {tid} error: {e}", file=sys.stderr)

    save_json(TIPS_STATE, state)
    return {"total": len(topics), "published": published, "skipped": skipped, "failed": failed}


def _publish_tip(disc_url, title, tslug, tid, raw):
    body = (
        raw
        + f"\n\n---\n"
        + f"*This is a community tip from the Workplace community. "
        + f"Discuss or contribute at the [original topic]({disc_url}/t/{tid}).*\n"
    )
    tmp = tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8")
    try:
        tmp.write(body)
        tmp.close()
        cmd = [
            sys.executable, PUBLISH_TOOL,
            "--file", tmp.name,
            "--path", f"{WIKI_TIPS_PREFIX}/{tslug}",
            "--title", title,
            "--tags", "tips,community,workplace",
            "--description", f"Community tip: {title[:120]}",
        ]
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=150)
        if r.returncode != 0:
            print(f"  publish failed ({tslug}): {r.stderr.strip()[:200]}", file=sys.stderr)
        return r.returncode == 0
    finally:
        try:
            os.unlink(tmp.name)
        except OSError:
            pass


# ---------------------------------------------------------------------------- signal loop
def build_signals(dc):
    try:
        top = dc.get("/top/monthly.json")
    except Exception:
        top = dc.get("/top.json")
    topics = top.get("topic_list", {}).get("topics", [])
    cats = {c["id"]: c for c in dc.get("/categories.json").get("category_list", {}).get("categories", [])}

    signals = []
    for t in topics:
        cat = cats.get(t.get("category_id"), {})
        if cat.get("read_restricted"):
            continue
        signals.append({
            "title": t.get("title"),
            "url": f"{dc.url}/t/{t.get('slug')}/{t.get('id')}",
            "category": cat.get("name"),
            "views": t.get("views", 0),
            "replies": max(0, t.get("posts_count", 1) - 1),
            "likes": t.get("like_count", 0),
            "has_accepted_answer": bool(t.get("has_accepted_answer")),
        })
    signals.sort(key=lambda s: (s["views"], s["replies"], s["likes"]), reverse=True)
    signals = signals[:25]

    out = {
        "generated_at": now_iso(),
        "source": "discourse:top/monthly",
        "community": dc.url,
        "purpose": "Most-active community questions — demand signal for the /generate-solution factory.",
        "signals": signals,
    }
    save_json(SIGNALS_JSON, out)
    _write_signals_md(out)
    unanswered = [s for s in signals if not s["has_accepted_answer"] and s["replies"] >= 0]
    return {"signals": len(signals), "top_unanswered": len(unanswered)}


def _write_signals_md(out):
    lines = [
        "# Community demand signals",
        "",
        f"_Generated {out['generated_at']} from {out['source']} — most-active public topics on "
        f"[{out['community']}]({out['community']})._",
        "",
        "These are the questions the community is most engaged with. The `/generate-solution` factory "
        "should treat unanswered/high-view rows as candidates for new Microsoft-technology solution docs.",
        "",
        "| # | Topic | Category | Views | Replies | Solved |",
        "|--:|-------|----------|------:|--------:|:------:|",
    ]
    for i, s in enumerate(out["signals"], 1):
        title = (s["title"] or "").replace("|", "\\|")
        lines.append(
            f"| {i} | [{title}]({s['url']}) | {s.get('category') or '-'} | "
            f"{s['views']} | {s['replies']} | {'✓' if s['has_accepted_answer'] else '—'} |"
        )
    lines.append("")
    os.makedirs(os.path.dirname(SIGNALS_MD), exist_ok=True)
    with open(SIGNALS_MD, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


# ---------------------------------------------------------------------------- pricing stats sync
# Keeps workplace.phoenixtekk.com/pricing in sync with the solution-library dashboard: reads the
# solution count + commercial catalog value straight from the auto-generated INDEX.html (the same
# figures the owner sees), writes them to the Bagisto store so the pricing template renders them.
INDEX_HTML = os.path.join(INDEX_DIR, "INDEX.html")
STORE_SSH = "linuxg5"
STORE_STATS_REMOTE = "/home/workplace/public_html/storage/app/portal-pricing-stats.json"
STORE_WEBROOT = "/home/workplace/public_html"


def sync_pricing_stats():
    if not os.path.exists(INDEX_HTML):
        return {"error": "INDEX.html not found"}
    html = open(INDEX_HTML, encoding="utf-8", errors="replace").read()
    m_sol = re.search(r'>([0-9,]+)</div>\s*<div class="l">\s*Solutions \(products\)', html, re.I)
    m_val = re.search(r'>\$([0-9,]+)(?:\.\d{2})?</div>\s*<div class="l">\s*Catalog Value', html, re.I)
    if not (m_sol and m_val):
        return {"error": "could not parse INDEX.html (labels changed?)"}
    solutions = int(m_sol.group(1).replace(",", ""))
    catalog = "$" + m_val.group(1)  # comma-formatted, cents dropped
    stats = {"solutions": solutions, "catalog_value": catalog, "generated_at": now_iso()}

    local_tmp = os.path.join(INDEX_DIR, "portal-pricing-stats.json")
    save_json(local_tmp, stats)

    # push to the store (scp then sudo-place + cache clear); best-effort.
    remote_tmp = "/tmp/portal-pricing-stats.json"
    scp = subprocess.run(
        ["scp", "-o", "BatchMode=yes", "-o", "ConnectTimeout=20", local_tmp, f"{STORE_SSH}:{remote_tmp}"],
        capture_output=True, text=True, timeout=60,
    )
    if scp.returncode != 0:
        return {**stats, "pushed": False, "err": scp.stderr.strip()[:160]}
    remote_cmd = (
        f"sudo -n cp {remote_tmp} {STORE_STATS_REMOTE} && "
        f"sudo -n chown workplace:workplace {STORE_STATS_REMOTE} && "
        f"cd {STORE_WEBROOT} && sudo -n -u workplace /usr/bin/php8.4 artisan cache:clear >/dev/null 2>&1 && echo OK"
    )
    ssh = subprocess.run(
        ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=25", STORE_SSH, remote_cmd],
        capture_output=True, text=True, timeout=90,
    )
    pushed = ssh.returncode == 0 and "OK" in ssh.stdout
    return {**stats, "pushed": pushed, "err": ("" if pushed else ssh.stderr.strip()[:160])}


def main():
    url, key, user, tips_cat = load_env()
    dc = Discourse(url, key, user)
    result = {"generated_at": now_iso()}
    try:
        result["tips"] = mirror_tips(dc, tips_cat)
    except Exception as e:
        result["tips"] = {"error": str(e)}
    try:
        result["signals"] = build_signals(dc)
    except Exception as e:
        result["signals"] = {"error": str(e)}
    try:
        result["pricing_stats"] = sync_pricing_stats()
    except Exception as e:
        result["pricing_stats"] = {"error": str(e)}
    print(json.dumps(result, indent=2))
    # non-zero exit only if BOTH jobs errored (so the scheduler log flags a total failure)
    if "error" in result.get("tips", {}) and "error" in result.get("signals", {}):
        sys.exit(1)


if __name__ == "__main__":
    main()
