<?php

namespace Phoenixtekk\B2BMarketplace\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class QuoteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return auth()->guard('customer')->check();
    }

    public function rules(): array
    {
        return [
            'quote_total'             => ['required', 'numeric', 'min:0'],
            'expires_at'              => ['nullable', 'date', 'after_or_equal:today'],
            'notes'                   => ['nullable', 'string', 'max:2000'],
            'line_items'              => ['nullable', 'array'],
            'line_items.*.rfq_item_id'=> ['nullable', 'integer'],
            'line_items.*.unit_price' => ['nullable', 'numeric', 'min:0'],
        ];
    }
}
