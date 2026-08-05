# Handoff — Running the Workplace Marketplace Solution-Doc Factory on a Local Ollama LLM

This document hands off the **package factory** used in this repo so you can run it with a
**locally-hosted Ollama model** instead of a hosted frontier model. Read this first; the other files
in this folder are the actual instructions/prompts and a runnable orchestrator.

- `HANDOFF.md` ← you are here (architecture, how it works, how to run it locally, limits)
- `ollama-system-prompt.md` — the system prompt (house style + hard rules) for the local model
- `ollama-authoring-prompts.md` — the per-file prompts + templates + the listing JSON contract
- `run_factory_ollama.py` — a Python orchestrator that drives Ollama through the whole build, then
  calls the existing deterministic tools

---

## 1. The single most important idea: the LLM only *authors*. Everything else is deterministic.

The factory is **not** "an LLM does everything." It is a pipeline where a language model writes text,
and **plain Python/PowerShell tools do all the compiling, packaging, validation, and publishing.**
Those tools do not care which model you use — they work the same with Ollama as with any other model.

```
          ┌─────────────────────────── LLM's job (swap in Ollama here) ───────────────────────────┐
 topic ─▶ │ author source/*.md  +  scripts/*.ps1  +  listing/bagisto-products.json  +  meta.json  │
          └───────────────────────────────────────────────────────────────────────────────────────┘
                                              │  (plain text + JSON files on disk)
                                              ▼
          ┌───────────────────────── deterministic tools (UNCHANGED, no LLM) ─────────────────────┐
          │ build-deliverables.py → DOCX + PDF + Scripts.zip + Complete-Solution.zip               │
          │ build-hero.py         → hero SVG + PNG                                                  │
          │ jsonschema            → validate listing against schema/bagisto-products.schema.json   │
          │ rebuild-index.ps1     → registry.json + INDEX.html                                      │
          │ publish.ps1 / loader  → load into the live store   (Stage 2 — infra, still not an LLM)  │
          └───────────────────────────────────────────────────────────────────────────────────────┘
```

**So porting to Ollama means: replace only the authoring brain.** Keep every tool in `tools/`,
`schema/`, `library/_index/`, and `pricing.md` exactly as they are.

---

## 2. The two stages

- **Stage 1 — Generate** (`/generate-solution` in the original): author a complete solution into the
  library. **This is what the Ollama orchestrator automates.** Output goes to
  `library/<category_slug>/<slug>/v<version>/` with subfolders `source/ scripts/ deliverables/ listing/`.
- **Stage 2 — Publish** (`/publish-solution`): back up the store DB, deploy the files to the server,
  load them into Bagisto, verify, publish the gated wiki page. **This stage is infrastructure
  operations (SSH/PowerShell/SQL), not language work — a local LLM is not needed or wanted here.**
  Keep doing Stage 2 with the existing `tools/publish.ps1` + `loader/create-bagisto-products.php`.

This handoff focuses on Stage 1 (authoring), because that is the only place a model is doing the work.

---

## 3. What one solution is made of (the files the model must produce)

Under `library/<category_slug>/<slug>/v1.0.0/`:

