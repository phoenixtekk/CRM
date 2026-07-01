<?php

namespace Phoenixtekk\B2BMarketplace\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Webkul\Customer\Models\Customer;

class CompanyUser extends Model
{
    protected $table = 'pt_b2b_company_users';

    protected $fillable = ['company_id', 'customer_id', 'role', 'status'];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class, 'company_id');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class, 'customer_id');
    }

    public function isManager(): bool
    {
        return in_array($this->role, ['owner', 'admin'], true);
    }
}
