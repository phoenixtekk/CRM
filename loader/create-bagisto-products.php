<?php
/**
 * Phoenixtekk Workplace Marketplace — Bagisto product loader (generic, idempotent)
 *
 * Creates products via Bagisto's own ProductRepository (no REST API, no tokens).
 * Reads a schema-conformant products JSON (schema/bagisto-products.schema.json).
 *
 * PLACEMENT: must run from the Bagisto app root (where vendor/ and bootstrap/ live):
 *   /home/workplace/public_html
 *
 * RUN AS THE SITE OWNER, WITH PHP 8.4 (default `php` on linuxg5 is 8.1 and will FATAL
 * on Bagisto's platform check):
 *   sudo -u workplace php8.4 create-bagisto-products.php --inspect
 *   sudo -u workplace php8.4 create-bagisto-products.php --file=solutions/<slug>/bagisto-products.json --dry-run
 *   sudo -u workplace php8.4 create-bagisto-products.php --file=solutions/<slug>/bagisto-products.json
 *
 * Output: one line per product — CREATE / SKIP / FAIL / DRY.
 * Idempotent: existing SKUs are skipped, so it is safe to re-run after fixing config.
 */

// =========================== CONFIG (verify with --inspect) ===========================
$CONFIG = [
    'channel_id'           => 1,          // Channels pivot uses the ID
    'channel_code'         => 'default',  // attribute scoping uses the CODE
    'locale_code'          => 'en',       // attribute scoping uses the CODE
    'attribute_family_id'  => 1,          // usually 1 = Default
    'inventory_source_id'  => 1,          // usually 1
    'default_category_ids' => [],         // fallback when category_path can't be resolved
    'digital_qty'          => 9999,       // stock for digital goods
];
// ======================================================================================

$appBase = __DIR__;
if (!file_exists($appBase . '/vendor/autoload.php') || !file_exists($appBase . '/bootstrap/app.php')) {
    fwrite(STDERR, "ERROR: run this from the Bagisto app root (vendor/ and bootstrap/ not found here).\n");
    exit(2);
}

require $appBase . '/vendor/autoload.php';
$app = require_once $appBase . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

/** Resolve a repository/service out of the container. */
function r(string $cls) { return app($cls); }

// ------------------------------- arg parsing -------------------------------
$opt = ['inspect' => false, 'dry' => false, 'file' => null, 'purge' => false, 'sync_images' => false, 'replace_images' => false];
foreach (array_slice($argv, 1) as $a) {
    if ($a === '--inspect')              $opt['inspect'] = true;
    elseif ($a === '--dry-run')          $opt['dry']     = true;
    elseif ($a === '--purge')            $opt['purge']   = true;        // delete the JSON's SKUs (republish from scratch)
    elseif ($a === '--sync-images')      $opt['sync_images'] = true;    // attach base image to existing SKUs only if none (idempotent)
    elseif ($a === '--replace-images')   $opt['replace_images'] = true; // delete existing images on the SKUs, then attach the JSON image
    elseif ($a === '--update-content')   $opt['update_content'] = true; // update name/descriptions/meta on existing SKUs (re-styles HTML)
    elseif ($a === '--ensure-category')  $opt['ensure_category'] = true; // create the category_path leaf if it doesn't exist
    elseif (str_starts_with($a, '--file=')) $opt['file'] = substr($a, 7);
}
$opt += ['update_content' => false, 'ensure_category' => false];

/**
 * Inline-style description HTML so it renders on storefront themes whose CSS reset (e.g. Tailwind
 * preflight) flattens headings and lists. Inline styles win over the theme stylesheet, so the
 * markup looks the same on the site as in the editor. Source JSON stays clean/semantic.
 */
