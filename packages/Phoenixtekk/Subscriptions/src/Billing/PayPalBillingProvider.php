<?php

namespace Phoenixtekk\Subscriptions\Billing;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Phoenixtekk\Subscriptions\Contracts\BillingProvider;
use Phoenixtekk\Subscriptions\Models\Plan;
use Phoenixtekk\Subscriptions\Support\Settings;
use Webkul\Customer\Models\Customer;

/**
 * PayPal implementation of the billing contract — the backup processor (redundancy so a single Stripe
 * freeze can't take billing fully offline). Uses PayPal's Subscriptions API (Catalog Products + Billing
 * Plans + Subscriptions) with hosted approval, so card data never touches this server.
 *
 * No SDK dependency — REST via the Laravel HTTP client. Webhooks are verified by PayPal's
 * verify-webhook-signature endpoint (requires the configured Webhook ID).
 */
class PayPalBillingProvider implements BillingProvider
{
    protected string $base;
    protected string $clientId;
    protected string $secret;
    protected string $webhookId;

    public function __construct()
    {
        $cfg = Settings::paypal();

        $this->clientId  = (string) ($cfg['client_id'] ?? '');
        $this->secret    = (string) ($cfg['secret'] ?? '');
        $this->webhookId  = (string) ($cfg['webhook_id'] ?? '');

        if ($this->clientId === '' || $this->secret === '') {
            throw new \RuntimeException('PayPal Client ID / Secret is not configured (admin → Configuration → Sales → Subscriptions & Billing).');
        }

        $this->base = ($cfg['mode'] ?? 'live') === 'sandbox'
            ? 'https://api-m.sandbox.paypal.com'
            : 'https://api-m.paypal.com';
    }

    /** OAuth2 client-credentials access token. */
    protected function token(): string
    {
        $res = Http::asForm()
            ->withBasicAuth($this->clientId, $this->secret)
            ->acceptJson()
            ->post($this->base . '/v1/oauth2/token', ['grant_type' => 'client_credentials']);

        $res->throw();

        return $res->json('access_token');
    }

    protected function client()
    {
        return Http::withToken($this->token())->acceptJson()->baseUrl($this->base);
    }

    /** PayPal has no pre-checkout customer object; the subscriber is supplied at subscription creation. */
    public function ensureCustomer(Customer $customer, ?string $existingId = null): string
    {
        return $existingId ?: (string) $customer->id;
    }

    public function createCheckoutSession(Customer $customer, string $providerCustomerId, Plan $plan, string $successUrl, string $cancelUrl): string
    {
        // provider_price_id holds the PayPal Billing Plan id.
        $res = $this->client()->post('/v1/billing/subscriptions', [
            'plan_id'   => $plan->provider_price_id,
            'custom_id' => (string) $customer->id, // our anchor back to the Bagisto customer
            'subscriber' => [
                'email_address' => $customer->email,
                'name' => [
                    'given_name' => $customer->first_name ?: $customer->email,
                    'surname'    => $customer->last_name ?: '',
                ],
            ],
            'application_context' => [
                'brand_name'  => config('app.name', 'Phoenixtekk'),
                'user_action' => 'SUBSCRIBE_NOW',
                'return_url'  => $successUrl,
                'cancel_url'  => $cancelUrl,
            ],
        ]);

        $res->throw();

        foreach ($res->json('links', []) as $link) {
            if (($link['rel'] ?? '') === 'approve') {
                return $link['href'];
            }
        }

        throw new \RuntimeException('PayPal did not return an approval link.');
    }

    /** PayPal has no per-merchant portal URL; subscribers manage subscriptions on their PayPal account. */
    public function billingPortalUrl(string $providerCustomerId, string $returnUrl): string
    {
        return ($this->base === 'https://api-m.sandbox.paypal.com')
            ? 'https://www.sandbox.paypal.com/myaccount/autopay/'
            : 'https://www.paypal.com/myaccount/autopay/';
    }

    public function cancelAtPeriodEnd(string $providerSubscriptionId): void
    {
        // PayPal cancellation stops future billing (no native cancel-at-period-end).
        $this->client()
            ->post("/v1/billing/subscriptions/{$providerSubscriptionId}/cancel", ['reason' => 'Customer requested cancellation'])
            ->throw();
    }

