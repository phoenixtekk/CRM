<?php

/**
 * Subscriptions & billing configuration.
 * Secrets come from the environment ONLY — never hardcode keys here or commit them.
 */
return [
    /*
     | Active payment processor. Switching providers is a CONFIG change only — pick it in the admin UI
     | (Configuration → Sales → Subscriptions & Billing), enter keys, run `subscriptions:sync-plans`,
     | and point the provider's webhook at /billing/webhook. No code or schema changes.
     |
     | Default: stripe (direct processor — permits subscriptions AND marketplaces). NOTE: Merchant-of-
     | Record providers (Polar, Paddle, Lemon Squeezy) PROHIBIT marketplaces in their Acceptable Use
     | Policies, so they are not viable for this storefront. Polar was removed for that reason
     | (2026-06-14). Freeze risk on a direct processor is mitigated operationally (see BILLING.md).
     */
    'provider' => env('BILLING_PROVIDER', 'stripe'),

    'providers' => [
        'stripe' => \Phoenixtekk\Subscriptions\Billing\StripeBillingProvider::class,
        'paypal' => \Phoenixtekk\Subscriptions\Billing\PayPalBillingProvider::class, // backup rail
    ],

    // Stripe (active direct processor).
    'stripe' => [
        'key'            => env('STRIPE_KEY'),             // publishable (test/live)
        'secret'         => env('STRIPE_SECRET'),          // secret key
        'webhook_secret' => env('STRIPE_WEBHOOK_SECRET'),  // signing secret for /billing/webhook
    ],

    'currency' => env('SUBSCRIPTIONS_CURRENCY', 'usd'),

    /*
     | Membership tiers. Amounts are in the smallest currency unit (cents).
     | The actual Stripe price IDs are created by `php artisan subscriptions:sync-plans`
     | and stored in pt_sub_plans — this is just the source-of-truth catalog.
     */
    'tiers' => [
        'individual' => [
            'name'        => 'Individual',
            'monthly'     => 49900,
            'annual'      => 598800,
            'description' => 'For the solo admin running deployments themselves.',
            'features'    => [
                'Unlimited access to every published solution',
                'All documentation + tested PowerShell scripts',
                'New solutions added every month',
                'Branded Word & PDF deliverables',
                'Email support',
            ],
        ],
        'professional' => [
            'name'        => 'Professional',
            'monthly'     => 99900,
            'annual'      => 1198800,
            'description' => 'For consultants and MSPs deploying for clients.',
            'features'    => [
                'Everything in Individual',
                'Commercial use rights for client work',
                'Editable source files & templates',
                'Priority support',
                'Early access to new solutions',
            ],
        ],
        'enterprise' => [
            'name'        => 'Enterprise',
            'monthly'     => 149900,
            'annual'      => 1798800,
            'description' => 'For IT teams standardizing across the org.',
            'features'    => [
                'Everything in Professional',
                'Enterprise licensing for your whole team',
                'Multi-admin access & governance',
                'Onboarding assistance',
                'Dedicated support channel',
            ],
        ],
    ],
];
