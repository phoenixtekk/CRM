<?php

namespace Phoenixtekk\B2BMarketplace\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Webkul\Product\Models\Product;

class RfqItem extends Model
{
    protected $table = 'pt_b2b_rfq_items';

    protected $fillable = [
        'rfq_id', 'product_id', 'name', 'quantity', 'unit', 'target_price', 'notes',
    ];

    protected $casts = [
        'quantity'     => 'decimal:2',
        'target_price' => 'decimal:4',
    ];

    public function rfq(): BelongsTo
    {
        return $this->belongsTo(Rfq::class, 'rfq_id');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id');
    }
}
