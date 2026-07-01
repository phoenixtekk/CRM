# Phoenixtekk Subscriptions & Billing

A native Bagisto package providing recurring memberships. **Provider-agnostic** by design: the active
payment processor is a config switch, not a code change. **Active processor: Stripe** (Billing).

> **Why not a Merchant of Record?** We preferred an MoR (Polar) for freeze protection, but MoR
> providers (Polar, Paddle, Lemon Squeezy) **prohibit marketplaces** in their Acceptable Use Policies,
> so they're not viable for this storefront. **Polar was removed (2026-06-14).** Stripe permits both
> subscriptions and marketplaces; direct-processor freeze risk is mitigated operationally (see
> BILLING.md). The abstraction remains, so a marketplace-friendly processor can be added later.

Uses **hosted Checkout + a hosted Billing Portal**, so card data never touches this server. Active
members get gated access to the full solution download library.

## Configuring / switching providers (no files, no redeploy)
Everything is set in the **admin UI**: Configuration → Sales → **Subscriptions & Billing**.
1. Pick the **Active Payment Provider** and **Save**.
2. Enter that provider's keys (masked password fields) and **Save**.
3. Admin → **Subscriptions** → click **Sync plans** to create that provider's products/prices
   (or run `php artisan subscriptions:sync-plans`).
4. Point the provider's webhook at `/billing/webhook`.

No schema or code changes. Plans, subscriptions, and webhook-event rows all carry a `provider` column,
so a fallback processor can coexist with the primary.

Values are stored in Bagisto's `core_config` table and read via `Support\Settings`, which falls back
to `.env` (`BILLING_PROVIDER`, `POLAR_*`, `STRIPE_*`) when a field is blank — so an env-based setup
still works and can be migrated to the UI field-by-field.

> **Security note:** like Bagisto's native payment-method keys, values entered in the UI are stored in
> `core_config` in plaintext. Restrict admin access. If you need encryption at rest or a secrets
> manager, keep the most sensitive secret (the provider access token / secret key) in `.env` instead —
> the UI field left blank falls back to env.

## Architecture
App/controllers depend only on `Contracts/BillingProvider`. Each driver is the *only* place that
talks to its processor, AND normalizes that processor's webhooks into one canonical event shape — so
the webhook controller contains zero processor-specific logic.

```
Contracts/BillingProvider.php       ← the only interface app code touches
Billing/PolarBillingProvider.php    ← default (Merchant of Record); REST API, Standard Webhooks
Billing/StripeBillingProvider.php   ← fallback (direct processor)
Services/MembershipService.php      ← "is this customer an active member?"
Http/Middleware/EnsureActiveMembership.php
Http/Controllers/Shop/SubscriptionController.php   ← pricing, checkout, portal
Http/Controllers/Shop/MemberLibraryController.php  ← gated downloads
Http/Controllers/WebhookController.php             ← provider-agnostic, idempotent
Console/Commands/SyncPlans.php                     ← creates the active provider's products/prices
```

## Tables (prefix `pt_sub_`)
- `pt_sub_plans` — provider × tier × interval → provider product/price ids + amount
- `pt_sub_subscriptions` — a customer's subscription: provider, status, period end, cancel flag
- `pt_sub_webhook_events` — processed (provider, event id) pairs (idempotency)

## Configuration (secrets in `.env` ONLY — never committed / never client-side)

```
BILLING_PROVIDER=polar

# Polar (default — Merchant of Record). Use a sandbox token + server first.
POLAR_ACCESS_TOKEN=polar_oat_...
POLAR_WEBHOOK_SECRET=whsec_...
POLAR_ORGANIZATION_ID=...        # optional; inferred from an org-scoped token
POLAR_SERVER=sandbox             # 'sandbox' for test, 'production' for live

# Stripe (fallback). Only needed if BILLING_PROVIDER=stripe.
STRIPE_KEY=pk_test_...
STRIPE_SECRET=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

SUBSCRIPTIONS_CURRENCY=usd       # optional
```

Tier pricing is in `Config/subscriptions.php` (amounts in cents).

## Setup (Polar, test/sandbox first)
1. In Polar, create a **sandbox** Organization Access Token; set `POLAR_ACCESS_TOKEN`, `POLAR_SERVER=sandbox`.
2. `php artisan subscriptions:sync-plans` → creates Polar products/prices, fills `pt_sub_plans`.
3. In Polar, add a webhook endpoint → `https://<domain>/billing/webhook`, subscribe to the
   `subscription.*` events; copy the signing secret into `POLAR_WEBHOOK_SECRET`.
4. `php artisan migrate` (if not already), `php artisan optimize:clear`.
5. Test a checkout, confirm the webhook flips the local subscription to `active` and the library unlocks.

## Routes
- `GET  /memberships` — public pricing (`shop.subscriptions.pricing`)
- `POST /memberships/checkout` — start hosted Checkout (auth)
- `GET  /memberships/success` — processor return URL
- `GET  /memberships/my-membership` — status + manage (auth)
- `GET  /memberships/portal` — redirect to the hosted Customer/Billing Portal (auth)
- `GET  /memberships/library` — member library (active membership required)
- `GET  /memberships/library/download/{link}` — stream a deliverable (active membership required)
- `POST /billing/webhook` — processor webhook (no CSRF; signature-verified by the active driver)
- `GET  /admin/subscriptions` — admin read-only list

## Gating downloads
Protect any storefront route with the `membership.active` middleware. Logged-out users are sent to
sign in; non-members are redirected to the pricing page.

## Adding Paddle (or any provider) later
1. Add `Billing/PaddleBillingProvider implements BillingProvider` (implement the 6 methods; normalize
   its webhooks to the canonical event in `parseWebhook`).
2. Register it in `config('subscriptions.providers')`.
3. Set `BILLING_PROVIDER=paddle` + its keys, run `subscriptions:sync-plans`, point its webhook at
   `/billing/webhook`. Nothing else changes.
