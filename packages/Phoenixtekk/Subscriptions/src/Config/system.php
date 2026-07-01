<?php

/**
 * Admin Configuration screen: Configuration → Sales → Subscriptions & Billing.
 *
 * Bagisto renders `fields` only at the THIRD key segment (group.section.subsection), so the fields
 * live under `sales.subscriptions.settings`. Values are stored in core_config and read via
 * Support\Settings (which falls back to .env). Password fields are masked in the UI.
 */
return [
    // Section (the clickable page under the existing "Sales" configuration group).
    [
        'key'  => 'sales.subscriptions',
        'name' => 'Subscriptions & Billing',
        'info' => 'Payment processor for recurring memberships. Enter your Stripe keys, then sync the '
                . 'membership products from Admin → Subscriptions. (Merchant-of-Record providers like '
                . 'Polar/Paddle are not usable here — their policies prohibit marketplaces.)',
        'sort' => 6,
    ],

    // Subsection that actually holds the fields.
    [
        'key'  => 'sales.subscriptions.settings',
        'name' => 'Provider & API Keys',
        'info' => 'Choose the active processor and enter its credentials. After saving, run '
                . 'Admin → Subscriptions → "Sync plans".',
        'sort' => 0,
        'fields' => [
            [
                'name'          => 'provider',
                'title'         => 'Active Payment Provider',
                'type'          => 'select',
                'channel_based' => false,
                'locale_based'  => false,
                'options'       => [
                    ['title' => 'Stripe (primary)',     'value' => 'stripe'],
                    ['title' => 'PayPal (backup rail)', 'value' => 'paypal'],
                ],
            ],
            [
                'name'  => 'currency',
                'title' => 'Currency (ISO code, e.g. usd)',
                'type'  => 'text',
            ],

            // --- Stripe ---
            [
                'name'  => 'stripe_key',
                'title' => 'Stripe Publishable Key',
                'type'  => 'text',
            ],
            [
                'name'  => 'stripe_secret',
                'title' => 'Stripe Secret Key',
                'type'  => 'password',
            ],
            [
                'name'  => 'stripe_webhook_secret',
                'title' => 'Stripe Webhook Secret',
                'type'  => 'password',
            ],

            // --- PayPal (backup rail) ---
            [
                'name'    => 'paypal_mode',
                'title'   => 'PayPal Mode',
                'type'    => 'select',
                'options' => [
                    ['title' => 'Live',    'value' => 'live'],
                    ['title' => 'Sandbox', 'value' => 'sandbox'],
                ],
            ],
            [
                'name'  => 'paypal_client_id',
                'title' => 'PayPal Client ID',
                'type'  => 'text',
            ],
            [
                'name'  => 'paypal_secret',
                'title' => 'PayPal Secret',
                'type'  => 'password',
            ],
            [
                'name'  => 'paypal_webhook_id',
                'title' => 'PayPal Webhook ID',
                'type'  => 'text',
            ],
        ],
    ],
];
