<?php

namespace Phoenixtekk\Subscriptions\Billing;

use Illuminate\Http\Request;
use Phoenixtekk\Subscriptions\Contracts\BillingProvider;
use Phoenixtekk\Subscriptions\Models\Plan;
use Phoenixtekk\Subscriptions\Support\Settings;
use Stripe\StripeClient;
use Stripe\Webhook;
use Webkul\Customer\Models\Customer;

/**
 * Stripe implementation of the billing contract. The ONLY class that talks to Stripe.
 * Uses hosted Checkout + Billing Portal, so card data never reaches this server.
 *
 * The active processor for this storefront (MoR providers prohibit marketplaces — see BILLING.md).
 */
class StripeBillingProvider implements BillingProvider
{
    protected StripeClient $stripe;

    protected string $webhookSecret;

    public function __construct()
    {
        $cfg = Settings::stripe();

        if (empty($cfg['secret'])) {
            throw new \RuntimeException('Stripe Secret Key is not configured (admin → Configuration → Sales → Subscriptions & Billing).');
        }

        $this->stripe        = new StripeClient($cfg['secret']);
        $this->webhookSecret = (string) ($cfg['webhook_secret'] ?? '');
    }

    public function ensureCustomer(Customer $customer, ?string $existingId = null): string
    {
        if ($existingId) {
            return $existingId;
        }

        $created = $this->stripe->customers->create([
            'email'    => $customer->email,
            'name'     => trim(($customer->first_name ?? '') . ' ' . ($customer->last_name ?? '')) ?: $customer->email,
            'metadata' => ['bagisto_customer_id' => (string) $customer->id],
        ]);

        return $created->id;
    }

    public function createCheckoutSession(Customer $customer, string $providerCustomerId, Plan $plan, string $successUrl, string $cancelUrl): string
    {
        $session = $this->stripe->checkout->sessions->create([
            'mode'                  => 'subscription',
            'customer'              => $providerCustomerId,
            'line_items'            => [[
                'price'    => $plan->provider_price_id,
                'quantity' => 1,
            ]],
            'success_url'           => $successUrl,
            'cancel_url'            => $cancelUrl,
            'allow_promotion_codes' => true,
            'metadata'              => [
                'bagisto_customer_id' => (string) $customer->id,
                'tier'                => $plan->tier,
                'interval'            => $plan->interval,
            ],
            'subscription_data'     => [
                'metadata' => [
                    'bagisto_customer_id' => (string) $customer->id,
                    'tier'                => $plan->tier,
                    'interval'            => $plan->interval,
                ],
            ],
        ]);

        return $session->url;
    }

    public function billingPortalUrl(string $providerCustomerId, string $returnUrl): string
    {
        $session = $this->stripe->billingPortal->sessions->create([
            'customer'   => $providerCustomerId,
            'return_url' => $returnUrl,
        ]);

        return $session->url;
    }

    public function cancelAtPeriodEnd(string $providerSubscriptionId): void
    {
        $this->stripe->subscriptions->update($providerSubscriptionId, ['cancel_at_period_end' => true]);
    }

    public function parseWebhook(Request $request): ?array
    {
        $event = Webhook::constructEvent(
            $request->getContent(),
            $request->header('Stripe-Signature', ''),
            $this->webhookSecret
        );

        $object = $event->data->object;

        switch ($event->type) {
            case 'checkout.session.completed':
                if (empty($object->subscription)) {
                    return ['id' => $event->id, 'type' => 'ignore', 'subscription' => null];
                }
                return [
                    'id'           => $event->id,
                    'type'         => 'subscription_active',
                    'subscription' => [
                        'provider_subscription_id' => $object->subscription,
                        'provider_customer_id'     => $object->customer ?? null,
                        'bagisto_customer_id'      => (int) ($object->metadata->bagisto_customer_id ?? 0) ?: null,
                        'tier'                     => $object->metadata->tier ?? null,
                        'interval'                 => $object->metadata->interval ?? null,
                        'status'                   => 'active',
                        'current_period_end'       => null,
                        'cancel_at_period_end'     => false,
                    ],
                ];

            case 'customer.subscription.created':
            case 'customer.subscription.updated':
            case 'customer.subscription.deleted':
                $priceId = $object->items->data[0]->price->id ?? null;
                $plan    = $priceId ? Plan::where('provider', 'stripe')->where('provider_price_id', $priceId)->first() : null;
                $status  = $event->type === 'customer.subscription.deleted' ? 'canceled' : $object->status;

                return [
                    'id'           => $event->id,
                    'type'         => $status === 'canceled' ? 'subscription_canceled' : 'subscription_active',
                    'subscription' => [
                        'provider_subscription_id' => $object->id,
                        'provider_customer_id'     => $object->customer ?? null,
                        'bagisto_customer_id'      => (int) ($object->metadata->bagisto_customer_id ?? 0) ?: null,
                        'tier'                     => $plan->tier ?? ($object->metadata->tier ?? null),
                        'interval'                 => $plan->interval ?? ($object->metadata->interval ?? null),
                        'status'                   => $status,
                        'current_period_end'       => $object->current_period_end ?? null,
                        'cancel_at_period_end'     => (bool) ($object->cancel_at_period_end ?? false),
                    ],
                ];

            case 'invoice.payment_failed':
                if (empty($object->subscription)) {
                    return ['id' => $event->id, 'type' => 'ignore', 'subscription' => null];
                }
                return [
                    'id'           => $event->id,
                    'type'         => 'payment_failed',
                    'subscription' => [
                        'provider_subscription_id' => $object->subscription,
                        'provider_customer_id'     => $object->customer ?? null,
                        'bagisto_customer_id'      => null,
                        'tier'                     => null,
                        'interval'                 => null,
                        'status'                   => 'past_due',
                        'current_period_end'       => null,
                        'cancel_at_period_end'     => false,
                    ],
                ];

            default:
                return ['id' => $event->id, 'type' => 'ignore', 'subscription' => null];
        }
    }

    public function createProductWithPrices(string $name, array $intervalAmounts, string $currency): array
    {
        $product = $this->stripe->products->create(['name' => $name]);

        $result = [];
        foreach ($intervalAmounts as $interval => $amount) {
            $price = $this->stripe->prices->create([
                'product'     => $product->id,
                'unit_amount' => $amount,
                'currency'    => $currency,
                'recurring'   => ['interval' => $interval], // 'month' | 'year'
            ]);
            $result[$interval] = ['product' => $product->id, 'price' => $price->id];
        }

        return $result;
    }
}
