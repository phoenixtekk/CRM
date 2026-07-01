<?php

use Illuminate\Support\Facades\Route;
use Phoenixtekk\Subscriptions\Http\Controllers\Admin\SubscriptionController;

Route::group([
    'middleware' => ['web', 'admin'],
    'prefix'     => config('app.admin_url', 'admin') . '/subscriptions',
], function () {
    Route::get('', [SubscriptionController::class, 'index'])->name('admin.subscriptions.index');
    Route::post('sync', [SubscriptionController::class, 'sync'])->name('admin.subscriptions.sync');
});
