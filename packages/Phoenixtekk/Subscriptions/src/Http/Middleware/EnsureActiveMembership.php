<?php

namespace Phoenixtekk\Subscriptions\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Phoenixtekk\Subscriptions\Services\MembershipService;

/**
 * Gate storefront routes behind an active membership. Logged-out → customer login;
 * logged-in non-members → the pricing page.
 */
class EnsureActiveMembership
{
    public function __construct(protected MembershipService $memberships) {}

    public function handle(Request $request, Closure $next)
    {
        $customer = auth()->guard('customer')->user();

        if (! $customer) {
            return redirect()->route('shop.customer.session.index');
        }

        if (! $this->memberships->isMember($customer)) {
            return redirect()->route('shop.subscriptions.pricing')
                ->with('warning', 'An active membership is required to access that.');
        }

        return $next($request);
    }
}
