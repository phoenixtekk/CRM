<?php

namespace Phoenixtekk\B2BMarketplace\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RfqRequest extends FormRequest
{
    public function authorize(): bool
    {
        return auth()->guard('customer')->check();
    }

    public function rules(): array
    {
        return [
            'title'                => ['required', 'string', 'max:255'],
            'description'          => ['nullable', 'string', 'max:5000'],
            'due_date'             => ['nullable', 'date', 'after_or_equal:today'],
            'items'                => ['required', 'array', 'min:1'],
            'items.*.name'         => ['required', 'string', 'max:255'],
            'items.*.product_id'   => ['nullable', 'integer', 'exists:products,id'],
            'items.*.quantity'     => ['required', 'numeric', 'min:0.01'],
            'items.*.unit'         => ['nullable', 'string', 'max:50'],
            'items.*.target_price' => ['nullable', 'numeric', 'min:0'],
            'items.*.notes'        => ['nullable', 'string', 'max:1000'],
        ];
    }
}