**`source/` (Markdown, authored in this exact order — this is the compiler's `SOURCE_ORDER`):**
1. `executive-summary.md`
2. `01-solution-overview.md` — what it is, how it works, benefits, limitations, the standard deployment model
3. `02-requirements.md` — each requirement as **Description / Why required / How to verify / How to implement if missing**
4. `global-requirements-<category_slug>.md` — category-wide prerequisites (one per category; reuse the existing file's content if present)
5. `03-implementation.md` — exact ordered, click-by-click steps
6. `05-testing.md` — validation with pass/fail gates
7. `06-troubleshooting.md` — **AUTHOR THIS LAST**
8. `07-best-practices.md`
9. `08-deliverables-summary.md`

**`scripts/` (PowerShell):** 5 scripts — typically Discovery / Validation / Reporting / Remediation
plus one topic-specific. Read-only by default; any write action guarded with `-WhatIf`. Each has a
header: Purpose · How to run · Expected results.

**`listing/bagisto-products.json`** — the store contract (schema below).

**`solution.meta.json`** — machine metadata (schema below).

**Then the deterministic tools produce** `deliverables/` (DOCX, PDF, Scripts.zip,
`<SOL>-Complete-Solution.zip`, hero PNG) — the model does **not** write those.

---

## 4. The two JSON contracts the model must emit

### `solution.meta.json`
```json
{
  "slug": "<slug>", "title": "<Title>", "category": "<Category>", "category_slug": "<category_slug>",
  "sol_code": "<SOL>", "version": "1.0.0", "status": "generated",
  "created": "<YYYY-MM-DD>", "updated": "<YYYY-MM-DD>", "published_at": null,
  "version_directive": "New", "branding": "off", "author_notes": [],
  "products": [
    { "sku": "PTK-<SOL>-COMM-001", "audience": "commercial", "price": 0.00 },
    { "sku": "PTK-<SOL>-NPO-001",  "audience": "nonprofit",  "price": 0.00 },
    { "sku": "PTK-<SOL>-GOV-001",  "audience": "government",  "price": 0.00 }
  ],
  "deliverables": ["<SOL>-Complete-Solution.zip"]
}
```

### `listing/bagisto-products.json` (validated against `schema/bagisto-products.schema.json`)
Top-level object `{ "solution": {...}, "products": [...] }`.
- `solution` requires: `slug`, `title`, `category_path` (array, e.g. `["Intune"]`), `version`.
- each `products[]` requires: `sku`, `name`, `type` (`downloadable`), `audience`
  (`commercial|nonprofit|government`, or `essentials|plus` for the 2-variant model, or `free`),
  `price` (≥ 0), `short_description`, `description`. Plus `meta_title`, `meta_description`, `url_key`,
  `image` (`<SOL>-hero.png`), `downloads` (`[{title, source_type:"file", source:"<SOL>-Complete-Solution.zip"}]`).
- Three products (commercial/nonprofit/government) share the same `downloads` + `image`.

**Pricing rule (enforced later):** `nonprofit.price == round(commercial*0.60, 2)` and
`government.price == round(commercial*0.85, 2)`. Set the commercial anchor from the effort scale in
`pricing.md` (T1 $1,295 … T5 $8,995). Most single-platform Intune solutions land **T2–T3 ($1,995–$2,495)**.

---

## 5. The house style the model must follow (this is what makes the docs good)

These are the rules that separate a usable guide from a generic one. They live in full in
`ollama-system-prompt.md`; the essentials:

1. **Audience = a novice admin who must "click to implement."** Imperative, exact steps. No *why* in
   the steps (the *why* lives in the Overview).
2. **Full navigation drill-downs**, every console → blade → tab, in required order. Never "open X → Create."
3. **Name every object you create** with a consistent convention `<Purpose> – <Scope/Platform> – <Stage>`
   (e.g. `WHfB – Compliance – Pilot`) and **reuse that exact name** in later steps, testing,
   troubleshooting, and scripts.
4. **Identify any store app by exact publisher + bundle/package ID**, and disambiguate from look-alikes.
5. **Never assume a prerequisite exists** — every requirement gets Description / Why / Verify / Implement-if-missing.
6. **One consistent deployment model** across all solutions: Assess → Configure → Pilot → Validate → Expand.
7. **Troubleshooting is authored LAST.**
8. **White-label by default** (`branding: off`) — the company name (Phoenixtekk / Workplace
   Marketplace / the store URL) must **not** appear anywhere in source, scripts, listing, or
   deliverables. Say "the standard/repeatable way", never "the Phoenixtekk way".
9. **Apply the accumulated lessons** in `library/_index/AUTHORING_LESSONS.md` before authoring.

---

## 6. ⚠️ The accuracy limitation you must plan around (read this twice)

The quality of the docs in this repo came in large part from **researching vendor facts on the live
web** (Microsoft Learn, ServiceNow docs, SAP docs) and **flagging anything unverifiable instead of
inventing it**. A local Ollama model **has no web access and will confidently hallucinate**
API names, PowerShell cmdlets, portal paths, permission scopes, and vendor config keys.

**Do one of these — do not skip it:**
- **(Recommended) Human-in-the-loop review gate.** Treat the Ollama output as a *first draft*. A human
  (or a web-capable model) verifies every concrete claim — cmdlet names, Graph scopes, menu paths,
  vendor keys — before the solution is published. The orchestrator stops at `status: generated` and
  never auto-publishes for this reason.
- **Give the local model retrieval.** Wire Ollama to a web-search / docs-RAG tool (e.g. an MCP
  search server, or a local mirror of the relevant Microsoft Learn pages) and instruct it to cite or
  flag. Without this, treat every vendor specific as "verify against current documentation".
- **Mark placeholders.** Instruct the model (the system prompt already does) that when it is not
  certain of an exact name/value, it must write a clearly-labeled `‹PLACEHOLDER — verify against
  <source>›` rather than guess. Then a human fills them.

This is the single biggest difference between the hosted runs and a local run. Design your process
around it.

---

## 7. Model & runtime recommendations for Ollama

- **Model size matters a lot here.** This is long-form, structured, technical authoring. Prefer the
  largest instruction-tuned model you can run: e.g. **Qwen2.5 32B/72B-Instruct, Llama 3.1/3.3 70B**,
  or a strong coding model for the PowerShell (e.g. **Qwen2.5-Coder 32B**). 7–8B models will produce
  shallow, error-prone docs — usable only as rough drafts.
- **Context window:** author one file at a time and feed only the minimum prior context (the
  overview + requirements) when writing later files. Request **≥ 16k context** (`num_ctx`); 32k is
  better. Long implementation guides can exceed a small model's window.
- **Temperature:** low (0.2–0.4) for accuracy and consistent formatting; JSON steps at ~0.1.
- **Structured output:** use Ollama's `"format": "json"` (or a JSON schema) for `meta.json` and the
  listing so you get parseable output.
- **Determinism:** set a fixed `seed` if you want reproducible drafts.

---

## 8. How to run it (quick start)

Prerequisites on the machine that will author:
- **Ollama** running (`ollama serve`; default `http://localhost:11434`) with a model pulled
  (`ollama pull qwen2.5:32b-instruct` or similar).
- **Python 3.10+** with the factory's build deps: `pip install python-docx reportlab jsonschema requests`.
- This repo checked out (so the tools, schema, pricing, and AUTHORING_LESSONS are present).
- For hero images only: a **Chromium/Edge/Chrome** browser (see portability note below).

Then:
```bash
python docs/ollama-factory/run_factory_ollama.py \
  --topic "Windows Firewall Management with Intune" \
  --category "Intune Solutions" \
  --sol-code WFM2 \
  --commercial-price 2295 \
  --model qwen2.5:32b-instruct
```
The orchestrator will: author every `source/*.md` and `scripts/*.ps1`, emit `solution.meta.json` and
`listing/bagisto-products.json`, validate the listing against the schema, then run
`build-deliverables.py` and `build-hero.py`. It stops at `status: generated` — **it does not
publish** (see §6). Review, correct the flagged placeholders, then run the normal Stage-2
`publish.ps1` when you're satisfied.

---

## 9. Portability notes (the tools were built on Windows)

- **`build-deliverables.py`** is pure `python-docx` + `reportlab` → **cross-platform**, no changes needed.
- **`build-hero.py`** renders the SVG to PNG via a **headless Chromium/Edge/Chrome**. Its
  `find_browser()` looks in Windows `Program Files` paths — on Linux/macOS, point it at your browser
  (e.g. `google-chrome`, `chromium`, or `/Applications/…/Chrome`). The SVG is always written even if
  PNG rendering is skipped, so a missing browser is non-fatal (you'd add the PNG later).
- **`rebuild-index.ps1`** and **`publish.ps1`** are PowerShell — run them with `pwsh` (PowerShell 7 is
  cross-platform) or reimplement the index rebuild in Python if you prefer (it just regenerates
  `registry.json`/`INDEX.*` from the `solution.meta.json` files).

---

## 10. Definition of done for one solution (the orchestrator checks these)

- All `source/*.md` present and non-empty, `06-troubleshooting.md` authored last.
- 5 `scripts/*.ps1` present, each with the Purpose/How-to-run/Expected header.
- `listing/bagisto-products.json` **validates against `schema/bagisto-products.schema.json`**, three
  products, `nonprofit == commercial*0.60`, `government == commercial*0.85`.
- `solution.meta.json` written with `status: generated`, `branding: off`.
- `build-deliverables.py` produced the DOCX/PDF/Scripts.zip + `<SOL>-Complete-Solution.zip`, and
  `listing.downloads[].source` matches the built bundle filename.
- **Brand-leak scan clean** (no company name in any authored file).
- **Human verification of vendor specifics done** before Stage-2 publish (§6).
