<?php

namespace Phoenixtekk\B2BMarketplace\Policies;

use Phoenixtekk\B2BMarketplace\Models\Company;
use Phoenixtekk\B2BMarketplace\Models\Rfq;
use Webkul\Customer\Models\Customer;

/**
 * RFQ visibility: the requester, any member of the RFQ's company, may view.
 * (Supplier visibility to open RFQs is enforced separately in the supplier dashboard.)
 */
class RfqPolicy
{
    public function view(Customer $user, Rfq $rfq): bool
    {
        if ((int) $rfq->requester_id === (int) $user->id) {
            return true;
        }

        if ($rfq->company_id) {
            $company = Company::find($rfq->company_id);

            return $company && in_array($user->id, $company->memberCustomerIds(), true);
        }

        return false;
    }

    public function update(Customer $user, Rfq $rfq): bool
    {
        return (int) $rfq->requester_id === (int) $user->id;
    }
}