function style_html(string $h): string {
    if ($h === '') return $h;
    $styles = [
        'h2' => 'font-size:1.5rem;font-weight:700;line-height:1.3;margin:1.1rem 0 .5rem;',
        'h3' => 'font-size:1.25rem;font-weight:700;line-height:1.3;margin:1rem 0 .5rem;',
        'h4' => 'font-size:1.05rem;font-weight:700;line-height:1.3;margin:.85rem 0 .4rem;',
        'p'  => 'margin:.6rem 0;line-height:1.6;',
        'ul' => 'list-style:disc;margin:.6rem 0 .6rem 1.5rem;padding-left:1rem;',
        'ol' => 'list-style:decimal;margin:.6rem 0 .6rem 1.5rem;padding-left:1rem;',
        'li' => 'margin:.3rem 0;line-height:1.55;',
    ];
    foreach ($styles as $tag => $css) {
        // add the style attribute only to opening tags that don't already have one
        $h = preg_replace('/<' . $tag . '\b(?![^>]*\bstyle=)([^>]*)>/i', '<' . $tag . '$1 style="' . $css . '">', $h);
    }
    return $h;
}

// ------------------------------- --inspect -------------------------------
if ($opt['inspect']) {
    $line = str_repeat('-', 60);
    echo "BAGISTO STORE INSPECTION\n$line\n";

    echo "CHANNELS (use id for 'channels' pivot, code for scoping):\n";
    foreach (r(\Webkul\Core\Repositories\ChannelRepository::class)->all() as $c) {
        echo sprintf("  id=%s  code=%s  name=%s\n", $c->id, $c->code, $c->name);
    }

    echo "LOCALES:\n";
    foreach (r(\Webkul\Core\Repositories\LocaleRepository::class)->all() as $l) {
        echo sprintf("  id=%s  code=%s  name=%s\n", $l->id, $l->code, $l->name);
    }

    echo "ATTRIBUTE FAMILIES:\n";
    foreach (r(\Webkul\Attribute\Repositories\AttributeFamilyRepository::class)->all() as $f) {
        echo sprintf("  id=%s  code=%s  name=%s\n", $f->id, $f->code, $f->name);
    }

    echo "INVENTORY SOURCES:\n";
    foreach (r(\Webkul\Inventory\Repositories\InventorySourceRepository::class)->all() as $s) {
        echo sprintf("  id=%s  code=%s  name=%s\n", $s->id, $s->code, $s->name);
    }

    echo "CATEGORIES (id : name):\n";
    foreach (r(\Webkul\Category\Repositories\CategoryRepository::class)->all() as $cat) {
        echo sprintf("  id=%s  name=%s\n", $cat->id, method_exists($cat, 'translate') && $cat->translate(($GLOBALS['CONFIG']['locale_code'] ?? 'en')) ? $cat->translate($GLOBALS['CONFIG']['locale_code'] ?? 'en')->name : ($cat->name ?? '(?)'));
    }
    exit(0);
}

// ------------------------------- load JSON -------------------------------
$file = $opt['file'];
if (!$file) {
    fwrite(STDERR, "ERROR: --file=<path to bagisto-products.json> is required (or use --inspect).\n");
    exit(2);
}
$jsonPath = (str_starts_with($file, '/')) ? $file : $appBase . '/' . $file;
if (!is_file($jsonPath)) {
    fwrite(STDERR, "ERROR: JSON not found: $jsonPath\n");
    exit(2);
}
$data = json_decode((string) file_get_contents($jsonPath), true);
if (!is_array($data) || empty($data['products'])) {
    fwrite(STDERR, "ERROR: invalid or empty products JSON: $jsonPath\n");
    exit(2);
}

$solDir   = dirname($jsonPath);                 // solutions/<slug>/ (for resolving download files)
$slug     = $data['solution']['slug'] ?? 'solution';
$catPath  = $data['solution']['category_path'] ?? [];

