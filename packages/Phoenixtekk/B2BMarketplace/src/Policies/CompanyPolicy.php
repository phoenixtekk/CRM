<?php

namespace Phoenixtekk\B2BMarketplace\Policies;

use Phoenixtekk\B2BMarketplace\Models\Company;
use Webkul\Customer\Models\Customer;

/**
 * Company members can view; only owner/admin roles can manage the company and its users.
 */
class CompanyPolicy
{
    public function view(Customer $user, Company $company): bool
    {
        return in_array($user->id, $company->memberCustomerIds(), true);
    }

    public function manage(Customer $user, Company $company): bool
    {
        return $company->users()
            ->where('customer_id', $user->id)
            ->whereIn('role', ['owner', 'admin'])
            ->exists();
    }
}
