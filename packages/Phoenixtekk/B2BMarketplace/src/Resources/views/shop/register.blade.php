<x-shop::layouts>
    <x-slot:title>Become a Supplier</x-slot:title>

    <div class="container mx-auto max-w-2xl px-4 py-8">
        <h1 class="mb-2 text-2xl font-bold">Apply to become a supplier</h1>
        <p class="mb-6 text-gray-600">Submit your company details. Your application will be reviewed and you'll get access to the supplier dashboard once approved.</p>

        @include('b2b::shop.partials.flash')

        <form method="POST" action="{{ route('shop.b2b.supplier.store') }}" class="space-y-4">
            @csrf
            @php($fields = ['company_name' => 'Company name *', 'legal_name' => 'Legal name', 'email' => 'Email *', 'phone' => 'Phone', 'website' => 'Website', 'tax_id' => 'Tax ID'])
            @foreach ($fields as $name => $label)
                <div>
                    <label class="mb-1 block text-sm font-medium">{{ $label }}</label>
                    <input type="text" name="{{ $name }}" value="{{ old($name) }}"
                        class="w-full rounded border px-3 py-2">
                    @error($name)<p class="mt-1 text-sm text-red-600">{{ $message }}</p>@enderror
                </div>
            @endforeach
            <div>
                <label class="mb-1 block text-sm font-medium">Address</label>
                <textarea name="address" rows="2" class="w-full rounded border px-3 py-2">{{ old('address') }}</textarea>
            </div>
            <div>
                <label class="mb-1 block text-sm font-medium">Notes</label>
                <textarea name="notes" rows="2" class="w-full rounded border px-3 py-2">{{ old('notes') }}</textarea>
            </div>
            <button type="submit" class="rounded bg-blue-600 px-5 py-2.5 font-semibold text-white">Submit application</button>
        </form>
    </div>
</x-shop::layouts>
