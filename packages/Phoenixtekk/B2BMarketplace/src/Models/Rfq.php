<?php

namespace Phoenixtekk\B2BMarketplace\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Webkul\Customer\Models\Customer;

class Rfq extends Model
{
    protected $table = 'pt_b2b_rfqs';

    protected $fillable = [
        'title', 'description', 'company_id', 'requester_id', 'status', 'due_date',
    ];

    protected $casts = [
        'due_date' => 'date',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class, 'company_id');
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'requester_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(RfqItem::class, 'rfq_id');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(RfqMessage::class, 'rfq_id');
    }

    public function quotes(): HasMany
    {
        return $this->hasMany(RfqQuote::class, 'rfq_id');
    }
}
