# CRM / Workplace Solutions — project rules

Project-scoped rules for this repo. These complement the global rules in
`~/.claude/CLAUDE.md` and the factory memory. This repo is the **Workplace Solutions
solution-doc factory** (see `FEATURES.md`, `docs/factory-workflow.md`).

## Every run that TOUCHES a published product ENDS with a summary of the product URLs

**Standing rule (owner directive, 2026-07-16; trigger widened same day).** Whenever a session
**touches any product solution that is live in the Workplace Solutions**, the **last step** is
always to **report a summary for every product touched in that run** — three things per product:
**Store link**, **Wiki link** (clickable markdown), **and the local path to that product's
deliverables**. The owner reviews by clicking, and reuses the built files locally; a run that reports
only names, counts, or a dollar total is **not done**.

**"Touches" is deliberately broad — if the owner might want to look at it, link it.** It covers:
- **new products** (single, or a wave of 100);
- **content changes to an existing live product** — a doc/source edit + republish, a field-fix folded
  in, a corrected script, a re-render of deliverables;
- **rename / re-home / re-price / re-image / re-publish**, even when the change is invisible in the
  docs;
- **learning-loop syncs** that push a correction back into a published solution;
- **retire/purge** — link what's gone too, but see the dead-link rule below.

The only runs exempt are those that touch **no live product at all** (pure tooling/factory-plumbing
work, authoring that stops before publish, or read-only analysis). When in doubt, **emit the links** —
an extra table costs nothing; a missing one costs the owner a hunt.

- **Generate the links, never hand-type them:**
  ```bash
  python tools/report-links.py --slug <slug> [--slug <slug> ...] --verify   # this run's products
  python tools/report-links.py --since <YYYY-MM-DD> --verify                # a whole wave
  python tools/report-links.py --slug <live> --retired <purged> --verify    # a run that retired one
  ```
  The tool derives everything from the data (`url_key` out of each `listing/bagisto-products.json`;
  `wiki_path` / `wiki_gated` out of each `solution.meta.json`), so free products
  (`<slug>-free` + public wiki) and `wiki_path` overrides come out right. **Guessing a URL is worse
  than omitting it.**
- **Local deliverables path is reported alongside the two links** — the owner reuses the built files
  (per the unbranded-copy rule), so "where is it online" and "where are the files" belong together.
  The tool reports the **version dir** (`library/<cat>/<slug>/v<ver>/deliverables`) — the source of
  truth a rebuild writes to; `library/_deliverables/<slug>/` is a publish-time copy. It flags ⚠ when
  the dir is missing/empty, when a bundle named in `meta.deliverables` isn't there, or when the
  **shelf drifts from the version dir** (= the store may have shipped a different file than what's on
  disk). Default output is a repo-relative clickable link; `--abs-paths` gives absolute Windows paths.
- **Always `--verify`.** Store must be **200**; wiki **403** = correctly gated, **200** = intentionally
  public. Anything else is marked ⚠ and exits 2 — **fix it, or say so plainly in the report. Never
  emit a dead URL.**
- **Retires use `--retired <slug>`, always.** `--verify` cannot detect a retired product — the store
  URL 404s but the wiki page answers **403 even when deleted** (Guests-deny fires before the 404), so
  it would look "correctly gated". `--retired` reports the removal in words, and covers slugs already
  `git rm`'d from the registry.
- **Exit 2 = something didn't check out** (a link that failed `--verify`, OR missing/stale local
  deliverables — the local checks fail with or without `--verify`). Fix it or say so plainly.
- **Format is automatic:** inline triples for 1–3 products, a table for a wave. Paste as-is into the
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
- **Never** put the company name (Phoenixtekk / "Workplace Solutions" / the legacy
  "Workplace Marketplace" / workplace.phoenixtekk.com) in the unbranded copy — same white-label
  discipline as the catalog (`branding: off`), verified brand-free. (Leak checks grep for BOTH brand
  phrases — the current name and the legacy one.)

This is part of "done" for any documentation deliverable: a branded copy where sales needs it,
**and** an unbranded local copy for everything else.
