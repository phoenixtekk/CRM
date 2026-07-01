# Changelog

## 1.1.0 — 2026-06-14

Make the package multi-provider; default to a Merchant of Record.

- **Polar** added as the default provider (`Billing/PolarBillingProvider`) — Merchant of Record,
  REST API, Standard Webhooks signature verification. Moves account-freeze risk off us.
- Active provider is now a config/env switch (`BILLING_PROVIDER`) resolved via a `providers` map —
  switching processors is config-only, no code or schema changes.
- Webhooks normalized into a single canonical event shape; `WebhookController` is now
  provider-agnostic (no processor-specific branching).
- Schema made provider-neutral: `provider` column added to all three tables; `stripe_*` columns
  renamed to `provider_*`; plans/subscriptions/events scoped per provider so a fallback can coexist.
- Webhook route renamed `stripe/webhook` → `billing/webhook`.
- `subscriptions:sync-plans` (was `SyncStripePlans`) now targets whatever provider is active.
- Stripe retained as a documented fallback driver; Paddle documented as the next fallback.

## 1.0.0 — 2026-06-14

Initial release.

- Native Bagisto package `Phoenixtekk/Subscriptions` for recurring memberships.
- Stripe Billing integration via hosted Checkout + Billing Portal (minimal PCI scope).
- Processor abstraction: `BillingProvider` contract with `StripeBillingProvider` driver — the only
  class that talks to Stripe.
- Three tiers (Individual, Professional, Enterprise), monthly + annual, defined in config.
- `subscriptions:sync-plans` console command creates Stripe products/prices and stores IDs.
- Signature-verified, idempotent webhook controller normalizing Stripe events into local state.
- `membership.active` middleware + member-only download library gating all solution deliverables.
- Read-only admin subscriptions list.
- Tables: `pt_sub_plans`, `pt_sub_subscriptions`, `pt_sub_webhook_events`.
