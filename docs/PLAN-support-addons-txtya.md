---
title: Workplace Marketplace — Support Add-ons, TxtYa, Client Workspace & Ticketing (Plan)
description: Design/plan for paid support add-ons, TxtYa omni-channel chat, a persistent client file-exchange workspace, and support ticketing with effort tracking. Plan only — build in a separate session.
published: true
date: 2026-06-29T00:00:00.000Z
tags: marketplace, support, txtya, ticketing, plan, bagisto
editor: markdown
dateCreated: 2026-06-29T00:00:00.000Z
---

# Workplace Marketplace — Support, TxtYa, Client Workspace & Ticketing (Plan)

> **Status: PLAN ONLY.** This captures the design so a future build session can execute it. Nothing
> here is built yet. Owner builds in a separate session.

## 1. Goals (what we're trying to achieve)

1. **Guarantee deliverables are always included** — close the Bagisto "optional downloadable-link
   checkbox" footgun so a buyer can never check out without their files.
2. **Sell paid support** as add-ons on each solution (chat support, priority implementation support,
   live calls), one-time and/or recurring.
3. **Provide chat support over TxtYa** so the customer uses whatever messaging app they prefer
   (SMS / WhatsApp / Teams / Slack / Telegram / Discord / web) while we operate from one place.
4. **Give every customer a persistent, secure Client Workspace** — a shared file-exchange "box" where
   the customer and the admin can upload/download files and content at any time (see §5; this is the
   improved version of the "Custom Box" idea).
5. **Track support effort** — auto-create support tickets, log time/effort, capture comments and
   history, with status/SLA (see §6).

All of this **reuses the existing purchase → entitlement plumbing** already built for Wiki.js doc
gating (`tools/wiki-provision.py` model) and the **private-disk** storage pattern used for paid
downloadables. Billing rides the existing **Stripe** rail (one-time) and the in-house
**Subscriptions** package (recurring) — processor stays abstracted per the global billing rule.

---

## 2. Background — why the "+ $0.00" checkboxes appear (the current concern)

A Bagisto **downloadable product** delivers its files via **Downloadable Links**. The storefront
renders each link as a **selectable, priced checkbox** (so "Implementation Guide (PDF) + $0.00").
Bagisto treats links as individually *purchasable* options and has **no native "required / always
included" flag**.

**Risk:** a customer can check out without selecting the links → they pay but the order carries no
downloadable file. This must be fixed independently of the support work.

---

## 3. Phase 0 — Guarantee deliverables (quick win, do first)

Pick one (recommended: do both A + B):

- **A. Bundle to a single always-included link.** Replace the two links (PDF + Scripts ZIP) with one
  **"Complete Solution Package (.zip)"** containing the PDF, the Word .docx, and the scripts — one
  thing to select, nothing to miss. (The loader already builds these deliverables; bundling is a
  packaging change + a one-time `--update-content` re-attach.)
- **B. Theme: force-include the deliverable links.** Customize the product/checkout theme so the
  solution's own deliverable links are **auto-selected and read-only (or hidden)** — they're inherent
  to the product, never deselectable. This is what makes "optional checkbox" stop being a footgun.

> After Phase 0, the *only* optional checkboxes a customer sees are the **paid support add-ons** (§4),
> which is exactly what that UI should be for.

---

## 4. Phase 1 — Paid support add-ons

Model support tiers as purchasable items attached to each solution. Three routes (increasing
effort / polish):

- **Route A — native, fastest:** each support tier is its own **priced downloadable link** on the
  product (e.g. *"30-Day Chat Support — $199"*, *"Priority Implementation Support — $499"*,
  *"Live Implementation Call (60 min) — $250"*). The "file" each link delivers is a short
  **"How to start your support session"** PDF containing the TxtYa join link + instructions. Zero new
  code; reuses the existing UI.
- **Route B — cleaner:** support tiers as **separate products** (or a grouped/bundle product)
  cross-sold on each solution page. Better fulfillment/UX control.
- **Route C — best UX:** a small **custom Bagisto module** adding a dedicated "Support & Services"
  selector on the product page, writing chosen add-ons onto the order and triggering fulfillment.