// ------------------------------- resolve category ids -------------------------------
$categoryIds = $CONFIG['default_category_ids'];
if (!empty($catPath)) {
    $leaf = end($catPath);
    $catRepo = r(\Webkul\Category\Repositories\CategoryRepository::class);
    foreach ($catRepo->all() as $cat) {
        $name = (method_exists($cat, 'translate') && $cat->translate($CONFIG['locale_code']))
            ? $cat->translate($CONFIG['locale_code'])->name : ($cat->name ?? null);
        if ($name !== null && strcasecmp(trim($name), trim($leaf)) === 0) {
            $categoryIds = [$cat->id];
            break;
        }
    }
    if ($categoryIds === $CONFIG['default_category_ids']) {
        if ($opt['ensure_category']) {
            // create the category under Root (locale 'all' fans the translated attrs into every locale)
            $root = $catRepo->getModel()->whereNull('parent_id')->first();
            $catSlug = preg_replace('/[^a-z0-9]+/', '-', strtolower($leaf));
            $new = $catRepo->create([
                'locale'       => 'all',
                'parent_id'    => $root ? $root->id : 1,
                'status'       => 1,
                'position'     => 99,
                'display_mode' => 'products_and_description',
                'name'         => $leaf,
                'slug'         => trim($catSlug, '-'),
                'url_path'     => trim($catSlug, '-'),
                'description'  => $leaf . ' — Phoenixtekk Workplace Marketplace.',
                'meta_title'   => $leaf,
            ]);
            $categoryIds = [$new->id];
            echo "CATEGORY created '$leaf' (id {$new->id})\n";
        } else {
            fwrite(STDERR, "WARN: category '$leaf' not found; using default_category_ids. Create it, use --ensure-category, or categorize in admin.\n");
        }
    }
}

// ------------------------------- create products -------------------------------
$productRepo = r(\Webkul\Product\Repositories\ProductRepository::class);
$exit = 0;

// --------- optional purge: delete the JSON's SKUs so they can be cleanly recreated ---------
if ($opt['purge']) {
    foreach ($data['products'] as $p) {
        $sku = $p['sku'] ?? null;
        if (!$sku) continue;
        $existing = $productRepo->findOneByField('sku', $sku);
        if ($existing) {
            if ($opt['dry']) { echo "DRY    would PURGE $sku (id {$existing->id})\n"; continue; }
            $productRepo->delete($existing->id);
            echo "PURGE  $sku (deleted id {$existing->id})\n";
        } else {
            echo "PURGE  $sku (absent, nothing to delete)\n";
        }
    }
    if (!$opt['dry']) { echo "Purge complete. Re-run without --purge to recreate.\n"; }
    exit(0);
}

// --------- optional update-content: refresh name/descriptions/meta on EXISTING SKUs (re-styles HTML) ---------
if ($opt['update_content']) {
    foreach ($data['products'] as $p) {
        $sku = $p['sku'] ?? null;
        if (!$sku) continue;
        $existing = $productRepo->findOneByField('sku', $sku);
        if (!$existing) { echo "UPDATE $sku (absent, skipped)\n"; continue; }
        if ($opt['dry']) { echo "DRY    would update content on $sku\n"; continue; }
        $urlKey = $p['url_key'] ?? ($slug . '-' . ($p['audience'] ?? 'commercial'));
        try {
            $productRepo->update([
                'channel'              => $CONFIG['channel_code'],
                'locale'               => $CONFIG['locale_code'],
                'sku'                  => $sku,
                'name'                 => $p['name'],
                'url_key'              => $urlKey,
                'short_description'    => style_html($p['short_description'] ?? ''),
                'description'          => style_html($p['description'] ?? ''),
                'price'                => (float) $p['price'],
                'weight'               => 0,
                'status'               => 1,
                'visible_individually' => 1,
                'meta_title'           => $p['meta_title'] ?? $p['name'],
                'meta_description'     => $p['meta_description'] ?? '',
                'channels'             => [$CONFIG['channel_id']],
                'categories'           => $categoryIds,
                'inventories'          => [$CONFIG['inventory_source_id'] => $CONFIG['digital_qty']],
            ], $existing->id);

            // Bagisto's update() drops relations not present in the payload — so re-attach the
            // downloadable files and the base image (clearing any leftovers first to avoid dupes).
            foreach (\Webkul\Product\Models\ProductDownloadableLink::where('product_id', $existing->id)->get() as $l) {
                if ($l->file) { foreach (['/storage/app/private/', '/storage/app/public/'] as $dk) { $f = $appBase . $dk . $l->file; if (is_file($f)) @unlink($f); } }
                $l->delete();
            }
            foreach (\Webkul\Product\Models\ProductImage::where('product_id', $existing->id)->get() as $im) {
                $f = $appBase . '/storage/app/public/' . $im->path; if (is_file($f)) @unlink($f);
                $im->delete();
            }
            $extra = '';
            if (($existing->type ?? 'simple') === 'downloadable' && !empty($p['downloads'])) {
                $n = attach_downloads($existing->id, $p['downloads'], $solDir, $CONFIG['locale_code'], $appBase);
                $extra .= " (+$n download" . ($n === 1 ? '' : 's') . ")";
            }
            if (!empty($p['image']) && attach_image($existing->id, $p['image'], $solDir, $appBase)) { $extra .= " (+image)"; }

            echo "UPDATE $sku (content restyled)$extra\n";
        } catch (\Throwable $e) { echo "FAIL   $sku — " . $e->getMessage() . "\n"; }
    }
    exit(0);
}

