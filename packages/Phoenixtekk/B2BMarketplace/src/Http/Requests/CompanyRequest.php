<?php

namespace Phoenixtekk\B2BMarketplace\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CompanyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return auth()->guard('customer')->check();
    }

    public function rules(): array
    {
        return [
            'name'       => ['required', 'string', 'max:255'],
            'legal_name' => ['nullable', 'string', 'max:255'],
            'email'      => ['nullable', 'email', 'max:255'],
            'phone'      => ['nullable', 'string', 'max:50'],
            'website'    => ['nullable', 'url', 'max:255'],
            'address'    => ['nullable', 'string', 'max:2000'],
            'tax_id'     => ['nullable', 'string', 'max:100'],
        ];
    }
}
