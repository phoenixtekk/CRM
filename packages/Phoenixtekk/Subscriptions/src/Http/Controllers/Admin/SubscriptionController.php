<?php

namespace Phoenixtekk\Subscriptions\Http\Controllers\Admin;

use Illuminate\Support\Facades\Artisan;
use Phoenixtekk\Subscriptions\Models\Plan;
use Phoenixtekk\Subscriptions\Models\Subscription;
use Phoenixtekk\Subscriptions\Support\Settings;
use Webkul\Admin\Http\Controllers\Controller;

/**
 * Admin: read-only view of who is subscribed, plus a one-click "Sync plans" action that creates the
 * active provider's products/prices via API (so the whole flow stays in the UI).
 */
class SubscriptionController extends Controller
{
    public function index()
    {
        $provider      = Settings::provider();
        $planCount     = Plan::where('provider', $provider)->whereNotNull('provider_price_id')->count();
        $subscriptions = Subscription::with('customer')->orderByDesc('id')->paginate(25);

        return view('subscriptions::admin.index', compact('subscriptions', 'provider', 'planCount'));
    }

    /** Create the active provider's products/prices via API (runs subscriptions:sync-plans). */
    public function sync()
    {
        try {
            $code   = Artisan::call('subscriptions:sync-plans');
            $output = trim(preg_replace('/\s+/', ' ', Artisan::output()));

            if ($code === 0) {
                session()->flash('success', 'Plans synced to ' . Settings::provider() . '. ' . $output);
            } else {
                session()->flash('error', 'Sync finished with errors. ' . $output);
            }
        } catch (\Throwable $e) {
            session()->flash('error', 'Sync failed: ' . $e->getMessage());
        }

        return redirect()->route('admin.subscriptions.index');
    }
}
