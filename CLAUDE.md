# CRM / Workplace Marketplace — project rules

Project-scoped rules for this repo. These complement the global rules in
`~/.claude/CLAUDE.md` and the factory memory. This repo is the **Workplace Marketplace
solution-doc factory** (see `FEATURES.md`, `docs/factory-workflow.md`).

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