**Recommendation:** ship **Route A** first (value now, no module), evolve to **Route C** in Phase 3.

**Pricing/billing:** one-time tiers on **Stripe**; a recurring **"Support Retainer"** uses the
in-house **Subscriptions** package. Keep SKUs mapped to entitlement windows + SLA.

---

## 5. Client Workspace — secure shared file exchange (the improved "Custom Box")

**What you asked for:** a persistent place where the customer can always upload/share files and
content, and where admin ↔ customer can exchange files.

**Improved concept — "Client Workspace":** a per-customer, authenticated area in the storefront
account (e.g. `/account/workspace`) that is **always available once logged in**, containing:

- **Secure File Exchange** — bidirectional upload/download between the customer and the admin/support
  team. Files stored on the **private disk** (same pattern as paid downloadables — never world-readable),
  scoped to that customer only, with size/type limits and an audit trail (who uploaded what, when).
- **Per-engagement folders** — optionally one folder per purchased solution / support engagement, so
  uploads (logs, screenshots, exported configs) attach to the right context and the right ticket (§6).
- **Always-on, not time-boxed** — the workspace persists for the life of the account (unlike a
  time-limited support window), so customers always have a place to drop content and retrieve shared
  files. Support *chat* (§7) and *tickets* (§6) can be entitlement-gated, but the file box stays.
- **Admin side** — staff see each customer's workspace from the Bagisto admin (or the helpdesk, §6),
  can post files back (e.g. a tailored script, a remediation export), and get notified on new uploads.

**Why this shape (vs. a raw "box"):** tying the file exchange to the **customer account + engagement
+ ticket** gives context, security scoping, and an audit trail — instead of a loose shared drive. It
reuses the private-disk + entitlement model we already trust for paywalled files.

**Build options:**
- **Native Bagisto module** (recommended for tight integration): a `workspace_files` table
  (customer_id, engagement/order_id, ticket_id, path, uploaded_by, size, mime, created_at), private-disk
  storage, account-area UI, admin UI, notifications. Most control, stays in the marketplace.
- **Integrate the helpdesk's attachments** (§6): if the chosen helpdesk has a customer portal with
  file upload, the "file exchange" can live there. Less to build, but the box is then in the helpdesk
  UI, not the store account. (Can do both: store account links to the helpdesk portal.)
- **Avoid** standing up a per-customer Nextcloud/cloud-drive — heavier to operate and harder to gate
  than a focused module.

**Security:** private disk only; per-customer authorization checks on every read/write; cap file size
and block executable/script MIME from customer→admin direction unless explicitly allowed; virus-scan
on upload (ClamAV on the host) before staff download; full audit log.

---

## 6. Support ticketing, effort tracking, logging & comments

**Recommendation: integrate a purpose-built open-source helpdesk rather than building ticketing from
scratch in Bagisto.** Two strong self-hostable fits for the linuxg* fleet:

- **FreeScout** — free, open-source, lightweight; mailbox + modules for **Time Tracking**, API,
  Telegram/WhatsApp/chat integrations. Easiest to stand up.
- **Zammad** — open-source, richer: SLAs, **time accounting**, triggers/automation, strong API,
  multi-channel. Heavier but more capable.

(If a fully-native experience is later required, a Bagisto ticket module is possible — tickets,
comments, status, assignee, `time_entries` — but it duplicates what these tools already do well.)

**How it ties together:**
- **Auto-create tickets:** on a **paid support order** (Bagisto order-paid event) → create a ticket in
  the helpdesk via its API, pre-filled with the customer, the purchased solution/SKU, the entitlement
  window, and a link to their Client Workspace (§5). Also auto-create/append a ticket on any **inbound
  TxtYa message** (§7) so every conversation is tracked.
- **Effort tracking:** use the helpdesk's **time-log / time-accounting** per ticket (billable vs
  non-billable), feeding reporting and any retainer burn-down.
- **Logging & comments:** native to the helpdesk — full thread history, internal notes, staff
  comments, status (open/pending/closed), assignee, tags, SLA timers.
- **Entitlement gate:** reuse the **purchase → access** model (the `wiki-provision.py` pattern) to
  open/close support eligibility and to expire time-boxed windows; a scheduled job closes expired
  threads and flags retainer renewals.

