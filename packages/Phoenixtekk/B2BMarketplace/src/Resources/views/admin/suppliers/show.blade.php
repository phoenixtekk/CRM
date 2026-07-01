<x-admin::layouts>
    <x-slot:title>{{ $supplier->company_name }} — Supplier</x-slot:title>

    <div class="flex items-center justify-between">
        <p class="text-xl font-bold text-gray-800 dark:text-white">{{ $supplier->company_name }}</p>
        <a href="{{ route('admin.b2b.suppliers.index') }}" class="text-blue-600 hover:underline">&larr; Back</a>
    </div>

    <div class="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-3">
        <div class="lg:col-span-2 rounded-lg border bg-white p-4 dark:bg-gray-900 dark:border-gray-800">
            <p class="mb-3 font-semibold text-gray-700 dark:text-gray-200">Application details</p>
            <dl class="grid grid-cols-2 gap-2 text-sm text-gray-700 dark:text-gray-300">
                <dt class="font-medium">Status</dt><dd>{{ ucfirst($supplier->status) }}</dd>
                <dt class="font-medium">Legal name</dt><dd>{{ $supplier->legal_name ?: '—' }}</dd>
                <dt class="font-medium">Email</dt><dd>{{ $supplier->email }}</dd>
                <dt class="font-medium">Phone</dt><dd>{{ $supplier->phone ?: '—' }}</dd>
                <dt class="font-medium">Website</dt><dd>{{ $supplier->website ?: '—' }}</dd>
                <dt class="font-medium">Tax ID</dt><dd>{{ $supplier->tax_id ?: '—' }}</dd>
                <dt class="font-medium">Address</dt><dd>{{ $supplier->address ?: '—' }}</dd>
                <dt class="font-medium">Applicant</dt><dd>{{ $supplier->applicant?->name }} (#{{ $supplier->customer_id }})</dd>
                <dt class="font-medium">Approved by</dt><dd>{{ $supplier->approved_by ? 'admin #' . $supplier->approved_by . ' @ ' . $supplier->approved_at?->format('Y-m-d H:i') : '—' }}</dd>
                @if ($supplier->rejected_reason)
                    <dt class="font-medium">Rejected reason</dt><dd>{{ $supplier->rejected_reason }}</dd>
                @endif
            </dl>

            @if ($supplier->notes)
                <p class="mt-3 text-sm text-gray-500">Notes: {{ $supplier->notes }}</p>
            @endif
        </div>

        <div class="rounded-lg border bg-white p-4 dark:bg-gray-900 dark:border-gray-800">
            <p class="mb-3 font-semibold text-gray-700 dark:text-gray-200">Actions</p>
            <form method="POST" action="{{ route('admin.b2b.suppliers.update_status', $supplier->id) }}" class="space-y-3">
                @csrf
                @method('PUT')
                <textarea name="rejected_reason" rows="2" placeholder="Reason (for reject)"
                    class="w-full rounded border px-2 py-1 text-sm dark:bg-gray-950 dark:text-white"></textarea>
                <div class="flex flex-wrap gap-2">
                    <button name="action" value="approve" class="rounded bg-green-600 px-3 py-1.5 text-sm font-semibold text-white">Approve</button>
                    <button name="action" value="reject" class="rounded bg-red-600 px-3 py-1.5 text-sm font-semibold text-white">Reject</button>
                    <button name="action" value="suspend" class="rounded bg-amber-600 px-3 py-1.5 text-sm font-semibold text-white">Suspend</button>
                    <button name="action" value="reactivate" class="rounded bg-blue-600 px-3 py-1.5 text-sm font-semibold text-white">Reactivate</button>
                </div>
            </form>
        </div>
    </div>

    <div class="mt-4 rounded-lg border bg-white p-4 dark:bg-gray-900 dark:border-gray-800">
        <p class="mb-2 font-semibold text-gray-700 dark:text-gray-200">Members ({{ $supplier->users->count() }})</p>
        <ul class="text-sm text-gray-600 dark:text-gray-300">
            @foreach ($supplier->users as $u)
                <li>{{ $u->customer?->name ?? 'Customer #' . $u->customer_id }} — {{ $u->role }}</li>
            @endforeach
        </ul>
    </div>
</x-admin::layouts>
