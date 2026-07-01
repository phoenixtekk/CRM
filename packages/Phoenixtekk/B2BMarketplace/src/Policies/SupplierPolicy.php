<?php

namespace Phoenixtekk\B2BMarketplace\Policies;

use Phoenixtekk\B2BMarketplace\Models\Supplier;
use Webkul\Customer\Models\Customer;

/**
 * A customer may only see/operate a supplier they belong to (via pt_b2b_supplier_users).
 */
class SupplierPolicy
{
    public function view(Customer $user, Supplier $supplier): bool
    {
        return in_array($user->id, $supplier->memberCustomerIds(), true);
    }

    /** Dashboard requires membership AND an approved supplier. */
    public function useDashboard(Customer $user, Supplier $supplier): bool
    {
        return $supplier->isApproved() && $this->view($user, $supplier);
    }

    public function submitQuote(Customer $user, Supplier $supplier): bool
    {
        return $this->useDashboard($user, $supplier);
    }
}