// --------- optional replace-images: delete existing images on the SKUs, then attach the JSON image ---------
if ($opt['replace_images']) {
    foreach ($data['products'] as $p) {
        $sku = $p['sku'] ?? null;
        if (!$sku || empty($p['image'])) continue;
        $existing = $productRepo->findOneByField('sku', $sku);
        if (!$existing) { echo "IMAGE  $sku (absent, skipped)\n"; continue; }
        if ($opt['dry']) { echo "DRY    would REPLACE image on $sku with {$p['image']}\n"; continue; }
        // delete old image rows + their files
        $old = \Webkul\Product\Models\ProductImage::where('product_id', $existing->id)->get();
        foreach ($old as $img) {
            $abs = $appBase . '/storage/app/public/' . $img->path;
            if (is_file($abs)) @unlink($abs);
            $img->delete();
        }
        attach_image($existing->id, $p['image'], $solDir, $appBase)
            ? print("IMAGE  $sku (replaced -> {$p['image']})\n")
            : print("IMAGE  $sku (FAILED — file missing)\n");
    }
    exit(0);
}

// --------- optional sync-images: attach base image to EXISTING SKUs (idempotent) ---------
if ($opt['sync_images']) {
    foreach ($data['products'] as $p) {
        $sku = $p['sku'] ?? null;
        if (!$sku || empty($p['image'])) continue;
        $existing = $productRepo->findOneByField('sku', $sku);
        if (!$existing) { echo "IMAGE  $sku (absent, skipped)\n"; continue; }
        if (\Webkul\Product\Models\ProductImage::where('product_id', $existing->id)->exists()) {
            echo "IMAGE  $sku (already has image, skipped)\n"; continue;
        }
        if ($opt['dry']) { echo "DRY    would attach image to $sku ({$p['image']})\n"; continue; }
        attach_image($existing->id, $p['image'], $solDir, $appBase) ? print("IMAGE  $sku (attached {$p['image']})\n")
                                                                    : print("IMAGE  $sku (FAILED — file missing)\n");
    }
    exit(0);
}

foreach ($data['products'] as $p) {
    $sku = $p['sku'] ?? '(missing sku)';
    try {
        if ($productRepo->findOneByField('sku', $sku)) { echo "SKIP   $sku (already exists)\n"; continue; }

        $type = $p['type'] ?? 'simple';
        if ($opt['dry']) { echo "DRY    would CREATE $sku ($type) @ \$" . number_format((float) $p['price'], 2) . "\n"; continue; }

        // Step 1: create the shell
        $product = $productRepo->create([
            'type'                => $type,
            'attribute_family_id' => $CONFIG['attribute_family_id'],
            'sku'                 => $sku,
        ]);

        // Step 2: update with full attribute set
        $urlKey = $p['url_key'] ?? ($slug . '-' . ($p['audience'] ?? 'commercial'));
        $payload = [
            'channel'              => $CONFIG['channel_code'],   // CODE for scoping
            'locale'               => $CONFIG['locale_code'],    // CODE for scoping
            'sku'                  => $sku,
            'name'                 => $p['name'],
            'url_key'              => $urlKey,
            'short_description'    => style_html($p['short_description'] ?? ''),
            'description'          => style_html($p['description'] ?? ''),
            'price'                => (float) $p['price'],
            'weight'               => 0,
            'status'               => 1,
            'visible_individually' => 1,
            'meta_title'           => $p['meta_title'] ?? $p['name'],
            'meta_description'     => $p['meta_description'] ?? '',
            'channels'             => [$CONFIG['channel_id']],                       // ID for pivot
            'categories'           => $categoryIds,
            'inventories'          => [$CONFIG['inventory_source_id'] => $CONFIG['digital_qty']],
        ];
        $productRepo->update($payload, $product->id);

        // Step 3: attach downloadable files (best-effort headless; verify in admin on first publish)
        $attached = '';
        if ($type === 'downloadable' && !empty($p['downloads'])) {
            $n = attach_downloads($product->id, $p['downloads'], $solDir, $CONFIG['locale_code'], $appBase);
            $attached = " (+$n download" . ($n === 1 ? '' : 's') . ")";
        }

        // Step 4: attach base/listing image
        if (!empty($p['image']) && attach_image($product->id, $p['image'], $solDir, $appBase)) {
            $attached .= " (+image)";
        }

        echo "CREATE $sku$attached\n";
    } catch (\Throwable $e) {
        $exit = 1;
        echo "FAIL   $sku — " . $e->getMessage() . "\n";
    }
}

