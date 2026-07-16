# CRM / Workplace Marketplace — project rules

Project-scoped rules for this repo. These complement the global rules in
`~/.claude/CLAUDE.md` and the factory memory. This repo is the **Workplace Marketplace
solution-doc factory** (see `FEATURES.md`, `docs/factory-workflow.md`).

## Every factory run ENDS with a summary of the product URLs

**Standing rule (owner directive, 2026-07-16).** Whenever the factory runs and produces product
solutions in the Workplace Marketplace, the **last generation step** is always to **report a summary
of the URL links to the product solutions created/updated in that run** — Store **and** Wiki, as
clickable markdown links. The owner reviews by clicking; a run that reports only names, counts, or a
dollar total is **not done**. This applies to every run: a single product, a rename/republish, a
re-home, or a wave of 100.

- **Generate the links, never hand-type them:**
  ```bash
  python tools/report-links.py --slug <slug> [--slug <slug> ...] --verify   # this run's products
  python tools/report-links.py --since <YYYY-MM-DD> --verify                # a whole wave
  ```
  The tool derives every URL from the data (`url_key` out of each `listing/bagisto-products.json`;
  `wiki_path` / `wiki_gated` out of each `solution.meta.json`), so free products
  (`<slug>-free` + public wiki) and `wiki_path` overrides come out right. **Guessing a URL is worse
  than omitting it.**
- **Always `--verify`.** Store must be **200**; wiki **403** = correctly gated, **200** = intentionally
  public. Anything else is marked ⚠ and exits 2 — **fix it, or say so plainly in the report. Never
  emit a dead URL.**
- **Format is automatic:** inline pairs for 1–3 products, a table for a wave. Paste as-is into the
  Shipped summary.
- Implements the global standing rule in `~/.claude/CLAUDE.md` ("Shipped reports — always include
  marketplace + wiki URLs"). See `publish-solution` SKILL §9.

## Always produce an UNBRANDED local copy of every documentation deliverable

**Standing rule (owner directive, 2026-07-06).** Whenever I create a documentation
deliverable — a client/consulting assessment, report, guide, architecture write-up, or any
compiled Word/PDF — I must **also produce an unbranded (white-label) version and store it
ONLY locally in the repo** (typically under `docs/` or the solution's `deliverables/`), so
the owner can reuse the content for purposes **outside sales** (internal use, client
handoffs under their own brand, templates, etc.).

- **Naming:** keep both when a branded copy is also needed — e.g.
  `docs/<name>.pdf` (branded) **and** `docs/<name>-unbranded.pdf` (unbranded). If only one is
  needed, default to **unbranded**.
- **How:** the factory compiler honors the `branding` flag — build the unbranded copy with
  `branding: "off"` (or `--no-brand`) in the build meta, exactly like the white-label catalog
  solutions.
- **Local-only:** the unbranded reuse copy is **not** published to the store or mirrored to
  the wiki by default — it is a local working artifact for the owner. (Branded/productized
  versions still follow the normal publish + §5 wiki-mirror flow.)
- **Never** put the company name (Phoenixtekk / "Workplace Marketplace" /
  workplace.phoenixtekk.com) in the unbranded copy — same white-label discipline as the
  catalog (`branding: off`), verified brand-free.

This is part of "done" for any documentation deliverable: a branded copy where sales needs it,
**and** an unbranded local copy for everything else.
