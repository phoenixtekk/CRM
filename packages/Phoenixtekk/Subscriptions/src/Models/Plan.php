<?php

namespace Phoenixtekk\Subscriptions\Models;

use Illuminate\Database\Eloquent\Model;

class Plan extends Model
{
    protected $table = 'pt_sub_plans';

    protected $fillable = [
        'provider', 'tier', 'interval', 'provider_product_id', 'provider_price_id', 'amount', 'currency', 'active',
    ];

    protected $casts = [
        'active' => 'boolean',
        'amount' => 'integer',
    ];
}
