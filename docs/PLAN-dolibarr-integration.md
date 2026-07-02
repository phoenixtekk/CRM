---
title: Dolibarr ERP/CRM Integration — Scope & Possibilities
description: Scope for feeding the marketplace catalog into Dolibarr, plus a map of what Dolibarr can do across the Phoenixtekk platform stack.
published: true
date: 2026-07-02T00:00:00.000Z
tags: dolibarr, crm, erp, integration, systemdocs, planning
editor: markdown
dateCreated: 2026-07-02T00:00:00.000Z
---

# Dolibarr ERP/CRM Integration — Scope & Possibilities

**Status:** planning / scope only — nothing built yet. Awaiting go-ahead per phase.

## What Dolibarr is here (verified)

- **App:** Dolibarr **20.0.4**, at **crm.phoenixtekk.com** on **linuxg5** (`/home/crm/public_html`,
  site user `crm`, its own MariaDB database — separate from the Bagisto `workplace` DB).
- **REST API:** **enabled and reachable** — `https://crm.phoenixtekk.com/api/index.php/` returns
  `401` (needs an API key), not `404`. This is the integration surface.
- It is a **full ERP/CRM** (modules seen in the tree: third parties, proposals, orders, invoices,
  accountancy, members/`adherents`, projects, API, AI). Today it is **not** connected to the store,
  wiki, blog, or marketing — it stands alone.

## Prerequisite for any write integration

A **Dolibarr API key** (Dolibarr → Home → Setup → Users & Groups → a service user → *API key*),
stored **only** in a repo-external secrets file (proposed `~/.claude/.dolibarr.env` with
`DOLIBARR_URL` + `DOLIBARR_API_KEY`, auto-loaded, **never committed** — same pattern as
`~/.claude/.wikijs.env`). You generate the key; I never store or print it.

---

## Phase 1 (requested): push the marketplace catalog into Dolibarr as products/services

**Goal:** every published solution becomes a Dolibarr **Product/Service** so you can quote and
invoice it from the CRM.

- **Source of truth:** the local library (`library/_index/registry.json` + each
  `solution.meta.json`) — already the source for the store. One new tool
  (`tools/dolibarr-sync.py`) reads it and **upserts** into Dolibarr over REST, **idempotent by
  `ref`** (the SKU), mirroring how the Bagisto loader works.
- **Mapping (recommended):**
  - One Dolibarr **Service** per solution (`type = service`), `ref = PTK-<SOL>` (base), `label =`
    title, `description =` the short pitch, `note =` link back to the store + wiki.
  - **Three price tiers → Dolibarr multiprice levels** (price level 1 = Commercial, 2 = Non-Profit,
    3 = Government). Dolibarr natively supports customer price levels, so a third party flagged
    "non-profit" automatically gets the NPO price on quotes/invoices — this reuses your existing
    3-tier model cleanly instead of creating 3 separate products.
  - Alternatively (simpler, less elegant): 3 separate products per solution keyed on the existing
    `PTK-<SOL>-COMM/NPO/GOV-001` SKUs.
- **Direction:** one-way (repo → Dolibarr), re-runnable, safe to run after every publish wave. Could
  later be wired into `publish.ps1` as a non-fatal final step (like the blog step).
- **Effort:** ~1 focused build session (tool + dry-run + first sync of all 126). No store/wiki risk
  (Dolibarr is a separate DB).

**Decision needed from you:** multiprice levels vs 3 separate products; services vs products.

---

## Phase 2+ possibilities — Dolibarr across your whole stack

Dolibarr can become the **back-office system of record** that the customer-facing platforms feed.
Ranked roughly by value/effort:

| # | Dolibarr capability | Connects to | What it gives you |
|---|---|---|---|
| 1 | **Catalog** (products/services) | Repo / Bagisto store | Quote & invoice any solution (Phase 1). |
| 2 | **Third parties + contacts** (CRM) | Bagisto `customers`, Mautic, WordPress leads | One customer record across store, marketing, and billing. |
| 3 | **Proposals / quotes → orders → invoices** | Store + MSP services | Formal quoting for the productized solutions **and** custom MSP work; PDF proposals; convert quote→order→invoice in one flow. |
| 4 | **Order/invoice sync from the store** | Bagisto orders | Store sales land as Dolibarr invoices → real revenue reporting & accounting, not just an e-commerce dashboard. |
| 5 | **Contracts** (recurring service lines + renewal alerts) | Subscriptions pkg, Support add-ons | Manage membership/subscription & support entitlements and **renewals** — the recurring layer Bagisto core lacks. |
| 6 | **Members / `adherents`** | Subscriptions / memberships | Membership tiers, dues, member area — an alternative home for the `PTK-SUB-*` tiers. |
| 7 | **Stripe module** | Stripe (already in use) | Take card payment directly on Dolibarr invoices/quotes; reconcile against Stripe. |
| 8 | **Tickets** | Zammad (helpdesk.phoenixtekk.com), Discourse, support add-ons | Link support tickets to the paying third party + contract for entitlement-aware support. |
| 9 | **Projects & time tracking** | Implementation / support delivery | Track delivery engagements, tasks, time, and **margin** per project. |
| 10 | **Double-entry accounting** | Everything above | Consolidate store + subscription + services revenue; VAT/tax; export packs for your accountant. |
| 11 | **Bank & reconciliation / expenses / suppliers (POs)** | Fleet costs, vendors | Full money-in/money-out picture. |
| 12 | **Email / SMS campaigns** | Mautic, **txtya** | Trigger outreach from CRM events (new lead, expiring contract). |

### Suggested end-state shape

```
Marketing (Mautic/WordPress)  ─▶ leads
Store (Bagisto)               ─▶ customers + orders
                                   │
                                   ▼
                    Dolibarr (crm.phoenixtekk.com) = back office
                    third parties · catalog · quotes · invoices ·
                    contracts/renewals · projects · accounting
                                   │
              Stripe (payment) ◀───┘───▶ Zammad/Discourse (support, entitlement-linked)
```

## Risks / standing rules to honor

- **Secrets:** API key only in `~/.claude/.dolibarr.env`; never committed or printed. Never copy the
  Dolibarr DB creds out of `conf.php`.
- **Billing (per global rule):** Dolibarr + Stripe is a **direct-processor** model — same freeze/hold
  dynamics as any aggregator. For revenue-critical **recurring** billing, weigh a Merchant-of-Record
  (Paddle/Polar) vs Stripe-direct before committing; abstract the processor behind one billing module.
- **Sync direction & conflicts:** start **one-way** (repo → Dolibarr) to avoid clobbering CRM edits;
  only add two-way where a clear owner exists per field.
- **Separate DB:** Dolibarr has its own DB on linuxg5 — integration work cannot affect the store/wiki.

## Next step

Say which Phase 1 mapping you want (multiprice levels vs 3 products) and generate the Dolibarr API
key; I'll build `tools/dolibarr-sync.py`, dry-run it, then sync all 126 solutions. Phases 2+ are
independent and can be picked à la carte.
