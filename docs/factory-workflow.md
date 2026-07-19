---
title: Workplace Solutions — Solution-Doc Factory Workflow
description: End-to-end workflow of the two-stage solution-doc factory (generate → publish) and the daily learning loop.
published: true
date: 2026-07-02T00:00:00.000Z
tags: workplace, marketplace, factory, workflow, systemdocs
editor: markdown
dateCreated: 2026-07-02T00:00:00.000Z
---

# Workplace Solutions — Solution-Doc Factory Workflow

The factory turns a job description / topic into a productized IT solution published across
three customer-facing surfaces, and learns from human wiki edits over time.

> **Where products publish:** the Bagisto store at **workplace.phoenixtekk.com** (linuxg5,
> `/home/workplace`) — **not** `crm.phoenixtekk.com`, which is a separate Dolibarr ERP/CRM on the
> same host.

```mermaid
flowchart TD
    subgraph INPUT["0 · Intake & scoping (interactive)"]
        A1["Job description / scenario / topic"] --> A2["Recon catalog (dedupe vs existing)"]
        A2 --> A3["Propose net-new solution titles"]
        A3 --> A4{"Owner approves the list?"}
    end
    A4 -- "yes: go" --> S1
    A4 -- "revise" --> A3
    subgraph STAGE1["Stage 1 · /generate-solution (local library only)"]
        S1["Write _spec.json per solution"] --> S2["Scaffold listing + meta + hero.json · 3-tier · white-label"]
        S2 --> S3["Parallel authoring agents → source/*.md + 5 PowerShell scripts + global-requirements"]
        S3 --> S4["add-deliverables-manifest.py"]
        S4 --> S5["build-deliverables.py → Word + PDF + Scripts.zip"]
        S5 --> S6["build-hero.py → hero SVG → PNG"]
    end
    S6 --> P0
    subgraph STAGE2["Stage 2 · /publish-solution (publish.ps1, per slug)"]
        P0["mysqldump DB backup (linuxg5)"] --> P1["scp deliverables + listing + loader → linuxg5"]
        P1 --> P2["loader create-bagisto-products.php (php8.4) → Bagisto store"]
        P2 --> P3["artisan indexer:index + optimize:clear"]
        P3 --> P4["mark meta published · rebuild INDEX"]
        P4 --> P5["publish-blog.py → WordPress DRAFT + hero featured image (linuxg2)"]
        P5 --> P6["publish-wiki.py → Wiki.js guide (linuxg3)"]
        P6 --> P7["wiki-access-sync.py --apply → Purchasers gating group"]
        P7 --> P8["wiki-learning-sync.py --init-baselines"]
        P8 --> P9{"Verify: store 200 · wiki 403 · downloads private"}
    end
    P9 -- "ok" --> OUT
    P9 -- "fail" --> P2
    subgraph OUT["Published surfaces"]
        O1["Bagisto STORE — workplace.phoenixtekk.com (linuxg5)"]
        O2["Wiki.js GUIDE, purchase-gated — docs.phoenixtekk.com (linuxg3)"]
        O3["WordPress BLOG draft — phoenixtekk.com (linuxg2)"]
        O4["Local library + _deliverables shelf (git)"]
    end
    P2 -.-> O1
    P6 -.-> O2
    P5 -.-> O3
    P4 -.-> O4
    subgraph LOOP["Daily learning loop (scheduled task)"]
        L1["Detect human wiki edits vs baseline"] --> L2["Classify: solution-fact vs generalizable lesson"]
        L2 --> L3["Sync fix into source/ · append AUTHORING_LESSONS.md"]
        L3 --> L4["Rebuild + republish (store + wiki)"]
        L4 --> L1
    end
    O2 -.->|"owner edits live wiki while validating"| L1
    L3 -.->|"feeds future authoring"| S3
```

## Stage summary

| Phase | Command / tool | Output |
|---|---|---|
| 0 Intake | interactive | Approved, deduped list of net-new solution titles |
| 1 Generate | `/generate-solution` (specs → scaffold → parallel agents → build-deliverables → build-hero) | Word/PDF/Scripts.zip + hero PNG in the local library |
| 2 Publish | `/publish-solution` → `publish.ps1` | Live store listing, gated wiki guide, blog draft |
| Loop | `wiki-learning-sync.py` (daily scheduled task) | Human corrections synced back into source + authoring lessons |

## Source files (repo)

- `docs/factory-workflow.mmd` — Mermaid source
- `docs/factory-workflow.drawio` — draw.io / diagrams.net (exports to Visio `.vsdx`)
- `docs/factory-workflow.md` — this document
