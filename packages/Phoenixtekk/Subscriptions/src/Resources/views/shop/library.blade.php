<x-shop::layouts>
    <x-slot:title>Member Library — Phoenixtekk Workplace</x-slot>

    <div class="container mt-12 max-lg:px-4">
        <div class="flex items-center justify-between mb-8">
            <div>
                <h1 class="text-3xl font-medium">Member Library</h1>
                <p class="text-gray-500 mt-1">Download any solution's deliverables — included with your membership.</p>
            </div>
            <a href="{{ route('shop.subscriptions.membership') }}" class="text-violet-700 underline text-sm">My membership</a>
        </div>

        @if ($solutions->isEmpty())
            <p class="text-gray-500">No downloadable solutions are available yet.</p>
        @else
            <div class="space-y-4">
                @foreach ($solutions as $productId => $links)
                    <div class="border rounded-xl p-5">
                        <h2 class="text-lg font-semibold mb-3">{{ $links->first()->product_name ?? $links->first()->sku }}</h2>
                        <ul class="divide-y">
                            @foreach ($links as $link)
                                <li class="flex items-center justify-between py-2">
                                    <span class="text-sm text-gray-700">{{ $link->link_title ?: $link->file_name }}</span>
                                    <a href="{{ route('shop.subscriptions.library.download', $link->link_id) }}"
                                        class="text-violet-700 hover:text-violet-900 text-sm font-medium">Download</a>
                                </li>
                            @endforeach
                        </ul>
                    </div>
                @endforeach
            </div>
        @endif
    </div>
</x-shop::layouts>
