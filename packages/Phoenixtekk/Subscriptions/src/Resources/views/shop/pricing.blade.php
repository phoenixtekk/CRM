<x-shop::layouts>
    <x-slot:title>Membership Plans — Phoenixtekk Workplace</x-slot>

    @push('styles')
    <style>
        .ptk-sub { max-width: 1120px; margin: 32px auto 64px; padding: 0 16px; }
        .ptk-hero { position: relative; overflow: hidden; border-radius: 28px; color: #fff; text-align: center;
            padding: 60px 24px; background: linear-gradient(135deg, #7c3aed 0%, #4f46e5 55%, #9333ea 100%);
            box-shadow: 0 24px 60px -24px rgba(79, 70, 229, .65); }
        .ptk-hero::before, .ptk-hero::after { content: ""; position: absolute; border-radius: 999px; filter: blur(40px); }
        .ptk-hero::before { width: 240px; height: 240px; top: -80px; right: -60px; background: rgba(255, 255, 255, .14); }
        .ptk-hero::after { width: 260px; height: 260px; bottom: -110px; left: -50px; background: rgba(236, 72, 153, .22); }
        .ptk-hero__inner { position: relative; }
        .ptk-hero__badge { display: inline-block; background: rgba(255, 255, 255, .16);
            border: 1px solid rgba(255, 255, 255, .28); padding: 7px 16px; border-radius: 999px; font-size: 14px; font-weight: 600; }
        .ptk-hero h1 { margin: 18px 0 0; font-size: clamp(28px, 4.2vw, 46px); font-weight: 800; line-height: 1.12; }
        .ptk-hero p { max-width: 640px; margin: 18px auto 0; font-size: 18px; line-height: 1.6; color: #ede9fe; }
        .ptk-hero__tags { margin-top: 22px; display: flex; flex-wrap: wrap; gap: 8px 22px; justify-content: center;
            font-size: 14px; color: #ddd6fe; }
        .ptk-banner { margin-top: 22px; border-radius: 14px; padding: 14px; text-align: center; }
        .ptk-banner--ok { background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46; }
        .ptk-banner--err { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; }
        .ptk-grid { margin-top: 40px; display: grid; grid-template-columns: repeat(3, 1fr); gap: 22px; align-items: stretch; }
        @media (max-width: 880px) { .ptk-grid { grid-template-columns: 1fr; max-width: 440px; margin-left: auto; margin-right: auto; } }
        .ptk-card { position: relative; display: flex; flex-direction: column; background: #fff; border-radius: 20px;
            padding: 28px; border: 1px solid #eef2ff; box-shadow: 0 8px 22px -14px rgba(17, 24, 39, .3); transition: transform .15s, box-shadow .15s; }
        .ptk-card:hover { transform: translateY(-4px); box-shadow: 0 22px 40px -20px rgba(79, 70, 229, .45); }
        .ptk-card--popular { border: 2px solid var(--accent); box-shadow: 0 24px 48px -20px rgba(124, 58, 237, .5); }
        .ptk-tag { position: absolute; top: -13px; left: 50%; transform: translateX(-50%); background: var(--accent);
            color: #fff; font-size: 12px; font-weight: 700; padding: 5px 14px; border-radius: 999px; white-space: nowrap; }
        .ptk-card h2 { margin: 0; font-size: 19px; font-weight: 800; color: #111827; }
        .ptk-card__desc { margin: 6px 0 0; font-size: 13.5px; color: #6b7280; min-height: 38px; }
        .ptk-price { margin-top: 18px; display: flex; align-items: flex-end; gap: 6px; }
        .ptk-price b { font-size: 42px; font-weight: 800; color: #111827; line-height: 1; }
        .ptk-price span { color: #6b7280; margin-bottom: 4px; }
        .ptk-annual { margin-top: 8px; font-size: 13.5px; color: #6b7280; }
        .ptk-annual b { color: var(--accent); }
        .ptk-save { display: inline-block; margin-left: 6px; background: var(--accent-soft); color: var(--accent);
            font-size: 12px; font-weight: 700; padding: 2px 9px; border-radius: 999px; }
        .ptk-feat { list-style: none; padding: 0; margin: 22px 0 0; flex: 1; }
        .ptk-feat li { display: flex; gap: 10px; align-items: flex-start; font-size: 14px; color: #374151; margin: 11px 0; }
        .ptk-feat svg { flex: none; width: 18px; height: 18px; color: var(--accent); margin-top: 1px; }
        .ptk-actions { margin-top: 24px; }
        .ptk-btn { display: block; width: 100%; text-align: center; border: 0; cursor: pointer; border-radius: 14px;
            padding: 14px; font-size: 15px; font-weight: 700; color: #fff; background: var(--accent);
            box-shadow: 0 10px 20px -10px var(--accent); transition: filter .15s; text-decoration: none; }
        .ptk-btn:hover { filter: brightness(1.08); color: #fff; }
        .ptk-btn--ghost { margin-top: 10px; background: #fff; color: #374151; border: 1px solid #e5e7eb;
            box-shadow: none; padding: 11px; font-size: 13.5px; font-weight: 600; }
        .ptk-btn--ghost:hover { background: #f9fafb; filter: none; color: #374151; }
        .ptk-note { text-align: center; font-size: 12px; color: #9ca3af; margin-top: 8px; }
        .ptk-foot { margin-top: 36px; display: flex; flex-wrap: wrap; gap: 8px 26px; justify-content: center;
            font-size: 13.5px; color: #6b7280; }
    </style>
    @endpush

    <div class="ptk-sub">
        <div class="ptk-hero">
            <div class="ptk-hero__inner">
                <span class="ptk-hero__badge">⚡ Phoenixtekk Membership</span>
                <h1>Deploy Technologies Like a Pro —<br>Without The Consulting Invoice</h1>
                <p>Unlimited access to every solution: step-by-step documentation and battle-tested PowerShell you
                   run yourself. Simpler, cheaper, and proven — minus the hourly rates.</p>
                <div class="ptk-hero__tags">
                    <span>✓ New solutions every month</span>
                    <span>✓ Cancel anytime</span>
                    <span>✓ Secure Stripe checkout</span>
                </div>
            </div>
        </div>

        @if (session('error'))
            <div class="ptk-banner ptk-banner--err">{{ session('error') }}</div>
        @endif

        @if ($current)
            <div class="ptk-banner ptk-banner--ok">
                You have an active <strong>{{ ucfirst($current->tier) }}</strong> membership.
                <a href="{{ route('shop.subscriptions.membership') }}" style="font-weight:700;text-decoration:underline;color:inherit;">Manage it →</a>
            </div>
        @endif

        <div class="ptk-grid">
            @php
                $accents = [
                    'individual'   => ['#4f46e5', '#eef2ff'],
                    'professional' => ['#7c3aed', '#f5f3ff'],
                    'enterprise'   => ['#c026d3', '#fdf4ff'],
                ];
            @endphp

            @foreach ($tiers as $key => $tier)
                @php
                    [$accent, $soft] = $accents[$key] ?? $accents['individual'];
                    $popular = $key === 'professional';
                    $save = $tier['monthly'] > 0 ? round((1 - ($tier['annual'] / ($tier['monthly'] * 12))) * 100) : 0;
                @endphp

                <div class="ptk-card {{ $popular ? 'ptk-card--popular' : '' }}" style="--accent: {{ $accent }}; --accent-soft: {{ $soft }};">
                    @if ($popular)<span class="ptk-tag">★ Most popular</span>@endif

                    <h2>{{ $tier['name'] }}</h2>
                    <p class="ptk-card__desc">{{ $tier['description'] ?? '' }}</p>

                    <div class="ptk-price"><b>${{ number_format($tier['monthly'] / 100, 0) }}</b><span>/month</span></div>
                    <p class="ptk-annual">
                        or <b>${{ number_format($tier['annual'] / 100, 0) }}/year</b>
                        @if ($save > 0)<span class="ptk-save">save {{ $save }}%</span>@endif
                    </p>

                    @if (! empty($tier['features']))
                        <ul class="ptk-feat">
                            @foreach ($tier['features'] as $feature)
                                <li>
                                    <svg width="18" height="18" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M16.704 5.29a1 1 0 010 1.42l-7.5 7.5a1 1 0 01-1.42 0l-3.5-3.5a1 1 0 011.42-1.42l2.79 2.79 6.79-6.79a1 1 0 011.42 0z" clip-rule="evenodd"/></svg>
                                    <span>{{ $feature }}</span>
                                </li>
                            @endforeach
                        </ul>
                    @endif

                    <div class="ptk-actions">
                        @auth('customer')
                            <form method="POST" action="{{ route('shop.subscriptions.checkout') }}">
                                @csrf
                                <input type="hidden" name="tier" value="{{ $key }}">
                                <button class="ptk-btn" type="submit" name="interval" value="month">Get {{ $tier['name'] }} →</button>
                                @if ($save > 0)
                                    <button class="ptk-btn ptk-btn--ghost" type="submit" name="interval" value="year">Pay yearly &amp; save {{ $save }}%</button>
                                @endif
                            </form>
                        @else
                            <a class="ptk-btn" href="{{ route('shop.customer.session.index') }}">Sign in to subscribe →</a>
                            <p class="ptk-note">New here? You can create an account at checkout.</p>
                        @endauth
                    </div>
                </div>
            @endforeach
        </div>

        <div class="ptk-foot">
            <span>🔒 Secure Stripe checkout</span>
            <span>↻ Cancel anytime from your account</span>
            <span>✓ Instant access to the member library</span>
        </div>
    </div>
</x-shop::layouts>
