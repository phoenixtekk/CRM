<x-admin::layouts>
    <x-slot:title>B2B Suppliers</x-slot:title>

    <div class="flex items-center justify-between">
        <p class="text-xl font-bold text-gray-800 dark:text-white">Supplier Applications</p>

        <form method="GET" action="{{ route('admin.b2b.suppliers.index') }}">
            <select name="status" onchange="this.form.submit()"
                class="rounded border px-3 py-1.5 text-sm dark:bg-gray-900 dark:text-white">
                <option value="">All statuses</option>
                @foreach (['pending', 'approved', 'rejected', 'suspended'] as $st)
                    <option value="{{ $st }}" {{ request('status') === $st ? 'selected' : '' }}>{{ ucfirst($st) }}</option>
                @endforeach
            </select>
        </form>
    </div>

    <div class="mt-4 overflow-x-auto rounded-lg border bg-white dark:bg-gray-900 dark:border-gray-800">
        <table class="w-full text-left text-sm">
            <thead class="border-b bg-gray-50 dark:bg-gray-950 dark:border-gray-800">
                <tr class="text-gray-600 dark:text-gray-300">
                    <th class="p-3">ID</th>
                    <th class="p-3">Company</th>
                    <th class="p-3">Applicant Email</th>
                    <th class="p-3">Status</th>
                    <th class="p-3">Applied</th>
                    <th class="p-3"></th>
                </tr>
            </thead>
            <tbody>
                @forelse ($suppliers as $supplier)
                    <tr class="border-b dark:border-gray-800">
                        <td class="p-3">{{ $supplier->id }}</td>
                        <td class="p-3 font-medium text-gray-800 dark:text-white">{{ $supplier->company_name }}</td>
                        <td class="p-3">{{ $supplier->email }}</td>
                        <td class="p-3">
                            <span class="rounded-full px-2 py-0.5 text-xs font-semibold
                                @class([
                                    'bg-amber-100 text-amber-700'  => $supplier->status === 'pending',
                                    'bg-green-100 text-green-700'   => $supplier->status === 'approved',
                                    'bg-red-100 text-red-700'       => $supplier->status === 'rejected',
                                    'bg-gray-200 text-gray-700'     => $supplier->status === 'suspended',
                                ])">{{ ucfirst($supplier->status) }}</span>
                        </td>
                        <td class="p-3">{{ $supplier->created_at?->format('Y-m-d') }}</td>
                        <td class="p-3">
                            <a href="{{ route('admin.b2b.suppliers.view', $supplier->id) }}"
                                class="text-blue-600 hover:underline">Review</a>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="p-6 text-center text-gray-500">No supplier applications yet.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div class="mt-4">{{ $suppliers->links() }}</div>
</x-admin::layouts>
