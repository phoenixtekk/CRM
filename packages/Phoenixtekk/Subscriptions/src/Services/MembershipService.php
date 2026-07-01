<?php

namespace Phoenixtekk\Subscriptions\Services;

use Phoenixtekk\Subscriptions\Models\Subscription;
use Webkul\Customer\Models\Customer;

/**
 * The single place app code asks "is this customer a member, and at what tier?".
 */
class MembershipService
{
    public function activeSubscription(?Customer $customer): ?Subscription
    {
        if (! $customer) {
            return null;
        }

        return Subscription::where('customer_id', $customer->id)
            ->whereIn('status', Subscription::ACTIVE_STATUSES)
            ->where(function ($q) {
                $q->whereNull('current_period_end')->orWhere('current_period_end', '>', now());
            })
            ->latest('id')
            ->first();
    }

    public function isMember(?Customer $customer): bool
    {
        return $this->activeSubscription($customer) !== null;
    }

    public function activeTier(?Customer $customer): ?string
    {
        return $this->activeSubscription($customer)?->tier;
    }
}
