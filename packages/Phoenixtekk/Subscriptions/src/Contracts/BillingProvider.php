<?php

namespace Phoenixtekk\Subscriptions\Contracts;

use Illuminate\Http\Request;
use Phoenixtekk\Subscriptions\Models\Plan;
use Webkul\Customer\Models\Customer;

/**
 * The single seam between the app and a payment processor. App/controllers depend only on this;
 * switching processors is a config change (`subscriptions.provider`) — no other code changes.
 *
 * parseWebhook() is the key to that promise: each driver verifies its own signature scheme and
 * NORMALIZES the provider's payload into the canonical event shape below, so the webhook controller
 * never contains processor-specific logic.
 *
 * Canonical event returned by parseWebhook():
 *   [
 *     'id'    => string,                 // unique event id (idempotency key)
 *     'type'  => 'subscription_active'   // membership should be active
 *              | 'subscription_canceled' // access revoked
 *              | 'payment_failed'        // mark past_due
 *              | 'ignore',               // event we don't act on
 *     'subscription' => [                // present unless type === 'ignore'
 *        'provider_subscription_id' => string,
 *        'provider_customer_id'     => ?string,
 *        'bagisto_customer_id'      => ?int,
 *        'tier'                     => ?string,
 *        'interval'                 => ?string,    // month | year
 *        'status'                   => string,     // active|trialing|past_due|canceled
 *        'current_period_end'       => ?int,       // unix timestamp
 *        'cancel_at_period_end'     => bool,
 *     ] | null,
 *   ]
 */
interface BillingProvider
{
    /** Ensure a processor-side customer exists for this Bagisto customer; return its processor id. */
    public function ensureCustomer(Customer $customer, ?string $existingId = null): string;

    /** Create a hosted subscription checkout session; return the URL to redirect the buyer to. */
    public function createCheckoutSession(Customer $customer, string $providerCustomerId, Plan $plan, string $successUrl, string $cancelUrl): string;

    /** Create a hosted self-serve billing/customer portal session; return its URL. */
    public function billingPortalUrl(string $providerCustomerId, string $returnUrl): string;

    /** Schedule cancellation at period end (no immediate loss of access). */
    public function cancelAtPeriodEnd(string $providerSubscriptionId): void;

    /** Verify signature + normalize an inbound webhook into the canonical event (throws on bad signature). */
    public function parseWebhook(Request $request): ?array;

    /** Create a product + a recurring price per interval; return [interval => ['product'=>id,'price'=>id]]. */
    public function createProductWithPrices(string $name, array $intervalAmounts, string $currency): array;
}
