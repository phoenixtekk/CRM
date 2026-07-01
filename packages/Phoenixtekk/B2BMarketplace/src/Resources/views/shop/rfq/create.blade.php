<x-shop::layouts>
    <x-slot:title>New RFQ</x-slot:title>

    <div class="container mx-auto max-w-3xl px-4 py-8">
        <h1 class="mb-4 text-2xl font-bold">Create RFQ</h1>
        @include('b2b::shop.partials.flash')

        <form method="POST" action="{{ route('shop.b2b.rfqs.store') }}" class="space-y-4">
            @csrf
            <div>
                <label class="mb-1 block text-sm font-medium">Title *</label>
                <input type="text" name="title" value="{{ old('title') }}" required class="w-full rounded border px-3 py-2">
            </div>
            <div>
                <label class="mb-1 block text-sm font-medium">Description</label>
                <textarea name="description" rows="3" class="w-full rounded border px-3 py-2">{{ old('description') }}</textarea>
            </div>
            <div class="flex gap-4">
                <div class="grow">
                    <label class="mb-1 block text-sm font-medium">Company</label>
                    <select name="company_id" class="w-full rounded border px-3 py-2">
                        <option value="">— Personal (no company) —</option>
                        @foreach ($companies as $c)
                            <option value="{{ $c->id }}">{{ $c->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label class="mb-1 block text-sm font-medium">Needed by</label>
                    <input type="date" name="due_date" value="{{ old('due_date') }}" class="rounded border px-3 py-2">
                </div>
            </div>

            <div>
                <div class="mb-1 flex items-center justify-between">
                    <label class="text-sm font-medium">Line items *</label>
                    <button type="button" onclick="addRow()" class="text-sm text-blue-600 hover:underline">+ Add item</button>
                </div>
                <div id="items" class="space-y-2">
                    <div class="grid grid-cols-12 gap-2">
                        <input name="items[0][name]" placeholder="Item name *" required class="col-span-5 rounded border px-2 py-1.5">
                        <input name="items[0][quantity]" type="number" step="0.01" value="1" placeholder="Qty" class="col-span-2 rounded border px-2 py-1.5">
                        <input name="items[0][unit]" value="each" placeholder="Unit" class="col-span-2 rounded border px-2 py-1.5">
                        <input name="items[0][target_price]" type="number" step="0.01" placeholder="Target" class="col-span-3 rounded border px-2 py-1.5">
                    </div>
                </div>
            </div>

            <div class="flex gap-2">
                <button type="submit" name="action" value="submit" class="rounded bg-blue-600 px-5 py-2.5 font-semibold text-white">Submit to suppliers</button>
                <button type="submit" name="action" value="draft" class="rounded border px-5 py-2.5 font-semibold">Save draft</button>
            </div>
        </form>
    </div>

    <script>
        let i = 1;
        function addRow() {
            const wrap = document.getElementById('items');
            const row = document.createElement('div');
            row.className = 'grid grid-cols-12 gap-2';
            row.innerHTML = `
                <input name="items[${i}][name]" placeholder="Item name" class="col-span-5 rounded border px-2 py-1.5">
                <input name="items[${i}][quantity]" type="number" step="0.01" value="1" class="col-span-2 rounded border px-2 py-1.5">
                <input name="items[${i}][unit]" value="each" class="col-span-2 rounded border px-2 py-1.5">
                <input name="items[${i}][target_price]" type="number" step="0.01" placeholder="Target" class="col-span-3 rounded border px-2 py-1.5">`;
            wrap.appendChild(row);
            i++;
        }
    </script>
</x-shop::layouts>