    public function parseWebhook(Request $request): ?array
    {
        $body  = json_decode($request->getContent(), true) ?: [];

        // Verify the event with PayPal (requires the configured Webhook ID).
        if ($this->webhookId === '') {
            throw new \RuntimeException('PayPal Webhook ID is not configured.');
        }

        $verify = $this->client()->post('/v1/notifications/verify-webhook-signature', [
            'auth_algo'         => $request->header('paypal-auth-algo'),
            'cert_url'          => $request->header('paypal-cert-url'),
            'transmission_id'   => $request->header('paypal-transmission-id'),
            'transmission_sig'  => $request->header('paypal-transmission-sig'),
            'transmission_time' => $request->header('paypal-transmission-time'),
            'webhook_id'        => $this->webhookId,
            'webhook_event'     => $body,
        ]);

        if (! $verify->successful() || $verify->json('verification_status') !== 'SUCCESS') {
            throw new \RuntimeException('PayPal webhook signature verification failed.');
        }

        $eventId  = $body['id'] ?? md5($request->getContent());
        $type     = $body['event_type'] ?? '';
        $resource = $body['resource'] ?? [];

        // Only subscription lifecycle + payment-failure events matter.
        $canonical = match (true) {
            str_contains($type, 'SUBSCRIPTION.ACTIVATED'),
            str_contains($type, 'SUBSCRIPTION.UPDATED'),
            str_contains($type, 'SUBSCRIPTION.RE-ACTIVATED') => 'subscription_active',
            str_contains($type, 'SUBSCRIPTION.CANCELLED'),
            str_contains($type, 'SUBSCRIPTION.EXPIRED'),
            str_contains($type, 'SUBSCRIPTION.SUSPENDED')    => 'subscription_canceled',
            str_contains($type, 'PAYMENT.FAILED')            => 'payment_failed',
            default                                          => 'ignore',
        };

        if ($canonical === 'ignore' || empty($resource['id'])) {
            return ['id' => $eventId, 'type' => 'ignore', 'subscription' => null];
        }

        $planId = $resource['plan_id'] ?? null;
        $plan   = $planId ? Plan::where('provider', 'paypal')->where('provider_price_id', $planId)->first() : null;

        $status   = strtoupper($resource['status'] ?? '');
        $localSt  = match ($status) {
            'ACTIVE'    => 'active',
            'SUSPENDED' => 'past_due',
            default     => 'canceled',
        };

        $nextBill = $resource['billing_info']['next_billing_time'] ?? null;

        return [
            'id'           => $eventId,
            'type'         => $canonical,
            'subscription' => [
                'provider_subscription_id' => $resource['id'],
                'provider_customer_id'     => $resource['subscriber']['payer_id'] ?? null,
                'bagisto_customer_id'      => isset($resource['custom_id']) ? (int) $resource['custom_id'] : null,
                'tier'                     => $plan->tier ?? null,
                'interval'                 => $plan->interval ?? null,
                'status'                   => $canonical === 'payment_failed' ? 'past_due' : $localSt,
                'current_period_end'       => $nextBill ? strtotime($nextBill) : null,
                'cancel_at_period_end'     => false,
            ],
        ];
    }

    public function createProductWithPrices(string $name, array $intervalAmounts, string $currency): array
    {
        $result = [];

        foreach ($intervalAmounts as $interval => $amount) {
            // 1) Catalog product
            $product = $this->client()->post('/v1/catalogs/products', [
                'name'     => "{$name} ({$interval}ly)",
                'type'     => 'SERVICE',
                'category' => 'SOFTWARE',
            ]);
            $product->throw();
            $productId = $product->json('id');

            // 2) Billing plan with one regular recurring cycle
            $plan = $this->client()->post('/v1/billing/plans', [
                'product_id' => $productId,
                'name'       => "{$name} ({$interval}ly)",
                'status'     => 'ACTIVE',
                'billing_cycles' => [[
                    'frequency'      => ['interval_unit' => strtoupper($interval), 'interval_count' => 1],
                    'tenure_type'    => 'REGULAR',
                    'sequence'       => 1,
                    'total_cycles'   => 0, // infinite until cancelled
                    'pricing_scheme' => ['fixed_price' => [
                        'value'         => number_format($amount / 100, 2, '.', ''),
                        'currency_code' => strtoupper($currency),
                    ]],
                ]],
                'payment_preferences' => [
                    'auto_bill_outstanding'     => true,
                    'setup_fee_failure_action'  => 'CONTINUE',
                    'payment_failure_threshold' => 1,
                ],
            ]);
            $plan->throw();

            $result[$interval] = ['product' => $productId, 'price' => $plan->json('id')];
        }

        return $result;
    }
}
