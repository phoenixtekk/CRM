#!/usr/bin/env python3
"""
add-deliverables-manifest.py — inject an explicit "what you receive" deliverables manifest into every
product description in a solution's listing/bagisto-products.json. Lists each deliverable file and, for
the scripts ZIP, every PowerShell script by NAME with a one-line purpose (parsed from each .ps1
.SYNOPSIS). Idempotent: replaces a previously-injected block.

Usage:
  python tools/add-deliverables-manifest.py --solution-dir library/<cat>/<slug>/v1.0.0
  python tools/add-deliverables-manifest.py --all            # every published solution in the registry
"""
import argparse, json, re, html
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MARK_OPEN = "<!--DELIVMANIFEST-->"
MARK_CLOSE = "<!--/DELIVMANIFEST-->"

# friendly label per source-doc filename (for describing the guide contents)
SECTION_LABELS = {
    "01-solution-overview.md": "solution overview",
    "02-requirements.md": "requirements",
    "03-implementation.md": "step-by-step implementation",
    "04-maintenance-and-updates.md": "maintenance &amp; updates",
    "05-testing.md": "testing &amp; validation",
    "06-troubleshooting.md": "troubleshooting",
    "07-best-practices.md": "best practices",
}


def synopsis_of(ps1: Path) -> str:
    """Return a short purpose for a script from its .SYNOPSIS (text after 'Name.ps1 — '), else ''."""
    try:
        lines = ps1.read_text(encoding="utf-8", errors="ignore").splitlines()
    except Exception:
        return ""
    syn = ""
    for i, ln in enumerate(lines[:40]):
        if ln.strip().lower() == ".synopsis":
            # first non-empty line(s) after .SYNOPSIS
            for nxt in lines[i + 1:i + 5]:
                s = nxt.strip()
                if s:
                    syn = s
                    break
            break
    if not syn:
        # Fallback for non-PowerShell scripts (.sh/.py/.sql/.wlst): scan the first ~20 lines for a
        # header comment line of the form "<name> — <purpose>" (comment chars stripped).
        for ln in lines[:20]:
            s = re.sub(r"^\s*(#+|--+|/\*+|\*+|<#)\s*", "", ln).strip()
            m = re.match(re.escape(ps1.name) + r"\s*[—\-:]\s*(.+)", s)
            if m:
                syn = m.group(1); break
    if not syn:
        return ""
    # strip leading "Name.ext — " / "Name.ext - " / "Name.ext: "
    syn = re.sub(r"^\s*" + re.escape(ps1.name) + r"\s*[—\-:]\s*", "", syn)
    syn = syn.rstrip(". ").strip()
    return syn


def guide_contents(src: Path) -> str:
    parts = [lbl for fn, lbl in SECTION_LABELS.items() if (src / fn).exists()]
    if not parts:
        parts = ["solution overview", "requirements", "step-by-step implementation",
                 "testing &amp; validation", "troubleshooting", "best practices"]
    return ", ".join(parts)


def build_block(vdir: Path) -> str:
    scr = vdir / "scripts"
    src = vdir / "source"
    exts = ("*.ps1", "*.sh", "*.py", "*.sql", "*.wlst")
    scripts = sorted([f for g in exts for f in scr.glob(g)], key=lambda p: p.name)
    script_label = "PowerShell Scripts" if scripts and all(s.suffix == ".ps1" for s in scripts) else "Automation Scripts"
    items = []
    for s in scripts:
        purpose = synopsis_of(s)
        name = html.escape(s.name)
        if purpose:
            items.append(f"<li><code>{name}</code> &mdash; {purpose}</li>")
        else:
            items.append(f"<li><code>{name}</code></li>")
    scripts_li = "".join(items)
    n = len(scripts)
    contents = guide_contents(src)
    block = (
        f"{MARK_OPEN}"
        "<h4>What you receive &mdash; every file in your download</h4>"
        "<p>This package is delivered as downloadable files you keep and reuse across unlimited "
        "devices &mdash; nothing is left out and nothing else is required:</p>"
        "<ul>"
        f"<li><strong>Implementation Guide (PDF)</strong> &mdash; the complete, click-by-click solution: "
        f"{contents}.</li>"
        f"<li><strong>{script_label} (ZIP)</strong> &mdash; {n} ready-to-run script"
        f"{'s' if n != 1 else ''} (read-only discovery/validation/reporting; remediation defaults to a "
        "safe preview):"
        f"<ul>{scripts_li}</ul></li>"
        "</ul>"
        f"{MARK_CLOSE}"
    )
    return block


def inject(desc: str, block: str) -> str:
    # remove any prior injected block (idempotent)
    desc = re.sub(re.escape(MARK_OPEN) + r".*?" + re.escape(MARK_CLOSE), "", desc, flags=re.S)
    # insert before the final delivery line if present, else append
    m = re.search(r"<p><em>Delivered\b", desc)
    if m:
        return desc[:m.start()] + block + desc[m.start():]
    return desc + block


def process(vdir: Path) -> int:
    lf = vdir / "listing" / "bagisto-products.json"
    if not lf.exists():
        print(f"  SKIP (no listing): {vdir}")
        return 0
    j = json.loads(lf.read_text(encoding="utf-8"))
    block = build_block(vdir)
    for p in j["products"]:
        p["description"] = inject(p["description"], block)
    lf.write_text(json.dumps(j, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return len(j["products"])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solution-dir")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()
    targets = []
    if args.all:
        reg = json.loads((ROOT / "library/_index/registry.json").read_text(encoding="utf-8"))
        for r in reg:
            targets.append(ROOT / r["rel_path"])
    elif args.solution_dir:
        targets.append(Path(args.solution_dir).resolve())
    else:
        ap.error("pass --solution-dir or --all")
    total = 0
    for t in targets:
        n = process(t)
        total += n
        print(f"  updated {n} products: {t.name if t.name!='v1.0.0' else t.parent.name}")
    print(f"Done. {len(targets)} solutions, {total} product descriptions updated.")


if __name__ == "__main__":
    main()
