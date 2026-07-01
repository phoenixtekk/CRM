<?php

namespace Phoenixtekk\Subscriptions\Http\Controllers\Shop;

use Illuminate\Http\Request;
use Phoenixtekk\Subscriptions\Contracts\BillingProvider;
use Phoenixtekk\Subscriptions\Models\Plan;
use Phoenixtekk\Subscriptions\Services\MembershipService;
use Phoenixtekk\Subscriptions\Support\Settings;
use Webkul\Shop\Http\Controllers\Controller;

class SubscriptionController extends Controller
{
    public function __construct(
        protected MembershipService $memberships
    ) {}

    /** Resolve the billing provider lazily — only checkout/portal need the provider configured. */
    protected function billing(): BillingProvider
    {
        return app(BillingProvider::class);
    }

    /** Public pricing page for the three tiers. */
    public function pricing()
    {
        $tiers   = config('subscriptions.tiers');
        $current = $this->memberships->activeSubscription(auth()->guard('customer')->user());

        return view('subscriptions::shop.pricing', compact('tiers', 'current'));
    }

    /** Start a hosted Checkout for {tier}/{interval} with the active provider. */
    public function checkout(Request $request)
    {
        $request->validate([
            'tier'     => 'required|in:individual,professional,enterprise',
            'interval' => 'required|in:month,year',
        ]);

        $customer = auth()->guard('customer')->user();

        $plan = Plan::where('provider', Settings::provider())
            ->where('tier', $request->tier)
            ->where('interval', $request->interval)
            ->first();

        if (! $plan || empty($plan->provider_product_id)) {
            return back()->with('error', 'This plan is not available for checkout yet. Please try again later.');
        }

        // reuse an existing processor-side customer id for this buyer if we have one
        $existingCustomer = $this->memberships->activeSubscription($customer)?->provider_customer_id;
        $billing = $this->billing();
        $providerCustomerId = $billing->ensureCustomer($customer, $existingCustomer);

        $url = $billing->createCheckoutSession(
            $customer,
            $providerCustomerId,
            $plan,
            route('shop.subscriptions.success'),
            route('shop.subscriptions.pricing')
        );

        return redirect()->away($url);
    }

    /** Processor redirects here after checkout; the webhook activates the membership. */
    public function success()
    {
        return redirect()->route('shop.subscriptions.membership')
            ->with('success', 'Thanks! Your membership is being activated — it appears here within a few moments.');
    }

    /** "My Membership" — status + manage (hosted billing/customer portal). */
    public function membership()
    {
        $subscription = $this->memberships->activeSubscription(auth()->guard('customer')->user());

        return view('subscriptions::shop.membership', compact('subscription'));
    }

    /** Redirect to the active processor's hosted billing/customer portal to update/cancel. */
    public function portal()
    {
        $customer = auth()->guard('customer')->user();
        $providerCustomerId = $this->memberships->activeSubscription($customer)?->provider_customer_id;

        if (! $providerCustomerId) {
            return redirect()->route('shop.subscriptions.membership')->with('warning', 'No active billing profile found.');
        }

        $url = $this->billing()->billingPortalUrl($providerCustomerId, route('shop.subscriptions.membership'));

        return redirect()->away($url);
    }
}
