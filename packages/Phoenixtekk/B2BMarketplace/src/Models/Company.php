<?php

namespace Phoenixtekk\B2BMarketplace\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Company extends Model
{
    protected $table = 'pt_b2b_companies';

    protected $fillable = [
        'name', 'legal_name', 'email', 'phone', 'website',
        'address', 'tax_id', 'status', 'notes', 'created_by',
    ];

    public function users(): HasMany
    {
        return $this->hasMany(CompanyUser::class, 'company_id');
    }

    public function rfqs(): HasMany
    {
        return $this->hasMany(Rfq::class, 'company_id');
    }

    /** Customer ids that belong to this company. */
    public function memberCustomerIds(): array
    {
        return $this->users()->pluck('customer_id')->all();
    }
}
