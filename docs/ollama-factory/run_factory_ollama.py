#!/usr/bin/env python3
"""
run_factory_ollama.py — drive a LOCAL Ollama model through Stage 1 of the solution-doc factory,
then hand off to the existing deterministic build tools. See HANDOFF.md in this folder.

WHAT IT DOES
  1. Authors every source/*.md and 5 scripts/*.ps1 by calling Ollama (system prompt = house style).
  2. Emits solution.meta.json + listing/hero.json + listing/bagisto-products.json (JSON mode).
  3. Validates the listing against schema/bagisto-products.schema.json.
  4. Runs tools/build-deliverables.py and tools/build-hero.py.
  5. STOPS at status "generated". It never publishes (a human must verify vendor facts first — the
     local model cannot web-research; see HANDOFF.md §6).

USAGE
  python docs/ollama-factory/run_factory_ollama.py \
      --topic "Windows Firewall Management with Intune" \
      --category "Intune Solutions" --sol-code WFM2 \
      --commercial-price 2295 --model qwen2.5:32b-instruct

REQUIREMENTS
  Ollama running (OLLAMA_HOST, default http://localhost:11434) with --model pulled.
  pip install requests jsonschema python-docx reportlab
"""
import argparse, json, os, re, subprocess, sys, datetime, pathlib

try:
    import requests
except ImportError:
    sys.exit("pip install requests")

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent  # docs/ollama-factory -> repo root
OLLAMA = os.environ.get("OLLAMA_HOST", "http://localhost:11434").rstrip("/")

# Store category display names (category_path in the listing) -> category_slug (folder + registry).
CATEGORY_SLUG = {
    "Intune Solutions": ("intune-solutions", "Intune"),
    "Entra ID Solutions": ("entra-id-solutions", "Entra"),
    "Defender Solutions": ("defender-solutions", "Defender"),
    "Sentinel Solutions": ("sentinel-solutions", "Sentinel"),
    "Azure Solutions": ("azure-solutions", "Azure"),
    "Security Solutions": ("security-solutions", "Security"),
    "Infrastructure": ("infrastructure", "Infrastructure"),
    "Cloud": ("cloud", "Cloud"),
    "Healthcare Solutions": ("healthcare-solutions", "Healthcare Solutions"),
    "Managed": ("managed", "Managed"),
    "Copilot": ("copilot", "Copilot"),
}


def slugify(s):
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def load_system_prompt():
    txt = (HERE / "ollama-system-prompt.md").read_text(encoding="utf-8")
    m = re.search(r"=== SYSTEM PROMPT ===(.*?)=== END SYSTEM PROMPT ===", txt, re.S)
    return m.group(1).strip() if m else txt


def ollama_chat(system, user, model, json_mode=False, temperature=0.3, num_ctx=16384):
    """One Ollama chat completion. Returns the assistant text."""
    payload = {
        "model": model,
        "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
        "stream": False,
        "options": {"temperature": 0.1 if json_mode else temperature, "num_ctx": num_ctx},
    }
    if json_mode:
        payload["format"] = "json"
    r = requests.post(f"{OLLAMA}/api/chat", json=payload, timeout=1200)
    r.raise_for_status()
    return r.json()["message"]["content"].strip()


