---
title: Dolibarr Back-Office — Enablement & Operations Runbook
description: Turn on Dolibarr as the back office for the marketplace — catalog sync, quotes→orders→invoices, and contracts/renewals.
published: true
date: 2026-07-02T00:00:00.000Z
tags: dolibarr, crm, erp, runbook, systemdocs, admin
editor: markdown
dateCreated: 2026-07-02T00:00:00.000Z
---

# Dolibarr Back-Office — Enablement & Operations Runbook

Companion to the [integration plan](/SystemDocs/dolibarr-crm-integration-plan). Covers what is
**built as code** vs what is **native Dolibarr configuration**, and the exact steps for each.

| Ask | Form | Status |
|---|---|---|
| Phase 1 — catalog → Dolibarr services | **code** `tools/dolibarr-sync.py` | ✅ built, dry-run verified (needs API key to run live) |
| #3 store orders/customers → third parties + invoices | **code** (future `tools/dolibarr-orders-sync.py`) | ⏳ staged — needs API key **and** real store orders (currently 1 order / 2 customers) |
| #4 quotes → orders → invoices + PDF proposals | **native Dolibarr** | ▶ enable modules + follow workflow below |
| #5 contracts + renewals (subscriptions / support) | **native Dolibarr** | ▶ enable modules + follow workflow below |

---

## 0. One-time prerequisites

1. **Generate an API key.** Dolibarr → Home → Setup → Users & Groups → pick a service user →
   **API key** (Generate). Enable the **API/REST (Web services)** module if not already on.
2. **Store the key locally, never in the repo:** create `~/.claude/.dolibarr.env`:
   ```
   DOLIBARR_URL=https://crm.phoenixtekk.com
   DOLIBARR_API_KEY=<the key>
   ```
   (`tools/dolibarr_client.py` auto-loads this; the key is sent as the `DOLAPIKEY` header and is
   never printed or committed.)
3. **Enable the modules** (Home → Setup → Modules): Products, Services, Proposals (commercial
   proposals), Customer Orders, Customer Invoices, Contracts, Members (Foundation), Stripe,
   optionally Projects.
4. **Turn on multiprice levels** (Setup → Modules → Products → *configure*): set
   *"Several prices per product / service (multiprices)"* = **3 levels**. Label them
   **1 = Commercial, 2 = Non-Profit, 3 = Government** to match the store's 3-tier model.

---

## Phase 1 — sync the catalog (code, built)

```bash
python tools/dolibarr-sync.py --dry-run     # preview (offline, no key) — shows all 126 + tiers
python tools/dolibarr-sync.py               # live upsert (after steps 1–4 above)
```

- Creates/updates one **Service** per solution, `ref = PTK-<SOL>`, idempotent — safe to re-run after
  every publish wave. Prices land on multiprice levels 1/2/3 (Commercial / NPO −40% / Gov −15%).
- `--separate-products` instead makes 3 products per solution keyed on the exact
  `PTK-<SOL>-COMM/NPO/GOV-001` SKUs (use only if you prefer discrete SKUs over price levels).
- Writes only to Dolibarr (separate DB) — zero risk to the store or wiki.

**Assign a customer's price level** on the third party's *Customer* tab → *Price level* = 2 (NPO) or
3 (Gov); their quotes/invoices then auto-use that tier.

---

## #4 — Quotes → Orders → Invoices + PDF (native)

For a productized solution **or** custom MSP work:

1. **Third party** (customer): Third parties → New → fill company; set *Price level* if NPO/Gov.
2. **Commercial Proposal (quote):** Commercial → Proposals → New → pick the customer.
   - Add a **catalog line** → select the synced service (`PTK-<SOL>`); price auto-fills from the
     customer's level.
   - Add **custom MSP lines** as free-text lines with a manual description + price/qty (hours ×
     rate) for bespoke work.
   - **Validate** → generates the numbered PDF proposal (Dolibarr renders it; no code needed).
3. **Convert:** on the validated proposal → *Create order* → then on the order → *Create invoice*.
4. **Invoice → PDF → payment:** validate the invoice (PDF), then record payment — via the **Stripe**
   module you can send a pay link / take card and reconcile.

> Everything here is built into Dolibarr once modules are on and the catalog is synced. No custom code.

---

## #5 — Contracts + Renewals (native)

For the recurring items the store can't bill on its own (`PTK-SUB-*` memberships, `PTK-SUPPORT-*`
add-ons):

- **Contracts module:** Commercial → Contracts → New → link the third party → add **service lines**
  (the synced subscription/support services) with **start / planned-end** dates. Activate the
  services. Dolibarr surfaces **expiring/expired services** on the dashboard for renewal action, and
  can email reminders.
- **Recurring (template) invoices:** Invoices → *Templates/Recurring* → build a template from a
  contract's lines and set the frequency; Dolibarr generates each period's invoice on schedule.
- **Members module** (alternative for memberships): define membership types = your tiers, with dues
  and automatic renewal reminders + an optional member portal.

> **Billing note (standing rule):** Dolibarr + Stripe is a direct-processor model — same freeze/hold
> dynamics as any aggregator. For revenue-critical recurring billing, weigh a Merchant-of-Record
> (Paddle/Polar) before committing, and keep the processor behind one billing abstraction.

---

## #3 — Store orders/customers → Dolibarr (staged code)

When the store goes live and real orders exist, a `tools/dolibarr-orders-sync.py` will read the
Bagisto `workplace` DB (customers + orders) and upsert **third parties** + **customer invoices** in
Dolibarr (idempotent by store order id), so store revenue flows into Dolibarr accounting.

- **Blocked on:** the API key (above) **and** meaningful order volume (today: **1 order, 2
  customers** — pre-launch).
- **Design:** one-way (store → Dolibarr), map Bagisto customer → third party (by email), order lines
  → invoice lines (match on `PTK-<SOL>` ref from Phase 1), record the Stripe payment reference.
- Say the word once the store is live and the key exists, and I'll build + verify it against real data.

---

## Summary

- **Run now (after key + modules):** `tools/dolibarr-sync.py` → 126 services with tiered pricing.
- **Use natively:** proposals → orders → invoices (#4) and contracts/renewals (#5).
- **Later:** store order sync (#3) at go-live.
