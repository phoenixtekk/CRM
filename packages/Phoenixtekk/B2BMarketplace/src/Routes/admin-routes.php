<?php

use Illuminate\Support\Facades\Route;
use Phoenixtekk\B2BMarketplace\Http\Controllers\Admin\SupplierController;

/*
 | Admin routes — protected by Bagisto's 'admin' middleware and the admin URL prefix.
 | Scope (v1.0): review supplier applications and change their status.
 */
Route::group([
    'middleware' => ['web', 'admin'],
    'prefix'     => config('app.admin_url', 'admin') . '/b2b',
], function () {
    Route::controller(SupplierController::class)->prefix('suppliers')->group(function () {
        Route::get('', 'index')->name('admin.b2b.suppliers.index');
        Route::get('{id}', 'view')->name('admin.b2b.suppliers.view');
        Route::put('{id}/status', 'updateStatus')->name('admin.b2b.suppliers.update_status');
    });
});
