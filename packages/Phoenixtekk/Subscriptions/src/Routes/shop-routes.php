<?php

use Illuminate\Support\Facades\Route;
use Phoenixtekk\Subscriptions\Http\Controllers\Shop\MemberLibraryController;
use Phoenixtekk\Subscriptions\Http\Controllers\Shop\SubscriptionController;

Route::group(['middleware' => ['web', 'locale', 'theme', 'currency'], 'prefix' => 'memberships'], function () {
    // Public pricing page.
    Route::get('', [SubscriptionController::class, 'pricing'])->name('shop.subscriptions.pricing');

    // Stripe hosted checkout return URL (membership activates via webhook).
    Route::get('success', [SubscriptionController::class, 'success'])->name('shop.subscriptions.success');

    // Authenticated member actions.
    Route::group(['middleware' => ['customer']], function () {
        Route::post('checkout', [SubscriptionController::class, 'checkout'])->name('shop.subscriptions.checkout');
        Route::get('my-membership', [SubscriptionController::class, 'membership'])->name('shop.subscriptions.membership');
        Route::get('portal', [SubscriptionController::class, 'portal'])->name('shop.subscriptions.portal');
    });

    // Members-only download library (entitlement-gated).
    Route::group(['middleware' => ['membership.active'], 'prefix' => 'library'], function () {
        Route::get('', [MemberLibraryController::class, 'index'])->name('shop.subscriptions.library');
        Route::get('download/{link}', [MemberLibraryController::class, 'download'])->name('shop.subscriptions.library.download');
    });
});
