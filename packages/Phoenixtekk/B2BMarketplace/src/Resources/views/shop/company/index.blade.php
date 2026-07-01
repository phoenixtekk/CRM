<x-shop::layouts>
    <x-slot:title>Company Account</x-slot:title>

    <div class="container mx-auto max-w-3xl px-4 py-8">
        <h1 class="mb-4 text-2xl font-bold">Company Account</h1>
        @include('b2b::shop.partials.flash')

        @if (! $company)
            <div class="rounded border bg-white p-6">
                <p class="mb-4 text-gray-600">You don't belong to a company yet. Create one to manage buyers and submit RFQs as a company.</p>
                <form method="POST" action="{{ route('shop.b2b.company.store') }}" class="space-y-3">
                    @csrf
                    @foreach (['name' => 'Company name *', 'legal_name' => 'Legal name', 'email' => 'Email', 'phone' => 'Phone', 'website' => 'Website', 'tax_id' => 'Tax ID'] as $n => $l)
                        <div>
                            <label class="mb-1 block text-sm font-medium">{{ $l }}</label>
                            <input type="text" name="{{ $n }}" value="{{ old($n) }}" class="w-full rounded border px-3 py-2">
                        </div>
                    @endforeach
                    <div>
                        <label class="mb-1 block text-sm font-medium">Address</label>
                        <textarea name="address" rows="2" class="w-full rounded border px-3 py-2">{{ old('address') }}</textarea>
                    </div>
                    <button class="rounded bg-blue-600 px-5 py-2.5 font-semibold text-white">Create company</button>
                </form>
            </div>
        @else
            <div class="mb-6 rounded border bg-white p-4">
                <p class="text-lg font-semibold">{{ $company->name }}</p>
                <p class="text-sm text-gray-500">{{ $company->email }} · your role: <strong>{{ $membership->role }}</strong></p>
            </div>

            <h2 class="mb-2 text-lg font-semibold">Members</h2>
            <table class="mb-6 w-full rounded border bg-white text-left text-sm">
                <thead class="border-b bg-gray-50"><tr><th class="p-2">Name</th><th class="p-2">Role</th>@if ($canManage)<th class="p-2"></th>@endif</tr></thead>
                <tbody>
                    @foreach ($users as $u)
                        <tr class="border-b">
                            <td class="p-2">{{ $u->customer?->name ?? 'Customer #' . $u->customer_id }}</td>
                            <td class="p-2">{{ $u->role }}</td>
                            @if ($canManage)
                                <td class="p-2 text-right">
                                    @if ($u->role !== 'owner')
                                        <form method="POST" action="{{ route('shop.b2b.company.users.destroy', [$company->id, $u->id]) }}" onsubmit="return confirm('Remove this user?')">
                                            @csrf @method('DELETE')
                                            <button class="text-red-600 hover:underline">Remove</button>
                                        </form>
                                    @endif
                                </td>
                            @endif
                        </tr>
                    @endforeach
                </tbody>
            </table>

            @if ($canManage)
                <h2 class="mb-2 text-lg font-semibold">Add a user</h2>
                <form method="POST" action="{{ route('shop.b2b.company.users.store', $company->id) }}" class="flex flex-wrap items-end gap-2 rounded border bg-white p-4">
                    @csrf
                    <div class="grow">
                        <label class="mb-1 block text-sm font-medium">Customer email</label>
                        <input type="email" name="email" required class="w-full rounded border px-3 py-2">
                    </div>
                    <div>
                        <label class="mb-1 block text-sm font-medium">Role</label>
                        <select name="role" class="rounded border px-3 py-2">
                            <option value="buyer">Buyer</option>
                            <option value="admin">Admin</option>
                            <option value="viewer">Viewer</option>
                        </select>
                    </div>
                    <button class="rounded bg-blue-600 px-4 py-2 font-semibold text-white">Add</button>
                </form>
            @endif
        @endif
    </div>
</x-shop::layouts>
