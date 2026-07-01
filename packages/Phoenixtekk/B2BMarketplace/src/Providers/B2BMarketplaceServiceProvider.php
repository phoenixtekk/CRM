<?php

namespace Phoenixtekk\B2BMarketplace\Providers;

use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;
use Phoenixtekk\B2BMarketplace\Models\Company;
use Phoenixtekk\B2BMarketplace\Models\Rfq;
use Phoenixtekk\B2BMarketplace\Models\Supplier;
use Phoenixtekk\B2BMarketplace\Policies\CompanyPolicy;
use Phoenixtekk\B2BMarketplace\Policies\RfqPolicy;
use Phoenixtekk\B2BMarketplace\Policies\SupplierPolicy;

/**
 * Phoenixtekk B2B Marketplace — native Bagisto package service provider.
 *
 * Registers routes, views, migrations, the admin menu/ACL entries, and authorization
 * policies. It does NOT modify Bagisto core; everything is additive and namespaced.
 */
class B2BMarketplaceServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        $this->loadMigrationsFrom(__DIR__ . '/../Database/Migrations');

        $this->loadRoutesFrom(__DIR__ . '/../Routes/admin-routes.php');
        $this->loadRoutesFrom(__DIR__ . '/../Routes/shop-routes.php');

        // Views are namespaced as `b2b::` (e.g. b2b::admin.suppliers.index).
        $this->loadViewsFrom(__DIR__ . '/../Resources/views', 'b2b');

        $this->registerPolicies();
    }

    /**
     * Register services / config.
     */
    public function register(): void
    {
        // Append our admin menu + ACL entries to Bagisto's (numeric arrays are concatenated).
        $this->mergeConfigFrom(__DIR__ . '/../Config/menu.php', 'menu.admin');
        $this->mergeConfigFrom(__DIR__ . '/../Config/acl.php', 'acl');
    }

    /**
     * Map Eloquent models to their authorization policies.
     */
    protected function registerPolicies(): void
    {
        Gate::policy(Supplier::class, SupplierPolicy::class);
        Gate::policy(Company::class, CompanyPolicy::class);
        Gate::policy(Rfq::class, RfqPolicy::class);
    }
}