def strip_fences(txt):
    """Remove ``` fences a model may wrap around output."""
    txt = re.sub(r"^```[a-zA-Z]*\n", "", txt.strip())
    txt = re.sub(r"\n```$", "", txt.strip())
    return txt.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--topic", required=True)
    ap.add_argument("--category", required=True, choices=list(CATEGORY_SLUG))
    ap.add_argument("--sol-code", required=True, help="short UPPER code, e.g. WFM2")
    ap.add_argument("--commercial-price", type=float, required=True)
    ap.add_argument("--notes", default="none", help="optional shaping note")
    ap.add_argument("--model", default=os.environ.get("OLLAMA_MODEL", "qwen2.5:32b-instruct"))
    ap.add_argument("--slug", default=None)
    ap.add_argument("--num-ctx", type=int, default=16384)
    args = ap.parse_args()

    SOL = args.sol_code.upper()
    slug = args.slug or slugify(args.topic)
    cat_slug, cat_store = CATEGORY_SLUG[args.category]
    today = datetime.date.today().isoformat()
    comm = round(args.commercial_price, 2)
    npo = round(comm * 0.60, 2)
    gov = round(comm * 0.85, 2)

    vdir = REPO / "library" / cat_slug / slug / "v1.0.0"
    src = vdir / "source"; scr = vdir / "scripts"; lst = vdir / "listing"
    for d in (src, scr, lst, vdir / "deliverables"):
        d.mkdir(parents=True, exist_ok=True)

    system = load_system_prompt().replace("<SOL>", SOL)
    ctx = {}  # cache authored text to feed later prompts

    def author(user, fname, target_dir, json_mode=False, key=None):
        print(f"  authoring {fname} ...", flush=True)
        out = ollama_chat(system, user, args.model, json_mode=json_mode, num_ctx=args.num_ctx)
        out = strip_fences(out)
        (target_dir / fname).write_text(out + "\n", encoding="utf-8")
        if key:
            ctx[key] = out
        return out

    P = {"TOPIC": args.topic, "SOL": SOL, "CATEGORY": args.category, "NOTES": args.notes,
         "CATEGORY_SLUG": cat_slug, "CATEGORY_STORE_NAME": cat_store, "TODAY": today,
         "COMM": comm, "NPO": npo, "GOV": gov}

    print(f"Authoring '{args.topic}'  [{SOL}]  ->  {vdir}")

    # --- source docs (author in the canonical order; troubleshooting LAST) ---
    author(f"Write 01-solution-overview.md for \"{args.topic}\". Shaping note: {args.notes}. "
           f"Start with heading '# 1. Solution Overview — {args.topic}'. Subsections: What it is; "
           f"How it works; Benefits; Limitations; The standard deployment model (Assess→Configure→"
           f"Pilot→Validate→Expand). 500-900 words. Mark uncertain facts with ‹VERIFY: … — check <source>›.",
           "01-solution-overview.md", src, key="overview")

    author(f"Write 02-requirements.md for \"{args.topic}\". Heading '# 2. Requirements'. Each "
           f"requirement as its own ## item with bold labels in order: **Description**, **Why "
           f"required**, **How to verify**, **How to implement if missing**. Include exact least-"
           f"privilege admin roles; mark uncertain scope/role names with ‹VERIFY:›.\n\n(context)\n{ctx['overview'][:2500]}",
           "02-requirements.md", src, key="requirements")

    gr = f"global-requirements-{cat_slug}.md"
    if not (src / gr).exists():
        author(f"Write {gr}: prerequisites common to EVERY solution in the '{args.category}' category "
               f"(tenant, licensing baseline, admin roles, network baseline). Same four-label format. "
               f"Category-general, not specific to this topic.", gr, src)

    author(f"Write 03-implementation.md for \"{args.topic}\". Heading '# 3. Implementation'. Exact "
           f"ordered click-by-click steps (Assess→Configure→Pilot→Validate→Expand), full navigation "
           f"drill-downs, NAME every object as '<Purpose> – <Scope> – <Stage>' and reuse the names. "
           f"Reference scripts {SOL}-Discovery.ps1 / {SOL}-Validation.ps1 where run. Mark uncertain "
           f"paths/values with ‹VERIFY:›.\n\n(context)\n{ctx['overview'][:1500]}\n{ctx['requirements'][:1500]}",
           "03-implementation.md", src, key="implementation")

    for role in ["Discovery", "Validation", "Reporting", "Remediation", "Report-Detail"]:
        author(f"Write a PowerShell script '{SOL}-{role}.ps1' for \"{args.topic}\" (role: {role}). "
               f"Read-only by default; change-making needs -WhatIf + explicit -Apply. Graph calls "
               f"cloud-aware (Connect-MgGraph -Environment Global|USGov|USGovDoD). Start with a comment "
               f"header: .SYNOPSIS (Purpose), HOW TO RUN, EXPECTED RESULTS, neutral .NOTES (no company "
               f"name). Use real cmdlets; if unsure, put ‹VERIFY:› in a comment. Output ONLY the script.",
               f"{SOL}-{role}.ps1", scr)

    author(f"Write 05-testing.md for \"{args.topic}\". Heading '# 5. Testing & Validation'. Explicit "
           f"PASS/FAIL gates referencing the exact object names and scripts.\n\n(context)\n{ctx['implementation'][:2500]}",
           "05-testing.md", src)
    author(f"Write 07-best-practices.md for \"{args.topic}\". Heading '# 7. Best Practices'. Specific, "
           f"bulleted, no filler.", "07-best-practices.md", src)
    author(f"Write 08-deliverables-summary.md for \"{args.topic}\". Heading '# 8. What's Included'. "
           f"Summarize the sections and the 5 scripts (name each + one line).", "08-deliverables-summary.md", src)
    author(f"Write executive-summary.md for \"{args.topic}\". Heading '# Executive Summary'. One page "
           f"for a decision-maker: problem, outcome, effort/risk, what they get. White-label.", "executive-summary.md", src)

    # troubleshooting LAST
    author(f"Write 06-troubleshooting.md for \"{args.topic}\". Heading '# 6. Troubleshooting'. "
           f"symptom → cause → fix → re-validate for the real failure modes, referencing the EXACT "
           f"object names and scripts from the implementation. Mark uncertain error codes/paths with "
           f"‹VERIFY:›.\n\n(context)\n{ctx['implementation'][:2500]}", "06-troubleshooting.md", src)

    # --- JSON: meta, hero, listing ---
    meta_user = (f"Output ONLY valid JSON for solution.meta.json. keys: slug=\"{slug}\", "
                 f"title=\"{args.topic}\", category=\"{args.category}\", category_slug=\"{cat_slug}\", "
                 f"sol_code=\"{SOL}\", version=\"1.0.0\", status=\"generated\", created=\"{today}\", "
                 f"updated=\"{today}\", published_at=null, version_directive=\"New\", branding=\"off\", "
                 f"author_notes=[\"pricing: set from effort scale\"], products=[3 items with sku "
                 f"PTK-{SOL}-COMM-001/NPO-001/GOV-001, audience commercial/nonprofit/government, price "
                 f"{comm}/{npo}/{gov}], deliverables=[\"{SOL}-Complete-Solution.zip\"].")
    meta = strip_fences(ollama_chat(system, meta_user, args.model, json_mode=True))
    # enforce the machine-critical fields regardless of what the model returned
    meta_obj = json.loads(meta)
    meta_obj.update({"slug": slug, "sol_code": SOL, "category": args.category, "category_slug": cat_slug,
                     "version": "1.0.0", "status": "generated", "branding": "off",
                     "deliverables": [f"{SOL}-Complete-Solution.zip"],
                     "products": [{"sku": f"PTK-{SOL}-COMM-001", "audience": "commercial", "price": comm},
                                  {"sku": f"PTK-{SOL}-NPO-001", "audience": "nonprofit", "price": npo},
                                  {"sku": f"PTK-{SOL}-GOV-001", "audience": "government", "price": gov}]})
    (vdir / "solution.meta.json").write_text(json.dumps(meta_obj, indent=2), encoding="utf-8")

    hero_user = (f"Output ONLY JSON for listing/hero.json for \"{args.topic}\": title_lines (3, colors "
                 f"white/green/blue), from{{label,items[4]}}, to{{label,stat}}, tagline, benefits[4] "
                 f"(icon from: shield fingerprint chip cloud lock key chart gear device users).")
    (lst / "hero.json").write_text(strip_fences(ollama_chat(system, hero_user, args.model, json_mode=True)) + "\n",
                                   encoding="utf-8")

    listing_user = (f"Output ONLY valid JSON: {{\"solution\":{{\"slug\":\"{slug}\",\"title\":\"{args.topic}\","
                    f"\"category_path\":[\"{cat_store}\"],\"version\":\"1.0.0\"}},\"products\":[3 products "
                    f"commercial/nonprofit/government]}}. Each product: sku, name, type \"downloadable\", "
                    f"audience, price ({comm}/{npo}/{gov}), short_description (HTML >=10 chars), description "
                    f"(HTML sales copy >=50 chars: <h3> hook, problem, run-it-yourself value 3 bullets, "
                    f"what's inside, bottom line), meta_title, meta_description, url_key "
                    f"(\"{slug}-commercial\"/-nonprofit/-government), image \"{SOL}-hero.png\", downloads "
                    f"[{{title:\"Complete Solution Package (PDF, Word Doc & Scripts)\",source_type:\"file\","
                    f"source:\"{SOL}-Complete-Solution.zip\"}}]. White-label, no company name.")
    listing_obj = json.loads(strip_fences(ollama_chat(system, listing_user, args.model, json_mode=True)))
    # enforce machine-critical fields
    listing_obj["solution"] = {"slug": slug, "title": args.topic, "category_path": [cat_store], "version": "1.0.0"}
    SKU_CODE = {"commercial": "COMM", "nonprofit": "NPO", "government": "GOV"}
    auds = [("commercial", comm), ("nonprofit", npo), ("government", gov)]
    for pr, (aud, price) in zip(listing_obj.get("products", []), auds):
        pr.update({"sku": f"PTK-{SOL}-{SKU_CODE[aud]}-001",
                   "type": "downloadable", "audience": aud, "price": price,
                   "url_key": f"{slug}-{aud}", "image": f"{SOL}-hero.png",
                   "downloads": [{"title": "Complete Solution Package (PDF, Word Doc & Scripts)",
                                  "source_type": "file", "source": f"{SOL}-Complete-Solution.zip"}]})
    (lst / "bagisto-products.json").write_text(json.dumps(listing_obj, indent=2, ensure_ascii=False), encoding="utf-8")

    # --- validate the listing against the real schema ---
    try:
        import jsonschema
        schema = json.loads((REPO / "schema" / "bagisto-products.schema.json").read_text(encoding="utf-8"))
        jsonschema.validate(listing_obj, schema)
        print("  schema: PASS")
    except Exception as e:
        print(f"  schema: FAIL — {str(e)[:200]}\n  (fix listing/bagisto-products.json before publishing)")

    # --- deterministic build tools (unchanged) ---
    rel = f"library/{cat_slug}/{slug}/v1.0.0"
    print("  running build-deliverables.py ...")
    subprocess.run([sys.executable, str(REPO / "tools" / "build-deliverables.py"), "--solution-dir", rel],
                   cwd=REPO)
    print("  running build-hero.py ...  (needs a Chromium/Edge browser; SVG still written if absent)")
    subprocess.run([sys.executable, str(REPO / "tools" / "build-hero.py"), "--solution-dir", rel], cwd=REPO)

    # LATEST.txt
    (REPO / "library" / cat_slug / slug / "LATEST.txt").write_text("v1.0.0\n", encoding="utf-8")

    print(f"""
DONE (status: generated) -> {vdir}
NEXT (human):
  1. Review every ‹VERIFY: …› marker and confirm the vendor/API/portal facts (the local model
     cannot web-research — do NOT publish unverified specifics).
  2. Brand-leak scan: grep -ri 'phoenixtekk\\|workplace marketplace' "{vdir}"  (expect nothing).
  3. Confirm deliverables/{SOL}-Complete-Solution.zip exists and the listing points at it.
  4. Rebuild the index: pwsh library/_index/rebuild-index.ps1
  5. Only then run Stage 2 (tools/publish.ps1) to load it into the store.
""")


if __name__ == "__main__":
    main()
