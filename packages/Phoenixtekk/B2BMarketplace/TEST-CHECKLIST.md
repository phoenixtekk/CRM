# Manual Test Checklist — Phoenixtekk B2B Marketplace v1.0

Run after install (`migrate` + `optimize:clear`). Use a storefront customer account and an admin account.

## Boot / install
- [ ] Site still loads (storefront home + admin) — no white screen after registering the provider.
- [ ] `php8.4 artisan migrate` created all 8 `pt_b2b_*` tables.
- [ ] `php8.4 artisan route:list --path=b2b` lists the admin + shop routes.

## Workflow 1 — Supplier registration
- [ ] Logged-in customer opens `/b2b/supplier/register`, submits the form.
- [ ] Application saved with status **pending**; a `pt_b2b_supplier_users` owner row is created.
- [ ] Visiting `/b2b/supplier/dashboard` shows the **pending** state (no dashboard actions).
- [ ] Submitting a second application does not create a duplicate (blocked).

## Workflow 2 — Admin approval
- [ ] Admin opens **B2B Marketplace → Suppliers**; the pending application is listed.
- [ ] Admin opens it and clicks **Approve**; status becomes **approved**, approved_by/approved_at set.
- [ ] Reject / Suspend / Reactivate each change status correctly (reject stores a reason).

## Workflow 3 — Company account
- [ ] Customer opens `/b2b/company`, creates a company (becomes **owner**).
- [ ] Owner adds a user by email with a role; the user appears in the members list.
- [ ] Owner removes a non-owner user; the owner cannot be removed.

## Workflow 4 — RFQ creation
- [ ] Company user opens `/b2b/rfqs/create`, adds ≥1 line item, clicks **Submit to suppliers**.
- [ ] RFQ persists with items; status **submitted**; visible at `/b2b/rfqs`.

## Workflow 5 — Supplier quote
- [ ] Approved supplier sees the RFQ under **Open RFQs** on the dashboard.
- [ ] Supplier opens it and submits a quote; RFQ status becomes **quoted**.
- [ ] Buyer sees the quote on the RFQ detail page.

## Security
- [ ] A pending (not approved) supplier gets 403 on `/b2b/supplier/rfqs/{id}/quote`.
- [ ] A customer cannot view another customer's RFQ (403) or another company's data.
- [ ] Admin routes require admin auth; `/b2b/*` storefront routes require customer auth.
- [ ] Invalid form input is rejected by validation (e.g. RFQ with no items, bad email).
