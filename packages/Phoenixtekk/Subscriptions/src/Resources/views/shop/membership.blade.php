<x-shop::layouts>
    <x-slot:title>My Membership — Phoenixtekk Workplace</x-slot>

    <div class="container mt-12 max-lg:px-4 max-w-3xl">
        <h1 class="text-3xl font-medium mb-6">My Membership</h1>

        @foreach (['success' => 'green', 'warning' => 'yellow', 'error' => 'red'] as $key => $color)
            @if (session($key))
                <div class="bg-{{ $color }}-50 border border-{{ $color }}-200 text-{{ $color }}-800 rounded p-3 mb-5">
                    {{ session($key) }}
                </div>
            @endif
        @endforeach

        @if ($subscription && $subscription->isActive())
            <div class="border rounded-xl p-6">
                <div class="flex items-center justify-between mb-4">
                    <div>
                        <p class="text-sm text-gray-500">Current plan</p>
                        <p class="text-xl font-semibold">{{ ucfirst($subscription->tier) }}
                            <span class="text-gray-400 text-base">/ {{ $subscription->interval ?? 'month' }}</span>
                        </p>
                    </div>
                    <span class="bg-green-100 text-green-800 text-sm px-3 py-1 rounded-full">
                        {{ ucfirst($subscription->status) }}
                    </span>
                </div>

                @if ($subscription->current_period_end)
                    <p class="text-sm text-gray-600">
                        {{ $subscription->cancel_at_period_end ? 'Access ends' : 'Renews' }}
                        on {{ $subscription->current_period_end->format('F j, Y') }}.
                    </p>
                @endif

                <div class="flex gap-3 mt-6">
                    <a href="{{ route('shop.subscriptions.library') }}"
                        class="bg-violet-600 hover:bg-violet-700 text-white rounded-lg px-5 py-2.5 font-medium">
                        Browse member library
                    </a>
                    <a href="{{ route('shop.subscriptions.portal') }}"
                        class="border border-gray-300 hover:bg-gray-50 rounded-lg px-5 py-2.5 font-medium">
                        Manage billing
                    </a>
                </div>
            </div>
        @else
            <div class="border rounded-xl p-8 text-center">
                <p class="text-gray-600 mb-5">You don't have an active membership yet.</p>
                <a href="{{ route('shop.subscriptions.pricing') }}"
                    class="bg-violet-600 hover:bg-violet-700 text-white rounded-lg px-6 py-2.5 font-medium">
                    View membership plans
                </a>
            </div>
        @endif
    </div>
</x-shop::layouts>