exit($exit);

/**
 * Attach downloadable links to a product, headless.
 * Copies file sources into storage/app/PRIVATE/product_downloadable_links/ (NOT the public,
 * web-symlinked disk — paid files must not be directly downloadable) and inserts
 * link rows (+ translation) via Bagisto models. Returns count attached.
 *
 * NOTE: downloadable file attachment outside the HTTP upload flow is the one part that
 * must be VERIFIED in admin on the first real publish (the DB backup is the safety net).
 */
function attach_downloads(int $productId, array $downloads, string $solDir, string $localeCode, string $appBase): int
{
    $count = 0;
    $diskDir = $appBase . '/storage/app/private/product_downloadable_links';
    if (!is_dir($diskDir)) @mkdir($diskDir, 0775, true);

    foreach ($downloads as $i => $d) {
        $type  = $d['source_type'] ?? 'file';
        $title = $d['title'] ?? ('Download ' . ($i + 1));

        // ProductDownloadableLink is a TranslatableModel (Astrotomic): `title` lives in the
        // translations table and the FK/locale are set by the trait — never insert the
        // translation row by hand. Set non-translated columns, then translateOrNew()->title.
        $link = new \Webkul\Product\Models\ProductDownloadableLink();
        $link->product_id = $productId;
        $link->type       = $type;
        $link->downloads  = 0;        // 0 = unlimited
        $link->sort_order = $i + 1;
        $link->price      = 0;

        if ($type === 'url') {
            $link->url = $d['source'];
        } else {
            $src = (str_starts_with($d['source'], '/')) ? $d['source'] : $solDir . '/' . $d['source'];
            if (!is_file($src)) { fwrite(STDERR, "WARN: download file missing, skipped: $src\n"); continue; }
            $base   = basename($src);
            $stored = 'product_downloadable_links/' . $productId . '-' . $base;
            copy($src, $appBase . '/storage/app/private/' . $stored);
            $link->file      = $stored;
            $link->file_name = $base;
        }

        // set the translated title for every configured locale (default at minimum)
        foreach (r(\Webkul\Core\Repositories\LocaleRepository::class)->all() as $loc) {
            $link->translateOrNew($loc->code)->title = $title;
        }
        $link->save();
        $count++;
    }
    return $count;
}

/**
 * Attach a base/listing image to a product, headless.
 * Copies the file into storage/app/public/product/<id>/ and inserts a product_images row
 * (type=image, position 0 = base image). product_images is NOT translatable — simple insert.
 */
function attach_image(int $productId, string $imageFile, string $solDir, string $appBase): bool
{
    $src = (str_starts_with($imageFile, '/')) ? $imageFile : $solDir . '/' . $imageFile;
    if (!is_file($src)) { fwrite(STDERR, "WARN: product image missing, skipped: $src\n"); return false; }

    $base   = basename($src);
    $relDir = 'product/' . $productId;
    $absDir = $appBase . '/storage/app/public/' . $relDir;
    if (!is_dir($absDir)) @mkdir($absDir, 0775, true);
    copy($src, $absDir . '/' . $base);

    \Webkul\Product\Models\ProductImage::create([
        'type'       => 'image',
        'path'       => $relDir . '/' . $base,
        'product_id' => $productId,
        'position'   => 0,
    ]);
    return true;
}
