<?php

namespace Phoenixtekk\Subscriptions\Console\Commands;

use Illuminate\Console\Command;
use Phoenixtekk\Subscriptions\Contracts\BillingProvider;
use Phoenixtekk\Subscriptions\Models\Plan;
use Phoenixtekk\Subscriptions\Support\Settings;

/**
 * Creates the active provider's products + monthly/annual prices for each tier (from config) and
 * stores the resulting ids in pt_sub_plans, scoped to the active provider. Run once per provider
 * after setting that provider's keys (test/sandbox first).
 *
 *   php artisan subscriptions:sync-plans
 *
 * Provider-agnostic: it talks to whatever BILLING_PROVIDER resolves to. Skips a tier already synced
 * for the active provider unless --force is given.
 */
class SyncPlans extends Command
{
    protected $signature = 'subscriptions:sync-plans {--force : recreate products/prices even if already stored}';

    protected $description = 'Create the active provider\'s products/prices for membership tiers and store their ids.';

    public function handle(BillingProvider $billing): int
    {
        $provider = Settings::provider();
        $currency = Settings::currency();
        $tiers    = config('subscriptions.tiers', []);

        $this->info("Active provider: {$provider}");

        foreach ($tiers as $tier => $cfg) {
            $already = Plan::where('provider', $provider)->where('tier', $tier)->whereNotNull('provider_price_id')->count();
            if ($already >= 2 && ! $this->option('force')) {
                $this->line("SKIP  {$tier} (already synced for {$provider})");
                continue;
            }

            $this->line("Creating {$provider} product + prices for {$tier} …");
            $created = $billing->createProductWithPrices(
                $cfg['name'],
                ['month' => $cfg['monthly'], 'year' => $cfg['annual']],
                $currency
            );

            foreach (['month' => $cfg['monthly'], 'year' => $cfg['annual']] as $interval => $amount) {
                Plan::updateOrCreate(
                    ['provider' => $provider, 'tier' => $tier, 'interval' => $interval],
                    [
                        'provider_product_id' => $created[$interval]['product'],
                        'provider_price_id'   => $created[$interval]['price'],
                        'amount'              => $amount,
                        'currency'            => $currency,
                        'active'              => true,
                    ]
                );
                $this->info("  {$tier}/{$interval} -> {$created[$interval]['price']}");
            }
        }

        $this->newLine();
        $this->info("Done. Plans stored in pt_sub_plans for provider [{$provider}].");

        return self::SUCCESS;
    }
}
