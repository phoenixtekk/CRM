<?php

namespace Phoenixtekk\B2BMarketplace\Http\Controllers\Shop;

use Phoenixtekk\B2BMarketplace\Http\Requests\SupplierRegistrationRequest;
use Phoenixtekk\B2BMarketplace\Models\Supplier;
use Phoenixtekk\B2BMarketplace\Models\SupplierUser;
use Webkul\Shop\Http\Controllers\Controller;

/**
 * Storefront: a logged-in customer applies to become a supplier.
 */
class SupplierRegistrationController extends Controller
{
    public function create()
    {
        $customer = auth()->guard('customer')->user();

        $existing = Supplier::where('customer_id', $customer->id)
            ->whereIn('status', ['pending', 'approved', 'suspended'])
            ->first();

        if ($existing) {
            return redirect()->route('shop.b2b.supplier.dashboard');
        }

        return view('b2b::shop.register');
    }

    public function store(SupplierRegistrationRequest $request)
    {
        $customer = auth()->guard('customer')->user();

        // Prevent duplicate active applications for the same customer.
        if (Supplier::where('customer_id', $customer->id)->whereIn('status', ['pending', 'approved'])->exists()) {
            return redirect()->route('shop.b2b.supplier.dashboard')
                ->with('warning', 'You already have a supplier application on file.');
        }

        $supplier = Supplier::create(array_merge($request->validated(), [
            'status'            => 'pending',
            'customer_id'       => $customer->id,
            'status_changed_at' => now(),
        ]));

        SupplierUser::create([
            'supplier_id' => $supplier->id,
            'customer_id' => $customer->id,
            'role'        => 'owner',
            'status'      => 'active',
        ]);

        return redirect()->route('shop.b2b.supplier.dashboard')
            ->with('success', 'Your supplier application has been submitted and is pending approval.');
    }
}
