<?php
/**
 * Surgical downloadable-link swap (Phase 0 — deliverable guarantee).
 *
 * For each SKU in the manifest, DELETE its existing downloadable links (and their private-disk
 * files) and attach exactly ONE link: the "Complete Solution Package" bundle. Touches ONLY the
 * downloadable links — does NOT alter name/description/price/image/categories (unlike the loader's
 * --update-content, which rewrites all of those). Run on linuxg5 from /home/workplace/public_html.
 *
 * Manifest JSON:
 *   { "bundles_dir": "/tmp/ptk-bundles", "title": "Complete Solution Package (...)",
 *     "entries": [ { "sol_code":"ADOBELIC", "file_name":"ADOBELIC-Complete-Solution.zip",
 *                    "skus":["PTK-ADOBELIC-COMM-001", ...] }, ... ] }
 *
 * Usage:
 *   sudo -u workplace php8.4 swap-downloads-to-bundle.php --manifest=/tmp/bundle-manifest.json [--only=SOL] [--dry-run]
 */

require '/home/workplace/public_html/vendor/autoload.php';
$app = require '/home/workplace/public_html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

$opt = ['manifest' => null, 'only' => null, 'dry' => false];
foreach ($argv as $a) {
    if (str_starts_with($a, '--manifest=')) $opt['manifest'] = substr($a, 11);
    elseif (str_starts_with($a, '--only='))  $opt['only'] = substr($a, 7);
    elseif ($a === '--dry-run')              $opt['dry'] = true;
}
if (!$opt['manifest'] || !is_file($opt['manifest'])) { fwrite(STDERR, "ERROR: --manifest=<file> required\n"); exit(1); }

$m = json_decode(file_get_contents($opt['manifest']), true);
if (!is_array($m) || empty($m['entries'])) { fwrite(STDERR, "ERROR: bad manifest\n"); exit(1); }

$appBase    = base_path();
$bundlesDir = rtrim($m['bundles_dir'] ?? '/tmp/ptk-bundles', '/');
$title      = $m['title'] ?? 'Complete Solution Package';
$locales    = app(\Webkul\Core\Repositories\LocaleRepository::class)->all();
$privBase   = $appBase . '/storage/app/private/';
$privDir    = $privBase . 'product_downloadable_links';
if (!is_dir($privDir)) @mkdir($privDir, 0775, true);

$skusDone = 0; $skusSkipped = 0; $solDone = 0; $problems = [];

foreach ($m['entries'] as $e) {
    $sol = $e['sol_code'] ?? '?';
    if ($opt['only'] && $sol !== $opt['only']) continue;
    $bundleSrc = $bundlesDir . '/' . $e['file_name'];
    if (!is_file($bundleSrc)) { $problems[] = "$sol: bundle missing at $bundleSrc"; continue; }

    foreach ($e['skus'] as $sku) {
        $p = DB::table('products')->where('sku', $sku)->first();
        if (!$p) { $problems[] = "$sku: product not found"; $skusSkipped++; continue; }
        if (($p->type ?? '') !== 'downloadable') { $problems[] = "$sku: not downloadable (type={$p->type})"; $skusSkipped++; continue; }

        if ($opt['dry']) {
            $cur = DB::table('product_downloadable_links')->where('product_id', $p->id)->count();
            echo "DRY  $sku (id={$p->id}): would replace {$cur} link(s) with 1 bundle ({$e['file_name']})\n";
            $skusDone++; continue;
        }

        DB::beginTransaction();
        try {
            // delete existing links + their stored files
            foreach (\Webkul\Product\Models\ProductDownloadableLink::where('product_id', $p->id)->get() as $l) {
                if ($l->file) {
                    foreach (['/storage/app/private/', '/storage/app/public/'] as $dk) {
                        $f = $appBase . $dk . $l->file; if (is_file($f)) @unlink($f);
                    }
                }
                $l->delete();
            }
            // attach the single bundle
            $stored = 'product_downloadable_links/' . $p->id . '-' . $e['file_name'];
            if (!copy($bundleSrc, $privBase . $stored)) throw new \RuntimeException("copy failed -> $stored");
            $link = new \Webkul\Product\Models\ProductDownloadableLink();
            $link->product_id = $p->id;
            $link->type       = 'file';
            $link->downloads  = 0;
            $link->sort_order = 1;
            $link->price      = 0;
            $link->file       = $stored;
            $link->file_name  = $e['file_name'];
            foreach ($locales as $loc) { $link->translateOrNew($loc->code)->title = $title; }
            $link->save();

            DB::commit();
            $skusDone++;
            echo "OK   $sku (id={$p->id}) -> 1 bundle link\n";
        } catch (\Throwable $ex) {
            DB::rollBack();
            $problems[] = "$sku: " . $ex->getMessage();
            $skusSkipped++;
        }
    }
    $solDone++;
}

echo "\n" . ($opt['dry'] ? 'DRY-RUN ' : '') . "done: {$solDone} solution(s), {$skusDone} sku(s) swapped, {$skusSkipped} skipped\n";
if ($problems) echo "PROBLEMS:\n  " . implode("\n  ", $problems) . "\n";

if (!$opt['dry'] && $skusDone) {
    \Artisan::call('indexer:index');
    echo "reindexed\n";
}
