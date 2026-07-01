<x-shop::layouts>
    <x-slot:title>RFQ #{{ $rfq->id }} — Quote</x-slot:title>

    <div class="container mx-auto max-w-3xl px-4 py-8">
        <a href="{{ route('shop.b2b.supplier.dashboard') }}" class="text-blue-600 hover:underline">&larr; Dashboard</a>
        <h1 class="mb-2 mt-2 text-2xl font-bold">{{ $rfq->title }}</h1>
        <p class="mb-4 text-gray-600">{{ $rfq->description }}</p>
        @include('b2b::shop.partials.flash')

        <h2 class="mb-2 text-lg font-semibold">Requested items</h2>
        <table class="mb-6 w-full rounded border bg-white text-left text-sm">
            <thead class="border-b bg-gray-50"><tr><th class="p-2">Item</th><th class="p-2">Qty</th><th class="p-2">Unit</th><th class="p-2">Target</th></tr></thead>
            <tbody>
                @foreach ($rfq->items as $item)
                    <tr class="border-b"><td class="p-2">{{ $item->name }}</td><td class="p-2">{{ $item->quantity }}</td><td class="p-2">{{ $item->unit }}</td><td class="p-2">{{ $item->target_price ? core()->formatBasePrice($item->target_price) : '—' }}</td></tr>
                @endforeach
            </tbody>
        </table>

        @if ($rfq->quotes->isNotEmpty())
            <div class="mb-6 rounded border border-green-300 bg-green-50 p-3 text-sm text-green-800">
                You have already submitted a quote for this RFQ (total {{ core()->formatBasePrice($rfq->quotes->first()->quote_total) }}).
            </div>
        @endif

        <h2 class="mb-2 text-lg font-semibold">Submit a quote</h2>
        <form method="POST" action="{{ route('shop.b2b.supplier.quote', $rfq->id) }}" class="space-y-3 rounded border bg-white p-4">
            @csrf
            <div>
                <label class="mb-1 block text-sm font-medium">Quote total *</label>
                <input type="number" step="0.01" name="quote_total" value="{{ old('quote_total') }}" required class="w-full rounded border px-3 py-2">
            </div>
            <div>
                <label class="mb-1 block text-sm font-medium">Expires on</label>
                <input type="date" name="expires_at" value="{{ old('expires_at') }}" class="w-full rounded border px-3 py-2">
            </div>
            <div>
                <label class="mb-1 block text-sm font-medium">Notes</label>
                <textarea name="notes" rows="3" class="w-full rounded border px-3 py-2">{{ old('notes') }}</textarea>
            </div>
            <button type="submit" class="rounded bg-blue-600 px-5 py-2.5 font-semibold text-white">Submit quote</button>
        </form>
    </div>
</x-shop::layouts>
