<?php

namespace Phoenixtekk\Subscriptions\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Webkul\Customer\Models\Customer;

class Subscription extends Model
{
    protected $table = 'pt_sub_subscriptions';

    protected $fillable = [
        'customer_id', 'provider', 'tier', 'interval', 'provider_customer_id', 'provider_subscription_id',
        'status', 'current_period_end', 'cancel_at_period_end',
    ];

    protected $casts = [
        'current_period_end'   => 'datetime',
        'cancel_at_period_end' => 'boolean',
    ];

    /** Statuses that grant access. */
    public const ACTIVE_STATUSES = ['active', 'trialing'];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'customer_id');
    }

    public function isActive(): bool
    {
        if (! in_array($this->status, self::ACTIVE_STATUSES, true)) {
            return false;
        }

        // active until the period end (Stripe keeps status 'active' until cancellation/expiry)
        return $this->current_period_end === null || $this->current_period_end->isFuture();
    }
}
