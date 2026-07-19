# BILLING — Phoenixtekk Workplace Solutions

## Processor & model in use
- **Store:** Bagisto ~2.3.x at workplace.phoenixtekk.com (linuxg5). Built-in payment packages present:
  **Stripe** (`Webkul\Stripe`, `stripe/stripe-php` 17.6), PayPal, Razorpay, PayU.
- **One-time products** (the 13 solutions / 26 SKUs, all `downloadable`): charged natively by Bagisto
  via the configured processor (Stripe). Working today.
- **Memberships** (3 tiers — Individual $499, Professional $999, Enterprise $1,499/mo; annual at a
  discount): powered by our **custom, provider-agnostic `Phoenixtekk/Subscriptions` package**, active
  processor **Stripe** (hosted Checkout + Billing Portal). MoR (Polar/Paddle) ruled out — they
  prohibit marketplaces. Recurring billing is **deployed (code + tables live)** but **not yet
  activated** — it needs Stripe API keys + a webhook secret (set in admin UI; see below).

## Decision (2026-06-14, revised through the day)
Recurring billing is a **custom, provider-agnostic integration** built in-house as the native Bagisto
package `Phoenixtekk/Subscriptions` (user's choice: "build our own"). **Net decision:**
- **Active processor: Stripe** (direct processor). Reason it isn't a Merchant of Record: **MoR
  providers prohibit marketplaces.** We tried Polar first (for MoR freeze protection), but Polar's
  Acceptable Use Policy bars marketplaces ("Polar is a Merchant of Record for digital products only;
  … marketplaces are not permitted"). Paddle and Lemon Squeezy have the same restriction. So MoR is
  **not viable for this storefront**, and **Polar was removed** (driver/config/UI) on 2026-06-14.
- Stripe permits **both subscriptions and marketplaces** (Stripe Billing + Connect) and is already
  set up. Direct-processor **freeze risk is accepted and mitigated operationally** (see below).
- **The abstraction stays** — provider is selectable in admin config / `BILLING_PROVIDER`, resolved
  through a `providers` map. If a marketplace-friendly MoR ever exists (or we split first-party
  memberships into a separate non-marketplace entity), adding a driver is contained.

### Freeze-risk mitigations (since we're on a direct processor)
- Clear billing descriptor (recognizable to cardholders), easy support contact at checkout.
- Keep chargebacks low; prompt consistent refunds.
- Enable **frequent payouts** so large balances don't sit where they can be frozen.
- Warn Stripe ahead of expected volume spikes / launches.
- **Backup processor built:** a `PayPalBillingProvider` is registered as a second rail (select "PayPal"
  in admin config + enter PayPal keys + run Sync), so a single Stripe freeze can't take billing fully
  offline. Note: PayPal has no hosted billing portal — members manage/cancel on their PayPal account
  (the "Manage billing" link points to PayPal's autopay page); cancellation is immediate, not
  cancel-at-period-end. Webhooks are verified via PayPal's verify-webhook-signature (needs Webhook ID).

Confirmed scope (unchanged): hosted Checkout + hosted Customer/Billing Portal (minimal PCI scope —
card data never touches the server); **gate solution downloads** behind active membership
(`membership.active` middleware + member library); **create products/prices via API**
(`php artisan subscriptions:sync-plans`, provider-aware).

## Architecture (lock-in mitigation — per global billing rule)
- Processor isolated behind ONE interface: `Phoenixtekk\Subscriptions\Contracts\BillingProvider`.
  Each driver (`Billing/PolarBillingProvider` = default, `Billing/StripeBillingProvider` = fallback)
  is the *only* place that talks to its processor **and** normalizes that processor's webhooks into a
  single canonical event shape — so `WebhookController` has zero processor-specific logic.
- Switching providers = set `BILLING_PROVIDER` + that provider's keys, run `subscriptions:sync-plans`,
  point its webhook at `/billing/webhook`. **No code or schema changes.**
- Schema is provider-neutral: every `pt_sub_*` table carries a `provider` column; plans/subscriptions
  are scoped per provider, so a fallback processor can run alongside the primary.
- Tables (prefix `pt_sub_`): `pt_sub_plans`, `pt_sub_subscriptions`, `pt_sub_webhook_events`.

## ⚠️ Risk & lock-in
- **Why MoR default:** direct aggregators (Stripe, PayPal, Square, Adyen) can freeze accounts / hold
  funds on chargeback or volume spikes — inherent to the model. A new launch-stage marketplace on a
  fresh account is exactly that risk profile. Polar/Paddle (MoR) absorb that liability.
- **Lock-in:** low. Recurring + entitlements are our own code and the data model is provider-neutral;
  only each driver is processor-specific. Adding a driver is contained. Migrating stored cards still
  requires a coordinated processor-to-processor transfer (PCI) and triggers re-authorization churn.

## Where secrets live (admin UI, with env fallback)
Provider selection + keys are set in the **admin UI**: Configuration → Sales → **Subscriptions &
Billing**. Values are stored in Bagisto's `core_config` table and read via `Support\Settings`, which
falls back to `.env` when a field is blank.

> **Security tradeoff (flagged per global rule):** UI-entered values are stored in `core_config` in
> **plaintext**, same as Bagisto's own payment-method secrets. This is the convenience cost of "no
> files/vars." Mitigations: restrict admin access; OR keep the most sensitive secret (provider access
> token / secret key) in `.env` and leave that UI field blank (env wins when the field is empty). A
> future hardening option is app-key encryption of these fields at rest.

Equivalent `.env` keys (fallback / optional override), on linuxg5 (`/home/workplace/public_html/.env`):
```
BILLING_PROVIDER=stripe
STRIPE_KEY=pk_live_...
STRIPE_SECRET=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
SUBSCRIPTIONS_CURRENCY=usd       # optional
```
(Bagisto's built-in one-time Stripe payment is configured separately in admin → Sales → Payment methods.)

## To ACTIVATE recurring (Stripe)
1. In the **Workplace Solutions** Stripe account, copy the API keys (Developers → API keys).
2. Admin → Configuration → Sales → **Subscriptions & Billing** → enter Stripe Secret Key (+ Publishable
   Key), Currency → **Save**. (Or set the `.env` keys above and leave UI blank.)
3. Admin → **Subscriptions** → click **Sync plans to Stripe** → creates the 6 products/prices in
   `pt_sub_plans` (provider=stripe).
4. In Stripe, add a webhook endpoint `https://workplace.phoenixtekk.com/billing/webhook`, events:
   `checkout.session.completed`, `customer.subscription.created/updated/deleted`,
   `invoice.payment_failed`; copy its signing secret into admin config (Stripe Webhook Secret) → Save.
5. Test a subscribe → webhook flips local sub to `active` → member library unlocks → cancel via portal.

## Deployment status (2026-06-14)
- Package deployed to live store under `packages/Phoenixtekk/Subscriptions/`, PSR-4 + provider
  registered, `composer dump-autoload` done, migrations applied, routes live.
- Current code: provider-agnostic with **Stripe** as the active (and only registered) processor;
  Polar removed (marketplace AUP). Admin UI provider config + one-click "Sync plans" button.
- Boot-checked healthy: `/`, `/memberships`, `/admin/login` all HTTP 200.
- Controllers resolve `BillingProvider` lazily so public/pricing pages work **without** any provider
  keys; only checkout/portal/webhook require Stripe configured.
