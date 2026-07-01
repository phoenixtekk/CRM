<?php

namespace Phoenixtekk\Subscriptions\Providers;

use Illuminate\Support\ServiceProvider;
use Phoenixtekk\Subscriptions\Contracts\BillingProvider;
use Phoenixtekk\Subscriptions\Console\Commands\SyncPlans;
use Phoenixtekk\Subscriptions\Http\Middleware\EnsureActiveMembership;
use Phoenixtekk\Subscriptions\Support\Settings;

/**
 * Phoenixtekk Subscriptions & Billing — native Bagisto package.
 *
 * Processor-abstracted: the app depends on the BillingProvider contract; the active driver (Stripe)
 * is the only place that talks to its processor. Card data never touches this server (hosted Checkout
 * + Portal). Provider is selectable in admin config / BILLING_PROVIDER.
 */
class SubscriptionsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__ . '/../Config/subscriptions.php', 'subscriptions');
        $this->mergeConfigFrom(__DIR__ . '/../Config/menu.php', 'menu.admin');
        $this->mergeConfigFrom(__DIR__ . '/../Config/acl.php', 'acl');
        $this->mergeConfigFrom(__DIR__ . '/../Config/system.php', 'core');

        // Resolve the active processor from admin config (UI) with .env fallback — switching providers
        // is a config change only (no code/redeploy).
        $this->app->bind(BillingProvider::class, function ($app) {
            $key = Settings::provider();
            $map = Settings::providerMap();

            if (empty($map[$key])) {
                throw new \RuntimeException("Unknown billing provider [{$key}]. Choose one of: " . implode(', ', array_keys($map)));
            }

            return $app->make($map[$key]);
        });
    }

    public function boot(): void
    {
        $this->loadMigrationsFrom(__DIR__ . '/../Database/Migrations');

        $this->loadRoutesFrom(__DIR__ . '/../Routes/shop-routes.php');
        $this->loadRoutesFrom(__DIR__ . '/../Routes/admin-routes.php');
        $this->loadRoutesFrom(__DIR__ . '/../Routes/webhook-routes.php');

        $this->loadViewsFrom(__DIR__ . '/../Resources/views', 'subscriptions');

        // Storefront middleware: require a logged-in customer with an active membership.
        $this->app['router']->aliasMiddleware('membership.active', EnsureActiveMembership::class);

        // Registered unconditionally so the admin "Sync plans" button (a web request) can run it too.
        $this->commands([SyncPlans::class]);
    }
}
