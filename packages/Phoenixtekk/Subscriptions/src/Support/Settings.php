<?php

namespace Phoenixtekk\Subscriptions\Support;

/**
 * Single source of truth for the runtime-selectable billing settings.
 *
 * Reads from Bagisto's admin Configuration (core_config table — written by the admin UI at
 * Configuration → Sales → Subscriptions & Billing), and falls back to .env so an existing env-based
 * setup keeps working. This is what lets the provider + keys be changed entirely in the UI, with no
 * file edits and no redeploy.
 */
class Settings
{
    protected const PREFIX = 'sales.subscriptions.settings.';

    /** Read a single admin-config value (null if unset). */
    protected static function cfg(string $field): ?string
    {
        $value = core()->getConfigData(self::PREFIX . $field);

        return ($value === '' || $value === null) ? null : $value;
    }

    /** Active processor key (e.g. stripe). */
    public static function provider(): string
    {
        return self::cfg('provider')
            ?? env('BILLING_PROVIDER')
            ?? config('subscriptions.provider', 'stripe');
    }

    public static function currency(): string
    {
        return self::cfg('currency')
            ?? env('SUBSCRIPTIONS_CURRENCY')
            ?? config('subscriptions.currency', 'usd');
    }

    /** Class map of provider key => driver (stays in the config file — not user-editable). */
    public static function providerMap(): array
    {
        return config('subscriptions.providers', []);
    }

    public static function stripe(): array
    {
        return [
            'key'            => self::cfg('stripe_key') ?? env('STRIPE_KEY'),
            'secret'         => self::cfg('stripe_secret') ?? env('STRIPE_SECRET'),
            'webhook_secret' => self::cfg('stripe_webhook_secret') ?? env('STRIPE_WEBHOOK_SECRET'),
        ];
    }

    public static function paypal(): array
    {
        return [
            'client_id'  => self::cfg('paypal_client_id') ?? env('PAYPAL_CLIENT_ID'),
            'secret'     => self::cfg('paypal_secret') ?? env('PAYPAL_SECRET'),
            'webhook_id' => self::cfg('paypal_webhook_id') ?? env('PAYPAL_WEBHOOK_ID'),
            'mode'       => self::cfg('paypal_mode') ?? env('PAYPAL_MODE', 'live'),
        ];
    }
}
