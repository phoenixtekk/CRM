<x-admin::layouts>
    <x-slot:title>Subscriptions</x-slot>

    <div class="flex items-center justify-between p-4">
        <div>
            <p class="text-xl text-gray-800 dark:text-white font-bold">Subscriptions</p>
            <p class="text-sm text-gray-500">
                Active provider: <span class="font-semibold">{{ ucfirst($provider) }}</span>
                · {{ $planCount }} plan price(s) synced
            </p>
        </div>

        <form method="POST" action="{{ route('admin.subscriptions.sync') }}"
            onsubmit="return confirm('Create/update the {{ ucfirst($provider) }} products &amp; prices for all tiers? This calls the provider API.');">
            @csrf
            <button type="submit"
                class="primary-button px-4 py-2 rounded-lg bg-violet-600 hover:bg-violet-700 text-white font-medium">
                Sync plans to {{ ucfirst($provider) }}
            </button>
        </form>
    </div>

    @foreach (['success' => 'green', 'error' => 'red', 'warning' => 'yellow'] as $key => $color)
        @if (session($key))
            <div class="mx-4 mb-3 rounded-lg p-3 text-sm bg-{{ $color }}-50 border border-{{ $color }}-200 text-{{ $color }}-800">
                {{ session($key) }}
            </div>
        @endif
    @endforeach

    <div class="bg-white dark:bg-gray-900 rounded-lg box-shadow p-4 m-4">
        <table class="w-full text-left">
            <thead>
                <tr class="border-b dark:border-gray-800 text-gray-600 dark:text-gray-300">
                    <th class="py-2 px-3">ID</th>
                    <th class="py-2 px-3">Customer</th>
                    <th class="py-2 px-3">Provider</th>
                    <th class="py-2 px-3">Tier</th>
                    <th class="py-2 px-3">Interval</th>
                    <th class="py-2 px-3">Status</th>
                    <th class="py-2 px-3">Renews / Ends</th>
                    <th class="py-2 px-3">Subscription ID</th>
                </tr>
            </thead>
            <tbody>
                @forelse ($subscriptions as $sub)
                    <tr class="border-b dark:border-gray-800 text-gray-700 dark:text-gray-200">
                        <td class="py-2 px-3">{{ $sub->id }}</td>
                        <td class="py-2 px-3">
                            {{ $sub->customer ? trim($sub->customer->first_name . ' ' . $sub->customer->last_name) : '—' }}
                            <div class="text-xs text-gray-400">{{ $sub->customer->email ?? '' }}</div>
                        </td>
                        <td class="py-2 px-3">{{ ucfirst($sub->provider) }}</td>
                        <td class="py-2 px-3">{{ ucfirst($sub->tier) }}</td>
                        <td class="py-2 px-3">{{ $sub->interval ?? '—' }}</td>
                        <td class="py-2 px-3">
                            <span class="px-2 py-0.5 rounded text-xs
                                {{ in_array($sub->status, ['active', 'trialing']) ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600' }}">
                                {{ ucfirst($sub->status) }}{{ $sub->cancel_at_period_end ? ' (cancels)' : '' }}
                            </span>
                        </td>
                        <td class="py-2 px-3">{{ $sub->current_period_end?->format('Y-m-d') ?? '—' }}</td>
                        <td class="py-2 px-3 text-xs text-gray-400">{{ $sub->provider_subscription_id }}</td>
                    </tr>
                @empty
                    <tr><td colspan="8" class="py-6 px-3 text-center text-gray-400">No subscriptions yet.</td></tr>
                @endforelse
            </tbody>
        </table>

        <div class="mt-4">{{ $subscriptions->links() }}</div>
    </div>
</x-admin::layouts>
