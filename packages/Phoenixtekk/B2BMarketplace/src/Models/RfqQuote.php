<?php

namespace Phoenixtekk\B2BMarketplace\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RfqQuote extends Model
{
    protected $table = 'pt_b2b_rfq_quotes';

    protected $fillable = [
        'rfq_id', 'supplier_id', 'quote_total', 'expires_at', 'notes', 'line_items', 'status',
    ];

    protected $casts = [
        'expires_at'  => 'date',
        'line_items'  => 'array',
        'quote_total' => 'decimal:4',
    ];

    public function rfq(): BelongsTo
    {
        return $this->belongsTo(Rfq::class, 'rfq_id');
    }

    public function supplier(): BelongsTo
    {
        return $this->belongsTo(Supplier::class, 'supplier_id');
    }
}
