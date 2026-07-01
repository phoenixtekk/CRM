<x-shop::layouts>
    <x-slot:title>RFQ #{{ $rfq->id }}</x-slot:title>

    <div class="container mx-auto max-w-3xl px-4 py-8">
        <a href="{{ route('shop.b2b.rfqs.index') }}" class="text-blue-600 hover:underline">&larr; My RFQs</a>
        <div class="mt-2 flex items-center justify-between">
            <h1 class="text-2xl font-bold">{{ $rfq->title }}</h1>
            <span class="rounded-full bg-gray-100 px-3 py-1 text-sm font-semibold">{{ ucfirst(str_replace('_', ' ', $rfq->status)) }}</span>
        </div>
        <p class="mb-4 mt-1 text-gray-600">{{ $rfq->description }}</p>
        @include('b2b::shop.partials.flash')

        @if ($rfq->status === 'draft')
            <form method="POST" action="{{ route('shop.b2b.rfqs.submit', $rfq->id) }}" class="mb-6">
                @csrf
                <button class="rounded bg-blue-600 px-4 py-2 font-semibold text-white">Submit to suppliers</button>
            </form>
        @endif

        <h2 class="mb-2 text-lg font-semibold">Items</h2>
        <table class="mb-6 w-full rounded border bg-white text-left text-sm">
            <thead class="border-b bg-gray-50"><tr><th class="p-2">Item</th><th class="p-2">Qty</th><th class="p-2">Unit</th><th class="p-2">Target</th></tr></thead>
            <tbody>
                @foreach ($rfq->items as $item)
                    <tr class="border-b"><td class="p-2">{{ $item->name }}</td><td class="p-2">{{ $item->quantity }}</td><td class="p-2">{{ $item->unit }}</td><td class="p-2">{{ $item->target_price ? core()->formatBasePrice($item->target_price) : '—' }}</td></tr>
                @endforeach
            </tbody>
        </table>

        <h2 class="mb-2 text-lg font-semibold">Quotes ({{ $rfq->quotes->count() }})</h2>
        <div class="mb-6 space-y-2">
            @forelse ($rfq->quotes as $q)
                <div class="rounded border bg-white p-3 text-sm">
                    <div class="flex justify-between">
                        <span class="font-medium">{{ $q->supplier?->company_name ?? 'Supplier #' . $q->supplier_id }}</span>
                        <span class="font-semibold">{{ core()->formatBasePrice($q->quote_total) }}</span>
                    </div>
                    @if ($q->notes)<p class="mt-1 text-gray-600">{{ $q->notes }}</p>@endif
                    @if ($q->expires_at)<p class="text-xs text-gray-500">Valid until {{ $q->expires_at->format('Y-m-d') }}</p>@endif
                </div>
            @empty
                <p class="text-gray-500">No quotes yet.</p>
            @endforelse
        </div>

        <h2 class="mb-2 text-lg font-semibold">Messages</h2>
        <div class="mb-3 space-y-2">
            @forelse ($rfq->messages as $m)
                <div class="rounded border bg-white p-2 text-sm">
                    <span class="text-xs font-semibold uppercase text-gray-500">{{ $m->author_type }}</span>
                    <p>{{ $m->message }}</p>
                    <span class="text-xs text-gray-400">{{ $m->created_at?->diffForHumans() }}</span>
                </div>
            @empty
                <p class="text-gray-500">No messages yet.</p>
            @endforelse
        </div>
        <form method="POST" action="{{ route('shop.b2b.rfqs.message', $rfq->id) }}" class="flex gap-2">
            @csrf
            <input name="message" required placeholder="Write a message…" class="grow rounded border px-3 py-2">
            <button class="rounded bg-blue-600 px-4 py-2 font-semibold text-white">Send</button>
        </form>
    </div>
</x-shop::layouts>
