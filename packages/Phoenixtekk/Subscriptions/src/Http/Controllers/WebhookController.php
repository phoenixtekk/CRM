<?php

namespace Phoenixtekk\Subscriptions\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Log;
use Phoenixtekk\Subscriptions\Contracts\BillingProvider;
use Phoenixtekk\Subscriptions\Models\Subscription;
use Phoenixtekk\Subscriptions\Models\WebhookEvent;
use Phoenixtekk\Subscriptions\Support\Settings;

/**
 * Receives processor webhooks (no session/CSRF — authenticated by the provider's signature).
 *
 * Provider-agnostic: the active driver verifies its own signature and normalizes the payload into
 * the canonical event shape (see BillingProvider). This controller only knows the canonical shape,
 * so switching processors needs no change here. Idempotent per (provider, event id).
 */
class WebhookController extends Controller
{
    public function handle(Request $request)
    {
        $provider = Settings::provider();
        $billing  = app(BillingProvider::class);

        try {
            $event = $billing->parseWebhook($request);
        } catch (\Throwable $e) {
            return response('Invalid signature', 400);
        }

        if (! $event || ($event['type'] ?? 'ignore') === 'ignore') {
            return response('ok', 200);
        }

        // Idempotency: never process the same event twice.
        if (WebhookEvent::where('provider', $provider)->where('provider_event_id', $event['id'])->exists()) {
            return response('Already processed', 200);
        }
        WebhookEvent::create([
            'provider'          => $provider,
            'provider_event_id' => $event['id'],
            'type'              => $event['type'],
            'processed_at'      => now(),
        ]);

        try {
            $this->apply($provider, $event);
        } catch (\Throwable $e) {
            Log::error('Subscriptions webhook processing error: ' . $e->getMessage());
            return response('Handler error', 500); // provider will retry
        }

        return response('ok', 200);
    }

    /** Apply a canonical event to local subscription state. */
    protected function apply(string $provider, array $event): void
    {
        $s = $event['subscription'] ?? null;
        if (! $s || empty($s['provider_subscription_id'])) {
            return;
        }

        $existing = Subscription::where('provider_subscription_id', $s['provider_subscription_id'])->first();

        // Canceled / revoked — revoke access, keep the row for history.
        if ($event['type'] === 'subscription_canceled') {
            if ($existing) {
                $existing->update(['status' => 'canceled']);
            }
            return;
        }

        // Payment failed — mark past_due (access lapses once the period ends).
        if ($event['type'] === 'payment_failed') {
            if ($existing) {
                $existing->update(['status' => 'past_due']);
            }
            return;
        }

        // Active — upsert. Coalesce nullable fields with any existing record so a sparse event
        // (e.g. checkout.completed before the full subscription object) never wipes known values.
        $customerId = $s['bagisto_customer_id'] ?? $existing?->customer_id;
        if (! $customerId) {
            return; // can't attribute to a Bagisto customer — skip rather than orphan
        }

        Subscription::updateOrCreate(
            ['provider_subscription_id' => $s['provider_subscription_id']],
            [
                'provider'             => $provider,
                'customer_id'          => $customerId,
                'tier'                 => $s['tier'] ?? $existing?->tier ?? 'individual',
                'interval'             => $s['interval'] ?? $existing?->interval,
                'provider_customer_id' => $s['provider_customer_id'] ?? $existing?->provider_customer_id,
                'status'               => $s['status'] ?? 'active',
                'current_period_end'   => isset($s['current_period_end'])
                    ? \Carbon\Carbon::createFromTimestamp($s['current_period_end'])
                    : $existing?->current_period_end,
                'cancel_at_period_end' => (bool) ($s['cancel_at_period_end'] ?? false),
            ]
        );
    }
}
