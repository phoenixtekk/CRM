<?php

namespace Phoenixtekk\B2BMarketplace\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Webkul\Customer\Models\Customer;

class SupplierUser extends Model
{
    protected $table = 'pt_b2b_supplier_users';

    protected $fillable = ['supplier_id', 'customer_id', 'role', 'status'];

    public function supplier(): BelongsTo
    {
        return $this->belongsTo(Supplier::class, 'supplier_id');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'customer_id');
    }
}