---

## 7. TxtYa — omni-channel chat layer

TxtYa lets the customer use any messaging app while we operate from one place.

- **On support purchase:** order-paid event handler calls the **TxtYa API** to register the customer
  contact + open a conversation, store the conversation id on the order/ticket, and email the customer
  a **"start chat" link** (routes to their preferred app).
- **Inbound routing:** TxtYa → webhook → create/append the **helpdesk ticket** (§6) and, where
  relevant, the **Client Workspace** engagement (§5), so chat, tickets, files, and effort all share one
  customer/engagement context.
- **Optional web widget:** embed a TxtYa web-chat widget on a gated `/support` page (entitlement-checked).
- **Tiering/SLA:** map SKU/add-on → TxtYa routing (priority queue, business-hours vs 24/7) and the
  helpdesk SLA.
- **Secrets:** TxtYa API key in env only (never committed), like every other integration.

---

## 8. Shared data model & entitlement (reuse what exists)

- **Entitlement source of truth:** the Bagisto store DB (paid `orders`/`order_items`, active
  `pt_sub_subscriptions`) — already the basis for Wiki.js gating. Add support/workspace entitlements to
  the same reconciliation.
- **Reconciler:** extend the `wiki-provision.py` pattern into a generic **`entitlement-sync`** that
  grants/revokes: Wiki.js doc access (existing) + support eligibility (helpdesk) + TxtYa conversation +
  Client Workspace access, and expires time-boxed windows.
- **Keys/IDs to persist on the order/ticket:** TxtYa conversation id, helpdesk ticket id, workspace
  folder id, entitlement window (start/end), SLA tier.
- **Storage:** private disk for all customer files (never the public, web-symlinked disk).

---

## 9. Phasing (suggested for the build session)

- **Phase 0 — Deliverables guarantee.** Bundle + force-include deliverable links. *Independent; do first.*
- **Phase 1 — Support add-ons (Route A).** Priced links + TxtYa-instructions PDF. Value, no module.
- **Phase 2 — TxtYa API integration.** Order-paid event → open conversation + email join link;
  inbound webhook → ticket; entitlement + expiry via the existing access model.
- **Phase 3 — Helpdesk + effort tracking.** Stand up FreeScout/Zammad on a linuxg host; auto-create
  tickets; time-logging; comments/SLA; TxtYa as a channel.
- **Phase 4 — Client Workspace module.** Native account-area secure file exchange (private disk,
  per-customer scope, audit trail, admin side, notifications), linked to engagements/tickets.
- **Phase 5 — Polish.** Custom "Support & Services" product UI (Route C), gated web-chat widget,
  retainer burn-down + renewal automation, admin dashboard of active sessions.

---

## 10. Open questions to settle before building

1. **TxtYa API/webhooks** — confirm a public REST API + inbound webhooks (endpoints, auth, contact +
   conversation model). This gates Phases 2/7.
2. **Pricing model** — one-time support windows vs recurring retainer (or both)? Window lengths + SLA
   per tier?
3. **Scope of support** — per-solution vs account-wide entitlement?
4. **Helpdesk choice** — FreeScout (lean) vs Zammad (rich)? Which linuxg host (check
   `~/.claude/server-inventory.md` for a free port/host before standing it up)?
5. **Client Workspace** — always-free for all customers, or gated to buyers? File size/type limits?
   Virus-scan requirement (ClamAV) before staff download?
6. **Staffing** — who answers, routing rules, business hours, escalation?
7. **Billing** — one-time on Stripe vs retainer on the Subscriptions package; keep processor abstracted.

---

## 11. Security & compliance notes (carry into build)

- All customer files on the **private disk**; per-customer authorization on every access; audit trail.
- Virus-scan customer uploads before staff download; constrain MIME/size.
- Secrets (TxtYa key, helpdesk API key) in env only — never committed, never in `NEXT_PUBLIC_*`/client.
- Reuse the verified paywall posture (paid files are **not** anonymously downloadable).
- Stand up any new service per the fleet rules: read `~/.claude/server-inventory.md` first, pick a
  free port, bind behind the existing Cloudflare → reverse proxy, update the inventory after.
