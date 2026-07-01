<?php

use Illuminate\Support\Facades\Route;
use Phoenixtekk\B2BMarketplace\Http\Controllers\Shop\CompanyController;
use Phoenixtekk\B2BMarketplace\Http\Controllers\Shop\RfqController;
use Phoenixtekk\B2BMarketplace\Http\Controllers\Shop\SupplierDashboardController;
use Phoenixtekk\B2BMarketplace\Http\Controllers\Shop\SupplierRegistrationController;

/*
 | Storefront routes — protected by Bagisto's 'customer' middleware (logged-in customers only).
 | Prefix /b2b; route names shop.b2b.*
 */
Route::group([
    'middleware' => ['web', 'customer'],
    'prefix'     => 'b2b',
], function () {
    // --- Supplier registration ---
    Route::controller(SupplierRegistrationController::class)->group(function () {
        Route::get('supplier/register', 'create')->name('shop.b2b.supplier.register');
        Route::post('supplier/register', 'store')->name('shop.b2b.supplier.store');
    });

    // --- Supplier dashboard (approved suppliers only; enforced in controller/policy) ---
    Route::controller(SupplierDashboardController::class)->group(function () {
        Route::get('supplier/dashboard', 'index')->name('shop.b2b.supplier.dashboard');
        Route::get('supplier/rfqs/{id}', 'rfq')->name('shop.b2b.supplier.rfq');
        Route::post('supplier/rfqs/{id}/quote', 'quote')->name('shop.b2b.supplier.quote');
    });

    // --- Company accounts ---
    Route::controller(CompanyController::class)->group(function () {
        Route::get('company', 'index')->name('shop.b2b.company.index');
        Route::post('company', 'store')->name('shop.b2b.company.store');
        Route::put('company/{id}', 'update')->name('shop.b2b.company.update');
        Route::post('company/{id}/users', 'addUser')->name('shop.b2b.company.users.store');
        Route::delete('company/{id}/users/{userId}', 'removeUser')->name('shop.b2b.company.users.destroy');
    });

    // --- RFQs (buyer side) ---
    Route::controller(RfqController::class)->group(function () {
        Route::get('rfqs', 'index')->name('shop.b2b.rfqs.index');
        Route::get('rfqs/create', 'create')->name('shop.b2b.rfqs.create');
        Route::post('rfqs', 'store')->name('shop.b2b.rfqs.store');
        Route::get('rfqs/{id}', 'show')->name('shop.b2b.rfqs.show');
        Route::post('rfqs/{id}/submit', 'submit')->name('shop.b2b.rfqs.submit');
        Route::post('rfqs/{id}/messages', 'message')->name('shop.b2b.rfqs.message');
    });
});
