<x-shop::layouts>
    <x-slot:title>My RFQs</x-slot:title>

    <div class="container mx-auto max-w-4xl px-4 py-8">
        <div class="mb-4 flex items-center justify-between">
            <h1 class="text-2xl font-bold">My RFQs</h1>
            <a href="{{ route('shop.b2b.rfqs.create') }}" class="rounded bg-blue-600 px-4 py-2 font-semibold text-white">+ New RFQ</a>
        </div>
        @include('b2b::shop.partials.flash')

        <div class="overflow-x-auto rounded border bg-white">
            <table class="w-full text-left text-sm">
                <thead class="border-b bg-gray-50"><tr><th class="p-3">#</th><th class="p-3">Title</th><th class="p-3">Status</th><th class="p-3">Quotes</th><th class="p-3">Due</th><th class="p-3"></th></tr></thead>
                <tbody>
                    @forelse ($rfqs as $rfq)
                        <tr class="border-b">
                            <td class="p-3">{{ $rfq->id }}</td>
                            <td class="p-3 font-medium">{{ $rfq->title }}</td>
                            <td class="p-3">{{ ucfirst(str_replace('_', ' ', $rfq->status)) }}</td>
                            <td class="p-3">{{ $rfq->quotes->count() }}</td>
                            <td class="p-3">{{ $rfq->due_date?->format('Y-m-d') ?? '—' }}</td>
                            <td class="p-3"><a href="{{ route('shop.b2b.rfqs.show', $rfq->id) }}" class="text-blue-600 hover:underline">Open</a></td>
                        </tr>
                    @empty
                        <tr><td colspan="6" class="p-6 text-center text-gray-500">No RFQs yet. <a href="{{ route('shop.b2b.rfqs.create') }}" class="text-blue-600 hover:underline">Create one</a>.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</x-shop::layouts>
