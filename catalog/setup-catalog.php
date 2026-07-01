<?php
/**
 * Phoenixtekk Workplace Marketplace — ONE-TIME catalog setup.
 * Creates the account-wide subscription tiers (Individual / Professional / Enterprise).
 * These are NOT per-solution — run this once. Idempotent (existing SKUs are skipped).
 *
 * RUN AS SITE OWNER, PHP 8.4, FROM THE BAGISTO APP ROOT:
 *   sudo -u workplace php8.4 setup-catalog.php --dry-run
 *   sudo -u workplace php8.4 setup-catalog.php
 *
 * Recurring billing is deferred: tiers publish as simple catalog entries with the
 * MONTHLY price shown and the annual price in the description. Wire a subscription
 * extension before relying on auto-charge.
 */

$CONFIG = [
    'channel_id'          => 1,
    'channel_code'        => 'default',
    'locale_code'         => 'en',
    'attribute_family_id' => 1,
    'inventory_source_id' => 1,
    'digital_qty'         => 999999,
];

$appBase = __DIR__;
if (!file_exists($appBase . '/vendor/autoload.php')) {
    fwrite(STDERR, "ERROR: run from the Bagisto app root.\n"); exit(2);
}
require $appBase . '/vendor/autoload.php';
$app = require_once $appBase . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$dry = in_array('--dry-run', array_slice($argv, 1), true);
$jsonPath = $appBase . '/catalog/subscriptions.json';
if (!is_file($jsonPath)) { fwrite(STDERR, "ERROR: catalog/subscriptions.json not found.\n"); exit(2); }
$data = json_decode((string) file_get_contents($jsonPath), true);

// resolve category id from category_path leaf
$catIds = [];
$leaf = end($data['category_path']);
$catRepo = app(\Webkul\Category\Repositories\CategoryRepository::class);
foreach ($catRepo->all() as $cat) {
    $name = (method_exists($cat, 'translate') && $cat->translate($CONFIG['locale_code']))
        ? $cat->translate($CONFIG['locale_code'])->name : ($cat->name ?? null);
    if ($name !== null && strcasecmp(trim($name), trim($leaf)) === 0) { $catIds = [$cat->id]; break; }
}

$productRepo = app(\Webkul\Product\Repositories\ProductRepository::class);
$exit = 0;
foreach ($data['tiers'] as $t) {
    $sku = $t['sku'];
    try {
        if ($productRepo->findOneByField('sku', $sku)) { echo "SKIP   $sku (exists)\n"; continue; }
        if ($dry) { echo "DRY    would CREATE $sku @ \$" . number_format($t['price'], 2) . "/mo\n"; continue; }

        $product = $productRepo->create([
            'type' => 'simple', 'attribute_family_id' => $CONFIG['attribute_family_id'], 'sku' => $sku,
        ]);
        $productRepo->update([
            'channel' => $CONFIG['channel_code'], 'locale' => $CONFIG['locale_code'], 'sku' => $sku,
            'name' => $t['name'], 'url_key' => strtolower(str_replace([' ', '—', '/'], ['-', '', '-'], $t['name'])),
            'short_description' => $t['short_description'], 'description' => $t['description'],
            'price' => (float) $t['price'], 'weight' => 0, 'status' => 1, 'visible_individually' => 1,
            'meta_title' => $t['name'], 'meta_description' => strip_tags($t['short_description']),
            'channels' => [$CONFIG['channel_id']], 'categories' => $catIds,
            'inventories' => [$CONFIG['inventory_source_id'] => $CONFIG['digital_qty']],
        ], $product->id);
        echo "CREATE $sku\n";
    } catch (\Throwable $e) { $exit = 1; echo "FAIL   $sku — " . $e->getMessage() . "\n"; }
}
exit($exit);
