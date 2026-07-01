@foreach (['success' => 'green', 'warning' => 'amber', 'error' => 'red'] as $type => $color)
    @if (session($type))
        <div class="mb-4 rounded border border-{{ $color }}-300 bg-{{ $color }}-50 px-4 py-3 text-sm text-{{ $color }}-700">
            {{ session($type) }}
        </div>
    @endif
@endforeach

@if ($errors->any())
    <div class="mb-4 rounded border border-red-300 bg-red-50 px-4 py-3 text-sm text-red-700">
        <ul class="list-disc pl-5">
            @foreach ($errors->all() as $e)<li>{{ $e }}</li>@endforeach
        </ul>
    </div>
@endif
