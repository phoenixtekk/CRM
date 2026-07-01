<x-shop::layouts>
    <x-slot:title>Supplier Dashboard</x-slot:title>

    <div class="container mx-auto max-w-4xl px-4 py-8">
        <h1 class="mb-4 text-2xl font-bold">Supplier Dashboard</h1>
        @include('b2b::shop.partials.flash')

        @if (! $supplier)
            <div class="rounded border bg-white p-6">
                <p class="mb-3">You are not registered as a supplier yet.</p>
                <a href="{{ route('shop.b2b.supplier.register') }}" class="rounded bg-blue-600 px-4 py-2 font-semibold text-white">Apply now</a>
            </div>
        @elseif (! $supplier->isApproved())
            <div class="rounded border border-amber-300 bg-amber-50 p-6 text-amber-800">
                <p class="font-semibold">Application status: {{ ucfirst($supplier->status) }}</p>
                <p class="mt-1 text-sm">Your supplier application for <strong>{{ $supplier->company_name }}</strong> is not yet approved. The dashboard unlocks once an administrator approves it.</p>
            </div>
        @else
            <div class="mb-6 rounded border bg-white p-4">
                <p class="font-semibold text-gray-800">{{ $supplier->company_name }}
                    <span class="ml-2 rounded-full bg-green-100 px-2 py-0.5 text-xs font-semibold text-green-700">Approved</span>
                </p>
                <p class="text-sm text-gray-500">{{ $supplier->email }}</p>
            </div>

            <h2 class="mb-2 text-lg font-semibold">Open RFQs</h2>
            <div class="mb-6 overflow-x-auto rounded border bg-white">
                <table class="w-full text-left text-sm">
                    <thead class="border-b bg-gray-50"><tr><th class="p-3">#</th><th class="p-3">Title</th><th class="p-3">Items</th><th class="p-3">Status</th><th class="p-3"></th></tr></thead>
                    <tbody>
                        @forelse ($openRfqs as $rfq)
                            <tr class="border-b">
                                <td class="p-3">{{ $rfq->id }}</td>
                                <td class="p-3 font-medium">{{ $rfq->title }}</td>
                                <td class="p-3">{{ $rfq->items->count() }}</td>
                                <td class="p-3">{{ ucfirst(str_replace('_', ' ', $rfq->status)) }}</td>
                                <td class="p-3"><a href="{{ route('shop.b2b.supplier.rfq', $rfq->id) }}" class="text-blue-600 hover:underline">View / Quote</a></td>
                            </tr>
                        @empty
                            <tr><td colspan="5" class="p-6 text-center text-gray-500">No open RFQs right now.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <h2 class="mb-2 text-lg font-semibold">My Quotes</h2>
            <div class="overflow-x-auto rounded border bg-white">
                <table class="w-full text-left text-sm">
                    <thead class="border-b bg-gray-50"><tr><th class="p-3">RFQ</th><th class="p-3">Total</th><th class="p-3">Status</th><th class="p-3">Submitted</th></tr></thead>
                    <tbody>
                        @forelse ($myQuotes as $q)
                            <tr class="border-b">
                                <td class="p-3">{{ $q->rfq?->title }}</td>
                                <td class="p-3">{{ core()->formatBasePrice($q->quote_total) }}</td>
                                <td class="p-3">{{ ucfirst($q->status) }}</td>
                                <td class="p-3">{{ $q->created_at?->format('Y-m-d') }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="4" class="p-6 text-center text-gray-500">No quotes submitted yet.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        @endif
    </div>
</x-shop::layouts>
