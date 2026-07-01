<?php

use Illuminate\Support\Facades\Route;
use Phoenixtekk\Subscriptions\Http\Controllers\WebhookController;

/*
 | Billing webhook endpoint (provider-agnostic — Stripe by default; any driver in the providers map).
 | Deliberately NO 'web' middleware group: a processor callback is not a browser session and must
 | not be subject to CSRF. Authentication is the provider's signature, verified inside the active
 | driver via its webhook secret. Point your processor's webhook here.
 */
Route::post('billing/webhook', [WebhookController::class, 'handle'])->name('subscriptions.webhook');
