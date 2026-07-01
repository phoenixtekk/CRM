<?php

namespace Phoenixtekk\B2BMarketplace\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Webkul\Customer\Models\Customer;

class Supplier extends Model
{
    protected $table = 'pt_b2b_suppliers';

    protected $fillable = [
        'company_name', 'legal_name', 'email', 'phone', 'website', 'address', 'tax_id',
        'status', 'customer_id', 'approved_by', 'approved_at', 'rejected_reason',
        'status_changed_at', 'notes',
    ];

    protected $casts = [
        'approved_at'       => 'datetime',
        'status_changed_at' => 'datetime',
    ];

    public function applicant(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'customer_id');
    }

    public function users(): HasMany
    {
        return $this->hasMany(SupplierUser::class, 'supplier_id');
    }

    public function quotes(): HasMany
    {
        return $this->hasMany(RfqQuote::class, 'supplier_id');
    }

    public function isApproved(): bool
    {
        return $this->status === 'approved';
    }

    public function memberCustomerIds(): array
    {
        return $this->users()->pluck('customer_id')->all();
    }
}
